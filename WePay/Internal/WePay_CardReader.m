//
//  WePay_CardReader.m
//  WePay
//
//  Created by Chaitanya Bagaria on 11/17/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RPx/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA/RUA.h") && __has_include("G4XSwiper/SwiperController.h")

#import "WePay_CardReader.h"
#import "WePay.h"
#import "WPConfig.h"
#import "WPClient.h"
#import "WPRP350XManager.h"
#import "WPError+internal.h"
#import "WPRoamHelper.h"
#import "WPG5XManager.h"
#import "WPExternalCardReaderHelper.h"
#import "WPClientHelper.h"

NSString *const kRP350XModelName = @"RP350X";
NSString *const kG5XModelName = @"G5X";

#define READ_AMOUNT [NSDecimalNumber one]
#define READ_CURRENCY @"USD"
#define READ_ACCOUNT_ID 12345

@interface WePay_CardReader ()

@property (nonatomic, strong) WPConfig *config;
@property (nonatomic, strong) NSString *sessionId;

@property (nonatomic, strong) id<WPDeviceManager> deviceManager;
@property (nonatomic, strong) id<WPExternalCardReaderDelegate> externalHelper;

@property (nonatomic, strong) NSString *connectedDeviceType;

@property (nonatomic, assign) BOOL swiperShouldTokenize;

@end

@implementation WePay_CardReader

#define WEPAY_LAST_DEVICE_KEY @"wepay.last.device.type"

- (instancetype) initWithConfig:(WPConfig *)config
{
    if (self = [super init]) {
        // pass the config to the client
        WPClient.config = config;
        
        // save the config
        self.config = config;

        // create the external helper
        self.externalHelper = [[WPExternalCardReaderHelper alloc] initWithConfig:self.config];

        // fetch saved device type
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *lastDeviceType = [defaults objectForKey:WEPAY_LAST_DEVICE_KEY];
        
        // initialize a device manager
        // TODO: Implement Roam ReaderSearchListener, instead of trying each device ourselves
        if ([kG5XModelName isEqualToString:lastDeviceType]) {
            [self startSwiperManager];
        } else {
            [self startEMVManager];
        }

        // configure RUA
        #ifdef DEBUG
            // Log response only when in debug builds
            [RUA enableDebugLogMessages:YES];
        #else
            [RUA enableDebugLogMessages:NO];
        #endif
    }
    
    return self;
}

- (void) startSwiperManager
{
    self.deviceManager = [[WPG5XManager alloc] initWithConfig:self.config];
    [self.deviceManager setManagerDelegate:self
                          externalDelegate:self.externalHelper];
}

- (void) startEMVManager
{
    self.deviceManager = [[WPRP350XManager alloc] initWithConfig:self.config];
    [self.deviceManager setManagerDelegate:self
                          externalDelegate:self.externalHelper];
}

- (void) startCardReaderForReadingWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate
{
    self.externalHelper.externalTokenizationDelegate = nil;
    self.externalHelper.externalCardReaderDelegate = cardReaderDelegate;
    self.sessionId = nil;
    self.swiperShouldTokenize = NO;

   [self.deviceManager processCard];
}

- (void) startCardReaderForTokenizingWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate
                                       tokenizationDelegate:(id<WPTokenizationDelegate>) tokenizationDelegate
                                      authorizationDelegate:(id<WPAuthorizationDelegate>) authorizationDelegate
                                                  sessionId:(NSString *)sessionId
{
    self.externalHelper.externalCardReaderDelegate = cardReaderDelegate;
    self.externalHelper.externalTokenizationDelegate = tokenizationDelegate;
    self.externalHelper.externalAuthorizationDelegate = authorizationDelegate;
    self.sessionId = sessionId;
    self.swiperShouldTokenize = YES;

    [self.deviceManager processCard];
}

