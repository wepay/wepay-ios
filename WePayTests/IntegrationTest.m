//
//  IntegrationTest.m
//  WePay
//
//  Created by Jianxin Gao on 7/27/16.
//  Copyright © 2016 WePay. All rights reserved.
//

#import "TestCheckoutDelegate.h"
#import "TestTokenizationDelegate.h"
#import "WePay.h"
#import "WPError+internal.h"
#import <XCTest/XCTest.h>

#define RP350X_CONNECTION_TIME_SEC 5

@interface IntegrationTest : XCTestCase

@property WePay *wepay;
@property WPConfig *config;

@end

@implementation IntegrationTest

- (void) setUp
{
    [super setUp];
    self.config = [[WPConfig alloc] initWithClientId:@"171482" environment:kWPEnvironmentStage];
    WPMockConfig *mockConfig = [[WPMockConfig alloc] init];
    mockConfig.useMockWepayClient = YES; // YES is default and can be changed to NO to interact with real WePay server
    self.config.mockConfig = mockConfig;
    self.wepay = [[WePay alloc] initWithConfig:self.config];
}

- (void) tearDown
{
    self.wepay = nil;
    self.config = nil;
    [super tearDown];
}

#pragma mark - Tests for tokenization

- (void) testValidTokenization
{
    WPPaymentInfo *paymentInfo = [self getPaymentInfoWithCardNumber:@"5496198584584769"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"paymentInfo:didTokenize: expected to be called."];
    TestTokenizationDelegate *tokenizationDelegate = [[TestTokenizationDelegate alloc] init];
    TokenizationSuccessBlock tokenizationSuccessBlock = ^(){
        [expectation fulfill];
    };
    tokenizationDelegate.tokenizationSuccessBlock = tokenizationSuccessBlock;
    
    [self.wepay tokenizePaymentInfo:paymentInfo tokenizationDelegate: tokenizationDelegate];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    XCTAssertTrue(tokenizationDelegate.successCallBackInvoked);
}

- (void) testInvalidTokenization
{
    self.config.mockConfig.cardTokenizationFailure = YES; //  only necessary if mockConfig.useMockWepayClient = YES
    WPPaymentInfo *paymentInfo = [self getPaymentInfoWithCardNumber:@"0"]; // invalid credit card number
    XCTestExpectation *expectation = [self expectationWithDescription:@"paymentInfo:didFailTokenization: expected to be called."];
    TestTokenizationDelegate *tokenizationDelegate = [[TestTokenizationDelegate alloc] init];
    TokenizationFailureBlock tokenizationFailureBlock = ^(){
        [expectation fulfill];
    };
    tokenizationDelegate.tokenizationFailureBlock = tokenizationFailureBlock;
    
    [self.wepay tokenizePaymentInfo:paymentInfo tokenizationDelegate: tokenizationDelegate];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    XCTAssertTrue(tokenizationDelegate.failureCallBackInvoked);
}

#pragma mark - Tests for signature storing.

- (void) testStoreSignatureSuccess
{
    // This test can only pass when using mocked WPClient implementation
    if (self.config.mockConfig.useMockWepayClient) {
        XCTestExpectation *expectation = [self expectationWithDescription:@"didStoreSignature:forCheckoutId: expected to be called"];
        TestCheckoutDelegate *checkoutDelegate = [[TestCheckoutDelegate alloc] init];
        StoreSignatureSuccessBlock storeSignatureSuccessBlock = ^(){
            [expectation fulfill];
        };
        checkoutDelegate.storeSignatureSuccessBlock = storeSignatureSuccessBlock;
        
        UIImage *image = [self getImageWithWidth:128 andHeight:128];
        
        [self.wepay storeSignatureImage:image
                          forCheckoutId:@"checkout id"
                       checkoutDelegate:checkoutDelegate];
        
        [self waitForExpectationsWithTimeout:3.0 handler:nil];
        XCTAssertTrue(checkoutDelegate.successCallBackInvoked);
    }
}

- (void) testStoreSignatureNilImgFailure
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"didFailToStoreSignatureImage:forCheckoutId:withError: expected to be called"];
    TestCheckoutDelegate *checkoutDelegate = [[TestCheckoutDelegate alloc] init];
    StoreSignatureFailureBlock storeSignatureFailureBlock = ^(){
        [expectation fulfill];
    };
    checkoutDelegate.storeSignatureFailureBlock = storeSignatureFailureBlock;
    
    [self.wepay storeSignatureImage:nil // image is nil
                      forCheckoutId:@"checkout id"
                   checkoutDelegate:checkoutDelegate];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    XCTAssertTrue(checkoutDelegate.failureCallBackInvoked);
    XCTAssertEqualObjects([WPError errorInvalidSignatureImage], checkoutDelegate.error);
}

- (void) testStoreSignatureInvalidImgFailure
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"didFailToStoreSignatureImage:forCheckoutId:withError: expected to be called"];
    TestCheckoutDelegate *checkoutDelegate = [[TestCheckoutDelegate alloc] init];
    StoreSignatureFailureBlock storeSignatureFailureBlock = ^(){
        [expectation fulfill];
    };
    checkoutDelegate.storeSignatureFailureBlock = storeSignatureFailureBlock;
    
    // image cannot be properly scaled
    UIImage *image = [self getImageWithWidth:129 andHeight:32];
    
    [self.wepay storeSignatureImage:image
                      forCheckoutId:@"checkout id"
                   checkoutDelegate:checkoutDelegate];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    XCTAssertTrue(checkoutDelegate.failureCallBackInvoked);
    XCTAssertEqualObjects([WPError errorInvalidSignatureImage], checkoutDelegate.error);
}

#pragma mark - Private helper method

- (WPPaymentInfo *)getPaymentInfoWithCardNumber:(NSString *)cardNumber
{
    WPPaymentInfo *paymentInfo = [[WPPaymentInfo alloc] initWithFirstName:@"WPiOS"
                                                                 lastName:@"Example"
                                                                    email:@"wp.ios.example@wepay.com"
                                                           billingAddress:[[WPAddress alloc] initWithZip:@"94306"]
                                                          shippingAddress:nil
                                                               cardNumber:cardNumber
                                                                      cvv:@"123"
                                                                 expMonth:@"04"
                                                                  expYear:@"2020"
                                                          virtualTerminal:YES];
    return paymentInfo;
}

- (UIImage *)getImageWithWidth:(CGFloat) width
                     andHeight:(CGFloat) height
{
    CGSize size = CGSizeMake(width, height);
    UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    [[UIColor whiteColor] setFill];
    UIRectFill(CGRectMake(0, 0, size.width, size.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
