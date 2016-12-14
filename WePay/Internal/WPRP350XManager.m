//
//  WPRP350XManager.m
//  WePay
//
//  Created by Chaitanya Bagaria on 8/4/15.
//  Copyright (c) 2015 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RPx/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA/RUA.h") 

#import <RUA/RUA.h>
#import "WPRP350XManager.h"
#import "WePay.h"
#import "WPConfig.h"
#import "WPMockConfig.h"
#import "WPDipConfighelper.h"
#import "WPDipTransactionHelper.h"
#import "WPError+internal.h"
#import "WPRoamHelper.h"
#import "WPMockRoamDeviceManager.h"

#define RP350X_CONNECTION_TIME_SEC 5

@interface WPRP350XManager () {
    int _currentPublicKeyIndex;
    __block WPRP350XManager *processor;
}

@property (nonatomic, strong) id<RUADeviceManager> roamDeviceManager;
@property (nonatomic, strong) WPDipConfigHelper *dipConfigHelper;
@property (nonatomic, strong) WPDipTransactionHelper *dipTransactionHelper;
@property (nonatomic, strong) WPConfig *config;

@property (nonatomic, assign) BOOL readerShouldWaitForCard;
@property (nonatomic, assign) BOOL readerIsWaitingForCard;
@property (nonatomic, assign) BOOL readerIsConnected;

@property (nonatomic, strong) NSString *deviceSerialNumber;

@end

@implementation WPRP350XManager


- (instancetype) initWithConfig:(WPConfig *)config
{
    self.config = config;

    if (self = [super init]) {
        self.dipConfigHelper = [[WPDipConfigHelper alloc] initWithConfig:config];
        self.dipTransactionHelper = [[WPDipTransactionHelper alloc] initWithConfigHelper:self.dipConfigHelper
                                                                                delegate:self
                                                                             environment:self.config.environment];
    }
    
    // store a weak instance for using inside blocks
    processor = self;
    return processor;
}

- (void) setManagerDelegate:(NSObject<WPDeviceManagerDelegate> *)managerDelegate
           externalDelegate:(NSObject<WPExternalCardReaderDelegate> *)externalDelegate
{
    self.managerDelegate = managerDelegate;
    self.externalDelegate = externalDelegate;
}

- (void) processCard
{
    NSLog(@"processCard");

    // clear any pending actions
    [self stopWaitingForCard];

    if (self.roamDeviceManager == nil) {
        [self startDevice];
    }

    // set options
    self.readerShouldWaitForCard = YES;

    // start card reader and wait for card
    [self checkAndWaitForEMVCard];
}

- (BOOL) startDevice
{
    NSLog(@"startDevice: RUADeviceTypeRP350x");
    
    WPMockConfig *mockConfig = self.config.mockConfig;
    if (mockConfig == nil) {
        // to use the real card reader
        self.roamDeviceManager = [RUA getDeviceManager:RUADeviceTypeRP350x];
    } else {
        // to use the mock implementation of card reader
        self.roamDeviceManager = [WPMockRoamDeviceManager getDeviceManager];
        ((WPMockRoamDeviceManager *) self.roamDeviceManager).mockConfig = mockConfig;
    }
    
    BOOL init = [self.roamDeviceManager initializeDevice:self];
    if (init) {
        [[self.roamDeviceManager getConfigurationManager] setCommandTimeout:TIMEOUT_WORKAROUND_SEC];
    } else {
        self.roamDeviceManager = nil;
    }

    return init;
}

- (void) stopDevice
{
    NSLog(@"stopDevice");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.readerShouldWaitForCard = NO;

        // stop waiting for card and cancel all pending notifications
        [self stopWaitingForCard];

        // release and delete the device manager
        [self.roamDeviceManager releaseDevice];
        self.roamDeviceManager = nil;
        NSLog(@"released device manager");

        // inform delegate
        [self.externalDelegate informExternalCardReader:kWPCardReaderStatusStopped];
    });
}

- (void) transactionCompleted
{
    self.readerShouldWaitForCard = NO;
    
    // stop waiting for card and cancel all pending notifications
    [self stopWaitingForCard];
}

