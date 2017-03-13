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
#import "WPUserDefaultsHelper.h"

#define TIMEOUT_DEVICE_SEARCH_SEC 6.5
#define TIMEOUT_ROAM_SEARCH_MS 6000

@interface WPIngenicoCardReaderDetector() {
    int completedDiscoveries;
}

@property (nonatomic, strong) id<RUADeviceManager> rp350xRoamDeviceManager;
@property (nonatomic, strong) id<RUADeviceManager> moby3000RoamDeviceManager;
@property (nonatomic, strong) WPMockRoamDeviceManager *mockRoamDeviceManager;
@property (nonatomic, strong) NSMutableArray *supportedDeviceManagers;
@property (nonatomic, strong) NSMutableArray *discoveredDevices;
@property (nonatomic, strong) WPConfig *config;

@property (nonatomic, strong) NSTimer *timeoutTimer;

@end

@implementation WPIngenicoCardReaderDetector

- (instancetype) init {
    if (self = [super init]) {
        self.rp350xRoamDeviceManager = [RUA getDeviceManager:RUADeviceTypeRP350x];
        self.moby3000RoamDeviceManager = [RUA getDeviceManager:RUADeviceTypeMOBY3000];
        self.mockRoamDeviceManager = [WPMockRoamDeviceManager getDeviceManager];
        
        self.supportedDeviceManagers = [NSMutableArray array];
        self.discoveredDevices = [NSMutableArray array];
        completedDiscoveries = 0;
    }
    return self;
}

- (void) findAvailablCardReadersWithConfig:(WPConfig *)config deviceDetectionDelegate:(id<WPCardReaderDetectionDelegate>)delegate {
    NSLog(@"findAvailableCardReaders");
    WPMockConfig *mockConfig = config.mockConfig;
    
    self.config = config;
    self.delegate = delegate;
    
    if (mockConfig && mockConfig.useMockCardReader) {
        [self.mockRoamDeviceManager setMockConfig:mockConfig];
        [self.supportedDeviceManagers addObject:self.mockRoamDeviceManager];
    }
    else {
        [self.supportedDeviceManagers addObject:self.rp350xRoamDeviceManager];
        [self.supportedDeviceManagers addObject:self.moby3000RoamDeviceManager];
    }
    
    [self beginDetection];
}

- (void) stopFindingCardReaders {
    NSLog(@"stopFindingCardReaders");
    [self stopTimeCounter];
    [self cancelAllDeviceManagerSearches:self.supportedDeviceManagers];
    completedDiscoveries = 0;
    [self.discoveredDevices removeAllObjects];
}

#pragma mark - Internal

- (void) beginDetection {
    for (id<RUADeviceManager> manager in self.supportedDeviceManagers) {
        [manager searchDevicesForDuration:TIMEOUT_ROAM_SEARCH_MS andListener:self];
    }
    
    [self stopTimeCounter];
    [self startTimeCounterForDuration:TIMEOUT_DEVICE_SEARCH_SEC];
}

- (void) cancelAllDeviceManagerSearches:(NSArray *)possibleDeviceManagers {
    for (id<RUADeviceManager> manager in possibleDeviceManagers) {
        [manager cancelSearch];
    }
}

- (void) startTimeCounterForDuration:(NSTimeInterval)interval {
    self.timeoutTimer = [NSTimer timerWithTimeInterval:interval
                                                target:self
                                              selector:@selector(detectionComplete)
                                              userInfo:nil
                                               repeats:NO];
    
    [[NSRunLoop mainRunLoop] addTimer:self.timeoutTimer forMode:NSDefaultRunLoopMode];
}

- (void) stopTimeCounter {
    if (self.timeoutTimer) {
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
    }
}

- (void) detectionComplete {
    NSLog(@"detectionComplete");
    [self stopTimeCounter];
    [self cancelAllDeviceManagerSearches:self.supportedDeviceManagers];
    
    if (self.discoveredDevices.count > 0) {
        // Make a copy to give to the delegate so we can clear the list safely
        NSMutableArray *callbackDevices = self.discoveredDevices;
        self.discoveredDevices = [[NSMutableArray alloc] init];
        [self.delegate onCardReaderDevicesDetected:callbackDevices];
    } else {
        [self beginDetection];
    }
}

#pragma mark - RUADeviceSearchListener

- (void) discoveredDevice:(RUADevice *)reader {
    NSLog(@"onDeviceDiscovered %@", reader.name);
    
    BOOL isMoby = reader.name && [reader.name hasPrefix:@"MOB30"];
    BOOL isAudioJack = reader.name && [reader.name isEqualToString:@"AUDIOJACK"];
    
    if (isMoby || isAudioJack) {
        NSLog(@"add device: %@", reader.name);
        [self.discoveredDevices addObject:reader];
    }
    
    if ([[WPUserDefaultsHelper getRememberedCardReader] isEqualToString:reader.name]) {
        // Stop searching for a device if we've found the card reader we rememeber.
        NSLog(@"onDeviceDiscovered: discovered remembered reader %@", reader.name);
        
        [self discoveryComplete];
    }
}

- (void) discoveryComplete {
    NSLog(@"onDiscoveryComplete");
    completedDiscoveries++;
    
    if (completedDiscoveries >= self.supportedDeviceManagers.count) {
        [self detectionComplete];
    }
}


@end

#endif
#endif
