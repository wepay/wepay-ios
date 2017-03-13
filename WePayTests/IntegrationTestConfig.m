//
//  IntegrationTestConfig.m
//  WePay
//
//  Created by Chaitanya Bagaria on 12/6/16.
//  Copyright © 2016 WePay. All rights reserved.
//

#import "TestAuthorizationDelegate.h"
#import "TestBatteryLevelDelegate.h"
#import "TestCardReaderDelegate.h"
#import "TestCheckoutDelegate.h"
#import "TestTokenizationDelegate.h"
#import "WePay.h"
#import "WPError+internal.h"
#import <XCTest/XCTest.h>

@interface IntegrationTestConfig : XCTestCase

@property WePay *wepay;
@property WPConfig *config;

@end

@implementation IntegrationTestConfig

- (void) setUp
{
    [super setUp];
    self.config = [[WPConfig alloc] initWithClientId:@"171482" environment:kWPEnvironmentStage];
    WPMockConfig *mockConfig = [[WPMockConfig alloc] init];
    mockConfig.useMockWepayClient = YES; // YES is default and can be changed to NO to interact with real WePay server
    self.config.mockConfig = mockConfig;
}

- (void) tearDown
{
    self.wepay = nil;
    self.config = nil;
    [super tearDown];
}

#if defined(__has_include)
#if __has_include("RPx_MFI/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA_MFI/RUA.h")

#pragma mark - startTransactionForReading tests

- (void) testRestartTransactionOnOtherErrorTrue_Reading
{
    self.config.restartTransactionAfterOtherErrors = YES;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    self.config.mockConfig.cardReadFailure =  YES;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:7 statuses:statuses successFlag:NO readOnlyFlag:YES];
    
    XCTAssertTrue(statuses.count >= 6); // There will be more because in mock the error-restart loop does not stop
    
    XCTAssertEqual(kWPCardReaderStatusSearching, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[4]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[5]);
}

- (void) testRestartTransactionOnOtherErrorFalse_Reading
{
    self.config.restartTransactionAfterOtherErrors = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    self.config.mockConfig.cardReadFailure =  YES;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:7 statuses:statuses successFlag:NO readOnlyFlag:YES];
    
    XCTAssertEqual(6, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusSearching, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[4]);
    XCTAssertEqual(kWPCardReaderStatusStopped, statuses[5]);
}

- (void) testRestartTransactionOnSuccessTrueSwipe_Reading
{
    self.config.restartTransactionAfterSuccess = YES;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodSwipe;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:7 statuses:statuses successFlag:YES readOnlyFlag:YES];
    
    XCTAssertTrue(statuses.count >= 6); // There will be more because in mock the error-restart loop does not stop
    
    XCTAssertEqual(kWPCardReaderStatusSearching, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusSwipeDetected, statuses[4]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[5]);
}

- (void) testRestartTransactionOnSuccessTrueDip_Reading
{
    self.config.restartTransactionAfterSuccess = YES;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:7 statuses:statuses successFlag:YES readOnlyFlag:YES];
    
    XCTAssertEqual(6, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusSearching, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[4]);
    XCTAssertEqual(kWPCardReaderStatusStopped, statuses[5]);
}

- (void) testRestartTransactionOnSuccessFalseSwipe_Reading
{
    self.config.restartTransactionAfterSuccess = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodSwipe;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:7 statuses:statuses successFlag:YES readOnlyFlag:YES];
    
    XCTAssertEqual(6, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusSearching, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusSwipeDetected, statuses[4]);
    XCTAssertEqual(kWPCardReaderStatusStopped, statuses[5]);
}

- (void) testRestartTransactionOnSuccessFalseDip_Reading
{
    self.config.restartTransactionAfterSuccess = YES;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:7 statuses:statuses successFlag:YES readOnlyFlag:YES];
    
    XCTAssertEqual(6, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusSearching, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[4]);
    XCTAssertEqual(kWPCardReaderStatusStopped, statuses[5]);
}

- (void) teststopCardReaderAfterOperationFalseDipSuccess_Reading
{
    self.config.stopCardReaderAfterOperation = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:6 statuses:statuses successFlag:YES readOnlyFlag:YES];
    
    XCTAssertEqual(5, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusSearching, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[4]);
}

- (void) teststopCardReaderAfterOperationFalseDipError_Reading
{
    self.config.stopCardReaderAfterOperation = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    self.config.mockConfig.cardReadFailure =  YES;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:6 statuses:statuses successFlag:NO readOnlyFlag:YES];
    
    XCTAssertEqual(5, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusSearching, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[4]);
}