/**
 *  Determines if we should restart transaction based on the response and the configuration.
 *  We may restart waiting if a CardReaderGeneralError was returned by the reader (and we're configured to wait). This usually happens due to a bad swipe.
 *  For unknown errors, we stop/restart waiting depending on the configuration.
 *  For successful transactions we dont restart the transaction.
 *
 */
- (BOOL) shouldRestartTransactionAfterError:(NSError *)error
                           forPaymentMethod:(NSString *)paymentMethod;
{
    if (error != nil) {
        // if the error code was a general error
        if (error.domain == kWPErrorSDKDomain && error.code == WPErrorCardReaderGeneralError) {
            // return whether or not we're configured to restart on general error
            return self.config.restartTransactionAfterGeneralError;
        }
        // return whether or not we're configured to restart on other errors
        return self.config.restartTransactionAfterOtherErrors;
    } else if ([paymentMethod isEqualToString:kWPPaymentMethodSwipe]) {
        // return whether or not we're configured to restart on successful swipe
        return self.config.restartTransactionAfterSuccess;
    } else {
        // dont restart on successful dip
        return NO;
    }
}

- (BOOL) shouldStopCardReaderAfterTransaction
{
    return self.config.stopCardReaderAfterTransaction;
}


#pragma mark - (private)

- (void) checkAndWaitForEMVCard
{
    NSLog(@"checkAndWaitForEMVCard");
    if (self.readerIsConnected) {
        // inform external checking reader
        [self.externalDelegate informExternalCardReader:kWPCardReaderStatusCheckingReader];
        
        if (self.deviceSerialNumber != nil) {
            if ([self.dipConfigHelper compareStoredConfigHashForKey:self.deviceSerialNumber]) {
                [self resetDevice];
            } else {
                // call delegate method for device reset
                [self.externalDelegate informExternalCardReaderResetCompletion:^(BOOL shouldReset) {
                    if (shouldReset) {
                        [self resetDevice];
                    } else {
                        [processor setupExpectedDOLs];
                    }
                }];
            }

        } else {
            [self fetchDeviceSerialNumber];
        }

    } else {
        // Wait a few seconds for the reader to be detected, otherwise announce not connected
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.externalDelegate performSelector:@selector(informExternalCardReader:)
                                withObject:kWPCardReaderStatusNotConnected
                                afterDelay:RP350X_CONNECTION_TIME_SEC];
        });
    }
}

- (void) resetDevice
{
    _currentPublicKeyIndex = 0;

    [self.dipConfigHelper clearConfigHashForKey:self.deviceSerialNumber];
    [self setupAIDSandPublicKeys];
}

- (void) fetchDeviceSerialNumber
{
    id <RUAConfigurationManager> cmgr = [self.roamDeviceManager getConfigurationManager];
    [cmgr getReaderCapabilities: ^(RUAProgressMessage messageType, NSString* additionalMessage) {
                            NSLog(@"RUAProgressMessage: %@",[WPRoamHelper RUAProgressMessage_toString:messageType]);
                        }
                       response: ^(RUAResponse *ruaResponse) {
                           NSLog(@"RUAResponse: %@", [WPRoamHelper RUAResponse_toDictionary:ruaResponse]);
                           self.deviceSerialNumber = [[ruaResponse responseData] objectForKey:@((int)RUAParameterInterfaceDeviceSerialNumber)];
                           self.readerIsConnected = YES;

                           // If we should wait for card
                           if (self.readerShouldWaitForCard) {
                               // Inform external delegate
                               [self.externalDelegate informExternalCardReader:kWPCardReaderStatusConnected];

                               // Check and wait - the delay is to let the reader get charged
                               [self performSelector:@selector(checkAndWaitForEMVCard) withObject:nil afterDelay:1.0];
                           } else if (!self.config.stopCardReaderAfterTransaction) {
                               // Inform external delegate
                               [self.externalDelegate informExternalCardReader:kWPCardReaderStatusConnected];
                           }
                       }];
}


/**
 *  Stops waiting for card - cancels card timeout timer, cancels scheduled checkAndWaitForEMVCard, asks Roam to stop waiting for card
 *
 */
