//
//  IntegrationTestCardReader.m
//  WePay
//
//  Created by Chaitanya Bagaria on 12/12/16.
//  Copyright © 2016 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RPx_MFI/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA_MFI/RUA.h")

#import "TestAuthorizationDelegate.h"
#import "TestBatteryLevelDelegate.h"
#import "TestCardReaderDelegate.h"
#import "TestCheckoutDelegate.h"
#import "TestTokenizationDelegate.h"
#import "WePay.h"
#import "WPError+internal.h"
#import <XCTest/XCTest.h>

#define CONNECTION_TIME_SEC 7

@interface IntegrationTestCardReader : XCTestCase

@property WePay *wepay;
@property WPConfig *config;

@end

@implementation IntegrationTestCardReader

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


#pragma mark - Tests for card reader's reading function

- (void) testReaderConnectionTimeout
{
    self.config.mockConfig.cardReadTimeOut = YES;
    XCTestExpectation *expectation = [self expectationWithDescription:@"cardReaderDidChangeStatus: with kWPCardReaderStatusNotConnected expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    StatusChangeBlock statusChangeBlock = ^(id status){
        if (status == kWPCardReaderStatusNotConnected) {
            [expectation fulfill];
        }
    };
    cardReaderDelegate.statusChangeBlock = statusChangeBlock;
    
    [self.wepay startTransactionForReadingWithCardReaderDelegate:cardReaderDelegate];
    
    [self waitForExpectationsWithTimeout:(CONNECTION_TIME_SEC + 1.0) handler:nil];
    XCTAssertTrue(cardReaderDelegate.cardReaderStatusNotConnectedInvoked);
}

- (void) testCardReadSuccess
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"didReadPaymentInfo: expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    ReadSuccessBlock readSuccessBlock = ^(){
        [expectation fulfill];
    };
    cardReaderDelegate.readSuccessBlock = readSuccessBlock;
    
    [self.wepay startTransactionForReadingWithCardReaderDelegate:cardReaderDelegate];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    XCTAssertTrue(cardReaderDelegate.successCallBackInvoked);
    XCTAssertNotNil(cardReaderDelegate.paymentInfo);
}

- (void) testCardReadFailure
{
    self.config.mockConfig.cardReadFailure = true;
    XCTestExpectation *expectation = [self expectationWithDescription:@"didFailToReadPaymentInfoWithError: expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    ReadFailureBlock readFailureBlock = ^(){
        [expectation fulfill];
    };
    cardReaderDelegate.readFailureBlock = readFailureBlock;
    
    [self.wepay startTransactionForReadingWithCardReaderDelegate:cardReaderDelegate];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    XCTAssertTrue(cardReaderDelegate.failureCallBackInvoked);
    XCTAssertNotNil(cardReaderDelegate.error);
}

- (void) testReaderResetRequest
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"cardReaderDidChangeStatus: with kWPCardReaderStatusConfiguringReader expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    StatusChangeBlock statusChangeBlock = ^(id status){
        if (status == kWPCardReaderStatusConfiguringReader) {
            [expectation fulfill];
        }
    };
    cardReaderDelegate.shouldResetCardReader = YES;
    cardReaderDelegate.statusChangeBlock = statusChangeBlock;
    
    [self.wepay startTransactionForReadingWithCardReaderDelegate:cardReaderDelegate];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    XCTAssertTrue(cardReaderDelegate.shouldResetCardReaderInvoked);
    XCTAssertTrue(cardReaderDelegate.cardReaderStatusConfiguringReaderInvoked);
}

- (void) testStopCardReader
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"cardReaderDidChangeStatus: with kWPCardReaderStatusStopped expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    StatusChangeBlock statusChangeBlock = ^(id status){
        if (status == kWPCardReaderStatusStopped) {
            [expectation fulfill];
        }
    };
    cardReaderDelegate.statusChangeBlock = statusChangeBlock;
    cardReaderDelegate.returnFromAuthorizeAmount = YES;
    
    [self.wepay startTransactionForReadingWithCardReaderDelegate:cardReaderDelegate];
    [self.wepay stopCardReader];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    XCTAssertTrue(cardReaderDelegate.cardReaderStatusStoppedInvoked);
}

#pragma mark - Tests for card reader's tokenization functionality (Swipe)

- (void) testSwipeTokenizeSuccess
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"paymentInfo:didTokenize: expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    TestTokenizationDelegate *tokenizationDelegate = [[TestTokenizationDelegate alloc] init];
    TokenizationSuccessBlock tokenizationSuccessBlock = ^(){
        [expectation fulfill];
    };
    tokenizationDelegate.tokenizationSuccessBlock = tokenizationSuccessBlock;
    
    [self.wepay startTransactionForTokenizingWithCardReaderDelegate:cardReaderDelegate
                                               tokenizationDelegate:tokenizationDelegate
                                              authorizationDelegate:nil];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssertTrue(tokenizationDelegate.successCallBackInvoked);
    XCTAssertNotNil(tokenizationDelegate.paymentToken);
}

