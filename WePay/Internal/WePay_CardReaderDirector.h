//
//  WePay_CardReaderDirector.h
//  WePay
//
//  Created by Chaitanya Bagaria on 11/17/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RUA_MFI/RUA.h")

#import <Foundation/Foundation.h>
#import <RUA_MFI/RUA.h>

#define TIMEOUT_DEFAULT_SEC 60
#define TIMEOUT_INFINITE_SEC -1
#define TIMEOUT_WORKAROUND_SEC 112

#define WEPAY_LAST_DEVICE_KEY @"wepay.last.device.type"

typedef NS_ENUM(NSInteger, CardReaderRequest) {
    CardReaderForReading,
    CardReaderForTokenizing,
    CardReaderForBatteryLevel
};

@class WPAuthorizationInfo;
@class WPConfig;
@class WPPaymentInfo;
@class WPPaymentToken;
@protocol WPCardReaderDelegate;
@protocol WPTokenizationDelegate;
@protocol WPAuthorizationDelegate;
@protocol WPBatteryLevelDelegate;

@protocol WPExternalCardReaderDelegate <NSObject>

- (void) informExternalCardReader:(NSString *)status;
- (void) informExternalCardReaderApplications:(NSArray *)applications
                                   completion:(void (^)(NSInteger selectedIndex))completion;
- (void) informExternalCardReaderSuccess:(WPPaymentInfo *)paymentInfo;
- (void) informExternalCardReaderFailure:(NSError *)error;
- (void) informExternalCardReaderSelection:(NSArray *)cardReaderNames completion:(void (^)(NSInteger selectedIndex))completion;
- (void) informExternalCardReaderResetCompletion:(void (^)(BOOL shouldReset))completion;
- (void) informExternalCardReaderAmountCompletion:(void (^)(BOOL implemented, NSDecimalNumber *amount, NSString *currencyCode, long accountId))completion;

- (void) informExternalTokenizerSuccess:(WPPaymentToken *)token forPaymentInfo:(WPPaymentInfo *)paymentInfo;
- (void) informExternalTokenizerFailure:(NSError *)error forPaymentInfo:(WPPaymentInfo *)paymentInfo;
- (void) informExternalTokenizerEmailCompletion:(void (^)(NSString *email))completion;

- (void) informExternalAuthorizationSuccess:(WPAuthorizationInfo *)authInfo forPaymentInfo:(WPPaymentInfo *)paymentInfo;
- (void) informExternalAuthorizationFailure:(NSError *)error forPaymentInfo:(WPPaymentInfo *)paymentInfo;

- (void) setExternalCardReaderDelegate:(id<WPCardReaderDelegate>) delegate;
- (void) setExternalTokenizationDelegate:(id<WPTokenizationDelegate>) delegate;
- (void) setExternalAuthorizationDelegate:(id<WPAuthorizationDelegate>) delegate;
- (void) setExternalBatteryLevelDelegate:(id<WPBatteryLevelDelegate>) delegate;

- (void) informExternalBatteryLevelSuccess:(int) batteryLevel;
- (void) informExternalBatteryLevelError:(NSError *)error;

- (id<WPCardReaderDelegate>) externalCardReaderDelegate;
- (id<WPTokenizationDelegate>) externalTokenizationDelegate;
- (id<WPAuthorizationDelegate>) externalAuthorizationDelegate;
- (id<WPBatteryLevelDelegate>) externalBatteryLevelDelegate;

@end

@protocol WPCardReaderManager <NSObject>

/**
 *  Starts the card reader.
 *
 */
- (void) startCardReader;

/**
 *  Completely stops the card reader.
 */
- (void) stopCardReader;

/**
 *  Triggers the card reader to perform the card reader request operation.
 *
 */
- (void) processCardReaderRequest;

/**
 *  Sets the CardReaderRequest type to use for the card reader.
 *
 */
- (void) setCardReaderRequest:(CardReaderRequest)request;

@end


@protocol WPTransactionDelegate <NSObject>

/**
 *  Marks the currently running transaction as completed;
 */
- (void) transactionCompleted;

@end


@interface WePay_CardReaderDirector : NSObject

- (instancetype) initWithConfig:(WPConfig *)config;

- (void) startTransactionForReadingWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate;

- (void) startTransactionForTokenizingWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate
                                        tokenizationDelegate:(id<WPTokenizationDelegate>) tokenizationDelegate
                                       authorizationDelegate:(id<WPAuthorizationDelegate>) authorizationDelegate
                                                   sessionId:(NSString *)sessionId;

- (void) stopCardReader;

- (void) getCardReaderBatteryLevelWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate
                                    batteryLevelDelegate:(id<WPBatteryLevelDelegate>) batteryLevelDelegate;

- (NSString *) getRememberedCardReader;

- (void) forgetRememberedCardReader;

@end

#endif
#endif
