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
#import "WPError+internal.h"

#define TIMEOUT_DEFAULT_SEC 60
#define TIMEOUT_INFINITE_SEC -1
#define TIMEOUT_WORKAROUND_SEC 112

@interface WePay_CardReader ()

@property (nonatomic, strong) NSString *clientId;
@property (nonatomic, strong) NSString *sessionId;

@property (nonatomic, assign) BOOL restartCardReaderAfterSuccess;
@property (nonatomic, assign) BOOL restartCardReaderAfterGeneralError;
@property (nonatomic, assign) BOOL restartCardReaderAfterOtherErrors;

@property (nonatomic, strong) id<RUADeviceManager> roamDeviceManager;
@property (nonatomic, strong) NSTimer *swipeTimeoutTimer;

@property (nonatomic, weak) id<WPCardReaderDelegate> externalCardReaderDelegate;
@property (nonatomic, weak) id<WPTokenizationDelegate> externalTokenizationDelegate;

@property (nonatomic, assign) BOOL swiperShouldTokenize;
@property (nonatomic, assign) BOOL swiperShouldWaitForSwipe;
@property (nonatomic, assign) BOOL swiperIsWaitingForSwipe;
@property (nonatomic, assign) BOOL swiperIsConnected;

@end

@implementation WePay_CardReader


- (instancetype) initWithConfig:(WPConfig *)config
{
    if (self = [super init]) {
        // pass the config to the client
        WPClient.config = config;
        
        // set the clientId
        self.clientId = config.clientId;

        // set the swiper restart options
        self.restartCardReaderAfterSuccess = config.restartCardReaderAfterSuccess;
        self.restartCardReaderAfterGeneralError = config.restartCardReaderAfterGeneralError;
        self.restartCardReaderAfterOtherErrors = config.restartCardReaderAfterOtherErrors;
    }
    
    return self;
}

- (void) startCardReaderForReadingWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate
{
    self.externalTokenizationDelegate = nil;
    self.externalCardReaderDelegate = cardReaderDelegate;
    self.sessionId = nil;
    
    [self startSwiperForTokenizing:NO];
}

- (void) startCardReaderForTokenizingWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate
                                       tokenizationDelegate:(id<WPTokenizationDelegate>) tokenizationDelegate
                                                  sessionId:(NSString *)sessionId;
{
    self.externalTokenizationDelegate = tokenizationDelegate;
    self.externalCardReaderDelegate = cardReaderDelegate;
    self.sessionId = sessionId;
    
    [self startSwiperForTokenizing:YES];
}

- (void) tokenizeSwipedPaymentInfo:(WPPaymentInfo *)paymentInfo
              tokenizationDelegate:(id<WPTokenizationDelegate>)tokenizationDelegate
                         sessionId:(NSString *)sessionId;
{
    self.externalTokenizationDelegate = tokenizationDelegate;

    NSError *error = [self validatePaymentInfoForTokenization:paymentInfo];

    if (error) {
        // invalid payment info, return error
        [self informExternalTokenizerFailure:error forPaymentInfo:paymentInfo];
    } else {
        [WPClient creditCardCreateSwipe:[self createSwipeRequestParamsForPaymentInfo:paymentInfo]
                           successBlock:^(NSDictionary * returnData) {
                               NSNumber *credit_card_id = [returnData objectForKey:@"credit_card_id"];
                               WPPaymentToken *token = [[WPPaymentToken alloc] initWithId:[credit_card_id stringValue]];
                               [self informExternalTokenizerSuccess:token forPaymentInfo:paymentInfo];
                           }
                           errorHandler:^(NSError * error) {
                               // Call error handler with error returned.
                               [self informExternalTokenizerFailure:error forPaymentInfo:paymentInfo];
                           }
         ];
    }
}

/**
 *  Stops the Roam device manager completely, and informs the delegate.
 */
- (void) stopCardReader
{
    self.swiperShouldWaitForSwipe = NO;

    // stop waiting for swipe and cancel all pending notifications
    [self stopWaitingForSwipe];

    // release and delete the device manager
    [self.roamDeviceManager releaseDevice];
    self.roamDeviceManager = nil;

    // inform delegate
    [self informExternalCardReader:kWPCardReaderStatusStopped];
}


#pragma mark Card Reader Swipe (private)

/**
 *  Initializes the swiper and waits for swipe
 *
 *  @param shouldTokenize determines if the obtained card info should be tokenized or not
 */
