//
//  WPTestWePay.m
//  WePay
//
//  Created by Chaitanya Bagaria on 5/11/15.
//  Copyright (c) 2015 WePay. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "WePay.h"

@interface WPTestWePay : XCTestCase <WPTokenizationDelegate>
{
    BOOL _tokenizationSuccessCallbackInvoked;
    BOOL _tokenizationFailureCallbackInvoked;
}

@property (nonatomic, strong) WePay *wepay;
@end

@implementation WPTestWePay

- (void)setUp {
    [super setUp];

    // set up wepay
    WPConfig *config = [[WPConfig alloc] initWithClientId:@"171482" environment:WPEnvironmentStage];
    self.wepay = [[WePay alloc] initWithConfig:config];

    // reset booleans
    _tokenizationSuccessCallbackInvoked = NO;
    _tokenizationFailureCallbackInvoked = NO;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

/**
 *  Tests passing manual tokenization
 */
- (void)testTokenizeManualPass {
    WPPaymentInfo *paymentInfo = [[WPPaymentInfo alloc] initWithFirstName:@"WPiOS"
                                                                 lastName:@"Example"
                                                                    email:@"wp.ios.example@wepay.com"
                                                           billingAddress:[[WPAddress alloc] initWithZip:@"94306"]
                                                          shippingAddress:nil
                                                               cardNumber:@"5496198584584769"
                                                                      cvv:@"123"
                                                                 expMonth:@"04"
                                                                  expYear:@"2020"
                                                          virtualTerminal:YES];

    [self.wepay tokenizePaymentInfo:paymentInfo tokenizationDelegate:self];

    if ([self waitForSuccess:&_tokenizationSuccessCallbackInvoked failure:&_tokenizationFailureCallbackInvoked timeoutInterval:60]) {
        XCTAssert(NO, @"timed out while waiting for success/failure");
    } else {
        XCTAssert(_tokenizationSuccessCallbackInvoked, @"paymentInfo:didTokenize: should have been called");
    }
}

/**
 *  Tests failing manual tokenization
 */
- (void)testTokenizeManualFail {
    WPPaymentInfo *paymentInfo = [[WPPaymentInfo alloc] initWithFirstName:@"WPiOS"
                                                                 lastName:@"Example"
                                                                    email:@"wp.ios.example@wepay.com"
                                                           billingAddress:[[WPAddress alloc] initWithZip:@"94306"]
                                                          shippingAddress:nil
                                                               cardNumber:@"0" // invalid cc number
                                                                      cvv:@"123"
                                                                 expMonth:@"04"
                                                                  expYear:@"2020"
                                                          virtualTerminal:YES];

    [self.wepay tokenizePaymentInfo:paymentInfo tokenizationDelegate:self];

    if ([self waitForSuccess:&_tokenizationFailureCallbackInvoked failure:&_tokenizationSuccessCallbackInvoked timeoutInterval:60]) {
        XCTAssert(NO, @"timed out while waiting for success/failure");
    } else {
        XCTAssert(_tokenizationFailureCallbackInvoked, @"paymentInfo:didFailTokenization: should have been called");
    }
}


#pragma mark - Wait+Assert helper methods

/**
 *  Waits for either the success flag or the failure flag to become YES in the specified timeout interval.
 *
 *  @param successFlag     reference to the success flag
 *  @param failureFlag     reference to the failure flag
 *  @param timeoutInterval the timeout interval
 *
 *  @return YES if timeout occured, else NO
 */
- (BOOL) waitForSuccess:(BOOL *)successFlag
                failure:(BOOL *)failureFlag
        timeoutInterval:(NSTimeInterval)timeoutInterval
{
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeoutInterval];
    NSDate *loopUntil;

    while (YES) {
        // run the loop for 1 second at a time
        loopUntil = [NSDate dateWithTimeIntervalSinceNow:1.0];
        [[NSRunLoop currentRunLoop] runUntilDate:loopUntil];

        // either success or failure trigger fired
        if (*successFlag || *failureFlag) {
            return NO; // timout did not occur
        }

        // in case of timeout
        if ([[NSDate date] compare:timeoutDate] == NSOrderedDescending) {
            return YES; // timeout occured
        }
    }
}


#pragma mark - WPTokenizationDelegate methods

- (void) paymentInfo:(WPPaymentInfo *)paymentInfo
         didTokenize:(WPPaymentToken *)paymentToken
{
    _tokenizationSuccessCallbackInvoked = YES;
}

- (void) paymentInfo:(WPPaymentInfo *)paymentInfo
 didFailTokenization:(NSError *)error
{
    _tokenizationFailureCallbackInvoked = YES;
}



@end
