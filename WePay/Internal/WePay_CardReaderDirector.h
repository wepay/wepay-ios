//
//  WePay_CardReaderDirector.h
//  WePay
//
//  Created by Chaitanya Bagaria on 11/17/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RPx_MFI/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA_MFI/RUA.h")

#import <Foundation/Foundation.h>
#import <RUA_MFI/RUA.h>

#define TIMEOUT_DEFAULT_SEC 60
#define TIMEOUT_INFINITE_SEC -1
#define TIMEOUT_WORKAROUND_SEC 112

#define WEPAY_LAST_DEVICE_KEY @"wepay.last.device.type"

typedef NS_ENUM(NSInteger, CardReaderRequest) {
    CardReaderForReading,
    CardReaderForTokenizing
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
- (void) informExternalCardReaderSuccess:(WPPaymentInfo *)paymentInfo;
- (void) informExternalCardReaderFailure:(NSError *)error;
- (void) informExternalCardReaderResetCompletion:(void (^)(BOOL shouldReset))completion;
- (void) informExternalCardReaderAmountCompletion:(void (^)(BOOL implemented, NSDecimalNumber *amount, NSString *currencyCode, long accountId))completion;

- (void) informExternalTokenizerSuccess:(WPPaymentToken *)token forPaymentInfo:(WPPaymentInfo *)paymentInfo;
- (void) informExternalTokenizerFailure:(NSError *)error forPaymentInfo:(WPPaymentInfo *)paymentInfo;
- (void) informExternalTokenizerEmailCompletion:(void (^)(NSString *email))completion;

- (void) informExternalAuthorizationSuccess:(WPAuthorizationInfo *)authInfo forPaymentInfo:(WPPaymentInfo *)paymentInfo;
- (void) informExternalAuthorizationFailure:(NSError *)error forPaymentInfo:(WPPaymentInfo *)paymentInfo;
- (void) informExternalAuthorizationApplications:(NSArray *)applications
                                      completion:(void (^)(NSInteger selectedIndex))completion;

- (void) setExternalCardReaderDelegate:(id<WPCardReaderDelegate>) delegate;
- (void) setExternalTokenizationDelegate:(id<WPTokenizationDelegate>) delegate;
- (void) setExternalAuthorizationDelegate:(id<WPAuthorizationDelegate>) delegate;

- (id<WPCardReaderDelegate>) externalCardReaderDelegate;
- (id<WPTokenizationDelegate>) externalTokenizationDelegate;
- (id<WPAuthorizationDelegate>) externalAuthorizationDelegate;

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
 *  Triggers the card reader to wait for card.
 *
 */
- (void) processCard;

/**
 *  Sets the CardReaderRequest type to use for the card reader.
 *
 */
- (void)setCardReaderRequest:(CardReaderRequest)request;

/**
 * Returns whether or not a card reader is connected
 * 
 * @return Boolean stating if card reader is connected
 */
- (BOOL) isConnected;

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

- (void) getCardReaderBatteryLevelWithBatteryLevelDelegate:(id<WPBatteryLevelDelegate>) batteryLevelDelegate;

@end

#endif
#endif
