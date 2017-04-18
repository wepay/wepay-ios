//
//  WPMockRoamDeviceManager.m
//  WePay
//
//  Created by Jianxin Gao on 7/15/16.
//  Copyright © 2016 WePay. All rights reserved.
//
#if defined(__has_include)
#if __has_include("RPx_MFI/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA_MFI/RUA.h")

#import "WPMockRoamDeviceManager.h"
#import "WPMockRoamTransactionManager.h"
#import "WPMockRoamConfigurationManager.h"
#import "WPMockConfig.h"

#define READER_CONNECTION_TIME_MSEC 200
#define READER_DISCOVERED_TIME_SEC 0.5
#define READER_RELEASE_TIME_SEC 0.5
#define DISCOVERY_COMPLETE_TIME_SEC 1

#define MOCK_DEVICE_NAME @"AUDIOJACK"
#define MOCK_DEVICE_IDENTIFIER @"RP350MOCK"

@interface WPMockRoamDeviceManager()

@property (nonatomic, strong) NSTimer *discoveredDeviceTimer;
@property (nonatomic, strong) NSTimer *discoveryCompleteTimer;

@end

@implementation WPMockRoamDeviceManager {
    BOOL isReady;
}

+ (id<RUADeviceManager>) getDeviceManager {
    static WPMockRoamDeviceManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WPMockRoamDeviceManager alloc] init];
    });
    return instance;
}

- (instancetype) init {
    if (self = [super init]) {
        isReady = false;
    }
    return self;
}

- (id<RUATransactionManager>) getTransactionManager
{
    static WPMockRoamTransactionManager *transactionManagerInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        transactionManagerInstance = [[WPMockRoamTransactionManager alloc] init];
    });
    return transactionManagerInstance;
}

- (id<RUAConfigurationManager>) getConfigurationManager
{
    static WPMockRoamConfigurationManager *configurationManagerInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        configurationManagerInstance = [[WPMockRoamConfigurationManager alloc] init];
    });
    return configurationManagerInstance;
}

- (RUADeviceType) getType
{
    return RUADeviceTypeRP350x;
}

- (BOOL) initializeDevice:(id<RUADeviceStatusHandler>)statusHandler
{
    self.deviceStatusHandler = statusHandler;
    
    // Update singleton objects so that properties/states don't persist through tests
    dispatch_async(dispatch_get_main_queue(), ^{
        WPMockRoamTransactionManager *transactionManager = [self getTransactionManager];
        transactionManager.deviceStatusHandler = statusHandler;
        transactionManager.mockConfig = self.mockConfig;
        [transactionManager resetStates];
        
        WPMockRoamConfigurationManager *configurationManager = [self getConfigurationManager];
        configurationManager.deviceStatusHandler = statusHandler;
        configurationManager.mockConfig = self.mockConfig;
    });
    
    if (!self.mockConfig.cardReadTimeOut) {
        dispatch_queue_t queue = dispatch_get_main_queue();
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, READER_CONNECTION_TIME_MSEC * NSEC_PER_MSEC);
        dispatch_after(time, queue, ^{
            isReady = YES;
            [statusHandler onConnected];
        });
    }

    return YES;
}

- (BOOL) isReady
{
    return isReady;
}

- (BOOL) releaseDevice
{
    [self releaseDevice:nil];
    return YES;
}

- (void) releaseDevice:(id<RUAReleaseHandler>)releaseHandler {
    if (self.deviceStatusHandler != nil) {
        dispatch_queue_t queue = dispatch_get_main_queue();
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, READER_RELEASE_TIME_SEC * NSEC_PER_SEC);
        dispatch_after(time, queue, ^{
            // Call done on releaseHandler
            if (releaseHandler) {
                [releaseHandler done];
            }
            
            [_deviceStatusHandler onDisconnected];
        });
    }
}

