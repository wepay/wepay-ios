//
//  WPIngenicoCardReaderManager.m
//  WePay
//
//  Created by Chaitanya Bagaria on 8/4/15.
//  Copyright (c) 2015 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RUA_MFI/RUA.h")

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
#import "WPUserDefaultsHelper.h"

#define CONNECTION_TIME_SEC 7

#define READ_AMOUNT [NSDecimalNumber one]
#define READ_CURRENCY @"USD"
#define READ_ACCOUNT_ID 12345
#define MAX_TRIES_FETCH_DEVICE_SERIAL_NUMBER 3

#define CARD_READER_TIMEOUT_INFINITE_SEC 0
#define CARD_READER_TIMEOUT_DEFAULT_SEC 60

@interface WPIngenicoCardReaderManager () {
    int _currentPublicKeyIndex;
    __block WPIngenicoCardReaderManager *processor;
    NSTimer *readerInformNotConnectedTimer;
    NSTimer *findReaderTimer;
    NSTimer *delayedOperationTimer;
}

@property (nonatomic, strong) id<RUADeviceManager> roamDeviceManager;
@property (nonatomic, strong) WPDipConfigHelper *dipConfigHelper;
@property (nonatomic, strong) WPDipTransactionHelper *dipTransactionHelper;
@property (nonatomic, strong) WPConfig *config;
@property (nonatomic, strong) NSObject<WPExternalCardReaderDelegate> *externalDelegate;

@property (nonatomic, assign) BOOL readerShouldPerformOperation;
@property (nonatomic, assign) BOOL readerIsWaitingForCard;
@property (nonatomic, assign) BOOL readerIsConnected;
@property (nonatomic, assign) BOOL isCardReaderStopped;
@property (nonatomic, assign) BOOL isSearching;
@property (nonatomic, assign) CardReaderRequest cardReaderRequest;

@property (nonatomic, strong) NSString *deviceSerialNumber;
@property (nonatomic, strong) NSString *connectedDeviceName;
@property (nonatomic, strong) WPIngenicoCardReaderDetector *detector;

@property (nonatomic, assign) NSInteger deviceSerialNumberFetchCount;

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
    
    // store a weak instance for using inside blocks
    processor = self;
    return processor;
}

- (void) processCardReaderRequest
{
    WPLog(@"processCardReaderRequest");
    // clear any pending actions
    [self stopFindingCardReaders];
    [self stopWaitingForCard];
    [self stopPendingOperations];
    self.readerShouldPerformOperation = YES;
    self.isCardReaderStopped = NO;

    if (self.cardReaderRequest == CardReaderForBatteryLevel) {
        [self checkAndWaitForBatteryLevel];
    } else {
        [self checkAndWaitForEMVCard];
    }
}

- (void) startCardReader
{
    self.readerShouldPerformOperation = YES;
    self.isCardReaderStopped = NO;
    [self startWaitingForReader];

    // If currently searching for card readers, stop the search and begin again
    if (self.isSearching) {
        [self stopFindingCardReaders];
        [self findCardReadersAfterDelay:1];
    } else {
        [self findCardReaders];
    }
}

- (void) stopCardReader
{
    WPLog(@"stopCardReader");

    self.isCardReaderStopped = YES;
    self.readerIsConnected = NO;
    [self endOperation];
    [self stopFindingCardReaders];
    [self.dipTransactionHelper stopTransaction];
    
    if (self.roamDeviceManager) {
        // iOS-specific workaround to get the result we want.
        [self stopRoamCardReaderCommandWorkaround];
    } else {
        // Card reader was stopped before we could find/initialize the RoamDeviceManager,
        // so just issue the kWPCardReaderStatusStopped status by default.
        [self.externalDelegate informExternalCardReader:kWPCardReaderStatusStopped];
    }
}

- (void) endOperation
{
    self.readerShouldPerformOperation = NO;
    
    // stop waiting for card and cancel all pending notifications
    [self stopWaitingForCard];
}