- (void) stopWaitingForCard
{
    NSLog(@"stopWaitingForCard");
    // cancel waiting for dip timeout timer
    // [self.dipTimeoutTimer invalidate];

    self.readerIsWaitingForCard = NO;

    // cancel any scheduled wait for card
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(checkAndWaitForEMVCard)
                                               object:nil];

    // cancel any scheduled notifications - kWPCardReaderStatusNotConnected
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(informExternalCardReader:)
                                               object:kWPCardReaderStatusNotConnected];


    // cancel transaction in case it is running
    id <RUATransactionManager> tmgr = [self.roamDeviceManager getTransactionManager];
    [tmgr cancelLastCommand];
}

- (void) fetchAuthInfoForTransaction
{
    // fetch Tx info from delegate
    [processor.managerDelegate fetchAuthInfo:^(BOOL implemented, NSDecimalNumber *amount, NSString *currencyCode, long accountId) {
        NSError *error = [self.managerDelegate validateAuthInfoImplemented:implemented amount:amount currencyCode:currencyCode accountId:accountId];
        if (error != nil) {
            // we found an error, return it
            [self.externalDelegate informExternalCardReaderFailure:error];
            
        } else {
            self.readerIsWaitingForCard = YES;
            
            // kick off transaction
            [processor.dipTransactionHelper performEMVTransactionStartCommandWithAmount:amount
                                                                           currencyCode:currencyCode
                                                                              accountid:accountId
                                                                      roamDeviceManager:self.roamDeviceManager
                                                                        managerDelegate:self.managerDelegate
                                                                       externalDelegate:self.externalDelegate];
        }
    }];
}

#pragma mark - EMV Reader Setup

- (void)setupTransactionDOLs
{
    NSLog(@"setupTransactionDOLs");
    __weak id <RUAConfigurationManager> cmgr = [self.roamDeviceManager getConfigurationManager];

    [cmgr setAmountDOL:self.dipConfigHelper.amountDOL progress:^(RUAProgressMessage messageType, NSString *additionalMessage) {
        NSLog(@"RUAProgressMessage: %@",[WPRoamHelper RUAProgressMessage_toString:messageType]);
    } response:^(RUAResponse *response) {
        NSLog(@"RUAResponseMessage: %@",[WPRoamHelper RUAResponse_toDictionary:response]);

        [cmgr setResponseDOL:self.dipConfigHelper.responseDOL progress:^(RUAProgressMessage messageType, NSString *additionalMessage) {
            NSLog(@"RUAProgressMessage: %@",[WPRoamHelper RUAProgressMessage_toString:messageType]);
        } response:^(RUAResponse *response) {
            NSLog(@"RUAResponseMessage: %@",[WPRoamHelper RUAResponse_toDictionary:response]);

            [cmgr setOnlineDOL:self.dipConfigHelper.onlineDOL progress:^(RUAProgressMessage messageType, NSString *additionalMessage) {
                NSLog(@"RUAProgressMessage: %@",[WPRoamHelper RUAProgressMessage_toString:messageType]);
            } response:^(RUAResponse *response) {
                NSLog(@"RUAResponseMessage: %@",[WPRoamHelper RUAResponse_toDictionary:response]);

                [processor setUserInterfaceOptions];
            }];
        }];
    }];
}

- (void) setUserInterfaceOptions
{
    id <RUAConfigurationManager> cmgr = [self.roamDeviceManager getConfigurationManager];

    [cmgr setUserInterfaceOptions:30
          withDefaultLanguageCode:RUALanguageCodeENGLISH
                withPinPadOptions:0x00
             withBackLightControl:0x00
                         progress: ^(RUAProgressMessage messageType, NSString* additionalMessage) {
                             NSLog(@"RUAProgressMessage: %@",[WPRoamHelper RUAProgressMessage_toString:messageType]);
                         }
                         response: ^(RUAResponse *response) {
                             NSLog(@"RUAResponseMessage: %@",[WPRoamHelper RUAResponse_toDictionary:response]);
                             [processor setupExpectedDOLs];
                         }];
}

- (void)setupExpectedDOLs
{
    id <RUAConfigurationManager> cmgr = [self.roamDeviceManager getConfigurationManager];
    [cmgr setExpectedAmountDOL:self.dipConfigHelper.amountDOL];
    [cmgr setExpectedResponseDOL:self.dipConfigHelper.responseDOL];
    [cmgr setExpectedOnlineDOL:self.dipConfigHelper.onlineDOL];

    [self performSelector:@selector(fetchAuthInfoForTransaction) withObject:nil afterDelay:1.0];
}