- (void) getBatteryStatus:(OnResponse)response {
    if (self.mockConfig.batteryLevelError) {
        dispatch_queue_t queue = dispatch_get_main_queue();
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, READER_CONNECTION_TIME_MSEC * NSEC_PER_MSEC);
        dispatch_after(time, queue, ^{
            RUAResponse *ruaResponse = [[RUAResponse alloc] init];
            ruaResponse.command = RUACommandBatteryInfo;
            ruaResponse.responseCode = RUAResponseCodeError;
            ruaResponse.responseType = RUAResponseTypeUnknown;
            ruaResponse.errorCode = RUAErrorCodeUnknownError;

            response(ruaResponse);
        });
    } else {
        dispatch_queue_t queue = dispatch_get_main_queue();
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, READER_CONNECTION_TIME_MSEC * NSEC_PER_MSEC);
        dispatch_after(time, queue, ^{
            RUAResponse *ruaResponse = [[RUAResponse alloc] init];
            ruaResponse.command = RUACommandBatteryInfo;
            ruaResponse.responseCode = RUAResponseCodeSuccess;
            ruaResponse.responseType = RUAResponseTypeUnknown;
            ruaResponse.responseData = @{[NSNumber numberWithInteger:RUAParameterBatteryLevel]: @(42)};

            response(ruaResponse);
        });
    }
}

- (void) searchDevices:(id<RUADeviceSearchListener>)searchListener {
    [self searchDevicesForDuration:DISCOVERY_COMPLETE_TIME_SEC andListener:searchListener];
}

- (void) searchDevicesForDuration:(long)duration andListener:(id<RUADeviceSearchListener>)searchListener {
    
    
    self.discoveredDeviceTimer = [NSTimer timerWithTimeInterval:READER_DISCOVERED_TIME_SEC
                                                         target:self
                                                       selector:@selector(discoveredDeviceTimeout:)
                                                       userInfo:@{ @"searchListener" : searchListener }
                                                        repeats:NO];
    
    // Bypassing durationInMilliseconds so that the mock experience is quicker.
    self.discoveryCompleteTimer = [NSTimer timerWithTimeInterval:DISCOVERY_COMPLETE_TIME_SEC
                                                          target:searchListener
                                                        selector:@selector(discoveryComplete)
                                                        userInfo:nil
                                                         repeats:NO];
    
    if (self.mockConfig.mockCardReaderIsDetected) {
        [[NSRunLoop mainRunLoop] addTimer:self.discoveredDeviceTimer forMode:NSDefaultRunLoopMode];
    }
    [[NSRunLoop mainRunLoop] addTimer:self.discoveryCompleteTimer forMode:NSDefaultRunLoopMode];
}

- (void) discoveredDeviceTimeout:(NSTimer *) timer {
    id<RUADeviceSearchListener> searchListener = [timer.userInfo objectForKey:@"searchListener"];
    RUADevice *device = [[RUADevice alloc] initWithName:MOCK_DEVICE_NAME
                                         withIdentifier:MOCK_DEVICE_IDENTIFIER
                             withCommunicationInterface:RUACommunicationInterfaceAudioJack];
    
    [searchListener discoveredDevice:device];
}

- (void) searchDevicesWithLowRSSI:(NSInteger)lowRSSI andHighRSSI:(NSInteger)highRSSI andListener:(id<RUADeviceSearchListener>)searchListener {}

- (void) cancelSearch {
    if (self.discoveredDeviceTimer) {
        [self.discoveredDeviceTimer invalidate];
        self.discoveredDeviceTimer = nil;
    }
    
    if (self.discoveryCompleteTimer) {
        [self.discoveryCompleteTimer invalidate];
        self.discoveryCompleteTimer = nil;
    }
}

- (void) enableFirmwareUpdateMode:(OnResponse)response {}

- (void) updateFirmware:(NSString *)firmareFilePath progress:(OnProgress)progress response:(OnResponse)response {}

- (void) getDeviceStatistics:(OnResponse)response {}

- (void) requestPairing:(id<RUAAudioJackPairingListener>)pairListener {}

- (void) confirmPairing:(BOOL)isMatching {}

#pragma mark - Mock methods

- (void) mockCardReaderDisconnect
{
    // Only mock disconnect if deviceStatusHandler exists (i.e. this device manager has
    // been initialized).
    if (self.deviceStatusHandler) {
        isReady = NO;
        [self.deviceStatusHandler onDisconnected];
    }
}

- (void) mockCardReaderConnect
{
    // Only mock connect if deviceStatusHandler exists (i.e. this device manager has been
    // initialized).
    if (self.deviceStatusHandler) {
        isReady = YES;
        [self.deviceStatusHandler onConnected];
    }
}

- (void) mockCardReaderError:(NSString *)message
{
    if (self.deviceStatusHandler) {
        isReady = NO;
        [self.deviceStatusHandler onError:message];
    }
}

@end

#endif
#endif
