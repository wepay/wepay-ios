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
    if (self.deviceStatusHandler != nil) {
        [_deviceStatusHandler onDisconnected];
    }
    return YES;
}

- (void)releaseDevice:(id<RUAReleaseHandler>)releaseHandler {
    
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

- (void) searchDevices:(id<RUADeviceSearchListener>)searchListener {}

- (void) searchDevicesForDuration:(long)duration andListener:(id<RUADeviceSearchListener>)searchListener {}

- (void) searchDevicesWithLowRSSI:(NSInteger)lowRSSI andHighRSSI:(NSInteger)highRSSI andListener:(id<RUADeviceSearchListener>)searchListener {}

- (void) cancelSearch {}

- (void) enableFirmwareUpdateMode:(OnResponse)response {}

- (void) updateFirmware:(NSString *)firmareFilePath progress:(OnProgress)progress response:(OnResponse)response {}

- (void) getDeviceStatistics:(OnResponse)response {}

- (void) requestPairing:(id<RUAAudioJackPairingListener>)pairListener {}

- (void) confirmPairing:(BOOL)isMatching {}



@end

#endif
#endif