- (void) startSwiperForTokenizing:(BOOL)shouldTokenize
{
    // clear any pending actions
    [self stopWaitingForSwipe];

    // set options
    self.swiperShouldTokenize = shouldTokenize;
    self.swiperShouldWaitForSwipe = YES;

    // start swiper and wait for swipe
    if (!self.roamDeviceManager) {
        [self startRoamDeviceManager];
    } else {
        [self checkAndWaitForSwipe];
    }
}

/**
 *  Initializes roam device manager, providing self as the delegate for device status handler
 *  If initialization fails, sends an error to WPCardReaderDelegate
 *  If initialization succeeds, tries to wait for swipe
 */
- (void) startRoamDeviceManager
{
    self.roamDeviceManager = [RUA getDeviceManager:RUADeviceTypeG4x];

    BOOL init = [self.roamDeviceManager initializeDevice:self];
    if (init) {
        [[self.roamDeviceManager getConfigurationManager] setCommandTimeout:TIMEOUT_WORKAROUND_SEC];

        [self checkAndWaitForSwipe];
    } else {
        self.roamDeviceManager = nil;

        NSError *error = [WPError errorInitializingCardReader];
        [self informExternalCardReaderFailure:error];
        self.swiperShouldWaitForSwipe = NO;
    }
}

/**
 *  Checks if swiper is connected. If yes, informs WPCardReaderDelegate of connected status, and triggers device to wait for swipe
 *  If device is not connected, then informs WPCardReaderDelegate of not connected status
 */
- (void) checkAndWaitForSwipe
{
    if (self.swiperIsConnected) {
        [self waitForSwipe];
    } else {
        // Wait a few seconds for the swiper to be detected, otherwise announce not connected
        [self performSelector:@selector(informExternalCardReader:) withObject:kWPCardReaderStatusNotConnected afterDelay:3.5];
    }
}

/**
 *  Asks roam device manager to wait for swipe
 *  Starts timeout timer to stop waiting if swipe does not occur
 */
- (void) waitForSwipe
{
    self.swiperIsWaitingForSwipe = YES;
    id <RUATransactionManager> tmgr = [self.roamDeviceManager getTransactionManager];
    [tmgr waitForMagneticCardSwipe: ^(RUAProgressMessage messageType, NSString* additionalMessage) {
                                        switch (messageType) {
                                            case RUAProgressMessageWaitingforCardSwipe:
                                                [self informExternalCardReader:kWPCardReaderStatusWaitingForSwipe];
                                                break;
                                            case RUAProgressMessageSwipeDetected:
                                                [self informExternalCardReader:kWPCardReaderStatusSwipeDetected];
                                                break;
                                            default:
                                                // Do nothing on progress, react to the response when it comes
                                                break;
                                        }
                                    }
                          response: ^(RUAResponse *ruaResponse) {
                                        // check if we should wait for swipe again
                                        if ([self shouldKeepWaitingForSwipeAfterResponse:ruaResponse]) {
                                            [self waitForSwipe];
                                        } else {
                                            self.swiperShouldWaitForSwipe = NO;
                                            [self stopCardReader];
                                        }

                                        // process reponse from swiper
                                        [self handleResponse:ruaResponse];
                                    }
    ];

    // WORKAROUND: Roam's SDK does not properly handle assigned timeouts. We're working around that by immediately restarting the swiper when it timesout on its own.
    // when Roam fixes their SDK, we should handle timeouts correctly - ie, timeout at the correct time as configured, or never timeout if configured as such.
    NSInteger timeout = self.restartCardReaderAfterOtherErrors ? TIMEOUT_WORKAROUND_SEC : TIMEOUT_DEFAULT_SEC;

    
    // Reset swipe timeout timer
    [self.swipeTimeoutTimer invalidate];
    self.swipeTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval: timeout
                                                  target:self
                                                selector:@selector(handleSwipeTimeout)
                                                userInfo:@"Timed out" repeats:NO];
}

- (void) handleSwipeTimeout
{
    // inform external
    NSError *error = [WPError errorForCardReaderTimeout];
    [self informExternalCardReaderFailure:error];

    if (self.restartCardReaderAfterOtherErrors) {
        // keep waiting for swipe
        [self waitForSwipe];
    } else {
        // stop waiting
        self.swiperShouldWaitForSwipe = NO;
        [self stopCardReader];
    }
}

/**
 *  Determines if we should restart waiting for swipe based on the response and the configuration.
 *  We may restart waiting if a CardReaderGeneralError was returned by the swiper (and we're configured to wait). This usually happens due to a bad swipe.
 *  For successful swipes and unknown errors, we stop/restart waiting depending on the configuration.
 *
 */
