//
//  WPBatteryHelper.m
//  WePay
//
//  Created by Chaitanya Bagaria on 8/31/16.
//  Copyright © 2016 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RPx/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA/RUA.h") 

#import "WPBatteryHelper.h"
#import "WPMockRoamDeviceManager.h"
#import "WPError+internal.h"
#import "WPRoamHelper.h"

#define RP350X_CONNECTION_TIME_SEC 5
#define TIMEOUT_DEFAULT_SEC 60

@interface WPBatteryHelper ()

@property (nonatomic, strong) NSObject<RUADeviceManager> *roamDeviceManager;
@property (nonatomic, strong) NSObject<WPBatteryLevelDelegate> *batteryLevelDelegate;
@property (nonatomic, strong) WPConfig *config;
@property (nonatomic, assign) BOOL isConnected;

@end

@implementation WPBatteryHelper

- (void) getCardReaderBatteryLevelWithBatteryLevelDelegate:(id<WPBatteryLevelDelegate>) batteryLevelDelegate
                                                    config:(WPConfig *)config
{
    NSLog(@"getCardReaderBatteryLevelWithBatteryLevelDelegate");
    if (batteryLevelDelegate == nil) {
        return;
    } else {
        self.batteryLevelDelegate = batteryLevelDelegate;
        self.config = config;
    }
    
    WPMockConfig *mockConfig = config.mockConfig;
    if (mockConfig != nil && mockConfig.useMockCardReader) {
        self.roamDeviceManager = [WPMockRoamDeviceManager getDeviceManager];
        [((WPMockRoamDeviceManager *) self.roamDeviceManager) setMockConfig:mockConfig];
    } else {
        self.roamDeviceManager = [RUA getDeviceManager:RUADeviceTypeRP350x];
    }
    
    BOOL init = [self.roamDeviceManager initializeDevice:self];
    if (init) {
        [[self.roamDeviceManager getConfigurationManager] setCommandTimeout:TIMEOUT_DEFAULT_SEC];
        [self startWaitingForReader];
    } else {
        [self informExternalError:[WPError errorCardReaderUnknownError]];
    }
}

- (void) startWaitingForReader
{
    NSLog(@"startWaitingForReader");

    // Wait a few seconds for the reader to be detected, otherwise announce not connected
    // has to be called from the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSelector:@selector(informExternalError:)
                   withObject:[WPError errorCardReaderNotConnected]
                   afterDelay:RP350X_CONNECTION_TIME_SEC];
    });
}

- (void) stopWaitingForReader
{
    NSLog(@"stopWaitingForReader");

    // cancel any scheduled notifications
    // has to be called from the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self
                                                 selector:@selector(informExternalError:)
                                                   object:[WPError errorCardReaderNotConnected]];
    });
}

- (void) informExternalError:(NSError *)error
{
    NSLog(@"informExternalError");
    
    dispatch_queue_t queue = self.config.callDelegateMethodsOnMainThread ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        // If the external delegate is listening for errors, send it
        if (self.batteryLevelDelegate && [self.batteryLevelDelegate respondsToSelector:@selector(didFailToGetBatteryLevelwithError:)]) {
            [self.batteryLevelDelegate didFailToGetBatteryLevelwithError:error];
            NSLog(@"did inform external");
        }
        
        [self cleanup];
    });
}

- (void) informExternalSuccess:(int) batteryLevel
{
    NSLog(@"informExternalSuccess");
    
    dispatch_queue_t queue = self.config.callDelegateMethodsOnMainThread ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        // If the external delegate is listening for errors, send it
        if (self.batteryLevelDelegate && [self.batteryLevelDelegate respondsToSelector:@selector(didGetBatteryLevel:)]) {
            [self.batteryLevelDelegate didGetBatteryLevel:batteryLevel];
            NSLog(@"did inform external");
        }
        
        [self cleanup];
    });
}

- (void) cleanup
{
    NSLog(@"cleanup");
    [self stopWaitingForReader];
    self.batteryLevelDelegate = nil;
    [self.roamDeviceManager releaseDevice];
    self.roamDeviceManager = nil;
}

#pragma mark ReaderStatusHandler

- (void) onConnected
{
    NSLog(@"WPBatteryHelper onConnected");
    self.isConnected = YES;

    [self stopWaitingForReader];
    
    NSLog(@"stopped waiting, checking battery");
    
    NSLog(@"roamDeviceManager: %@", self.roamDeviceManager);

    [self.roamDeviceManager getBatteryStatus:^(RUAResponse *response) {
        NSLog(@"RUAResponse: %@", [WPRoamHelper RUAResponse_toDictionary:response]);
        
        NSDictionary *responseData = [WPRoamHelper RUAResponse_toDictionary:response];
        NSString *errorCode = [responseData objectForKey: [WPRoamHelper RUAParameter_toString:RUAParameterErrorCode]];
        NSString *command = [responseData objectForKey:[WPRoamHelper RUAParameter_toString:RUAParameterCommand]];
        
        if (errorCode != nil) {
            [self informExternalError:[WPError errorFailedToGetBatteryLevel]];
        } else {
            if ([command isEqualToString:[WPRoamHelper RUACommand_toString:RUACommandBatteryInfo]]) {
                int batteryLevel = [[responseData objectForKey: [WPRoamHelper RUAParameter_toString:RUAParameterBatteryLevel]] intValue];
                [self informExternalSuccess:batteryLevel];
            } else {
                NSLog(@"unexpected command : %@", command);
                [self informExternalError:[WPError errorFailedToGetBatteryLevel]];
            }
        }
    }];
    
    NSLog(@"getting battery info");

}

- (void) onDisconnected
{
    NSLog(@"WPBatteryHelper onDisconnected");
    
    if (self.isConnected) {
        self.isConnected = NO;
        [self informExternalError:[WPError errorCardReaderNotConnected]];
    }
}

- (void) onError:(NSString *)message
{
    NSLog(@"WPBatteryHelper onError: %@", message);

    [self informExternalError:[WPError errorCardReaderUnknownError]];
}

@end

#endif
#endif

