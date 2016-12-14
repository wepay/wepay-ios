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
#if __has_include("RPx/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA/RUA.h")

#pragma mark - startTransactionForReading tests

- (void) testRestartTransactionOnOtherErrorTrue_Reading
{
    self.config.restartTransactionAfterOtherErrors = YES;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    self.config.mockConfig.cardReadFailure =  YES;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:6 statuses:statuses successFlag:NO readOnlyFlag:YES];
    
    XCTAssertTrue(statuses.count >= 5); // There will be more because in mock the error-restart loop does not stop
    
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[4]);
}

- (void) testRestartTransactionOnOtherErrorFalse_Reading
{
    self.config.restartTransactionAfterOtherErrors = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    self.config.mockConfig.cardReadFailure =  YES;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:6 statuses:statuses successFlag:NO readOnlyFlag:YES];
    
    XCTAssertEqual(5, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusStopped, statuses[4]);
}

- (void) testRestartTransactionOnSuccessTrueSwipe_Reading
{
    self.config.restartTransactionAfterSuccess = YES;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodSwipe;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:6 statuses:statuses successFlag:YES readOnlyFlag:YES];
    
    XCTAssertTrue(statuses.count >= 5); // There will be more because in mock the error-restart loop does not stop
    
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusSwipeDetected, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[4]);
}

- (void) testRestartTransactionOnSuccessTrueDip_Reading
{
    self.config.restartTransactionAfterSuccess = YES;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:6 statuses:statuses successFlag:YES readOnlyFlag:YES];
    
    XCTAssertEqual(5, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusStopped, statuses[4]);
}

- (void) testRestartTransactionOnSuccessFalseSwipe_Reading
{
    self.config.restartTransactionAfterSuccess = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodSwipe;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:6 statuses:statuses successFlag:YES readOnlyFlag:YES];
    
    XCTAssertEqual(5, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusSwipeDetected, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusStopped, statuses[4]);
}

- (void) testRestartTransactionOnSuccessFalseDip_Reading
{
    self.config.restartTransactionAfterSuccess = YES;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:6 statuses:statuses successFlag:YES readOnlyFlag:YES];
    
    XCTAssertEqual(5, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusStopped, statuses[4]);
}

- (void) testStopCardReaderAfterTransactionFalseDipSuccess_Reading
{
    self.config.stopCardReaderAfterTransaction = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:5 statuses:statuses successFlag:YES readOnlyFlag:YES];
    
    XCTAssertEqual(4, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[3]);
}

- (void) testStopCardReaderAfterTransactionFalseDipError_Reading
{
    self.config.stopCardReaderAfterTransaction = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    self.config.mockConfig.cardReadFailure =  YES;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:5 statuses:statuses successFlag:NO readOnlyFlag:YES];
    
    XCTAssertEqual(4, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[3]);
}

- (void) testStopCardReaderAfterTransactionFalseSwipeSuccess_Reading
{
    self.config.stopCardReaderAfterTransaction = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodSwipe;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:5 statuses:statuses successFlag:YES readOnlyFlag:YES];
    
    XCTAssertEqual(4, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusSwipeDetected, statuses[3]);
}

- (void) testStopCardReaderAfterTransactionFalseSwipeError_Reading
{
    self.config.stopCardReaderAfterTransaction = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodSwipe;
    self.config.mockConfig.cardReadFailure =  YES;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:5 statuses:statuses successFlag:NO readOnlyFlag:YES];
    
    XCTAssertEqual(4, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusSwipeDetected, statuses[3]);
}

#pragma mark - startTransactionForTokenizing tests

- (void) testRestartTransactionOnOtherErrorTrue_Tokenizing
{
    self.config.restartTransactionAfterOtherErrors = YES;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    self.config.mockConfig.cardReadFailure =  YES;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:6 statuses:statuses successFlag:NO readOnlyFlag:NO];
    
    XCTAssertTrue(statuses.count >= 5); // There will be more because in mock the error-restart loop does not stop
    
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[4]);
}

