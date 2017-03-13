//
//  WPRiskHelper.m
//  WePay
//
//  Created by Chaitanya Bagaria on 4/1/15.
//  Copyright (c) 2015 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("TrustDefender/TrustDefender.h")

#import "WPRiskHelper.h"
#import "WPConfig.h"

#define PROFILING_TIMEOUT_SECS @(30)
#define WEPAY_THREATMETRIX_ORG_ID @"ncwzrc4k"


@interface WPRiskHelper ()

@property (nonatomic, strong) THMTrustDefender* profile;
@property (nonatomic, strong) NSString* _sessionId;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL useLocation;
@end

@implementation WPRiskHelper

- (instancetype) initWithConfig:(WPConfig *)config
{
    if (self = [super init]) {
        // save location config
        self.useLocation = config.useLocation;
    }

    return self;
}

- (NSString *) sessionId
{
    if (!self._sessionId) {
        // we only want one profiling session active at a time
        [self startProfiling];
    }

    return self._sessionId;
}

- (void) startProfiling
{
    // initialize a profileing scheme
    self.profile = [THMTrustDefender sharedInstance];
    
    NSMutableDictionary *options = [@{
        THMOrgID : WEPAY_THREATMETRIX_ORG_ID,
        THMTimeout : PROFILING_TIMEOUT_SECS
    } mutableCopy];
    
    __block WPRiskHelper *blockSelf = self;
    if (self.useLocation) {
        // ask user for location permission on main thread - will only ask if the app has never asked before
        dispatch_async(dispatch_get_main_queue(), ^{
            [blockSelf requestLocationPermission];
        });

        // tell TM to use location
        [options addEntriesFromDictionary:@{
            THMLocationServicesWithPrompt: @YES,
            THMDesiredLocationAccuracy: @(kCLLocationAccuracyBest)
        }];
    }
    
    [self.profile configure:options];
    
    // Fire off the profiling request.
    
    THMStatusCode status = [self.profile doProfileRequestWithCallback:^(NSDictionary *result) {
        // whether or not we succeeded, ignore the result and clean up
        
        // delete the sessionId, we want a new one every time we profile
        self._sessionId = nil;
        
        // cleanup resources
        self.profile = nil;
        
        // release location manager on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [blockSelf cleanupLocationManager];
            blockSelf = nil;
        });
    }];
    
    if (status == THMStatusCodeOk) {
        // The profiling successfully started, store session id
        self._sessionId = [[self.profile getResult] valueForKey:THMSessionID];
    } else {
        // handle error
        // nothing special
    }
}

- (void) requestLocationPermission
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;

    // Check required for iOS 8.
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    // set location accuracy
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    
    // request location updates
    [self.locationManager startUpdatingLocation];
}

- (void) cleanupLocationManager
{
    
    // stop updating location if still active
    [self.locationManager stopUpdatingLocation];

    self.locationManager.delegate = nil;
    self.locationManager = nil;
}

#pragma mark - cleanup

- (void) dealloc
{
    // cancel profiling
    [self.profile cancel];
    
    [self cleanupLocationManager];

    // nil out properties
    self.profile = nil;
    self._sessionId = nil;
}

@end

#endif
#endif