/** This function is a break from Android implementation because of the varying reader behavior */
- (void) stopRoamCardReaderCommandWorkaround
{
    id <RUATransactionManager> tmgr = [self.roamDeviceManager getTransactionManager];
    [tmgr sendCommand:RUACommandEMVTransactionStop withParameters:nil
             progress: ^(RUAProgressMessage messageType, NSString* additionalMessage) {
                 NSString *helpMsg = [WPRoamHelper RUAProgressMessage_toString:messageType];
                 WPLog(@"stopCardReader RUAProgressMessage: %@", helpMsg);
                 
                 // For read transactions, Roam gives us this progress message, but then
                 // hangs instead of responds. Releasing RoamDeviceManager at this point
                 // will properly bring down the card reader.
                 if (messageType == RUAProgressMessagePleaseRemoveCard) {
                     WPLog(@"Encountered expected progress message while stopping card reader. Releasing deviceManager.");
                     [self tearDownDeviceManager];
                 }
             }
             response: ^(RUAResponse *ruaResponse) {
                 WPLog(@"stopCardReader RUAResponseMessage: %@",[WPRoamHelper RUAResponse_toDictionary:ruaResponse]);
                 
                 RUAErrorCode errorCode = ruaResponse.errorCode;
                 
                 // For tokenize transactions, Roam responds with this error. The workaround
                 // is to simply try again.
                 if (errorCode == RUAErrorCodeCommandCancelledUponReceiptOfACancelWaitCommand) {
                     WPLog(@"Encountered expected error response while stopping card reader. Trying again.");
                     
                     [self stopCardReader];
                 } else {
                     [self tearDownDeviceManager];
                 }
             }
     ];
}

- (void) tearDownDeviceManager
{
    if (self.roamDeviceManager) {
        // The external 'kWPCardReaderStatusStopped' status won't get issued until the release finishes.
        [self.roamDeviceManager releaseDevice:self];
    }
}

- (BOOL) shouldStopCardReaderAfterOperation
{
    return self.config.stopCardReaderAfterOperation;
}

- (BOOL) shouldDelayOperation {
    return self.dipTransactionHelper != nil && self.dipTransactionHelper.isWaitingForCardRemoval;
}

- (BOOL) isConnected {
    return self.readerIsConnected && self.roamDeviceManager != nil;
}

#pragma mark - (private)

- (void) checkAndWaitForBatteryLevel {
    if ([self isConnected]) {
        [self createDelayedOperation:@selector(checkBatteryLevel) withDelay:1];
    } else {
        [self startCardReader];
    }
}

- (void) checkBatteryLevel {
    WPLog(@"checkBatteryLevel");
    if ([self isConnected]) {
        if ([self shouldDelayOperation]) {
            // Recursively delay by 1 second while we should be delaying
            [self createDelayedOperation:@selector(checkBatteryLevel) withDelay:1.0];
        } else {
            self.readerShouldPerformOperation = YES;
            [self.roamDeviceManager getBatteryStatus:^(RUAResponse *response) {
                NSDictionary *responseData = [WPRoamHelper RUAResponse_toDictionary:response];
                NSString *errorCode = [responseData objectForKey: [WPRoamHelper RUAParameter_toString:RUAParameterErrorCode]];
                
                if (errorCode) {
                    WPLog(@"Error getting battery level. RUAResponse: %@", responseData);
                    [self.externalDelegate informExternalBatteryLevelError:[WPError errorFailedToGetBatteryLevel]];
                    if ([self shouldStopCardReaderAfterOperation]) {
                        [self stopCardReader];
                    }
                } else {
                    NSString *batteryLevelStr = [responseData objectForKey: [WPRoamHelper RUAParameter_toString:RUAParameterBatteryLevel]];
                    int batteryLevel = [batteryLevelStr intValue];
                    [self.externalDelegate informExternalBatteryLevelSuccess:batteryLevel];
                    if ([self shouldStopCardReaderAfterOperation]) {
                        [self stopCardReader];
                    } else {
                        [self endOperation];
                    }
                }
            }];
        }
    } else {
        [self startCardReader];
    }
}