- (void) tokenizeSwipedPaymentInfo:(WPPaymentInfo *)paymentInfo
              tokenizationDelegate:(id<WPTokenizationDelegate>)tokenizationDelegate
                         sessionId:(NSString *)sessionId;
{
    self.externalHelper.externalTokenizationDelegate = tokenizationDelegate;

    NSError *error = [self validatePaymentInfoForTokenization:paymentInfo];

    if (error) {
        // invalid payment info, return error
        [self.externalHelper informExternalTokenizerFailure:error forPaymentInfo:paymentInfo];
    } else {

        NSDictionary *params = [WPClientHelper createCardRequestParamsForPaymentInfo:paymentInfo
                                                                            clientId:self.config.clientId
                                                                           sessionId:self.sessionId];

        [WPClient creditCardCreateSwipe:params
                           successBlock:^(NSDictionary * returnData) {
                               NSNumber *credit_card_id = [returnData objectForKey:@"credit_card_id"];
                               WPPaymentToken *token = [[WPPaymentToken alloc] initWithId:[credit_card_id stringValue]];
                               [self.externalHelper informExternalTokenizerSuccess:token forPaymentInfo:paymentInfo];
                           }
                           errorHandler:^(NSError * error) {
                               // Call error handler with error returned.
                               [self.externalHelper informExternalTokenizerFailure:error forPaymentInfo:paymentInfo];
                           }
         ];
    }
}

/**
 *  Stops the Roam device manager completely, and informs the delegate.
 */
- (void) stopCardReader
{
    [self.deviceManager stopDevice];
}

#pragma mark WPDeviceManagerDelegate methods

- (void) handleSwipeResponse:(NSDictionary *) responseData
{
    NSError *error = [self validateSwiperInfoForTokenization:responseData];

    if (error != nil) {
        // we found an error, return it
        [self.externalHelper informExternalCardReaderFailure:error];
    } else {
        // extract useful non-encrypted data
        NSString *pan = [responseData objectForKey:@"PAN"];
        if (pan == nil) {
            NSString *track2 = [responseData objectForKey:@"Track2Data"];
            if (track2 != nil) {
                pan = [self extractPANfromTrack2:track2];
            }
        }
        
        // pan can still be nil at this point
        pan = [self sanitizePAN:pan];
        
        NSDictionary *info = @{@"firstName"         : [WPRoamHelper firstNameFromRUAData:responseData],
                               @"lastName"          : [WPRoamHelper lastNameFromRUAData:responseData],
                               @"paymentDescription": pan ? pan : @"",
                               @"swiperInfo"        : responseData
                            };

        WPPaymentInfo *paymentInfo = [[WPPaymentInfo alloc] initWithSwipedInfo:info];

        // return payment info to delegate
        [self handlePaymentInfo:paymentInfo];
    }
}


- (void) handlePaymentInfo:(WPPaymentInfo *)paymentInfo
{
    [self handlePaymentInfo:paymentInfo successHandler:nil errorHandler:nil];
}

- (void) handlePaymentInfo:(WPPaymentInfo *)paymentInfo
            successHandler:(void (^)(NSDictionary * returnData)) successHandler
              errorHandler:(void (^)(NSError * error)) errorHandler
{
    [self.externalHelper informExternalTokenizerEmailCompletion:^(NSString *email) {
        if (email) {
            [paymentInfo addEmail:email];
        }

        // send paymentInfo to external delegate
        [self.externalHelper informExternalCardReaderSuccess:paymentInfo];

        // tokenize if requested
        if(self.swiperShouldTokenize && self.externalHelper.externalTokenizationDelegate) {
            if (paymentInfo.swiperInfo) {
                // inform external
                [self.externalHelper informExternalCardReader:kWPCardReaderStatusTokenizing];

                // tokenize
                [self tokenizeSwipedPaymentInfo:paymentInfo
                           tokenizationDelegate:self.externalHelper.externalTokenizationDelegate
                                      sessionId:self.sessionId];
            } else if (paymentInfo.emvInfo) {
                
                NSError *error = [self validatePaymentInfoForTokenization:paymentInfo];
                if (error) {
                    // invalid payment info, return error
                    [self.externalHelper informExternalTokenizerFailure:error forPaymentInfo:paymentInfo];
                    errorHandler(error);
                    
                } else {
                    // inform external
                    [self.externalHelper informExternalCardReader:kWPCardReaderStatusAuthorizing];
                    
                    // make params
                    NSDictionary *params = [WPClientHelper createCardRequestParamsForPaymentInfo:paymentInfo
                                                                                        clientId:self.config.clientId
                                                                                       sessionId:self.sessionId];
                    // execute api call
                    [WPClient creditCardCreateEMV:params
                                     successBlock:successHandler
                                     errorHandler:errorHandler];
                }
            }
        }

    }];
}