- (void) testSwipeTokenizeFailure
{
    self.config.mockConfig.cardTokenizationFailure = YES;
    XCTestExpectation *expectation = [self expectationWithDescription:@"paymentInfo:didFailTokenization: expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    TestTokenizationDelegate *tokenizationDelegate = [[TestTokenizationDelegate alloc] init];
    TokenizationFailureBlock tokenizationFailureBlock = ^(){
        [expectation fulfill];
    };
    tokenizationDelegate.tokenizationFailureBlock = tokenizationFailureBlock;
    
    [self.wepay startTransactionForTokenizingWithCardReaderDelegate:cardReaderDelegate
                                               tokenizationDelegate:tokenizationDelegate
                                              authorizationDelegate:nil];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssertTrue(tokenizationDelegate.failureCallBackInvoked);
    XCTAssertNotNil(tokenizationDelegate.error);
}

- (void) testEmailInsertion
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"paymentInfo:didTokenize: expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    TestTokenizationDelegate *tokenizationDelegate = [[TestTokenizationDelegate alloc] init];
    TokenizationSuccessBlock tokenizationSuccessBlock = ^(){
        [expectation fulfill];
    };
    tokenizationDelegate.tokenizationSuccessBlock = tokenizationSuccessBlock;
    
    [self.wepay startTransactionForTokenizingWithCardReaderDelegate:cardReaderDelegate
                                               tokenizationDelegate:tokenizationDelegate
                                              authorizationDelegate:nil];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssertEqualObjects(@"a@b.com", tokenizationDelegate.paymentInfo.email);
}

#pragma mark - Tests for card reader's authorization functionality (EMV)

