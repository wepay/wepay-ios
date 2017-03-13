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
#import "WPMockRoamDeviceManager.h"
#import "WPMockRoamTransactionManager.h"

#define CONNECTION_TIME_SEC 7   // Same value as the wait for connection timeout in WPIngenicoCardReaderManager. 
#define DISCOVERY_TIME 1        // Discovery time defined in MockRoamDeviceManager
#define WAIT_TIME_SHORT_SEC 3.0
#define WAIT_TIME_MEDIUM_SEC 4.0
#define WAIT_TIME_LONG_SEC 5.0

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
    // Clear standardUserDefaults before each test.
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:@"xctest"];
    
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
    
    [self waitForExpectationsWithTimeout:(DISCOVERY_TIME + CONNECTION_TIME_SEC + 1.0) handler:nil];
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
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_MEDIUM_SEC handler:nil];
    XCTAssertTrue(cardReaderDelegate.successCallBackInvoked);
    XCTAssertNotNil(cardReaderDelegate.paymentInfo);
}

- (void) testCardReadFailure
{
    self.config.mockConfig.cardReadFailure = true;
    XCTestExpectation *expectation = [self expectationWithDescription:@"didFailToReadPaymentInfoWithError: expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    ReadFailureBlock readFailureBlock = ^(NSError *error){
        [expectation fulfill];
    };
    cardReaderDelegate.readFailureBlock = readFailureBlock;
    
    [self.wepay startTransactionForReadingWithCardReaderDelegate:cardReaderDelegate];
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_MEDIUM_SEC handler:nil];
    XCTAssertTrue(cardReaderDelegate.failureCallBackInvoked);
    XCTAssertNotNil(cardReaderDelegate.error);
}

- (void) testCardReaderSelectionNegative
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"didFailToReadPaymentInfoWithError: expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    ReadFailureBlock readFailureBlock = ^(NSError *error){
        [expectation fulfill];
    };
    cardReaderDelegate.selectedCardReaderIndex = -1;
    cardReaderDelegate.readFailureBlock = readFailureBlock;
    
    [self.wepay startTransactionForReadingWithCardReaderDelegate:cardReaderDelegate];
    
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
    XCTAssertTrue(cardReaderDelegate.failureCallBackInvoked);
    XCTAssertNotNil(cardReaderDelegate.error);
}

- (void) testCardReaderSelectionTooBig
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"didFailToReadPaymentInfoWithError: expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    ReadFailureBlock readFailureBlock = ^(NSError *error){
        [expectation fulfill];
    };
    cardReaderDelegate.selectedCardReaderIndex = INT_MAX;
    cardReaderDelegate.readFailureBlock = readFailureBlock;
    
    [self.wepay startTransactionForReadingWithCardReaderDelegate:cardReaderDelegate];
    
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
    XCTAssertTrue(cardReaderDelegate.failureCallBackInvoked);
    XCTAssertNotNil(cardReaderDelegate.error);
}

- (void) testBadCardReaderSelectionRestart
{
    self.config.restartTransactionAfterOtherErrors = YES;
    XCTestExpectation *failureExpectation = [self expectationWithDescription:@"didFailToReadPaymentInfoWithError: expected to be called"];
    XCTestExpectation *successExpectation = [self expectationWithDescription:@"didReadPaymentInfo: expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];

    // Test failure for an invalid selection
    ReadFailureBlock readFailureBlock = ^(NSError *error){
        if (error.code == WPErrorInvalidCardReaderSelection) {
            // Select a valid card reader this time, since we failed once and are
            // expecting a restart
            [failureExpectation fulfill];
            cardReaderDelegate.selectedCardReaderIndex = 0;
        }
    };
    cardReaderDelegate.selectedCardReaderIndex = -1;
    cardReaderDelegate.readFailureBlock = readFailureBlock;
    
    // Test success for a subsequent valid selection
    ReadSuccessBlock readSuccessBlock = ^(){
        [successExpectation fulfill];
    };
    cardReaderDelegate.readSuccessBlock = readSuccessBlock;
    
    [self.wepay startTransactionForReadingWithCardReaderDelegate:cardReaderDelegate];
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_LONG_SEC handler:nil];
    XCTAssertTrue(cardReaderDelegate.failureCallBackInvoked);
    XCTAssertTrue(cardReaderDelegate.successCallBackInvoked);
    XCTAssertNotNil(cardReaderDelegate.error);
    XCTAssertNotNil(cardReaderDelegate.paymentInfo);
}

