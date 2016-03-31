//
//  WPG5XManager.m
//  WePay
//
//  Created by Chaitanya Bagaria on 8/4/15.
//  Copyright (c) 2015 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RPx/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA/RUA.h") && __has_include("G4XSwiper/SwiperController.h")

#import "WPG5XManager.h"
#import "WePay.h"
#import "WPConfig.h"
#import "WPError+internal.h"
#import "WPRoamHelper.h"

@interface WPG5XManager ()

@property (nonatomic, strong) id<RUADeviceManager> roamDeviceManager;
@property (nonatomic, assign) BOOL swiperShouldWaitForSwipe;
@property (nonatomic, assign) BOOL swiperIsWaitingForSwipe;
@property (nonatomic, assign) BOOL swiperIsConnected;

@property (nonatomic, assign) BOOL restartCardReaderAfterSuccess;
@property (nonatomic, assign) BOOL restartCardReaderAfterGeneralError;
@property (nonatomic, assign) BOOL restartCardReaderAfterOtherErrors;

@property (nonatomic, strong) NSTimer *swipeTimeoutTimer;

@end

@implementation WPG5XManager

- (instancetype) initWithConfig:(WPConfig *)config
{
    if (self = [super init]) {
        // set the swiper restart options
        self.restartCardReaderAfterSuccess = config.restartCardReaderAfterSuccess;
        self.restartCardReaderAfterGeneralError = config.restartCardReaderAfterGeneralError;
        self.restartCardReaderAfterOtherErrors = config.restartCardReaderAfterOtherErrors;
    }
    
    return self;
}

- (void) setManagerDelegate:(NSObject<WPDeviceManagerDelegate> *)managerDelegate
           externalDelegate:(NSObject<WPExternalCardReaderDelegate> *)externalDelegate
{
    self.managerDelegate = managerDelegate;
    self.externalDelegate = externalDelegate;
}

- (void) processCard
{
    // clear any pending actions
    [self stopWaitingForSwipe];

    if (self.roamDeviceManager == nil) {
        [self startDevice];
    }

    // set options
    self.swiperShouldWaitForSwipe = YES;

    // start swiper and wait for swipe
    [self checkAndWaitForSwipe];
}

- (BOOL) startDevice
{
    self.roamDeviceManager = [RUA getDeviceManager:RUADeviceTypeG4x];

    BOOL init = [self.roamDeviceManager initializeDevice:self];
    if (init) {
        [[self.roamDeviceManager getConfigurationManager] setCommandTimeout:TIMEOUT_WORKAROUND_SEC];
    } else {
        self.roamDeviceManager = nil;
    }

    return init;
}

/**
 *  Stops the Roam device manager completely, and informs the delegate.
 */
- (void) stopDevice
{
    self.swiperShouldWaitForSwipe = NO;

    // stop waiting for swipe and cancel all pending notifications
    [self stopWaitingForSwipe];

    // release and delete the device manager
    [self.roamDeviceManager releaseDevice];
    self.roamDeviceManager = nil;

    // inform delegate
    [self.externalDelegate informExternalCardReader:kWPCardReaderStatusStopped];
}


#pragma mark - (private)

/**
 *  Checks if swiper is connected. If yes, triggers device to wait for swipe
 *  If device is not connected, then informs WPCardReaderDelegate of not connected status
 */
- (void) checkAndWaitForSwipe
{
    if (self.swiperIsConnected) {
        [self waitForSwipe];
    } else {
        // Wait a few seconds for the swiper to be detected, otherwise announce not connected
        [self.externalDelegate performSelector:@selector(informExternalCardReader:) withObject:kWPCardReaderStatusNotConnected afterDelay:3.5];
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
                [self.externalDelegate informExternalCardReader:kWPCardReaderStatusWaitingForCard];
                break;
            case RUAProgressMessageSwipeDetected:
                [self.externalDelegate informExternalCardReader:kWPCardReaderStatusSwipeDetected];
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
                                  [self stopDevice];
                              }

                              // fetch Tx info from delegate
                              [self.managerDelegate fetchAuthInfo:^(BOOL implemented, NSDecimalNumber *amount, NSString *currencyCode, long accountId) {
                                  NSError *error = [self.managerDelegate validateAuthInfoImplemented:implemented amount:amount currencyCode:currencyCode accountId:accountId];
                                  if (error != nil) {
                                      // we found an error, return it
                                      [self.externalDelegate informExternalCardReaderFailure:error];
                                  } else {
                                      // process reponse from swiper
                                      NSMutableDictionary *responseData = [[WPRoamHelper RUAResponse_toDictionary:ruaResponse] mutableCopy];
                                      NSString *fullName = [WPRoamHelper fullNameFromRUAData:responseData];
                                      
                                      [responseData setObject:(fullName ? fullName : [NSNull null]) forKey:@"FullName"];
                                      [responseData setObject:kG5XModelName forKey:@"Model"];
                                      [responseData setObject:@(NO) forKey:@"Fallback"];
                                      [responseData setObject:@(accountId) forKey:@"AccountId"];
                                      [responseData setObject:currencyCode forKey:@"CurrencyCode"];
                                      [responseData setObject:amount forKey:@"Amount"];
                                      
                                      [self.managerDelegate handleSwipeResponse:responseData];
                                  }
                              }];
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
    [self.externalDelegate informExternalCardReaderFailure:error];

    if (self.restartCardReaderAfterOtherErrors) {
        // keep waiting for swipe
        [self waitForSwipe];
    } else {
        // stop waiting
        self.swiperShouldWaitForSwipe = NO;
        [self stopDevice];
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
    NSDictionary *responseData = [WPRoamHelper RUAResponse_toDictionary:ruaResponse];

    // check for errors
    NSError *error = [self.managerDelegate validateSwiperInfoForTokenization:responseData];
    return [self shouldKeepWaitingForCardAfterError:error forPaymentMethod:kWPPaymentMethodSwipe];
}

- (BOOL) shouldKeepWaitingForCardAfterError:(NSError *)error forPaymentMethod:(NSString *)paymentMethod;
{
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



#pragma mark ReaderStatusHandler

- (void)onConnected
{
    [self.managerDelegate connectedDevice:kG5XModelName];

    self.swiperIsConnected = YES;

    // Cancel any scheduled calls for swiper not connected
    [NSObject cancelPreviousPerformRequestsWithTarget:self.externalDelegate
                                             selector:@selector(informExternalCardReader:)
                                               object:kWPCardReaderStatusNotConnected];

    // If we should wait for swipe
    if (self.swiperShouldWaitForSwipe) {
        // Inform external delegate
        [self.externalDelegate informExternalCardReader:kWPCardReaderStatusConnected];

        // Check and wait - the delay is to let the swiper get charged
        [self performSelector:@selector(checkAndWaitForSwipe) withObject:nil afterDelay:2.0];
    }
}

- (void)onDisconnected
{
    [self.managerDelegate disconnectedDevice];
    self.swiperIsConnected = NO;

    // Inform external delegate if we should wait for swipe
    if (self.swiperShouldWaitForSwipe) {
        [self.externalDelegate informExternalCardReader:kWPCardReaderStatusNotConnected];
    }

    // Stop waiting for swipe
    [self stopWaitingForSwipe];
}

- (void)onError:(NSString *)message
{
    // gets called when wrong reader type is connected
    NSLog(@"onError");
    self.swiperIsConnected = NO;

    // inform delegate
    [self.managerDelegate handleDeviceStatusError:message];
}

@end

#endif
#endif