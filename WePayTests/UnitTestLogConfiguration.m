//
//  UnitTestLogConfiguration.m
//  WePay
//
//  Created by Zach Vega-Perkins on 4/3/17.
//  Copyright © 2017 WePay. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "WPConfig.h"
#import "WePay.h"

@interface UnitTestLogConfiguration : XCTestCase

@end

@implementation UnitTestLogConfiguration

- (void) setUp {
    [super setUp];
    globalLogLevel = @"";
}

- (void) testConfigWithLogLevel {
    // Changing the config's log should not change the global log level until it is passed into
    // a WePay constructor.
    WPConfig *config = [[WPConfig alloc] initWithClientId:@"171482" environment:kWPEnvironmentStage];
    
    config.logLevel = kWPLogLevelNone;
    XCTAssertNotEqualObjects(kWPLogLevelNone, globalLogLevel);
    
    __unused WePay *wePay = [[WePay alloc] initWithConfig:config];
    XCTAssertEqualObjects(kWPLogLevelNone, globalLogLevel);
}

- (void) testMultipleConfigs {
    WPConfig *config0 = [[WPConfig alloc] initWithClientId:@"171482" environment:kWPEnvironmentStage];
    WPConfig *config1 = [[WPConfig alloc] initWithClientId:@"171482" environment:kWPEnvironmentStage];
    
    config0.logLevel = kWPLogLevelAll;
    config1.logLevel = kWPLogLevelNone;
    
    WePay *wePay = [[WePay alloc] initWithConfig:config0];
    wePay = [[WePay alloc] initWithConfig:config1];
    
    XCTAssertEqualObjects(config1.logLevel, globalLogLevel);
}

@end