- (void) checkAndWaitForEMVCard
{
    WPLog(@"checkAndWaitForEMVCard");
    if ([self isConnected]) {
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
            self.deviceSerialNumberFetchCount = 0;
            [self fetchDeviceSerialNumber];
        }
    } else if (!self.isCardReaderStopped) {
        [self startCardReader];
    } else {
        // Nothing to do. Getting to this point means stopCardReader was called.
    }
}

- (void) startWaitingForReader {
    if (readerInformNotConnectedTimer) {
        [readerInformNotConnectedTimer invalidate];
    }
    
    readerInformNotConnectedTimer = [NSTimer timerWithTimeInterval:CONNECTION_TIME_SEC
                                                            target:self
                                                          selector:@selector(waitForReaderTimeout)
                                                          userInfo:nil
                                                           repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:readerInformNotConnectedTimer forMode:NSDefaultRunLoopMode];
}

- (void) waitForReaderTimeout {
    WPLog(@"Waiting for reader timed out. Signalling not connected.");
    
    readerInformNotConnectedTimer = nil;
    [self.externalDelegate informExternalCardReader:kWPCardReaderStatusNotConnected];
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
    self.deviceSerialNumberFetchCount++;
    
    [cmgr getReaderCapabilities: ^(RUAProgressMessage messageType, NSString* additionalMessage) {
                            WPLog(@"RUAProgressMessage: %@",[WPRoamHelper RUAProgressMessage_toString:messageType]);
                        }
                       response: ^(RUAResponse *ruaResponse) {
                           WPLog(@"RUAResponse: %@", [WPRoamHelper RUAResponse_toDictionary:ruaResponse]);
                           self.deviceSerialNumber = [[ruaResponse responseData] objectForKey:@((int)RUAParameterInterfaceDeviceSerialNumber)];
                           
                           // Only proceed with completing the connection if we were able to get a serial number.
                           if (self.deviceSerialNumber) {
                               self.readerIsConnected = YES;

                               // If we should wait for card
                               if (self.readerShouldPerformOperation) {
                                   // Inform external delegate
                                   [self.externalDelegate informExternalCardReader:kWPCardReaderStatusConnected];
                                   
                                   // Check and wait - the delay is to let the reader get charged
                                   if (self.cardReaderRequest == CardReaderForBatteryLevel) {
                                       [self createDelayedOperation:@selector(checkBatteryLevel) withDelay:1.0];
                                   } else {
                                       [self performSelector:@selector(checkAndWaitForEMVCard) withObject:nil afterDelay:1.0];
                                   }
                               } else if (!self.config.stopCardReaderAfterOperation) {
                                   // Inform external delegate
                                   [self.externalDelegate informExternalCardReader:kWPCardReaderStatusConnected];
                               }
                           } else if (self.deviceSerialNumberFetchCount < MAX_TRIES_FETCH_DEVICE_SERIAL_NUMBER) {
                               // Sometimes Roam doesn't give us the device serial number the first time,
                               // so we'll ask again.
                               [self fetchDeviceSerialNumber];
                           } else {
                               // If we can't fetch the serial number after multiple retries,
                               // we'll configure the reader fromm scratch.
                               [self resetDevice];
                           }
                       }];
}


/**
 *  Stops waiting for card - cancels card timeout timer, cancels scheduled checkAndWaitForEMVCard, asks Roam to stop waiting for card
 *
 */