- (void) testBadCardReaderSelectionNoRestart
{
    self.config.restartTransactionAfterOtherErrors = NO;
    XCTestExpectation *failureExpectation = [self expectationWithDescription:@"didFailToReadPaymentInfoWithError: expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    
    ReadFailureBlock readFailureBlock = ^(NSError *error){
        [failureExpectation fulfill];
    };
    cardReaderDelegate.selectedCardReaderIndex = -1;
    cardReaderDelegate.readFailureBlock = readFailureBlock;

    [self.wepay startTransactionForReadingWithCardReaderDelegate:cardReaderDelegate];
    
    // Expecting failure block to be called because of the bad selection index, then
    // the connection to time out because restart is set to NO.
    [self waitForExpectationsWithTimeout:CONNECTION_TIME_SEC + 1.0 handler:nil];
    XCTAssertTrue(cardReaderDelegate.failureCallBackInvoked);
    XCTAssertNotNil(cardReaderDelegate.error);
    XCTAssertFalse(cardReaderDelegate.cardReaderStatusNotConnectedInvoked);
}

- (void) testReaderResetRequest
{
    XCTestExpectation *wfcExpectation = [self expectationWithDescription:@"cardReaderDidChangeStatus: with kWPCardReaderStatusWaitingForCard expected to be called"];
    XCTestExpectation *cfgExpectation = [self expectationWithDescription:@"cardReaderDidChangeStatus: with kWPCardReaderStatusConfiguringReader expected to be called after shouldResetCardReader is invoked"];
    __block TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    StatusChangeBlock statusChangeBlock = ^(id status){
        if (status == kWPCardReaderStatusConfiguringReader && cardReaderDelegate.shouldResetCardReaderInvoked) {
            [cfgExpectation fulfill];
        } else if (status == kWPCardReaderStatusWaitingForCard) {
            [wfcExpectation fulfill];
        }
    };
    cardReaderDelegate.statusChangeBlock = statusChangeBlock;
    cardReaderDelegate.shouldResetCardReader = YES;
    
    ReadSuccessBlock readSuccessBlock = ^() {
        [self.wepay startTransactionForReadingWithCardReaderDelegate:cardReaderDelegate];
    };
    cardReaderDelegate.readSuccessBlock = readSuccessBlock;
    
    [self.wepay startTransactionForReadingWithCardReaderDelegate:cardReaderDelegate];
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_MEDIUM_SEC handler:nil];
    XCTAssertTrue(cardReaderDelegate.shouldResetCardReaderInvoked);
    XCTAssertTrue(cardReaderDelegate.cardReaderStatusConfiguringReaderInvoked);
}

- (void) testStopCardReader
{
    self.config.stopCardReaderAfterOperation = NO;
    XCTestExpectation *expectation = [self expectationWithDescription:@"cardReaderDidChangeStatus: with kWPCardReaderStatusStopped expected to be called"];
    XCTestExpectation *disconnectedNotCalledExpectation = [self expectationWithDescription:@"Expected fulfillment after async delay."];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    __block id mostRecentStatus = nil;
    StatusChangeBlock statusChangeBlock = ^(id status){
        if (status == kWPCardReaderStatusWaitingForCard) {
            [self.wepay stopCardReader];
        } else if (status == kWPCardReaderStatusStopped) {
            [expectation fulfill];
        }
        
        mostRecentStatus = status;
    };
    cardReaderDelegate.statusChangeBlock = statusChangeBlock;
    cardReaderDelegate.returnFromAuthorizeAmount = YES;
    
    [self.wepay startTransactionForReadingWithCardReaderDelegate:cardReaderDelegate];
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, WAIT_TIME_MEDIUM_SEC * NSEC_PER_SEC);
    dispatch_after(time, queue, ^{
        if (!cardReaderDelegate.cardReaderStatusNotConnectedInvoked) {
            [disconnectedNotCalledExpectation fulfill];
        }
    });
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_LONG_SEC handler:nil];
    XCTAssertEqual(mostRecentStatus, kWPCardReaderStatusStopped);
}