- (BOOL) shouldKeepWaitingForSwipeAfterResponse:(RUAResponse *)ruaResponse
{
    // convert the response to a dictionary
    NSDictionary *responseData = [self RUAResponse_toDictionary:ruaResponse];

    // check for errors
    NSError *error = [self validateSwiperInfoForTokenization:responseData];
    if (error != nil) {
        // if the error code was a general error
        if (error.domain == kWPErrorSDKDomain && error.code == WPErrorCardReaderGeneralError) {
            // return whether or not we're configured to restart on general error
            return self.restartCardReaderAfterGeneralError;
        }
        // return whether or not we're configured to restart on other errors
        return self.restartCardReaderAfterOtherErrors;
    } else {
        // return whether or not we're configured to restart on success
        return self.restartCardReaderAfterSuccess;
    }
}

/**
 *  Stops waiting for swipe - cancels swipe timeout timer, cancels schduled checkAndWaitForSwipe, asks Roam to stop waiting for swipe
 *
 */
- (void) stopWaitingForSwipe
{
    // cancel waiting for swipe timeout timer
    [self.swipeTimeoutTimer invalidate];
    
    self.swiperIsWaitingForSwipe = NO;
    
    // cancel any scheduled wait for swipe
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(checkAndWaitForSwipe)
                                               object:nil];

    // cancel any scheduled notifications - kWPSwiperStatusNotConnected
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(informExternalCardReader:)
                                               object:kWPCardReaderStatusNotConnected];

    
    // tell RUA to stop waiting for swipe
    id <RUATransactionManager> tmgr = [self.roamDeviceManager getTransactionManager];
    [tmgr stopWaitingForMagneticCardSwipe];
}

/**
 *  Handle swipe response from Roam
 *
 *  @param ruaResponse The response
 */
- (void) handleResponse:(RUAResponse *) ruaResponse
{
    NSDictionary *responseData = [self RUAResponse_toDictionary:ruaResponse];
    NSError *error = [self validateSwiperInfoForTokenization:responseData];

    if (error != nil) {
        // we found an error, return it
        [self informExternalCardReaderFailure:error];
    } else {
        // extract useful non-encrypted data
        NSDictionary *info = @{@"firstName"         : [self firstNameFromRUAData:responseData],
                               @"lastName"          : [self lastNameFromRUAData:responseData],
                               @"paymentDescription": [responseData objectForKey:@"PAN"],
                               @"swiperInfo"        : responseData};

        WPPaymentInfo *paymentInfo = [[WPPaymentInfo alloc] initWithSwipedInfo:info];

        // return payment info to delegate
        [self informExternalCardReaderSuccess:paymentInfo];

        // tokenize if requested
        if(self.swiperShouldTokenize && self.externalTokenizationDelegate) {
            // inform external
            [self informExternalCardReader:kWPCardReaderStatusTokenizing];

            // tokenize
            [self tokenizeSwipedPaymentInfo:paymentInfo
                       tokenizationDelegate:self.externalTokenizationDelegate
                                  sessionId:self.sessionId];
        }
    }
}

/**
 *  Converts swiped payment info into request params for a create_swipe request
 *
 *  @param paymentInfo The swiped payment info
 *
 *  @return The request params
 */
- (NSDictionary *) createSwipeRequestParamsForPaymentInfo:(WPPaymentInfo *)paymentInfo
{
    NSDictionary *swiperInfo = paymentInfo.swiperInfo;

    NSString *fullName = [self fullNameFromRUAData:swiperInfo];
    NSString *track1Status = [swiperInfo objectForKey:@"track1Status"] ? [swiperInfo objectForKey:@"track1Status"] : @"0";
    NSString *track2Status = [swiperInfo objectForKey:@"track2Status"] ? [swiperInfo objectForKey:@"track2Status"] : @"0";

    NSString *formatID = [swiperInfo objectForKey:@"FormatID"];

    NSMutableDictionary * requestParams = [@{} mutableCopy];
    [requestParams setObject:self.clientId forKey:@"client_id"];
    [requestParams setObject:(fullName ? fullName : [NSNull null]) forKey:@"user_name"];
    [requestParams setObject:[swiperInfo objectForKey:@"EncryptedTrack"] forKey:@"encrypted_track"];
    [requestParams setObject:[swiperInfo objectForKey:@"KSN"] forKey:@"ksn"];
    [requestParams setObject:track1Status forKey:@"track_1_status"];
    [requestParams setObject:track2Status forKey:@"track_2_status"];
    [requestParams setObject:formatID forKey:@"format_id"];

    if (self.sessionId) {
        [requestParams setObject:self.sessionId forKey:@"device_token"];
    }

    if (paymentInfo.email) {
        [requestParams setObject:paymentInfo.email forKey:@"email"];
    }
    
    return requestParams;
}

