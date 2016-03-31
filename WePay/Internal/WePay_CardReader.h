//
//  WePay_CardReader.h
//  WePay
//
//  Created by Chaitanya Bagaria on 11/17/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RPx/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA/RUA.h") && __has_include("G4XSwiper/SwiperController.h")

#import <Foundation/Foundation.h>
#import <RUA/RUA.h>

#define TIMEOUT_DEFAULT_SEC 60
#define TIMEOUT_INFINITE_SEC -1
#define TIMEOUT_WORKAROUND_SEC 112

extern NSString *const kG5XModelName;
extern NSString *const kRP350XModelName;

@class WPAuthorizationInfo;
@class WPConfig;
@class WPPaymentInfo;
@class WPPaymentToken;
@protocol WPCardReaderDelegate;
@protocol WPTokenizationDelegate;
@protocol WPAuthorizationDelegate;

@protocol WPDeviceManagerDelegate <NSObject>

- (void) handleSwipeResponse:(NSDictionary *) responseData;
- (void) handlePaymentInfo:(WPPaymentInfo *)paymentInfo;
- (void) handlePaymentInfo:(WPPaymentInfo *)paymentInfo
            successHandler:(void (^)(NSDictionary * returnData)) successHandler
              errorHandler:(void (^)(NSError * error)) errorHandler;
- (void) issueReversalForCreditCardId:(NSNumber *)creditCardId
                            accountId:(NSNumber *)accountId
                         roamResponse:(NSDictionary *)cardInfo;
- (void) fetchAuthInfo:(void (^)(BOOL implemented, NSDecimalNumber *amount, NSString *currencyCode, long accountId))completion;
- (void) handleDeviceStatusError:(NSString *)message;
- (void) connectedDevice:(NSString *)deviceType;
- (void) disconnectedDevice;

- (NSError *) validateAuthInfoImplemented:(BOOL)implemented
                                   amount:(NSDecimalNumber *)amount
                             currencyCode:(NSString *)currencyCode
                                accountId:(long)accountId;
- (NSError *) validatePaymentInfoForTokenization:(WPPaymentInfo *)paymentInfo;
- (NSError *) validateSwiperInfoForTokenization:(NSDictionary *)swiperInfo;
- (NSString *) sanitizePAN:(NSString *)pan;

@end

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

@protocol WPDeviceManager <NSObject>

/**
 *  Sets up the delegates for the device manager.
 *
 *  @param managerDelegate  The manager delegate.
 *  @param externalDelegate The external delegate.
*/
- (void) setManagerDelegate:(NSObject<WPDeviceManagerDelegate> *)managerDelegate
           externalDelegate:(NSObject<WPExternalCardReaderDelegate> *)externalDelegate;

/**
 *  Starts the card reader.
 *
 *  @return YES if initialized, NO otherwise.
 */
- (BOOL) startDevice;

/**
 *  Completely stops the device.
 */
- (void) stopDevice;

/**
 *  Triggers the card reader to wait for card.
 *
 */
- (void) processCard;

/**
 *  Determines if the card reader should restart after a dip/swipe error/success.
 *
 *  @param error The error that occured. Can be nil if the operation succeeded.
 */
- (BOOL) shouldKeepWaitingForCardAfterError:(NSError *)error forPaymentMethod:(NSString *)paymentMethod;

@end


@interface WePay_CardReader : NSObject <WPDeviceManagerDelegate>

- (instancetype) initWithConfig:(WPConfig *)config;

- (void) startCardReaderForReadingWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDlegate;

- (void) startCardReaderForTokenizingWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate
                                       tokenizationDelegate:(id<WPTokenizationDelegate>) tokenizationDelegate
                                      authorizationDelegate:(id<WPAuthorizationDelegate>) authorizationDelegate
                                                  sessionId:(NSString *)sessionId;

- (void) stopCardReader;

- (void) tokenizeSwipedPaymentInfo:(WPPaymentInfo *)paymentInfo
              tokenizationDelegate:(id<WPTokenizationDelegate>)tokenizationDelegate
                         sessionId:(NSString *)sessionId;
@end

#endif
#endif
