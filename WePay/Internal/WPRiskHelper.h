//
//  WPRiskHelper.h
//  WePay
//
//  Created by Chaitanya Bagaria on 4/1/15.
//  Copyright (c) 2015 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("TrustDefenderMobile/TrustDefenderMobile.h")

#import <Foundation/Foundation.h>
#import <TrustDefenderMobile/TrustDefenderMobile.h>

@class WPConfig;

@interface WPRiskHelper : NSObject <TrustDefenderMobileDelegate, CLLocationManagerDelegate>

/**
 *  The designated initializer
 *
 *  @param config The WePay config
 *
 *  @return A \ref WPRiskHelper instance.
 */
- (instancetype) initWithConfig:(WPConfig *)config;

/**
 *  Fetches a new session id. Triggers profiling if not already running.
 *  This method should be called everytime a sensitive API call is made.
 *
 *  @return The session id. Can be nil if profiling fails to start.
 */
- (NSString *) sessionId;

@end

#endif
#endif