- (void) issueReversalForCreditCardId:(NSNumber *)creditCardId
                            accountId:(NSNumber *)accountId
                         roamResponse:(NSDictionary *)cardInfo
{
    NSDictionary *requestParams = [WPClientHelper reversalRequestParamsForCardInfo:cardInfo
                                                                          clientId:self.config.clientId
                                                                      creditCardId:creditCardId
                                                                         accountId:accountId];
    
    [WPClient creditCardAuthReverse:requestParams
                       successBlock:^(NSDictionary * returnData) {
                           NSLog(@"creditCardAuthReverse success response: %@", returnData);
                       }
                       errorHandler:^(NSError * error) {
                           NSLog(@"creditCardAuthReverse error response: %@", error);
                       }];
}

- (void) fetchAuthInfo:(void (^)(BOOL implemented, NSDecimalNumber *amount, NSString *currencyCode, long accountId))completion
{
    if (self.swiperShouldTokenize) {
        // ask external for auth info
        [self.externalHelper informExternalCardReaderAmountCompletion:completion];
    } else {
        // this is a read operation, auth a small amount
        completion(YES, READ_AMOUNT, READ_CURRENCY, READ_ACCOUNT_ID);
    }
}

- (NSError *) validateAuthInfoImplemented:(BOOL)implemented
                                   amount:(NSDecimalNumber *)amount
                             currencyCode:(NSString *)currencyCode
                                accountId:(long)accountId
{
    NSArray *allowedCurrencyCodes = @[kWPCurrencyCodeUSD];
    
    if (!implemented) {
        return [WPError errorAuthInfoNotProvided];
    } else if (amount == nil
               || [amount isEqual:[NSNull null]]
               || [[amount decimalNumberByMultiplyingByPowerOf10:2] intValue] < 99 // amount is less than 0.99
               || ([currencyCode isEqualToString:kWPCurrencyCodeUSD] && amount.decimalValue._exponent < -2)) { // USD amount has more than 2 places after decimal point
        return [WPError errorInvalidAuthInfo];
    } else if (![allowedCurrencyCodes containsObject:currencyCode]) {
        return [WPError errorInvalidAuthInfo];
    } else if (accountId <= 0) {
        return [WPError errorInvalidAuthInfo];
    }
    
    // no validation errors
    return nil;
}

- (void) handleDeviceStatusError:(NSString *)message
{
    // stop device silently
    [self.deviceManager setManagerDelegate:nil externalDelegate:nil];
    [self.deviceManager stopDevice];

    if ([@"Connected Device is not G4x" isEqualToString:message]) {
        [self startEMVManager];
        [self.deviceManager processCard];
    } else if ([@"Landi OpenDevice Error::-3" isEqualToString:message] || [@"Connected Device is not RP350x" isEqualToString:message]) {
        [self startSwiperManager];
        [self.deviceManager processCard];
    } else {
        NSError *error = [WPError errorForCardReaderStatusErrorWithMessage:message];
        [self.externalHelper informExternalCardReaderFailure:error];
    }
}

- (void) connectedDevice:(NSString *)deviceType
{
    if (![self.connectedDeviceType isEqualToString:deviceType]) {
        self.connectedDeviceType = deviceType;
        [self storeLastConnectedDeviceType:deviceType];
    }
}

- (void) disconnectedDevice
{
    self.connectedDeviceType = nil;
}