- (void) testStopDuringCardReaderSelection
{
    XCTestExpectation *stopExpectation = [self expectationWithDescription:@"cardReaderDidChangeStatus: with kWPCardReaderStatusStopped expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    
    SelectCardReaderBlock selectCardReaderBlock = ^(void (^callback) (NSInteger selectedIndex)) {
        [self.wepay stopCardReader];
        callback(0);
    };
    cardReaderDelegate.selectCardReaderBlock = selectCardReaderBlock;
    
    StatusChangeBlock statusChangeBlock = ^(id status){
        if (status == kWPCardReaderStatusStopped) {
            [stopExpectation fulfill];
        }
    };
    cardReaderDelegate.statusChangeBlock = statusChangeBlock;
    cardReaderDelegate.returnFromAuthorizeAmount = YES;
    
    [self.wepay startTransactionForReadingWithCardReaderDelegate:cardReaderDelegate];
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_MEDIUM_SEC handler:nil];
    XCTAssertTrue(cardReaderDelegate.cardReaderStatusStoppedInvoked);
    XCTAssertNil(cardReaderDelegate.error);
}

- (void) testCardReaderSearchesUntilDiscovered
{
    self.config.mockConfig.mockCardReaderIsDetected = NO;
    XCTestExpectation *expectation = [self expectationWithDescription:@"cardReaderDidChangeStatus: with kWPCardReaderStatusConnected expected to be called"];
    NSMutableArray *statuses = [[NSMutableArray alloc] init];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    
    SelectCardReaderBlock selectCardReaderBlock = ^(void (^callback) (NSInteger selectedIndex)) {
        callback(0);
    };
    cardReaderDelegate.selectCardReaderBlock = selectCardReaderBlock;
    
    StatusChangeBlock statusChangeBlock = ^(id status){
        if (status == kWPCardReaderStatusNotConnected) {
            self.config.mockConfig.mockCardReaderIsDetected = YES;
        } else if (status == kWPCardReaderStatusConnected) {
            [expectation fulfill];
        }
        [statuses addObject:status];
    };
    cardReaderDelegate.statusChangeBlock = statusChangeBlock;
    
    [self.wepay startTransactionForReadingWithCardReaderDelegate:cardReaderDelegate];
    
    // Waiting for CONNECTION_TIME_MS + DISCOVERY_TIME + 1 seconds as buffer
    // We are waiting for the first attempt at connection to fail, then expecting
    // the second attempt to succeed.
    [self waitForExpectationsWithTimeout:(CONNECTION_TIME_SEC + DISCOVERY_TIME + 1) handler:nil];
    
    XCTAssertTrue(statuses.count >= 3);
    XCTAssertEqual([statuses objectAtIndex:0], kWPCardReaderStatusSearching);
    XCTAssertEqual([statuses objectAtIndex:1], kWPCardReaderStatusNotConnected);
    XCTAssertEqual([statuses objectAtIndex:2], kWPCardReaderStatusConnected);
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
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_LONG_SEC handler:nil];
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
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_LONG_SEC handler:nil];
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
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_LONG_SEC handler:nil];
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
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_LONG_SEC handler:nil];
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
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_LONG_SEC handler:nil];
    XCTAssertTrue(authorizationDelegate.failureCallBackInvoked);
    XCTAssertNotNil(authorizationDelegate.error);
}

- (void) testEMVApplicationSelectionSuccessTransactionTokenizing
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
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_LONG_SEC handler:nil];
    XCTAssertTrue(cardReaderDelegate.selectEMVApplicationInvoked);
    NSString *paymentDescription = authorizationDelegate.paymentInfo ? authorizationDelegate.paymentInfo.paymentDescription : nil;
    NSString *lastFourDigitsOfPAN = paymentDescription ? [paymentDescription substringFromIndex:(paymentDescription.length - 4)] : nil;
    XCTAssertEqualObjects(@"4444", lastFourDigitsOfPAN);
}