- (void) teststopCardReaderAfterOperationFalseSwipeSuccess_Reading
{
    self.config.stopCardReaderAfterOperation = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodSwipe;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:6 statuses:statuses successFlag:YES readOnlyFlag:YES];
    
    XCTAssertEqual(5, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusSearching, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusSwipeDetected, statuses[4]);
}

- (void) teststopCardReaderAfterOperationFalseSwipeError_Reading
{
    self.config.stopCardReaderAfterOperation = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodSwipe;
    self.config.mockConfig.cardReadFailure =  YES;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:6 statuses:statuses successFlag:NO readOnlyFlag:YES];
    
    XCTAssertEqual(5, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusSearching, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusSwipeDetected, statuses[4]);
}

#pragma mark - startTransactionForTokenizing tests

- (void) testRestartTransactionOnOtherErrorTrue_Tokenizing
{
    self.config.restartTransactionAfterOtherErrors = YES;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    self.config.mockConfig.cardReadFailure =  YES;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:7 statuses:statuses successFlag:NO readOnlyFlag:NO];
    
    XCTAssertTrue(statuses.count >= 6); // There will be more because in mock the error-restart loop does not stop
    
    XCTAssertEqual(kWPCardReaderStatusSearching, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[4]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[5]);
}

- (void) testRestartTransactionOnOtherErrorFalse_Tokenizing
{
    self.config.restartTransactionAfterOtherErrors = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    self.config.mockConfig.cardReadFailure =  YES;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:7 statuses:statuses successFlag:NO readOnlyFlag:NO];
    
    XCTAssertEqual(6, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusSearching, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[4]);
    XCTAssertEqual(kWPCardReaderStatusStopped, statuses[5]);
}

- (void) testRestartTransactionOnSuccessTrueSwipe_Tokenizing
{
    self.config.restartTransactionAfterSuccess = YES;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodSwipe;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:9 statuses:statuses successFlag:YES readOnlyFlag:NO];
    
    XCTAssertTrue(statuses.count >= 7); // There will be more because in mock the error-restart loop does not stop
    
    XCTAssertEqual(kWPCardReaderStatusSearching, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusSwipeDetected, statuses[4]);
    XCTAssertEqual(kWPCardReaderStatusTokenizing, statuses[5]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[6]);
}

- (void) testRestartTransactionOnSuccessTrueDip_Tokenizing
{
    self.config.restartTransactionAfterSuccess = YES;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:9 statuses:statuses successFlag:YES readOnlyFlag:NO];
    
    XCTAssertEqual(7, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusSearching, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[4]);
    XCTAssertEqual(kWPCardReaderStatusAuthorizing, statuses[5]);
    XCTAssertEqual(kWPCardReaderStatusStopped, statuses[6]);
}

- (void) testRestartTransactionOnSuccessFalseSwipe_Tokenizing
{
    self.config.restartTransactionAfterSuccess = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodSwipe;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:9 statuses:statuses successFlag:YES readOnlyFlag:NO];
    
    XCTAssertEqual(7, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusSearching, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusSwipeDetected, statuses[4]);
    XCTAssertEqual(kWPCardReaderStatusTokenizing, statuses[5]);
    XCTAssertEqual(kWPCardReaderStatusStopped, statuses[6]);
}

- (void) testRestartTransactionOnSuccessFalseDip_Tokenizing
{
    self.config.restartTransactionAfterSuccess = YES;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:9 statuses:statuses successFlag:YES readOnlyFlag:NO];
    
    XCTAssertEqual(7, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusSearching, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[4]);
    XCTAssertEqual(kWPCardReaderStatusAuthorizing, statuses[5]);
    XCTAssertEqual(kWPCardReaderStatusStopped, statuses[6]);
}

- (void) teststopCardReaderAfterOperationFalseDipSuccess_Tokenizing
{
    self.config.stopCardReaderAfterOperation = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:8 statuses:statuses successFlag:YES readOnlyFlag:NO];
    
    XCTAssertEqual(6, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusSearching, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[4]);
    XCTAssertEqual(kWPCardReaderStatusAuthorizing, statuses[5]);
}

- (void) teststopCardReaderAfterOperationFalseDipError_Tokenizing
{
    self.config.stopCardReaderAfterOperation = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    self.config.mockConfig.cardReadFailure =  YES;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:6 statuses:statuses successFlag:NO readOnlyFlag:NO];
    
    XCTAssertEqual(5, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusSearching, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[4]);
}