- (void)setupAIDSandPublicKeys {

    [processor clearAIDSList];
}

- (void) clearAIDSList
{
    //inform external about reader config
    [self.externalDelegate informExternalCardReader:kWPCardReaderStatusConfiguringReader];

    id <RUAConfigurationManager> cmgr = [self.roamDeviceManager getConfigurationManager];
    [cmgr clearAIDSList:NULL
               response: ^(RUAResponse *ruaResponse) {
                   NSLog(@"[debug] %@", [WPRoamHelper RUAResponse_toString:ruaResponse]);
                   [processor clearPublicKeys];
               }];
}

- (void)clearPublicKeys {
    id <RUAConfigurationManager> cmgr = [self.roamDeviceManager getConfigurationManager];
    [cmgr clearPublicKeys:NULL
                 response: ^(RUAResponse *ruaResponse) {
                     NSLog(@"[debug] %@", [WPRoamHelper RUAResponse_toString:ruaResponse]);
                     [processor submitAIDs];
                 }];
}

- (void)submitAIDs {
    id <RUAConfigurationManager> cmgr = [self.roamDeviceManager getConfigurationManager];
    [cmgr submitAIDList:self.dipConfigHelper.aidsList
               progress:^(RUAProgressMessage messageType, NSString* additionalMessage) {
                   NSLog(@"[debug] %s", __FUNCTION__);
               }
               response: ^(RUAResponse *ruaResponse) {
                   NSLog(@"[debug] %@", [WPRoamHelper RUAResponse_toString:ruaResponse]);
                   [processor submitPublicKeys];
               }];
}

- (void)submitPublicKeys {
    id <RUAConfigurationManager> cmgr = [self.roamDeviceManager getConfigurationManager];

    if ([self.dipConfigHelper.publicKeyList count] > _currentPublicKeyIndex) {
        RUAPublicKey *pubKey = (RUAPublicKey *)[self.dipConfigHelper.publicKeyList objectAtIndex:_currentPublicKeyIndex++];

        [cmgr submitPublicKey:pubKey
                     progress:^(RUAProgressMessage messageType, NSString* additionalMessage) {
                         NSLog(@"[debug] %s", __FUNCTION__);
                     }
                     response: ^(RUAResponse *ruaResponse) {
                         NSLog(@"[debug] %@", [WPRoamHelper RUAResponse_toString:ruaResponse]);
                         if (_currentPublicKeyIndex < [self.dipConfigHelper.publicKeyList count]) {
                             [processor submitPublicKeys];
                         }
                         else {
                             [processor.dipConfigHelper storeConfigHashForKey:self.deviceSerialNumber];
                             [processor setupTransactionDOLs];
                         }
                     }];
    } else {
        [processor.dipConfigHelper storeConfigHashForKey:self.deviceSerialNumber];
        [processor setupTransactionDOLs];
    }
}



#pragma mark ReaderStatusHandler

- (void)onConnected
{
    NSLog(@"onConnected");
    [self.managerDelegate connectedDevice:kRP350XModelName];

    if (!self.readerIsConnected) {
        [processor fetchDeviceSerialNumber];

        // Cancel any scheduled calls for reader not connected
        [NSObject cancelPreviousPerformRequestsWithTarget:self.externalDelegate
                                                 selector:@selector(informExternalCardReader:)
                                                   object:kWPCardReaderStatusNotConnected];
    }
}

- (void)onDisconnected
{
    NSLog(@"onDisconnected");
    [self.managerDelegate disconnectedDevice];

    // Inform external delegate if we should wait for card, and the reader was previously connected
    if (self.readerShouldWaitForCard && self.readerIsConnected) {
        [self.externalDelegate informExternalCardReader:kWPCardReaderStatusNotConnected];
        [self stopWaitingForCard];
    } else if (!self.config.stopCardReaderAfterTransaction) {
        // Inform external delegate
        [self.externalDelegate informExternalCardReader:kWPCardReaderStatusNotConnected];
    }

    self.readerIsConnected = NO;
    self.deviceSerialNumber = nil;
}

- (void)onError:(NSString *)message
{
    // gets called when wrong reader type is connected
    NSLog(@"onError");
    self.readerIsConnected = NO;

    // inform delegate
    [self.managerDelegate handleDeviceStatusError:message];
}


@end

#endif
#endif
