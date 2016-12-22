//
//  WPIngenicoCardReaderDetector.m
//  WePay
//
//  Created by Cameron Alley on 12/12/16.
//  Copyright © 2016 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RPx_MFI/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA_MFI/RUA.h")

#import <RUA_MFI/RUA.h>

#import "WPConfig.h"
#import "WPIngenicoCardReaderDetector.h"
#import "WPMockConfig.h"
#import "WPMockRoamDeviceManager.h"

#define TIMEOUT_DEVICE_SEARCH_MS 8000.0
#define TIMEOUT_DEVICE_SEARCH_SEC 8

@interface WPIngenicoCardReaderDetector() {
    BOOL isDiscovered;
}

@property (nonatomic, strong) id<RUADeviceManager> rp350xRoamDeviceManager;
@property (nonatomic, strong) id<RUADeviceManager> moby3000RoamDeviceManager;
@property (nonatomic, strong) WPMockRoamDeviceManager *mockRoamDeviceManager;
@property (nonatomic, strong) NSArray *supportedDeviceManagers;
@property (nonatomic, strong) WPConfig *config;

@property (nonatomic, strong) NSTimer *timeoutTimer;

@end

@implementation WPIngenicoCardReaderDetector

- (instancetype) init {
    if (self = [super init]) {
        self.rp350xRoamDeviceManager = [RUA getDeviceManager:RUADeviceTypeRP350x];
        self.moby3000RoamDeviceManager = [RUA getDeviceManager:RUADeviceTypeMOBY3000];
        self.mockRoamDeviceManager = [WPMockRoamDeviceManager getDeviceManager];
        
        self.supportedDeviceManagers = @[
                                         self.rp350xRoamDeviceManager,
                                         self.moby3000RoamDeviceManager,
                                         self.mockRoamDeviceManager
                                        ];
        isDiscovered = false;
    }
    return self;
}

- (void) findFirstAvailableDeviceWithConfig:(WPConfig *)config deviceDetectionDelegate:(id<WPCardReaderDetectionDelegate>)delegate {
    WPMockConfig *mockConfig = config.mockConfig;
    
    self.config = config;
    self.delegate = delegate;
    
    if (mockConfig && mockConfig.useMockCardReader) {
        [self findFirstAvailableDeviceMockWithConfig:mockConfig];
    }
    else {
        [self findFirstAvailableDeviceInternalWithConfig:config deviceDetectionDelegate:delegate];
    }
}

#pragma mark - Internal

- (void) findFirstAvailableDeviceInternalWithConfig:(WPConfig *)config deviceDetectionDelegate:(id<WPCardReaderDetectionDelegate>)delegate {
    id<RUADeviceManager> existingDeviceManager = [self getReadyDeviceManager:self.supportedDeviceManagers];
    
    [self cancelAllDeviceManagerSearches:self.supportedDeviceManagers];
    
    if (!existingDeviceManager) {
        [self initializeDeviceManager:self.rp350xRoamDeviceManager];
        [self.moby3000RoamDeviceManager searchDevicesForDuration:TIMEOUT_DEVICE_SEARCH_MS andListener:self];
        
        [self stopTimeCounter];
        [self startTimeCounterForDuration:TIMEOUT_DEVICE_SEARCH_SEC];
    }
    else {
        // We already have an existing DeviceManager that's ready to go, so pass that to the delegate.
        [self.delegate onCardReaderManagerDetected:existingDeviceManager];
    }
}

- (void) findFirstAvailableDeviceMockWithConfig:(WPMockConfig *)mockConfig {
    [self stopTimeCounter];
    [self startTimeCounterForDuration:TIMEOUT_DEVICE_SEARCH_SEC];
    
    [self.mockRoamDeviceManager setMockConfig:mockConfig];
    [self initializeDeviceManager:self.mockRoamDeviceManager];
}

- (void) initializeDeviceManager:(id<RUADeviceManager>)manager {
    [manager initializeDevice:self];
}

- (id<RUADeviceManager>) getReadyDeviceManager:(NSArray *)possibleDeviceManagers {
    id <RUADeviceManager> result = nil;
    
    for (id<RUADeviceManager> manager in possibleDeviceManagers) {
        if ([manager isReady]) {
            result = manager;
            break;
        }
    }
    
    return result;
}

- (BOOL) isAnyDeviceManagerReady {
    return [self getReadyDeviceManager:self.supportedDeviceManagers] != nil;
}

- (void) cancelAllDeviceManagerSearches:(NSArray *)possibleDeviceManagers {
    for (id<RUADeviceManager> manager in possibleDeviceManagers) {
        [manager cancelSearch];
    }
}

- (void) startTimeCounterForDuration:(NSTimeInterval)interval {
    self.timeoutTimer = [NSTimer timerWithTimeInterval:interval
                                               repeats:NO
                                                 block:^(NSTimer * _Nonnull timer) {
                                                     self.timeoutTimer = nil;
                                                     [self cancelAllDeviceManagerSearches:self.supportedDeviceManagers];
                                                     [self.delegate onCardReaderDetectionTimeout];
                                                 }];
    [[NSRunLoop mainRunLoop] addTimer:self.timeoutTimer forMode:NSDefaultRunLoopMode];
}

- (void) stopTimeCounter {
    if (!self.timeoutTimer) {
        return;
    }
    
    [self.timeoutTimer invalidate];
    self.timeoutTimer = nil;
}

#pragma mark - RUADeviceStatusHandler

- (void)onConnected {
    id<RUADeviceManager> foundDeviceManager = [self getReadyDeviceManager:self.supportedDeviceManagers];
    
    if (!foundDeviceManager) {
        NSLog(@"unknown card reader device connected");
    }
    else {
        [self cancelAllDeviceManagerSearches:self.supportedDeviceManagers];
        [self stopTimeCounter];
        [self.delegate onCardReaderManagerDetected:foundDeviceManager];
    }
}

- (void)onDisconnected {
    NSLog(@"device detection: onDisconnected");
}

- (void)onError:(NSString *)message {
    NSLog(@"device detection: encountered roam error: %@", message);
    [self.delegate onCardReaderDetectionFailed:message];
}

#pragma mark - RUADeviceSearchListener

- (void)discoveredDevice:(RUADevice *)reader {
    NSLog(@"onDeviceDiscovered %@", reader.name);
    BOOL isMoby = reader.name && [reader.name hasPrefix:@"MOB30"];
    if (isMoby && ![self.moby3000RoamDeviceManager isReady]) {
        NSLog(@"initializing discovered device");
        isDiscovered = YES;
        [self cancelAllDeviceManagerSearches:self.supportedDeviceManagers];
        [self stopTimeCounter];
        
        [[self.moby3000RoamDeviceManager getConfigurationManager] activateDevice:reader];
        [self initializeDeviceManager:self.moby3000RoamDeviceManager];
    }
}

- (void)discoveryComplete {
    NSLog(@"onDiscoveryComplete");
    
    if (!isDiscovered && ![self isAnyDeviceManagerReady]) {
        [self.delegate onCardReaderDetectionFailed:@"Unable to find any supported Bluetooth devices"];
    }
}


@end

#endif
#endif
