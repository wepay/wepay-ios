//
//  UnitTestWPRememberCardReaderHelper.m
//  WePay
//
//  Created by Zach Vega-Perkins on 2/14/17.
//  Copyright © 2017 WePay. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "WPUserDefaultsHelper.h"

@interface UnitTestWPUserDefaultsHelper : XCTestCase

@end

@implementation UnitTestWPUserDefaultsHelper

- (void) tearDown {
    // Clear standardUserDefaults before each test.
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:@"xctest"];
    
    [super tearDown];
}

- (void) testHappyPathRememberCardReader
{
    NSString *cardReaderIdentifier = @"Nimbus 2000";
    
    [WPUserDefaultsHelper rememberCardReaderWithIdentifier:cardReaderIdentifier];
    XCTAssertEqualObjects(cardReaderIdentifier, [WPUserDefaultsHelper getRememberedCardReader]);
}

- (void) testHappyPathForgetCardReader
{
    NSString *cardReaderIdentifier = @"Nimbus 2000";
    NSString *checkIdentifier = nil;
    
    [WPUserDefaultsHelper rememberCardReaderWithIdentifier:cardReaderIdentifier];
    [WPUserDefaultsHelper forgetRememberedCardReader];
    checkIdentifier = [WPUserDefaultsHelper getRememberedCardReader];
    
    XCTAssertEqual(checkIdentifier, nil);
}

- (void) testGetRememberCardReaderWhenEmpty
{
    // Try to get the remembered card reader when nothing has been remembered yet.
    NSString *emptyIdentifier = [WPUserDefaultsHelper getRememberedCardReader];
    
    XCTAssertEqual(emptyIdentifier, nil);
}

@end