/**
 *  Validates a payment info instance for tokenization.
 *
 *  @param paymentInfo the payment info to be validated.
 *
 *  @return NSError instance if validation fails, else nil.
 */
- (NSError *) validatePaymentInfoForTokenization:(WPPaymentInfo *)paymentInfo
{
    NSDictionary *swiperInfo = paymentInfo.swiperInfo;
    return [self validateSwiperInfoForTokenization:swiperInfo];
}

/**
 *  Validates swiper info for tokenization.
 *  If the swiper info has an error code, the appropriate error is returned. Otherwise, we validate that full name exists.
 *
 *  @param paymentInfo the payment info to be validated.
 *
 *  @return NSError instance if validation fails, else nil.
 */
- (NSError *) validateSwiperInfoForTokenization:(NSDictionary *)swiperInfo
{
    // if the swiper info has an error code, return the appropriate error
    if ([swiperInfo objectForKey: @"ErrorCode"] != nil) {
        return [WPError errorWithCardReaderResponseData:swiperInfo];
    }

    // check if name exists
    NSString *fullName = [self fullNameFromRUAData:swiperInfo];
    if (fullName == nil) {
        // this indicates a bad swipe or an unsupported card.
        // we expect all supported cards to return a name
        return [WPError errorCardReaderNameNotFound];
    }

    // no issues
    return nil;
}


#pragma mark ReaderStatusHandler

- (void)onConnected
{
    self.swiperIsConnected = YES;
    
    // Cancel any scheduled calls for swiper not connected
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(informExternalCardReader:)
                                               object:kWPCardReaderStatusNotConnected];
    
    // If we should wait for swipe
    if (self.swiperShouldWaitForSwipe) {
        // Inform external delegate
        [self informExternalCardReader:kWPCardReaderStatusConnected];

        // Check and wait - the delay is to let the swiper get charged
        [self performSelector:@selector(checkAndWaitForSwipe) withObject:nil afterDelay:2.0];
    }
}

- (void)onDisconnected
{
    self.swiperIsConnected = NO;
    
    // Inform external delegate if we should wait for swipe
    if (self.swiperShouldWaitForSwipe) {
        [self informExternalCardReader:kWPCardReaderStatusNotConnected];
    }
    
    // Stop waiting for swipe
    [self stopWaitingForSwipe];
}

- (void)onError:(NSString *)message
{
    NSLog(@"onError");
    self.swiperIsConnected = NO;

    // inform delegate
    NSError *error = [WPError errorForCardReaderStatusErrorWithMessage:message];
    [self informExternalCardReaderFailure:error];

    // Stop waiting for swipe
    [self stopWaitingForSwipe];
}

#pragma mark - inform external

- (void) informExternalCardReader:(NSString *)status
{
    // If the external delegate is listening for status updates, send it
    if (self.externalCardReaderDelegate && [self.externalCardReaderDelegate respondsToSelector:@selector(cardReaderDidChangeStatus:)]) {
        [self.externalCardReaderDelegate cardReaderDidChangeStatus:status];
    }
}

- (void) informExternalCardReaderSuccess:(WPPaymentInfo *)paymentInfo
{
    // If the external delegate is listening for success, send it
    if (self.externalCardReaderDelegate && [self.externalCardReaderDelegate respondsToSelector:@selector(didReadPaymentInfo:)]) {
        [self.externalCardReaderDelegate didReadPaymentInfo:paymentInfo];
    }
}

- (void) informExternalCardReaderFailure:(NSError *)error
{
    // If the external delegate is listening for errors, send it
    if (self.externalCardReaderDelegate && [self.externalCardReaderDelegate respondsToSelector:@selector(didFailToReadPaymentInfoWithError:)]) {
        [self.externalCardReaderDelegate didFailToReadPaymentInfoWithError:error];
    }
}