- (void) stopWaitingForCard
{
    WPLog(@"stopWaitingForCard");
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

- (void) stopPendingOperations {
    WPLog(@"stopPendingOperations");
    if (delayedOperationTimer) {
        [delayedOperationTimer invalidate];
    }
    delayedOperationTimer = nil;
}

- (void) createDelayedOperation:(SEL)selector withDelay:(NSTimeInterval)delay {
    [self stopPendingOperations];
    delayedOperationTimer = [NSTimer timerWithTimeInterval:delay target:self selector:selector userInfo:nil repeats:NO];
    
    [[NSRunLoop mainRunLoop] addTimer:delayedOperationTimer forMode:NSDefaultRunLoopMode];
}

- (void) fetchAuthInfoForTransaction
{
    if ([self isConnected]) {
        if ([self shouldDelayOperation]) {
            // Delay by 1 second while we should be delaying
            [self createDelayedOperation:@selector(fetchAuthInfoForTransaction) withDelay:1.0];
        } else {
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
            } else if (self.cardReaderRequest == CardReaderForReading) {
                amountCallback(YES, READ_AMOUNT, READ_CURRENCY, READ_ACCOUNT_ID);
            } else {
                WPLog(@"fetchAuthInfoForTransaction called with invalid card reader request type.");
            }
        }
    } else {
        // Nothing to do. Getting to this point either means stopCardReader was called or
        // the reader got disconnected.
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

- (void) stopFindingCardReaders {
    self.isSearching = NO;
    if (self.detector) {
        [self.detector stopFindingCardReaders];
        self.detector = nil;
    }
    
    if (findReaderTimer) {
        [findReaderTimer invalidate];
    }
}

- (void) findCardReaders {
    self.isSearching = YES;
    self.detector = [[WPIngenicoCardReaderDetector alloc] init];
    [self.detector findAvailablCardReadersWithConfig:self.config deviceDetectionDelegate:self];
    [self.externalDelegate informExternalCardReader:kWPCardReaderStatusSearching];
}

- (void) findCardReadersAfterDelay:(NSTimeInterval) delay {
    self.isSearching = YES;
    findReaderTimer = [NSTimer timerWithTimeInterval:delay target:self selector:@selector(findCardReaders) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:findReaderTimer forMode:NSDefaultRunLoopMode];
}

#pragma mark - EMV Reader Setup

- (void) setupTransactionDOLs
{
    WPLog(@"setupTransactionDOLs");
    __weak id <RUAConfigurationManager> cmgr = [self.roamDeviceManager getConfigurationManager];

    [cmgr setAmountDOL:self.dipConfigHelper.amountDOL progress:^(RUAProgressMessage messageType, NSString *additionalMessage) {
        WPLog(@"RUAProgressMessage: %@",[WPRoamHelper RUAProgressMessage_toString:messageType]);
    } response:^(RUAResponse *response) {
        WPLog(@"RUAResponseMessage: %@",[WPRoamHelper RUAResponse_toDictionary:response]);

        [cmgr setResponseDOL:self.dipConfigHelper.responseDOL progress:^(RUAProgressMessage messageType, NSString *additionalMessage) {
            WPLog(@"RUAProgressMessage: %@",[WPRoamHelper RUAProgressMessage_toString:messageType]);
        } response:^(RUAResponse *response) {
            WPLog(@"RUAResponseMessage: %@",[WPRoamHelper RUAResponse_toDictionary:response]);

            [cmgr setOnlineDOL:self.dipConfigHelper.onlineDOL progress:^(RUAProgressMessage messageType, NSString *additionalMessage) {
                WPLog(@"RUAProgressMessage: %@",[WPRoamHelper RUAProgressMessage_toString:messageType]);
            } response:^(RUAResponse *response) {
                WPLog(@"RUAResponseMessage: %@",[WPRoamHelper RUAResponse_toDictionary:response]);

                [processor setUserInterfaceOptions];
            }];
        }];
    }];
}

- (void) setUserInterfaceOptions
{
    id <RUAConfigurationManager> cmgr = [self.roamDeviceManager getConfigurationManager];

    [cmgr setUserInterfaceOptions:[self getCardReaderTimeout]
          withDefaultLanguageCode:RUALanguageCodeENGLISH
                withPinPadOptions:0x00
             withBackLightControl:0x00
                         progress: ^(RUAProgressMessage messageType, NSString* additionalMessage) {
                             WPLog(@"RUAProgressMessage: %@",[WPRoamHelper RUAProgressMessage_toString:messageType]);
                         }
                         response: ^(RUAResponse *response) {
                             WPLog(@"RUAResponseMessage: %@",[WPRoamHelper RUAResponse_toDictionary:response]);
                             if (self.cardReaderRequest == CardReaderForBatteryLevel) {
                                 [self checkBatteryLevel];
                             } else {
                                 [processor setupExpectedDOLs];
                             }
                         }];
}

- (void) setupExpectedDOLs
{
    id <RUAConfigurationManager> cmgr = [self.roamDeviceManager getConfigurationManager];
    [cmgr setExpectedAmountDOL:self.dipConfigHelper.amountDOL];
    [cmgr setExpectedResponseDOL:self.dipConfigHelper.responseDOL];
    [cmgr setExpectedOnlineDOL:self.dipConfigHelper.onlineDOL];

    [self performSelector:@selector(fetchAuthInfoForTransaction) withObject:nil afterDelay:1.0];
}

- (void) setupAIDSandPublicKeys {

    [processor clearAIDSList];
}

- (void) clearAIDSList
{
    //inform external about reader config
    [self.externalDelegate informExternalCardReader:kWPCardReaderStatusConfiguringReader];

    id <RUAConfigurationManager> cmgr = [self.roamDeviceManager getConfigurationManager];
    [cmgr clearAIDSList:NULL
               response: ^(RUAResponse *ruaResponse) {
                   WPLog(@"[debug] %@", [WPRoamHelper RUAResponse_toString:ruaResponse]);
                   [processor clearPublicKeys];
               }];
}

- (void) clearPublicKeys {
    id <RUAConfigurationManager> cmgr = [self.roamDeviceManager getConfigurationManager];
    [cmgr clearPublicKeys:NULL
                 response: ^(RUAResponse *ruaResponse) {
                     WPLog(@"[debug] %@", [WPRoamHelper RUAResponse_toString:ruaResponse]);
                     [processor submitAIDs];
                 }];
}

- (void) submitAIDs {
    id <RUAConfigurationManager> cmgr = [self.roamDeviceManager getConfigurationManager];
    [cmgr submitAIDList:self.dipConfigHelper.aidsList
               progress:^(RUAProgressMessage messageType, NSString* additionalMessage) {
                   WPLog(@"[debug] %s", __FUNCTION__);
               }
               response: ^(RUAResponse *ruaResponse) {
                   WPLog(@"[debug] %@", [WPRoamHelper RUAResponse_toString:ruaResponse]);
                   [processor submitPublicKeys];
               }];
}

- (void) submitPublicKeys {
    id <RUAConfigurationManager> cmgr = [self.roamDeviceManager getConfigurationManager];

    if ([self.dipConfigHelper.publicKeyList count] > _currentPublicKeyIndex) {
        RUAPublicKey *pubKey = (RUAPublicKey *)[self.dipConfigHelper.publicKeyList objectAtIndex:_currentPublicKeyIndex++];

        [cmgr submitPublicKey:pubKey
                     progress:^(RUAProgressMessage messageType, NSString* additionalMessage) {
                         WPLog(@"[debug] %s", __FUNCTION__);
                     }
                     response: ^(RUAResponse *ruaResponse) {
                         WPLog(@"[debug] %@", [WPRoamHelper RUAResponse_toString:ruaResponse]);
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
    if ([self shouldStopCardReaderAfterOperation]) {
        [self stopCardReader];
    } else {
        [self endOperation];
    }
}

#pragma mark WPCardReaderDetectionDelegate

- (void) onCardReaderDevicesDetected:(NSArray *)devices {
    self.isSearching = NO;
    
    NSArray *deviceNames = [self getNamesFromDevices:devices];
    NSString *rememberedName = nil;
    RUADevice *rememberedDevice = nil;
    WPLog(@"onCardReaderDevicesDetected: device list: %@", deviceNames);
    
    // Don't want to time out on device detection - partner will need time to pick a card reader
    if (readerInformNotConnectedTimer) {
        [readerInformNotConnectedTimer invalidate];
    }
    
    rememberedName = [WPUserDefaultsHelper getRememberedCardReader];
    rememberedDevice = [self getDeviceByName:rememberedName fromDevices:devices];
    
    if (rememberedDevice) {
        // Detected an existing remembered device, so use that.
        WPLog(@"Detected remembered device %@. Initializing this device.", rememberedName);
        
        self.roamDeviceManager = [self getDeviceManagerForDevice:rememberedDevice];

        self.connectedDeviceName = rememberedName;
        [self initializeDeviceManager:self.roamDeviceManager withDevice:rememberedDevice];
    } else {
        // No remembered device exists, or the remembered device wasn't detected --
        // ask what it should be from a list.
        [self.externalDelegate informExternalCardReaderSelection:deviceNames completion:^(NSInteger selectedIndex) {
            WPLog(@"Using card reader at index: %li", (long) selectedIndex);
            self.roamDeviceManager = [self getDeviceManagerFromDevices:devices atIndex:selectedIndex];
            
            if (self.roamDeviceManager) {
                self.connectedDeviceName = deviceNames[selectedIndex];
                [self initializeDeviceManager:self.roamDeviceManager withDevice:devices[selectedIndex]];
            }
            else {
            	// Inform the partner of the invalid card reader selection
        	    NSError *selectionError = [WPError errorInvalidCardReaderSelection];
    	        [self.externalDelegate informExternalCardReaderFailure:selectionError];
                
                if ([self.config restartTransactionAfterOtherErrors]) {
                    [self processCardReaderRequest];
                }
            }
        }];
    }
}

- (NSArray *) getNamesFromDevices:(NSArray *)devices {
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:devices.count];
    
    for (RUADevice *device in devices) {
        [names addObject:device.name];
    }
    
    return names;
}

- (RUADevice *) getDeviceByName:(NSString *) name fromDevices:(NSArray *) devices {
    RUADevice *foundDevice = nil;
    
    for (RUADevice *device in devices) {
        if ([device.name isEqualToString:name]) {
            foundDevice = device;
            break;
        }
    }
    
    return foundDevice;
}

- (id<RUADeviceManager>) getDeviceManagerFromDevices:(NSArray *)devices atIndex:(NSInteger)index {
    id<RUADeviceManager> deviceManager = nil;
    
    if (-1 < index && index < devices.count) {
        // Selected index is within range of the array
        RUADevice *selectedDevice = devices[index];
        
        deviceManager = [self getDeviceManagerForDevice:selectedDevice];
    }

    return deviceManager;
}

- (id<RUADeviceManager>) getDeviceManagerForDevice:(RUADevice *) device {
    id<RUADeviceManager> deviceManager = nil;
    
    if ([device.name isEqualToString:@"AUDIOJACK"] && self.config.mockConfig.useMockCardReader) {
        // Attempt Mock RP350X connection
        WPMockRoamDeviceManager *mockManager = [WPMockRoamDeviceManager getDeviceManager];
        
        mockManager.mockConfig = self.config.mockConfig;
        deviceManager = mockManager;
    } else if ([device.name isEqualToString:@"AUDIOJACK"]) {
        // Attempt real RP350X connection
        WPLog(@"Using audiojack card reader");
        deviceManager = [RUA getDeviceManager:RUADeviceTypeRP350x];
    } else {
        // Attempt Moby3000 connection
        WPLog(@"Using Bluetooth card reader for device: %@", device.name);
        deviceManager = [RUA getDeviceManager:RUADeviceTypeMOBY3000];
    }
    
    return deviceManager;
}

- (void) initializeDeviceManager:(id<RUADeviceManager>)roamDeviceManager withDevice:(RUADevice *)device {
    if (![self isConnected] && self.readerShouldPerformOperation) {
        // If readerShouldPerformOperation and we're not currently connected, let's reset/start
        // the connection timer.
        [self startWaitingForReader];
    }

    if ([roamDeviceManager getType] == RUADeviceTypeMOBY3000) {
        [[roamDeviceManager getConfigurationManager] activateDevice:device];
    }
    
    [roamDeviceManager initializeDevice:self];
}

- (int) getCardReaderTimeout {
    if (self.config.restartTransactionAfterOtherErrors) {
        return CARD_READER_TIMEOUT_INFINITE_SEC;
    } else {
        return CARD_READER_TIMEOUT_DEFAULT_SEC;
    }
}

#pragma mark RUADeviceStatusHandler

- (void) onConnected
{
    WPLog(@"onConnected");
    WPLog(@"is device ready? %@", [self.roamDeviceManager isReady] ? @"YES":@"NO");

    if (!self.roamDeviceManager) {
        WPLog(@"roamDeviceManager was nil");
        
        [self startCardReader];
    } else if (!self.readerIsConnected) {
        if (self.connectedDeviceName) {
            [WPUserDefaultsHelper rememberCardReaderWithIdentifier:self.connectedDeviceName];
        }
        
        self.deviceSerialNumberFetchCount = 0;
        [self fetchDeviceSerialNumber];
        
        // Cancel any scheduled calls for reader not connected
        if (readerInformNotConnectedTimer) [readerInformNotConnectedTimer invalidate];
        [NSObject cancelPreviousPerformRequestsWithTarget:self.externalDelegate
                                                 selector:@selector(informExternalCardReader:)
                                                   object:kWPCardReaderStatusNotConnected];
    }
}

- (void) onDisconnected
{
    WPLog(@"onDisconnected");

    // If a user is unplugging/replugging a card reader fast enough, it's possible that
    // we get this onDisconnected callback when really the card reader is connected.
    // The first two checks below ensure that we only try to send
    // kWPCardReaderStatusNotConnected if the card reader is truly disconnected.
    if ([self isConnected] && ![self.roamDeviceManager isReady] && !self.isCardReaderStopped) {
        // Inform external delegate if we should wait for card, and the reader was previously connected
        if (self.readerShouldPerformOperation) {
            [self.externalDelegate informExternalCardReader:kWPCardReaderStatusNotConnected];
            [self stopWaitingForCard];
            [self stopPendingOperations];
        } else if (!self.config.stopCardReaderAfterOperation) {
            // Inform external delegate
            [self.externalDelegate informExternalCardReader:kWPCardReaderStatusNotConnected];
        }
    }

    self.connectedDeviceName = nil;
    self.readerIsConnected = NO;
    self.deviceSerialNumber = nil;
}

- (void) onError:(NSString *)message
{
    // gets called when wrong reader type is connected
    WPLog(@"onError: %@", message);
    if (self.readerIsConnected) {
        NSError *error;
        
        if (self.readerIsWaitingForCard) {
            error = [WPError errorForCardReaderStatusErrorWithMessage:message];
        } else {
            // Roam encountered an error while we're trying to set up the card reader.
            error = [WPError errorInitializingCardReader];
        }
        
        [self.externalDelegate informExternalCardReaderFailure:error];
        [self stopCardReader];
        
        self.connectedDeviceName = nil;
        self.readerIsConnected = NO;
    } else {
        // Failed to initialize (and therefore connect to) the card reader.
        NSError *error = [WPError errorCardReaderUnableToConnect];
        
        [self.externalDelegate informExternalCardReaderFailure:error];
        [self stopFindingCardReaders];
        [self stopPendingOperations];
    }
}

#pragma mark RUAReleaseHandler

- (void) done {
    WPLog(@"released device manager");
    
    if (self.roamDeviceManager) {
        self.roamDeviceManager = nil;
        // inform delegate
        [self.externalDelegate informExternalCardReader:kWPCardReaderStatusStopped];
    }
}

@end

#endif
#endif