- (void) testEMVApplicationSelectionSuccessTransactionReading
{
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    self.config.mockConfig.multipleEMVApplication = YES;
    XCTestExpectation *expectation = [self expectationWithDescription:@"didReadPaymentInfo:paymentInfo: expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    ReadSuccessBlock readSuccessBlock = ^() {
        [expectation fulfill];
    };
    cardReaderDelegate.readSuccessBlock = readSuccessBlock;
    
    [self.wepay startTransactionForReadingWithCardReaderDelegate:cardReaderDelegate];
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_LONG_SEC handler:nil];
}

- (void) testEMVApplicationSelectionError
{
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    self.config.mockConfig.multipleEMVApplication = YES;
    XCTestExpectation *expectation = [self expectationWithDescription:@"didFailToReadPaymentInfoWithError: expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    ReadFailureBlock readFailureBlock = ^(NSError *error){
        [expectation fulfill];
    };
    cardReaderDelegate.readFailureBlock = readFailureBlock;
    cardReaderDelegate.mockEMVApplicationSelectionError = YES;
    
    [self.wepay startTransactionForReadingWithCardReaderDelegate:cardReaderDelegate];
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_LONG_SEC handler:nil];
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
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_LONG_SEC handler:nil];
    XCTAssertEqualObjects([NSDecimalNumber numberWithDouble:24.61], authorizationDelegate.authorizationInfo.amount);
}

#pragma mark - Tests for possible errors returned by validateAuthInfoImplemented:amount:currencyCode:accountId: method in WePay_CardReader class

- (void) testAuthInfoFailureForAmountTooSmall
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"didFailToReadPaymentInfoWithError: expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    cardReaderDelegate.authorizedAmount = @"0.9"; // auth amount too small
    ReadFailureBlock readFailureBlock = ^(NSError *error){
        [expectation fulfill];
    };
    cardReaderDelegate.readFailureBlock = readFailureBlock;
    TestTokenizationDelegate *tokenizationDelegate = [[TestTokenizationDelegate alloc] init];
    
    [self.wepay startTransactionForTokenizingWithCardReaderDelegate:cardReaderDelegate
                                               tokenizationDelegate:tokenizationDelegate
                                              authorizationDelegate:nil];
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_LONG_SEC handler:nil];
    XCTAssertTrue(cardReaderDelegate.failureCallBackInvoked);
    XCTAssertEqualObjects([WPError errorInvalidTransactionAmount], cardReaderDelegate.error);
}

- (void) testAuthInfoFailureForInvalidAccountId
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"didFailToReadPaymentInfoWithError: expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    cardReaderDelegate.accountId = 0; // invalid account id
    ReadFailureBlock readFailureBlock = ^(NSError *error){
        [expectation fulfill];
    };
    cardReaderDelegate.readFailureBlock = readFailureBlock;
    TestTokenizationDelegate *tokenizationDelegate = [[TestTokenizationDelegate alloc] init];
    
    [self.wepay startTransactionForTokenizingWithCardReaderDelegate:cardReaderDelegate
                                               tokenizationDelegate:tokenizationDelegate
                                              authorizationDelegate:nil];
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_LONG_SEC handler:nil];
    XCTAssertTrue(cardReaderDelegate.failureCallBackInvoked);
    XCTAssertEqualObjects([WPError errorInvalidTransactionAccountID], cardReaderDelegate.error);
}

#pragma mark - Tests for Battery Level.

- (void) testBatteryLevelSuccess
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"didGetBatteryLevel: expected to be called"];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    TestBatteryLevelDelegate *batteryLevelDelegate = [[TestBatteryLevelDelegate alloc] init];
    BatteryLevelSuccessBlock batteryLevelSuccessBlock = ^(){
        [expectation fulfill];
    };
    batteryLevelDelegate.batteryLevelSuccessBlock = batteryLevelSuccessBlock;
    
    [self.wepay getCardReaderBatteryLevelWithCardReaderDelegate:cardReaderDelegate
                                           batteryLevelDelegate:batteryLevelDelegate];
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_LONG_SEC handler:nil];
    XCTAssertTrue(batteryLevelDelegate.successCallBackInvoked);
    XCTAssertTrue(cardReaderDelegate.selectCardReaderInvoked);
}

