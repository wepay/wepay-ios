//
//  WPIngenicoCardReaderManager.m
//  WePay
//
//  Created by Chaitanya Bagaria on 8/4/15.
//  Copyright (c) 2015 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RPx_MFI/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA_MFI/RUA.h")

#import <RUA_MFI/RUA.h>
#import "WPIngenicoCardReaderManager.h"
#import "WePay.h"
#import "WPConfig.h"
#import "WPMockConfig.h"
#import "WPDipConfighelper.h"
#import "WPDipTransactionHelper.h"
#import "WPError+internal.h"
#import "WPRoamHelper.h"
#import "WPMockRoamDeviceManager.h"

#define CONNECTION_TIME_SEC 7

#define READ_AMOUNT [NSDecimalNumber one]
#define READ_CURRENCY @"USD"
#define READ_ACCOUNT_ID 12345

@interface WPIngenicoCardReaderManager () {
    int _currentPublicKeyIndex;
    __block WPIngenicoCardReaderManager *processor;
    NSTimer *readerInformNotConnectedTimer;
}

@property (nonatomic, strong) id<RUADeviceManager> roamDeviceManager;
@property (nonatomic, strong) WPDipConfigHelper *dipConfigHelper;
@property (nonatomic, strong) WPDipTransactionHelper *dipTransactionHelper;
@property (nonatomic, strong) WPConfig *config;
@property (nonatomic, strong) NSObject<WPExternalCardReaderDelegate> *externalDelegate;

@property (nonatomic, assign) BOOL readerShouldWaitForCard;
@property (nonatomic, assign) BOOL readerIsWaitingForCard;
@property (nonatomic, assign) BOOL readerIsConnected;
@property (nonatomic, assign) CardReaderRequest cardReaderRequest;

@property (nonatomic, strong) NSString *deviceSerialNumber;
@property (nonatomic, strong) NSString *connectedDeviceType;


@end

@implementation WPIngenicoCardReaderManager


- (instancetype) initWithConfig:(WPConfig *)config
     externalCardReaderDelegate:(NSObject<WPExternalCardReaderDelegate> *)delegate

{
    if (self = [super init]) {
        self.config = config;
        self.dipConfigHelper = [[WPDipConfigHelper alloc] initWithConfig:config];
        self.externalDelegate = delegate;
        self.dipTransactionHelper = [[WPDipTransactionHelper alloc] initWithConfigHelper:self.dipConfigHelper
                                                                                delegate:self
                                                              externalCardReaderDelegate:self.externalDelegate
                                                                                  config:self.config
                                     ];
    }
    
    WPIngenicoCardReaderDetector *detector = [[WPIngenicoCardReaderDetector alloc] init];
    [detector findFirstAvailableDeviceWithConfig:self.config deviceDetectionDelegate:self];
    
    // store a weak instance for using inside blocks
    processor = self;
    return processor;
}

- (void) processCard
{
    NSLog(@"processCard");

    // clear any pending actions
    [self stopWaitingForCard];

    // set options
    self.readerShouldWaitForCard = YES;

    // start card reader and wait for card
    [self checkAndWaitForEMVCard];
}

- (void) startCardReader
{
    [self startWaitingForReader];
    self.readerShouldWaitForCard = YES;
}

- (void) stopCardReader
{
    NSLog(@"stopCardReader");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self endTransaction];

        // inform delegate
        [self.externalDelegate informExternalCardReader:kWPCardReaderStatusStopped];
        
        if (self.roamDeviceManager) {
            // release and delete the device manager
            [self.roamDeviceManager releaseDevice];
            self.roamDeviceManager = nil;
            NSLog(@"released device manager");
        }
    });
}

- (void) endTransaction
{
    self.readerShouldWaitForCard = NO;
    
    // stop waiting for card and cancel all pending notifications
    [self stopWaitingForCard];
}

- (BOOL) shouldStopCardReaderAfterTransaction
{
    return self.config.stopCardReaderAfterTransaction;
}

- (BOOL) isConnected {
    return self.readerIsConnected && self.roamDeviceManager != nil;
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
        [self startWaitingForReader];
    }
}