- (void) testRestartTransactionOnOtherErrorFalse_Tokenizing
{
    self.config.restartTransactionAfterOtherErrors = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    self.config.mockConfig.cardReadFailure =  YES;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:6 statuses:statuses successFlag:NO readOnlyFlag:NO];
    
    XCTAssertEqual(5, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusStopped, statuses[4]);
}

- (void) testRestartTransactionOnSuccessTrueSwipe_Tokenizing
{
    self.config.restartTransactionAfterSuccess = YES;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodSwipe;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:8 statuses:statuses successFlag:YES readOnlyFlag:NO];
    
    XCTAssertTrue(statuses.count >= 6); // There will be more because in mock the error-restart loop does not stop
    
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusSwipeDetected, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusTokenizing, statuses[4]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[5]);
}

- (void) testRestartTransactionOnSuccessTrueDip_Tokenizing
{
    self.config.restartTransactionAfterSuccess = YES;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:8 statuses:statuses successFlag:YES readOnlyFlag:NO];
    
    XCTAssertEqual(6, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusAuthorizing, statuses[4]);
    XCTAssertEqual(kWPCardReaderStatusStopped, statuses[5]);
}

- (void) testRestartTransactionOnSuccessFalseSwipe_Tokenizing
{
    self.config.restartTransactionAfterSuccess = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodSwipe;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:8 statuses:statuses successFlag:YES readOnlyFlag:NO];
    
    XCTAssertEqual(6, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusSwipeDetected, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusTokenizing, statuses[4]);
    XCTAssertEqual(kWPCardReaderStatusStopped, statuses[5]);
}

- (void) testRestartTransactionOnSuccessFalseDip_Tokenizing
{
    self.config.restartTransactionAfterSuccess = YES;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:8 statuses:statuses successFlag:YES readOnlyFlag:NO];
    
    XCTAssertEqual(6, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusAuthorizing, statuses[4]);
    XCTAssertEqual(kWPCardReaderStatusStopped, statuses[5]);
}

- (void) testStopCardReaderAfterTransactionFalseDipSuccess_Tokenizing
{
    self.config.stopCardReaderAfterTransaction = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:7 statuses:statuses successFlag:YES readOnlyFlag:NO];
    
    XCTAssertEqual(5, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusAuthorizing, statuses[4]);
    
}

- (void) testStopCardReaderAfterTransactionFalseDipError_Tokenizing
{
    self.config.stopCardReaderAfterTransaction = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodDip;
    self.config.mockConfig.cardReadFailure =  YES;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:5 statuses:statuses successFlag:NO readOnlyFlag:NO];
    
    XCTAssertEqual(4, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusCardDipped, statuses[3]);
}

- (void) testStopCardReaderAfterTransactionFalseSwipeSuccess_Tokenizing
{
    self.config.stopCardReaderAfterTransaction = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodSwipe;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:7 statuses:statuses successFlag:YES readOnlyFlag:NO];
    
    XCTAssertEqual(5, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusSwipeDetected, statuses[3]);
    XCTAssertEqual(kWPCardReaderStatusTokenizing, statuses[4]);
    
}

- (void) testStopCardReaderAfterTransactionFalseSwipeError_Tokenizing
{
    self.config.stopCardReaderAfterTransaction = NO;
    self.config.mockConfig.mockPaymentMethod = kWPPaymentMethodSwipe;
    self.config.mockConfig.cardReadFailure =  YES;
    
    NSMutableArray *statuses = [@[] mutableCopy];
    
    [self restartTestHelperWithTicksCount:5 statuses:statuses successFlag:NO readOnlyFlag:NO];
    
    XCTAssertEqual(4, statuses.count);
    
    XCTAssertEqual(kWPCardReaderStatusConnected, statuses[0]);
    XCTAssertEqual(kWPCardReaderStatusCheckingReader, statuses[1]);
    XCTAssertEqual(kWPCardReaderStatusWaitingForCard, statuses[2]);
    XCTAssertEqual(kWPCardReaderStatusSwipeDetected, statuses[3]);
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
    cardReaderDelegate.readFailureBlock = ^(){
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
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    
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