- (void) testBatteryLevelFailure
{
    self.config.mockConfig.batteryLevelError = YES;
    XCTestExpectation *expectation = [self expectationWithDescription:@"didFailToGetBatteryLevelwithError: expected to be called"];
    TestBatteryLevelDelegate *batteryLevelDelegate = [[TestBatteryLevelDelegate alloc] init];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    BatteryLevelFailureBlock batteryLevelFailureBlock = ^(){
        [expectation fulfill];
    };
    batteryLevelDelegate.batteryLevelFailureBlock = batteryLevelFailureBlock;
    
    [self.wepay getCardReaderBatteryLevelWithCardReaderDelegate:cardReaderDelegate
                                           batteryLevelDelegate:batteryLevelDelegate];
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_LONG_SEC handler:nil];
    XCTAssertTrue(cardReaderDelegate.selectCardReaderInvoked);
    XCTAssertTrue(batteryLevelDelegate.failureCallBackInvoked);
    XCTAssertEqualObjects([WPError errorFailedToGetBatteryLevel], batteryLevelDelegate.error);
}

- (void) testBatteryInfoSuccessAfterTransaction_StopAfterOperationFalse
{
    XCTestExpectation *batteryLevelExpectation = [self expectationWithDescription:@"onBatteryLevel: expected to be called"];
    XCTestExpectation *successExcpectation = [self expectationWithDescription:@"onSuccess: expected to be called"];
    self.config.stopCardReaderAfterOperation = NO;
    
    TestBatteryLevelDelegate *batteryLevelDelegate = [[TestBatteryLevelDelegate alloc] init];
    batteryLevelDelegate.batteryLevelSuccessBlock = ^{
        [batteryLevelExpectation fulfill];
    };
    
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    __weak TestCardReaderDelegate *cardReaderDelegateRef = cardReaderDelegate;
    cardReaderDelegate.readSuccessBlock = ^{
        [successExcpectation fulfill];
        [self.wepay getCardReaderBatteryLevelWithCardReaderDelegate:cardReaderDelegateRef
                                               batteryLevelDelegate:batteryLevelDelegate];
    };
    
    [self.wepay startTransactionForTokenizingWithCardReaderDelegate:cardReaderDelegate
                                               tokenizationDelegate:[[TestTokenizationDelegate alloc] init]
                                              authorizationDelegate:[[TestAuthorizationDelegate alloc] init]];
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_LONG_SEC handler:nil];
    XCTAssertTrue(cardReaderDelegate.selectCardReaderInvoked);
    XCTAssertTrue(cardReaderDelegate.successCallBackInvoked);
    XCTAssertNil(cardReaderDelegate.error);
    XCTAssertNil(batteryLevelDelegate.error);
    XCTAssertGreaterThan(batteryLevelDelegate.batteryLevel, 0);
}

- (void) testBatteryInfoErrorAfterTransaction_StopAfterOperationFalse
{
    XCTestExpectation *batteryLevelExpectation = [self expectationWithDescription:@"onBatteryLevelFailure: expected to be called"];
    XCTestExpectation *successExcpectation = [self expectationWithDescription:@"onSuccess: expected to be called"];
    self.config.stopCardReaderAfterOperation = NO;
    self.config.mockConfig.batteryLevelError = YES;
    
    TestBatteryLevelDelegate *batteryLevelDelegate = [[TestBatteryLevelDelegate alloc] init];
    batteryLevelDelegate.batteryLevelFailureBlock = ^{
        [batteryLevelExpectation fulfill];
    };
    
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    __weak TestCardReaderDelegate *cardReaderDelegateRef = cardReaderDelegate;
    cardReaderDelegate.readSuccessBlock = ^{
        [successExcpectation fulfill];
        [self.wepay getCardReaderBatteryLevelWithCardReaderDelegate:cardReaderDelegateRef
                                               batteryLevelDelegate:batteryLevelDelegate];
    };
    
    [self.wepay startTransactionForTokenizingWithCardReaderDelegate:cardReaderDelegate
                                               tokenizationDelegate:[[TestTokenizationDelegate alloc] init]
                                              authorizationDelegate:[[TestAuthorizationDelegate alloc] init]];
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_LONG_SEC handler:nil];
    XCTAssertTrue(cardReaderDelegate.selectCardReaderInvoked);
    XCTAssertTrue(cardReaderDelegate.successCallBackInvoked);
    XCTAssertNil(cardReaderDelegate.error);
    XCTAssertNotNil(batteryLevelDelegate.error);
    XCTAssertTrue(batteryLevelDelegate.failureCallBackInvoked);
    XCTAssertFalse(batteryLevelDelegate.successCallBackInvoked);
}

