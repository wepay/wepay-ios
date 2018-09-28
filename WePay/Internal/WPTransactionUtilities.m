//
//  TransactionUtilities.m
//  WePay
//
//  Created by Cameron Alley on 12/7/16.
//  Copyright © 2016 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RUA_MFI/RUA.h")

#import "WPTransactionUtilities.h"
#import "WePay.h"
#import "WPConfig.h"
#import "WPClient.h"
#import "WPIngenicoCardReaderManager.h"
#import "WPError+internal.h"
#import "WPRoamHelper.h"
#import "WPExternalCardReaderHelper.h"
#import "WPClientHelper.h"
#import "WPBatteryHelper.h"

@interface WPTransactionUtilities()

@property (nonatomic, strong) WPConfig *config;
@property (nonatomic, strong) id<WPExternalCardReaderDelegate> externalHelper;
@property (nonatomic, strong) NSString *sessionId;


@end

@implementation WPTransactionUtilities

- (instancetype) initWithConfig:(WPConfig *)config
      externalCardReaderHelper:(id<WPExternalCardReaderDelegate>) externalHelper
{
    if (self = [super init]) {
        self.config = config;
        self.externalHelper = externalHelper;
    }
    
    return self;
}


- (void) handleSwipeResponse:(NSDictionary *) responseData
              successHandler:(void (^)(NSDictionary * returnData)) successHandler
                errorHandler:(void (^)(NSError * error)) errorHandler
               finishHandler:(void (^)(void)) finishHandler
{
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
    
    [self handlePaymentInfo:paymentInfo
             successHandler:successHandler
               errorHandler:errorHandler
              finishHandler:finishHandler];
}

- (void) handlePaymentInfo:(WPPaymentInfo *)paymentInfo
            successHandler:(void (^)(NSDictionary * returnData)) successHandler
              errorHandler:(void (^)(NSError * error)) errorHandler
             finishHandler:(void (^)(void)) finishHandler
{
    [self.externalHelper informExternalTokenizerEmailCompletion:^(NSString *email) {
        if (email) {
            [paymentInfo addEmail:email];
        }
        
        // send paymentInfo to external delegate
        [self.externalHelper informExternalCardReaderSuccess:paymentInfo];
        
        // tokenize if requested
        if (self.cardReaderRequest == CardReaderForTokenizing && self.externalHelper.externalTokenizationDelegate) {
            
            NSError *error = [self validatePaymentInfoForTokenization:paymentInfo];
            if (error) {
                // invalid payment info, return error
                [self.externalHelper informExternalTokenizerFailure:error forPaymentInfo:paymentInfo];
                if (errorHandler != nil) {
                    errorHandler(error);
                }
            } else if (paymentInfo.swiperInfo) {
                // inform external
                [self.externalHelper informExternalCardReader:kWPCardReaderStatusTokenizing];
                
                // tokenize
                [self tokenizeSwipedPaymentInfo:paymentInfo
                           tokenizationDelegate:self.externalHelper.externalTokenizationDelegate
                                      sessionId:self.sessionId
                                 successHandler:successHandler
                                   errorHandler:errorHandler];
                
            } else if (paymentInfo.emvInfo) {
                
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
        } else {
            // done with tranaction, call finish
            if (finishHandler != nil) {
                finishHandler();
            }
        }
    }];
}


- (void) tokenizeSwipedPaymentInfo:(WPPaymentInfo *)paymentInfo
              tokenizationDelegate:(id<WPTokenizationDelegate>)tokenizationDelegate
                         sessionId:(NSString *)sessionId
                    successHandler:(void (^)(NSDictionary * returnData)) successHandler
                      errorHandler:(void (^)(NSError * error)) errorHandler
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
                               if (successHandler) {
                                   successHandler(returnData);
                               }
                           }
                           errorHandler:^(NSError * error) {
                               // Call error handler with error returned.
                               [self.externalHelper informExternalTokenizerFailure:error forPaymentInfo:paymentInfo];
                               if (errorHandler) {
                                   errorHandler(error);
                               }
                           }
         ];
    }
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
                           WPLog(@"creditCardAuthReverse success response: %@", returnData);
                       }
                       errorHandler:^(NSError * error) {
                           WPLog(@"creditCardAuthReverse error response: %@", error);
                       }];
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
        WPLog(@"validateSwiperInfoForTokenization: No encrypted track found");
        return [WPError errorInvalidCardData];
    }
    
    // check if KSN exists
    NSString *ksn = [swiperInfo objectForKey:@"KSN"];
    if (ksn == nil || [@"" isEqualToString:ksn]) {
        WPLog(@"validateSwiperInfoForTokenization: No KSN found");
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
