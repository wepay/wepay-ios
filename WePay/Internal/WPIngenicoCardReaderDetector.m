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
#import <CoreBluetooth/CoreBluetooth.h>
#import <AVFoundation/AVFoundation.h>

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

// Allows the detection process to be interrupted at arbitrary times.
// Without this, unwanted detection restarts would occur in some cases.
@property (nonatomic, assign) BOOL isStopped;

@end

// Reference to CoreBluetooth so we can determine if user has Bluetooth enabled.
// Is static so we only initialize once (Bluetooth notification is shown once per init).
static CBCentralManager *bluetoothManager = nil;

@implementation WPIngenicoCardReaderDetector

- (instancetype) init {
    if (self = [super init]) {
        self.rp350xRoamDeviceManager = [RUA getDeviceManager:RUADeviceTypeRP350x];
        self.moby3000RoamDeviceManager = [RUA getDeviceManager:RUADeviceTypeMOBY3000];
        self.mockRoamDeviceManager = [WPMockRoamDeviceManager getDeviceManager];
        
        self.supportedDeviceManagers = [NSMutableArray array];
        self.discoveredDevices = [NSMutableArray array];
        completedDiscoveries = 0;
        
        if (!bluetoothManager) {
            bluetoothManager = [[CBCentralManager alloc] initWithDelegate:nil queue:nil];
        }
    }
    return self;
}

- (void) findAvailablCardReadersWithConfig:(WPConfig *)config deviceDetectionDelegate:(id<WPCardReaderDetectionDelegate>)delegate {
    WPLog(@"findAvailableCardReaders");
    WPMockConfig *mockConfig = config.mockConfig;
    
    self.config = config;
    self.delegate = delegate;
    
    if ([self isMockTransaction]) {
        [self.mockRoamDeviceManager setMockConfig:mockConfig];
        [self.supportedDeviceManagers addObject:self.mockRoamDeviceManager];
    } else {
        [self.supportedDeviceManagers addObject:self.rp350xRoamDeviceManager];
        [self.supportedDeviceManagers addObject:self.moby3000RoamDeviceManager];
    }
    
    [self beginDetection];
}

- (void) stopFindingCardReaders {
    WPLog(@"stopFindingCardReaders");
    self.isStopped = YES;
    completedDiscoveries = 0;
    [self.discoveredDevices removeAllObjects];
    
    [self stopTimeCounter];
    [self cancelAllDeviceManagerSearches:self.supportedDeviceManagers];
}

#pragma mark - Internal

- (void) beginDetection {
    self.isStopped = NO;
    
    if (bluetoothManager.state == CBCentralManagerStatePoweredOn || bluetoothManager.state == CBCentralManagerStateUnknown || [self isMockTransaction]) {
        // Searching for either device manager type triggers a Bluetooth search.
        // We want to make sure Bluetooth is enabled before initiating search.
        for (id<RUADeviceManager> manager in self.supportedDeviceManagers) {
            [manager searchDevicesForDuration:TIMEOUT_ROAM_SEARCH_MS andListener:self];
        }
    } else if ([self isAudioJackPluggedIn]) {
        // If Bluetooth is not enabled, we can only use a headphone jack device.
        WPLog(@"Manually creating AUDIOJACK device since it was not detected, but a device is plugged into the audio jack.");
        RUADevice *audioJackDevice = [[RUADevice alloc] initWithName:@"AUDIOJACK"
                                                      withIdentifier:@"AUDIOJACK"
                                          withCommunicationInterface:RUACommunicationInterfaceAudioJack];
        [self discoveredDevice:audioJackDevice];
        [self detectionComplete];
    } else {
        // Nothing to do. Bluetooth isn't enabled and no device is plugged into the
        // headphone jack.
        WPLog(@"Unable to search for Bluetooth card readers if Bluetooth is disabled.");
        WPLog(@"No device detected in headphone jack.");
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
    WPLog(@"detectionComplete");
    [self stopTimeCounter];
    [self cancelAllDeviceManagerSearches:self.supportedDeviceManagers];
    
    if (self.discoveredDevices.count > 0) {
        // Make a copy to give to the delegate so we can clear the list safely
        NSMutableArray *callbackDevices = self.discoveredDevices;
        self.discoveredDevices = [[NSMutableArray alloc] init];
        [self.delegate onCardReaderDevicesDetected:callbackDevices];
        self.isStopped = YES;
    } else if (!self.isStopped) {
        [self beginDetection];
    }
}

- (BOOL) isAudioJackPluggedIn {
    AVAudioSessionRouteDescription *route = [[AVAudioSession sharedInstance] currentRoute];
    BOOL result = self.config.mockConfig && self.config.mockConfig.useMockCardReader;
        
    for (AVAudioSessionPortDescription* description in [route outputs]) {
        if ([AVAudioSessionPortHeadphones isEqualToString:[description portType]]) {
            WPLog(@"Detected that something is plugged into the audio jack.");
            result = YES;
            break;
        }
    }
    
    return result;
}

- (BOOL) isMockTransaction {
    WPMockConfig *mockConfig = self.config.mockConfig;
    
    return mockConfig && mockConfig.useMockCardReader;
}

#pragma mark - RUADeviceSearchListener

- (void) discoveredDevice:(RUADevice *)reader {
    WPLog(@"onDeviceDiscovered %@", reader.name);
    
    BOOL isMoby = reader.name && [reader.name hasPrefix:@"MOB30"];
    // We check if something is plugged into AUDIOJACK because ROAM incorrectly detects
    // a device there on some versions of iOS.
    BOOL isAudioJack = reader.name && [reader.name isEqualToString:@"AUDIOJACK"] && [self isAudioJackPluggedIn];
    
    if (isMoby || isAudioJack) {
        WPLog(@"add device: %@", reader.name);
        [self.discoveredDevices addObject:reader];
    }
    
    if ([[WPUserDefaultsHelper getRememberedCardReader] isEqualToString:reader.name]) {
        // Stop searching for a device if we've found the card reader we rememeber.
        WPLog(@"onDeviceDiscovered: discovered remembered reader %@", reader.name);
        
        [self discoveryComplete];
    }
}

- (void) discoveryComplete {
    WPLog(@"onDiscoveryComplete");
    completedDiscoveries++;
    
    if (completedDiscoveries >= self.supportedDeviceManagers.count) {
        [self detectionComplete];
    }
}


@end

#endif
#endif