- (void) testBatteryInfoSuccessAfterTransaction_StopAfterOperationTrue
{
    XCTestExpectation *batteryLevelExpectation = [self expectationWithDescription:@"onBatteryLevel: expected to be called"];
    XCTestExpectation *successExcpectation = [self expectationWithDescription:@"onSuccess: expected to be called"];
    self.config.stopCardReaderAfterOperation = YES;
    
    TestBatteryLevelDelegate *batteryLevelDelegate = [[TestBatteryLevelDelegate alloc] init];
    batteryLevelDelegate.batteryLevelSuccessBlock = ^{
        [batteryLevelExpectation fulfill];
    };
    
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    __weak TestCardReaderDelegate *cardReaderDelegateRef = cardReaderDelegate;
    cardReaderDelegate.readSuccessBlock = ^{
        [successExcpectation fulfill];
        [self.wepay getCardReaderBatteryLevelWithCardReaderDelegate:cardReaderDelegateRef
                                               batteryLevelDelegate:batteryLevelDelegate];
    };
    
    [self.wepay startTransactionForTokenizingWithCardReaderDelegate:cardReaderDelegate
                                               tokenizationDelegate:[[TestTokenizationDelegate alloc] init]
                                              authorizationDelegate:[[TestAuthorizationDelegate alloc] init]];
    
    // Since configured to stop, we will go through discovery twice. The Long wait time is to
    // account for the successful transaction time.
    [self waitForExpectationsWithTimeout:DISCOVERY_TIME + DISCOVERY_TIME + WAIT_TIME_LONG_SEC handler:nil];
    XCTAssertTrue(cardReaderDelegate.selectCardReaderInvoked);
    XCTAssertTrue(cardReaderDelegate.successCallBackInvoked);
    XCTAssertNil(cardReaderDelegate.error);
    XCTAssertNil(batteryLevelDelegate.error);
    XCTAssertGreaterThan(batteryLevelDelegate.batteryLevel, 0);
}

- (void) testBatteryInfoErrorAfterTransaction_StopAfterOperationTrue
{
    XCTestExpectation *batteryLevelExpectation = [self expectationWithDescription:@"onBatteryLevelFailure: expected to be called"];
    XCTestExpectation *successExcpectation = [self expectationWithDescription:@"onSuccess: expected to be called"];
    self.config.stopCardReaderAfterOperation = YES;
    self.config.mockConfig.batteryLevelError = YES;
    
    TestBatteryLevelDelegate *batteryLevelDelegate = [[TestBatteryLevelDelegate alloc] init];
    batteryLevelDelegate.batteryLevelFailureBlock = ^{
        [batteryLevelExpectation fulfill];
    };
    
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    __weak TestCardReaderDelegate *cardReaderDelegateRef = cardReaderDelegate;
    cardReaderDelegate.readSuccessBlock = ^{
        [successExcpectation fulfill];
        [self.wepay getCardReaderBatteryLevelWithCardReaderDelegate:cardReaderDelegateRef
                                               batteryLevelDelegate:batteryLevelDelegate];
    };
    
    [self.wepay startTransactionForTokenizingWithCardReaderDelegate:cardReaderDelegate
                                               tokenizationDelegate:[[TestTokenizationDelegate alloc] init]
                                              authorizationDelegate:[[TestAuthorizationDelegate alloc] init]];
    
    // Since configured to stop, we will go through discovery twice. The Long wait time is to
    // account for the successful transaction time.
    [self waitForExpectationsWithTimeout:DISCOVERY_TIME + DISCOVERY_TIME + WAIT_TIME_LONG_SEC handler:nil];
    XCTAssertTrue(cardReaderDelegate.selectCardReaderInvoked);
    XCTAssertTrue(cardReaderDelegate.successCallBackInvoked);
    XCTAssertNil(cardReaderDelegate.error);
    XCTAssertNotNil(batteryLevelDelegate.error);
    XCTAssertTrue(batteryLevelDelegate.failureCallBackInvoked);
    XCTAssertFalse(batteryLevelDelegate.successCallBackInvoked);
}

