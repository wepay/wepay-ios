//
//  WPRiskHelper.m
//  WePay
//
//  Created by Chaitanya Bagaria on 4/1/15.
//  Copyright (c) 2015 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("TrustDefenderMobile/TrustDefenderMobile.h")

#import "WPRiskHelper.h"
#import "WPConfig.h"

@interface WPRiskHelper ()

@property (nonatomic, strong) TrustDefenderMobile* profile;
@property (nonatomic, strong) NSString* _sessionId;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL useLocation;
@end

@implementation WPRiskHelper

static NSInteger const PROFILING_TIMEOUT_SECS = 30;
static NSString * const WEPAY_THREATMETRIX_ORG_ID = @"ncwzrc4k";

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
        [self startProfiling];
    }

    return self._sessionId;
}

- (void) startProfiling
{
    // initialize a profileing scheme
    self.profile = [[TrustDefenderMobile alloc] init];

    // set location permission
    if (self.useLocation) {
        // ask user for permission - will only ask if the app has never asked before
        [self requestLocationPermission];

        // tell TM to use location
        [self.profile registerLocationServices];

        // set location accuracy
        self.profile.desiredAccuracy = kCLLocationAccuracyBest;
    }


    // set delegate
    self.profile.delegate = self;

    // set time out
    self.profile.timeout = PROFILING_TIMEOUT_SECS;

    // start profiling
    thm_status_code_t status = [self.profile doProfileRequestFor:WEPAY_THREATMETRIX_ORG_ID];

    if (status == THM_OK) {
        // The profiling successfully started, store session id
        self._sessionId = self.profile.sessionID;
    } else {
        // handle error
        // nothing special
    }
}

- (void) requestLocationPermission
{
    // initialize a location manager
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

    // stop asking for updates - TM will ask for location itself
    // [self.locationManager stopUpdatingLocation];
}


#pragma mark - TrustDefenderMobileDelegate methods

- (void) profileComplete:(thm_status_code_t) status;
{
    // If we registered a delegate, this function will be called once the profiling is complete
    if (status == THM_OK)
    {
        // No errors, profiling succeeded!
        // Do nothing special
    } else {
        // error!
        // Do nothing special
    }

    // stop requesting location
    [self.locationManager stopUpdatingLocation];

    // delete the sessionId
    self._sessionId = nil;

    // cleanup resources
    self.profile = nil;
}

#pragma mark - cleanup

- (void) dealloc
{
    // cancel profiling
    [self.profile cancel];

    // stop updating location if still active
    [self.locationManager stopUpdatingLocation];

    // nil out properties
    self.profile.delegate = nil;
    self.profile = nil;
    self._sessionId = nil;
    self.locationManager.delegate = nil;
    self.locationManager = nil;
}


@end

#endif
#endif
