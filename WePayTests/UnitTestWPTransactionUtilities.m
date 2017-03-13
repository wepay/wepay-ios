//
//  UnitTestWePay_CardReaderDirector.m
//  WePay
//
//  Created by Jianxin Gao on 8/3/16.
//  Copyright © 2016 WePay. All rights reserved.
//
#if defined(__has_include)
#if __has_include("RPx_MFI/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA_MFI/RUA.h")

#import <XCTest/XCTest.h>
#import "WPTransactionUtilities.h"

@interface UnitTestWPTransactionUtilities : XCTestCase\

@property WPTransactionUtilities *transactionUtilities;

@end

@interface UnitTestWPTransactionUtilities (UnitTest)

- (NSString *) extractPANfromTrack2:(NSString *)track2;

@end

@implementation UnitTestWPTransactionUtilities

- (void) setUp {
    [super setUp];
    self.transactionUtilities = [[WPTransactionUtilities alloc] initWithConfig:nil externalCardReaderHelper:nil];
}

- (void) testExtractPANfromTrack2
{
    NSString *expected = @"5413330000009049";
    NSString *result = [self.transactionUtilities extractPANfromTrack2:@"3B353431333333000000000000393034393D323531323232300000000000000000003F"];
    
    XCTAssertEqualObjects(expected, result);
}

@end


#endif
#endif