- (void) testBatteryLevelTooLow
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"didFailToReadPaymentInfoWithError:RUAErrorCodeBatteryTooLowError expected to be called"];
    WPMockRoamDeviceManager *deviceManager = [WPMockRoamDeviceManager getDeviceManager];
    WPMockRoamTransactionManager *transactionManager = [deviceManager getTransactionManager];
    
    self.config.mockConfig.cardReadFailure = YES;
    transactionManager.mockCommandErrorCode = RUAErrorCodeBatteryTooLowError;
 
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    ReadFailureBlock readFailBlock = ^(NSError *error) {
        if (cardReaderDelegate.error.code == WPErrorCardReaderBatteryTooLow) {
            [expectation fulfill];
        }
    };
    cardReaderDelegate.readFailureBlock = readFailBlock;
    
    [self.wepay startTransactionForReadingWithCardReaderDelegate:cardReaderDelegate];
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
}

#pragma mark - Tests for card reader disconnection

- (void) testDisconnectCardReaderAfterTransactionConfigStopCardReaderYes
{
    self.config.stopCardReaderAfterOperation = YES;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    
    XCTestExpectation *authorizedExpectation = [self expectationWithDescription:@"paymentInfo:didAuthorize: expected to be called"];
    XCTestExpectation *stoppedExpectation = [self expectationWithDescription:@"cardReaderDidChangeStatus: expected final status to be kWPCardReaderStatusStopped"];
    
    //Should not get onDisconnected or onConnected callback AFTER the mock DC/RC occurs
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    TestTokenizationDelegate *tokenizationDelegate = [[TestTokenizationDelegate alloc] init];
    TestAuthorizationDelegate *authorizationDelegate = [[TestAuthorizationDelegate alloc] init];
    __block id mostRecentCardReaderStatus = nil;
    
    AuthorizationSuccessBlock authorizationSuccessBlock = ^() {
        WPMockRoamDeviceManager *mockRoamDeviceManager = [WPMockRoamDeviceManager getDeviceManager];
        
        [authorizedExpectation fulfill];
        
        // Disconnect the card reader after successful authorization.
        [mockRoamDeviceManager mockCardReaderDisconnect];
    };
    authorizationDelegate.authorizationSuccessBlock = authorizationSuccessBlock;
    
    StatusChangeBlock statusChangeBlock = ^(id status) {
        mostRecentCardReaderStatus = status;
    };
    cardReaderDelegate.statusChangeBlock = statusChangeBlock;
    
    [self.wepay startTransactionForTokenizingWithCardReaderDelegate:cardReaderDelegate
                                               tokenizationDelegate:tokenizationDelegate
                                              authorizationDelegate:authorizationDelegate];
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, WAIT_TIME_MEDIUM_SEC * NSEC_PER_SEC);
    dispatch_after(time, queue, ^{
        // We're expecting the transaction to go through as normal and end in a stopped state
        // because of our config value.
        if (mostRecentCardReaderStatus == kWPCardReaderStatusStopped) {
            [stoppedExpectation fulfill];
        }
    });
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_LONG_SEC handler:nil];
    
    // We're expecting the transaction to go through as normal and end in a stopped state
    // because of our config value.
    XCTAssertTrue(authorizationDelegate.successCallBackInvoked);
    XCTAssertFalse(cardReaderDelegate.cardReaderStatusNotConnectedInvoked);
    XCTAssertNotNil(authorizationDelegate.authorizationInfo);
    XCTAssertNil(cardReaderDelegate.error);
    XCTAssertNil(tokenizationDelegate.error);
}