- (void) testEMVAuthorizeSuccess
{
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    XCTestExpectation *expectation = [self expectationWithDescription:@"paymentInfo:didAuthorize: expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    TestTokenizationDelegate *tokenizationDelegate = [[TestTokenizationDelegate alloc] init];
    TestAuthorizationDelegate *authorizationDelegate = [[TestAuthorizationDelegate alloc] init];
    AuthorizationSuccessBlock authorizationSuccessBlock = ^(){
        [expectation fulfill];
    };
    authorizationDelegate.authorizationSuccessBlock = authorizationSuccessBlock;
    
    [self.wepay startTransactionForTokenizingWithCardReaderDelegate:cardReaderDelegate
                                               tokenizationDelegate:tokenizationDelegate
                                              authorizationDelegate:authorizationDelegate];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssertTrue(authorizationDelegate.successCallBackInvoked);
    XCTAssertNotNil(authorizationDelegate.authorizationInfo);
}

- (void) testEMVAuthorizeFailure
{
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    self.config.mockConfig.EMVAuthFailure = YES;
    XCTestExpectation *expectation = [self expectationWithDescription:@"paymentInfo:didFailAuthorization: expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    // 20.61 is the magic number that will lead to authorization error.
    cardReaderDelegate.authorizedAmount = @"20.61";
    TestTokenizationDelegate *tokenizationDelegate = [[TestTokenizationDelegate alloc] init];
    TestAuthorizationDelegate *authorizationDelegate = [[TestAuthorizationDelegate alloc] init];
    AuthorizationFailureBlock authorizationFailureBlock = ^(){
        [expectation fulfill];
    };
    authorizationDelegate.authorizationFailureBlock = authorizationFailureBlock;
    
    [self.wepay startTransactionForTokenizingWithCardReaderDelegate:cardReaderDelegate
                                               tokenizationDelegate:tokenizationDelegate
                                              authorizationDelegate:authorizationDelegate];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssertTrue(authorizationDelegate.failureCallBackInvoked);
    XCTAssertNotNil(authorizationDelegate.error);
}

- (void) testEMVApplicationSelectionSuccess
{
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    self.config.mockConfig.multipleEMVApplication = YES;
    XCTestExpectation *expectation = [self expectationWithDescription:@"selectEMVApplication:completion: expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    TestTokenizationDelegate *tokenizationDelegate = [[TestTokenizationDelegate alloc] init];
    TestAuthorizationDelegate *authorizationDelegate = [[TestAuthorizationDelegate alloc] init];
    AuthorizationSuccessBlock authorizationSuccessBlock = ^(){
        [expectation fulfill];
    };
    authorizationDelegate.authorizationSuccessBlock = authorizationSuccessBlock;
    
    [self.wepay startTransactionForTokenizingWithCardReaderDelegate:cardReaderDelegate
                                               tokenizationDelegate:tokenizationDelegate
                                              authorizationDelegate:authorizationDelegate];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssertTrue(authorizationDelegate.selectEMVApplicationInvoked);
    NSString *paymentDescription = authorizationDelegate.paymentInfo ? authorizationDelegate.paymentInfo.paymentDescription : nil;
    NSString *lastFourDigitsOfPAN = paymentDescription ? [paymentDescription substringFromIndex:(paymentDescription.length - 4)] : nil;
    XCTAssertEqualObjects(@"4444", lastFourDigitsOfPAN);
}

- (void) testEMVApplicationSelectionError
{
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    self.config.mockConfig.multipleEMVApplication = YES;
    XCTestExpectation *expectation = [self expectationWithDescription:@"didFailToReadPaymentInfoWithError: expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    ReadFailureBlock readFailureBlock = ^(){
        [expectation fulfill];
    };
    cardReaderDelegate.readFailureBlock = readFailureBlock;
    TestTokenizationDelegate *tokenizationDelegate = [[TestTokenizationDelegate alloc] init];
    TestAuthorizationDelegate *authorizationDelegate = [[TestAuthorizationDelegate alloc] init];
    authorizationDelegate.mockEMVApplicationSelectionError = YES;
    
    [self.wepay startTransactionForTokenizingWithCardReaderDelegate:cardReaderDelegate
                                               tokenizationDelegate:tokenizationDelegate
                                              authorizationDelegate:authorizationDelegate];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssertTrue(cardReaderDelegate.failureCallBackInvoked);
}

- (void) testAuthorizeAmountSuccess
{
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    XCTestExpectation *expectation = [self expectationWithDescription:@"paymentInfo:didAuthorize: expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    TestTokenizationDelegate *tokenizationDelegate = [[TestTokenizationDelegate alloc] init];
    TestAuthorizationDelegate *authorizationDelegate = [[TestAuthorizationDelegate alloc] init];
    AuthorizationSuccessBlock authorizationSuccessBlock = ^(){
        [expectation fulfill];
    };
    authorizationDelegate.authorizationSuccessBlock = authorizationSuccessBlock;
    
    [self.wepay startTransactionForTokenizingWithCardReaderDelegate:cardReaderDelegate
                                               tokenizationDelegate:tokenizationDelegate
                                              authorizationDelegate:authorizationDelegate];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssertEqualObjects([NSDecimalNumber numberWithDouble:24.61], authorizationDelegate.authorizationInfo.amount);
}

#pragma mark - Tests for possible errors returned by validateAuthInfoImplemented:amount:currencyCode:accountId: method in WePay_CardReader class

- (void) testAuthInfoFailureForAmountTooSmall
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"didFailToReadPaymentInfoWithError: expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    cardReaderDelegate.authorizedAmount = @"0.9"; // auth amount too small
    ReadFailureBlock readFailureBlock = ^(){
        [expectation fulfill];
    };
    cardReaderDelegate.readFailureBlock = readFailureBlock;
    TestTokenizationDelegate *tokenizationDelegate = [[TestTokenizationDelegate alloc] init];
    
    [self.wepay startTransactionForTokenizingWithCardReaderDelegate:cardReaderDelegate
                                               tokenizationDelegate:tokenizationDelegate
                                              authorizationDelegate:nil];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssertTrue(cardReaderDelegate.failureCallBackInvoked);
    XCTAssertEqualObjects([WPError errorInvalidTransactionAmount], cardReaderDelegate.error);
}

- (void) testAuthInfoFailureForInvalidAccountId
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"didFailToReadPaymentInfoWithError: expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    cardReaderDelegate.accountId = 0; // invalid account id
    ReadFailureBlock readFailureBlock = ^(){
        [expectation fulfill];
    };
    cardReaderDelegate.readFailureBlock = readFailureBlock;
    TestTokenizationDelegate *tokenizationDelegate = [[TestTokenizationDelegate alloc] init];
    
    [self.wepay startTransactionForTokenizingWithCardReaderDelegate:cardReaderDelegate
                                               tokenizationDelegate:tokenizationDelegate
                                              authorizationDelegate:nil];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssertTrue(cardReaderDelegate.failureCallBackInvoked);
    XCTAssertEqualObjects([WPError errorInvalidTransactionAccountID], cardReaderDelegate.error);
}

#pragma mark - Tests for Battery Level.

- (void) testBatteryLevelSuccess
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"didGetBatteryLevel: expected to be called"];
    TestBatteryLevelDelegate *batteryLevelDelegate = [[TestBatteryLevelDelegate alloc] init];
    BatteryLevelSuccessBlock batteryLevelSuccessBlock = ^(){
        [expectation fulfill];
    };
    batteryLevelDelegate.batteryLevelSuccessBlock = batteryLevelSuccessBlock;
    
    [self.wepay getCardReaderBatteryLevelWithBatteryLevelDelegate:batteryLevelDelegate];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    XCTAssertTrue(batteryLevelDelegate.successCallBackInvoked);
}

- (void) testBatteryLevelFailure
{
    self.config.mockConfig.batteryLevelError = YES;
    XCTestExpectation *expectation = [self expectationWithDescription:@"didFailToGetBatteryLevelwithError: expected to be called"];
    TestBatteryLevelDelegate *batteryLevelDelegate = [[TestBatteryLevelDelegate alloc] init];
    BatteryLevelFailureBlock batteryLevelFailureBlock = ^(){
        [expectation fulfill];
    };
    batteryLevelDelegate.batteryLevelFailureBlock = batteryLevelFailureBlock;
    
    [self.wepay getCardReaderBatteryLevelWithBatteryLevelDelegate:batteryLevelDelegate];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    XCTAssertTrue(batteryLevelDelegate.failureCallBackInvoked);
    XCTAssertEqualObjects([WPError errorFailedToGetBatteryLevel], batteryLevelDelegate.error);
}

@end

#endif
#endif