- (void) startWaitingForReader {
    if (readerInformNotConnectedTimer) {
        [readerInformNotConnectedTimer invalidate];
    }
    
    readerInformNotConnectedTimer = [NSTimer timerWithTimeInterval:CONNECTION_TIME_SEC
                                                           repeats:NO
                                                             block:^(NSTimer * _Nonnull timer) {
                                                                 readerInformNotConnectedTimer = nil;
                                                                 [self.externalDelegate informExternalCardReader:kWPCardReaderStatusNotConnected];
                                                             }];
    [[NSRunLoop mainRunLoop] addTimer:readerInformNotConnectedTimer forMode:NSDefaultRunLoopMode];
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
    [readerInformNotConnectedTimer invalidate];
    readerInformNotConnectedTimer = nil;


    // cancel transaction in case it is running
    id <RUATransactionManager> tmgr = [self.roamDeviceManager getTransactionManager];
    [tmgr cancelLastCommand];
}

- (void) fetchAuthInfoForTransaction
{
    // fetch Tx info from delegate
    void (^amountCallback)(BOOL, NSDecimalNumber*, NSString*, long) = ^(BOOL implemented, NSDecimalNumber *amount, NSString *currencyCode, long accountId) {
        NSError *error = [self validateAuthInfoImplemented:implemented amount:amount currencyCode:currencyCode accountId:accountId];
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
                                                                      cardReaderRequest:self.cardReaderRequest];
        }
    };
    
    if (self.cardReaderRequest == CardReaderForTokenizing) {
        [self.externalDelegate informExternalCardReaderAmountCompletion:amountCallback];
    }
    else {
        amountCallback(YES, READ_AMOUNT, READ_CURRENCY, READ_ACCOUNT_ID);
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
        return [WPError errorInvalidTransactionAmount];
    } else if (![allowedCurrencyCodes containsObject:currencyCode]) {
        return [WPError errorInvalidTransactionCurrencyCode];
    } else if (accountId <= 0) {
        return [WPError errorInvalidTransactionAccountID];
    }
    
    // no validation errors
    return nil;
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

#pragma mark WPTransactionDelegate

/**
 *  Marks the currently running transaction as completed;
 */
- (void) transactionCompleted {
    [self endTransaction];
    
    if ([self shouldStopCardReaderAfterTransaction]) {
        [self stopCardReader];
    }
}

#pragma mark WPCardReaderDetectionDelegate
- (void)onCardReaderManagerDetected:(id<RUADeviceManager>)manager {
    self.roamDeviceManager = manager;
    [self.roamDeviceManager initializeDevice:self];
}

- (void)onCardReaderDetectionTimeout {
    NSLog(@"onCardReaderDetectionTimeout");
}

- (void)onCardReaderDetectionFailed:(NSString *)message {
    NSLog(@"device detection failed with message %@", message);
}

#pragma mark ReaderStatusHandler

- (void)onConnected
{
    NSLog(@"onConnected");
    NSLog(@"is device ready? %@", [self.roamDeviceManager isReady] ? @"YES":@"NO");

    if (!self.roamDeviceManager) {
        [self startCardReader];
    } else if (!self.readerIsConnected) {
        [processor fetchDeviceSerialNumber];
        
        // Cancel any scheduled calls for reader not connected
        if (readerInformNotConnectedTimer) [readerInformNotConnectedTimer invalidate];
        [NSObject cancelPreviousPerformRequestsWithTarget:self.externalDelegate
                                                 selector:@selector(informExternalCardReader:)
                                                   object:kWPCardReaderStatusNotConnected];
    }
    
    self.readerIsConnected = YES;
}

- (void)onDisconnected
{
    NSLog(@"onDisconnected");

    if (self.readerIsConnected) {
        // Inform external delegate if we should wait for card, and the reader was previously connected
        if (self.readerShouldWaitForCard) {
            [self.externalDelegate informExternalCardReader:kWPCardReaderStatusNotConnected];
            [self stopWaitingForCard];
        } else if (!self.config.stopCardReaderAfterTransaction) {
            // Inform external delegate
            [self.externalDelegate informExternalCardReader:kWPCardReaderStatusNotConnected];
        }
    }

    self.readerIsConnected = NO;
    self.deviceSerialNumber = nil;
}

- (void)onError:(NSString *)message
{
    // gets called when wrong reader type is connected
    NSLog(@"onError: %@", message);
    if (self.readerIsConnected) {
        if (self.readerIsWaitingForCard) {
            NSError *error = [WPError errorForCardReaderStatusErrorWithMessage:message];
            [self.externalDelegate informExternalCardReaderFailure:error];
            [self stopCardReader];
        }
        
        self.readerIsConnected = NO;
    }
}

@end

#endif
#endif