// Tests that the card reader manager stays in its transaction-complete state even after
// disconnecting/reconnecting the card reader.
- (void) testDisconnectAndReconnectCardReaderAfterTransactionConfigStopCardReaderNo
{
    self.config.stopCardReaderAfterOperation = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    
    XCTestExpectation *reconnectExpectation = [self expectationWithDescription:@"cardReaderDidChangeStatus: expected to be called with status: kWPCardReaderStatusConnected following disconnection."];
    XCTestExpectation *delayedExpectation = [self expectationWithDescription:@"Expected delayed assertion block to be called."];
    
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    TestTokenizationDelegate *tokenizationDelegate = [[TestTokenizationDelegate alloc] init];
    TestAuthorizationDelegate *authorizationDelegate = [[TestAuthorizationDelegate alloc] init];
    __block WPMockRoamDeviceManager *mockRoamDeviceManager = nil;
    __block BOOL isDisconnectCalled = NO;
    __block id mostRecentCardReaderStatus = nil;
    
    AuthorizationSuccessBlock authorizationSuccessBlock = ^() {
        mockRoamDeviceManager = [WPMockRoamDeviceManager getDeviceManager];
        
        // Disconnect the card reader after successful authorization.
        [mockRoamDeviceManager mockCardReaderDisconnect];
    };
    authorizationDelegate.authorizationSuccessBlock = authorizationSuccessBlock;
    
    StatusChangeBlock statusChangeBlock = ^(id status) {
        if (status == kWPCardReaderStatusNotConnected) {
            isDisconnectCalled = YES;
            
            // Reconnect the card reader after disconnect is detected.
            [mockRoamDeviceManager mockCardReaderConnect];
        } else if (isDisconnectCalled && status == kWPCardReaderStatusConnected) {
            [reconnectExpectation fulfill];
        }
        
        mostRecentCardReaderStatus = status;
    };
    cardReaderDelegate.statusChangeBlock = statusChangeBlock;
    
    [self.wepay startTransactionForTokenizingWithCardReaderDelegate:cardReaderDelegate
                                               tokenizationDelegate:tokenizationDelegate
                                              authorizationDelegate:authorizationDelegate];
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, WAIT_TIME_MEDIUM_SEC * NSEC_PER_SEC);
    dispatch_after(time, queue, ^{
        // Ensure that the final state of the card reader is connected. It should not
        // attempt to read a card again.
        [delayedExpectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_LONG_SEC handler:nil];
    XCTAssertTrue(mostRecentCardReaderStatus == kWPCardReaderStatusConnected);
    XCTAssertTrue(authorizationDelegate.successCallBackInvoked);
    XCTAssertTrue(cardReaderDelegate.cardReaderStatusNotConnectedInvoked);
    XCTAssertNotNil(authorizationDelegate.authorizationInfo);
    XCTAssertNil(cardReaderDelegate.error);
    XCTAssertNil(tokenizationDelegate.error);
}

#pragma mark - Tests for remembering the card reader

- (void) testCheckRememberedCardReaderOnConnection
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Expected to have 'AUDIOJACK' as the remembered card reader."];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    StatusChangeBlock statusChangeBlock = ^(id status) {
        if (status == kWPCardReaderStatusConnected) {
            // Should have a remembered card reader at this point.
            if ([[self.wepay getRememberedCardReader] isEqualToString:@"AUDIOJACK"]) {
                [expectation fulfill];
            }
        }
    };
    cardReaderDelegate.statusChangeBlock = statusChangeBlock;
    
    [self.wepay startTransactionForReadingWithCardReaderDelegate:cardReaderDelegate];
    
    [self waitForExpectationsWithTimeout:WAIT_TIME_SHORT_SEC handler:nil];
}

- (void) testForgetCardReaderOnConnection
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Expected to have no remembered card reader after forgetting."];
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    StatusChangeBlock statusChangeBlock = ^(id status) {
        if (status == kWPCardReaderStatusConnected) {
            // Forget the card reader after it's been remembered.
            [self.wepay forgetRememberedCardReader];
        }
    };
    cardReaderDelegate.statusChangeBlock = statusChangeBlock;
    
    ReadSuccessBlock successBlock = ^() {
        // We shouldn't have a remembered card reader after the transaction.
        [expectation fulfill];
        XCTAssertEqual([self.wepay getRememberedCardReader], nil);
    };
    cardReaderDelegate.readSuccessBlock = successBlock;
    
    [self.wepay startTransactionForReadingWithCardReaderDelegate:cardReaderDelegate];
    [self waitForExpectationsWithTimeout:WAIT_TIME_MEDIUM_SEC handler:nil];
}

@end

#endif
#endif