- (void) teststopCardReaderAfterOperationFalseSwipeSuccess_Tokenizing
{
    self.config.stopCardReaderAfterOperation = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodSwipe;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:8 statuses:statuses successFlag:YES readOnlyFlag:NO];
    
    XCTAssertEqual(6, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusSearching, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusSwipeDetected, statuses[4]);
    XCTAssertEqual(kWPCardReaderStatusTokenizing, statuses[5]);
    
}

- (void) teststopCardReaderAfterOperationFalseSwipeError_Tokenizing
{
    self.config.stopCardReaderAfterOperation = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodSwipe;
    self.config.mockConfig.cardReadFailure =  YES;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:6 statuses:statuses successFlag:NO readOnlyFlag:NO];
    
    XCTAssertEqual(5, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusSearching, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusSwipeDetected, statuses[4]);
}

/**
 * Helper for configuring handlers and starting transactions
 * @param ticksCount number of ticks expected. Status change messages, success messages, and failure messages count as ticks.
 * @param statuses an empty list of status change messages that will be populated with statuses that are received.
 * @param shouldSucceed whether or not the transaction is expected to succeed
 * @param readOnly if true, will start a read transaction, otherwise will start a tokenization transaction
 */
- (void) restartTestHelperWithTicksCount:(int)ticksCount
                                statuses:(NSMutableArray *)statuses
                             successFlag:(bool)shouldSucceed
                            readOnlyFlag:(bool)readOnly
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%d ticks expected", ticksCount]];
    __block int ticks = 0;
    __block NSMutableArray *testStatuses = [@[] mutableCopy];
    
    TestCardReaderDelegate *cardReaderDelegate = [[TestCardReaderDelegate alloc] init];
    cardReaderDelegate.readSuccessBlock = ^(){
        ticks++;
        if (ticks == ticksCount) {
            [expectation fulfill];
        }
    };
    cardReaderDelegate.readFailureBlock = ^(NSError *error){
        ticks++;
        if (ticks == ticksCount) {
            [expectation fulfill];
        }
    };
    cardReaderDelegate.statusChangeBlock = ^(id status){
        
        if (statuses == nil) {
            NSLog(@"skipping adding nil status");
        } else {
            [testStatuses addObject:status];
        }
        
        ticks++;
        if (ticks == ticksCount) {
            [expectation fulfill];
        }
    };
    
    TestTokenizationDelegate *tokenizationDelegate = [[TestTokenizationDelegate alloc] init];
    tokenizationDelegate.tokenizationSuccessBlock = ^(){
        ticks++;
        if (ticks == ticksCount) {
            [expectation fulfill];
        }
    };
    tokenizationDelegate.tokenizationFailureBlock = ^(){
        ticks++;
        if (ticks == ticksCount) {
            [expectation fulfill];
        }
    };
    
    TestAuthorizationDelegate *authorizationDelegate = [[TestAuthorizationDelegate alloc] init];
    authorizationDelegate.authorizationSuccessBlock = ^(){
        ticks++;
        if (ticks == ticksCount) {
            [expectation fulfill];
        }
    };
    authorizationDelegate.authorizationFailureBlock = ^(){
        ticks++;
        if (ticks == ticksCount) {
            [expectation fulfill];
        }
    };
    
    self.wepay = [[WePay alloc] initWithConfig:self.config];
    
    if (readOnly) {
        [self.wepay startTransactionForReadingWithCardReaderDelegate:cardReaderDelegate];
    } else {
        [self.wepay startTransactionForTokenizingWithCardReaderDelegate:cardReaderDelegate
                                                   tokenizationDelegate:tokenizationDelegate
                                                  authorizationDelegate:authorizationDelegate];
    }
    
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
    
    if (shouldSucceed) {
        XCTAssertTrue(cardReaderDelegate.successCallBackInvoked);
        if (!readOnly) {
            XCTAssertTrue(tokenizationDelegate.successCallBackInvoked || authorizationDelegate.successCallBackInvoked);
        }
    } else {
        XCTAssertTrue(cardReaderDelegate.failureCallBackInvoked);
        XCTAssertNotNil(cardReaderDelegate.error);
    }
    
    NSArray *statusesCopy = [testStatuses copy]; // to avoid iterating while changes are being made
    
    for (id status in statusesCopy) {
        [statuses addObject:status];
    }
    
    NSLog(@"statuses: %@", statuses);
}

#endif
#endif

@end