- (void) informExternalTokenizerSuccess:(WPPaymentToken *)token forPaymentInfo:(WPPaymentInfo *)paymentInfo
{
    // If the external delegate is listening for success, send it
    if (self.externalTokenizationDelegate && [self.externalTokenizationDelegate respondsToSelector:@selector(paymentInfo:didTokenize:)]) {
        [self.externalTokenizationDelegate paymentInfo:paymentInfo didTokenize:token];
    }
}

- (void) informExternalTokenizerFailure:(NSError *)error forPaymentInfo:(WPPaymentInfo *)paymentInfo
{
    // If the external delegate is listening for error, send it
    if (self.externalTokenizationDelegate && [self.externalTokenizationDelegate respondsToSelector:@selector(paymentInfo:didFailTokenization:)]) {
        [self.externalTokenizationDelegate paymentInfo:paymentInfo didFailTokenization:error];
    }
}

#pragma mark - Roam data manipulation

/**
 *  Converts Roam's response into a dictionary
 *
 *  @param response The response from Roam
 *
 *  @return The response as a dictionary
 */
- (NSDictionary *)RUAResponse_toDictionary:(RUAResponse *)response
{
    NSMutableDictionary *returnDict = [@{} mutableCopy];
    NSDictionary *responseData = [response responseData];
    
    [returnDict setObject:[RUAEnumerationHelper RUACommand_toString:[response command]] forKey:[RUAEnumerationHelper RUAParameter_toString:RUAParameterCommand]];
    [returnDict setObject:[RUAEnumerationHelper RUAResponseCode_toString:[response responseCode]] forKey:[RUAEnumerationHelper RUAParameter_toString:RUAParameterResponseCode]];
    [returnDict setObject:[RUAEnumerationHelper RUAResponseType_toString:[response responseType]] forKey:[RUAEnumerationHelper RUAParameter_toString:RUAParameterResponseType]];
    
    if ([response responseCode] == RUAResponseCodeError) {
        [returnDict setObject:[RUAEnumerationHelper RUAErrorCode_toString:[response errorCode]] forKey:[RUAEnumerationHelper RUAParameter_toString:RUAParameterErrorCode]];
        if ([response additionalErrorDetails] != nil) {
            [returnDict setObject:[response additionalErrorDetails] forKey:[RUAEnumerationHelper RUAParameter_toString:RUAParameterErrorDetails]];
        }
    }
    
    if (responseData != nil) {
        NSArray *keyArray =  [[response responseData] allKeys];
        int count = (int)[keyArray count];
        RUAParameter param;
        for (int i = 0; i < count; i++) {
            param = (RUAParameter)[[keyArray objectAtIndex:i] intValue];
            [returnDict setObject:[responseData objectForKey:[keyArray objectAtIndex:i]] forKey:[RUAEnumerationHelper RUAParameter_toString:param]];
        }
    }
    
    return returnDict;
}

/**
 *  Extracts first name from Roam response dictionary
 *
 *  @param ruaData Roam respose dictionary
 *
 *  @return first name if available, otherwise empty string
 */
- (NSString *) firstNameFromRUAData:(NSDictionary *) ruaData
{
    NSMutableString *encName = [[ruaData objectForKey:@"CardHolderName"] mutableCopy];
    CFStringTrimWhitespace((__bridge CFMutableStringRef) encName);
    NSArray *names = [encName componentsSeparatedByString:@"/"];
    
    NSString *result = @"";
    
    if (names && [names count] > 1) {
        result = names[1];
    }
    
    return result;
}

/**
 *  Extracts last name from Roam response dictionary
 *
 *  @param ruaData Roam respose dictionary
 *
 *  @return last name if available, otherwise empty string
 */

- (NSString *) lastNameFromRUAData:(NSDictionary *) ruaData
{
    NSMutableString *encName = [[ruaData objectForKey:@"CardHolderName"] mutableCopy];
    CFStringTrimWhitespace((__bridge CFMutableStringRef) encName);
    NSArray *names = [encName componentsSeparatedByString:@"/"];
    
    NSString *result = @"";
    
    if (names && [names count] > 0) {
        result = names[0];
    }
    
    return result;
}

/**
 *  Extracts full name from Roam response dictionary
 *
 *  @param ruaData Roam respose dictionary
 *
 *  @return full name if available, otherwise nil
 */

- (NSString *) fullNameFromRUAData:(NSDictionary *) ruaData
{
    NSString *name = [NSString stringWithFormat:@"%@ %@", [self firstNameFromRUAData:ruaData], [self lastNameFromRUAData:ruaData]];
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if ([@"" isEqualToString:name] ) {
        return nil;
    }
    
    return name;
}

@end

#endif
#endif

