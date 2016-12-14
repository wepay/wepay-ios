//
//  UnitTestWePay_CardReader.m
//  WePay
//
//  Created by Jianxin Gao on 8/3/16.
//  Copyright © 2016 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RPx/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA/RUA.h")


#import <XCTest/XCTest.h>
#import "WePay_CardReader.h"

@interface UnitTestWePay_CardReader : XCTestCase

@property WePay_CardReader *cardReader;

@end

@interface WePay_CardReader (UnitTest)

- (NSString *) extractPANfromTrack2:(NSString *)track2;

@end

@implementation UnitTestWePay_CardReader

- (void)setUp {
    [super setUp];
    self.cardReader = [[WePay_CardReader alloc] init];
}

- (void) testExtractPANfromTrack2
{
    NSString *expected = @"5413330000009049";
    NSString *result = [self.cardReader extractPANfromTrack2:@"3B353431333333000000000000393034393D323531323232300000000000000000003F"];
    
    XCTAssertEqualObjects(expected, result);
}

@end

#endif
#endif