- (void)storeLastConnectedDeviceType:(NSString *)deviceTpe
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:deviceTpe forKey:WEPAY_LAST_DEVICE_KEY];
    [defaults synchronize];
}



- (NSError *) validatePaymentInfoForTokenization:(WPPaymentInfo *)paymentInfo
{
    if (paymentInfo.swiperInfo) {
        NSDictionary *swiperInfo = paymentInfo.swiperInfo;
        return [self validateSwiperInfoForTokenization:swiperInfo];
    } else if (paymentInfo.emvInfo) {
        NSDictionary *emvInfo = paymentInfo.emvInfo;
        return [self validateEMVInfoForTokenization:emvInfo];
    }

    // no issues
    return nil;
}

- (NSError *) validateSwiperInfoForTokenization:(NSDictionary *)swiperInfo
{
    // if the swiper info has an error code, return the appropriate error
    if ([swiperInfo objectForKey: @"ErrorCode"] != nil) {
        return [WPError errorWithCardReaderResponseData:swiperInfo];
    }

    // check if name exists
    NSString *fullName = [WPRoamHelper fullNameFromRUAData:swiperInfo];
    if (fullName == nil) {
        // this indicates a bad swipe or an unsupported card.
        // we expect all supported cards to return a name
        return [WPError errorNameNotFound];
    }

    // check if encrypted track exists
    NSString *encryptedTrack = [swiperInfo objectForKey:@"EncryptedTrack"];
    if (encryptedTrack == nil || [@"" isEqualToString:encryptedTrack]) {
        // this indicates a bad swipe or an unsupported card.
        // we expect all supported cards to return an encrypted track
        NSLog(@"validateSwiperInfoForTokenization: No encrypted track found");
        return [WPError errorInvalidCardData];
    }

    // check if KSN exists
    NSString *ksn = [swiperInfo objectForKey:@"KSN"];
    if (ksn == nil || [@"" isEqualToString:ksn]) {
        NSLog(@"validateSwiperInfoForTokenization: No KSN found");
        return [WPError errorInvalidCardData];
    }


    // no issues
    return nil;
}

- (NSError *) validateEMVInfoForTokenization:(NSDictionary *)emvInfo
{
    // validate same data as swiper
    return [self validateSwiperInfoForTokenization:emvInfo];
}

- (NSString *) sanitizePAN:(NSString *)pan
{
    if (pan == nil || [pan isEqual:[NSNull null]]) {
        return pan;
    }

    NSString *result = [pan stringByReplacingOccurrencesOfString:@"F" withString:@""];
    NSInteger length = [result length];

    if (length > 4) {
        result = [result stringByReplacingCharactersInRange:NSMakeRange(0, length - 4) withString:[@"" stringByPaddingToLength:length - 4 withString: @"X" startingAtIndex:0]];
    }

    return result;
}

- (NSString *) extractPANfromTrack2:(NSString *)track2
{
    if (track2 == nil) {
        return nil;
    }
    
    // decode track 2 from hex to ascii string
    NSMutableString * decodedTrack2 = [[NSMutableString alloc] init];
    int i = 0;
    while (i < [track2 length])
    {
        NSString * hexChar = [track2 substringWithRange: NSMakeRange(i, 2)];
        if ([hexChar isEqualToString:@"00"]) {
            hexChar = @"30";
        }
        
        int value = 0;
        sscanf([hexChar cStringUsingEncoding:NSASCIIStringEncoding], "%x", &value);
        [decodedTrack2 appendFormat:@"%c", (char)value];
        i+=2;
    }
    
    // find the PAN
    NSRange r1 = [decodedTrack2 rangeOfString:@";"];
    NSRange r2 = [decodedTrack2 rangeOfString:@"="];
    
    if (r1.length == 0 || r2.length == 0) {
        return nil;
    } else {
        NSRange rSub = NSMakeRange(r1.location + r1.length, r2.location - r1.location - r1.length);
        return [decodedTrack2 substringWithRange:rSub];
    }
}


@end

#endif
#endif

