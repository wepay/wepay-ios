//
//  WePay.h
//  WePay
//
//  Created by Chaitanya Bagaria on 10/30/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "WPAddress.h"
#import "WPConfig.h"
#import "WPPaymentInfo.h"
#import "WPPaymentToken.h"
#import "WPAuthorizationInfo.h"

@class WPConfig;
@class WPPaymentInfo;
@class WPPaymentToken;

// Environments
extern NSString * const kWPEnvironmentStage;
extern NSString * const kWPEnvironmentProduction;

// Payment Methods
extern NSString * const kWPPaymentMethodSwipe;
extern NSString * const kWPPaymentMethodManual;
extern NSString * const kWPPaymentMethodDip;

// Card Reader status
extern NSString * const kWPCardReaderStatusNotConnected;
extern NSString * const kWPCardReaderStatusConnected;
extern NSString * const kWPCardReaderStatusCheckingReader;
extern NSString * const kWPCardReaderStatusConfiguringReader;
extern NSString * const kWPCardReaderStatusWaitingForCard;
extern NSString * const kWPCardReaderStatusShouldNotSwipeEMVCard;
extern NSString * const kWPCardReaderStatusCheckCardOrientation;
extern NSString * const kWPCardReaderStatusChipErrorSwipeCard;
extern NSString * const kWPCardReaderStatusSwipeErrorSwipeAgain;
extern NSString * const kWPCardReaderStatusSwipeDetected;
extern NSString * const kWPCardReaderStatusCardDipped;
extern NSString * const kWPCardReaderStatusTokenizing;
extern NSString * const kWPCardReaderStatusAuthorizing;
extern NSString * const kWPCardReaderStatusStopped;

// Currency Codes
extern NSString * const kWPCurrencyCodeUSD;

/**
 *  \protocol WPAuthorizationDelegate
 *  This delegate protocol has to be adopted by any class that handles EMV authorization responses.
 */
@protocol WPAuthorizationDelegate <NSObject>
@required
/**
 *  Called when the EMV card contains more than one application. The applications should be presented to the payer for selection. Once the payer makes a choice, you need to execute the completion block with the index of the selected application. The transaction cannot proceed until the completion block is executed.
 *  Example:
 *      completion(0);
 *
 *  @param applications    The array of NSStrings containing application names from the card.
 *  @param completion      The block to be executed with the index of the selected application.
 *  @param selectedIndex   The index of the selected application in the array of applications from the card.
 */
- (void) selectEMVApplication:(NSArray *)applications
                   completion:(void (^)(NSInteger selectedIndex))completion;

/**
 *  Called when an authorization call succeeds.
 *
 *  @param paymentInfo       The payment info for the card that was authorized.
 *  @param authorizationInfo The authorization info for the transaction that was authorized.
 */
- (void) paymentInfo:(WPPaymentInfo *)paymentInfo
        didAuthorize:(WPAuthorizationInfo *)authorizationInfo;

/**
 *  Called when an authorization call fails.
 *
 *  @param paymentInfo The payment info for the card that failed authorization.
 *  @param error       The error which caused the failure.
 */
- (void) paymentInfo:(WPPaymentInfo *)paymentInfo
didFailAuthorization:(NSError *)error;

@end

/** \protocol WPTokenizationDelegate
 *  This delegate protocol has to be adopted by any class that handles tokenization responses.
 */
@protocol WPTokenizationDelegate <NSObject>

/**
 *  Called when a tokenization call succeeds.
 *
 *  @param paymentInfo  The payment info that was tokenized.
 *  @param paymentToken The payment token representing the payment info.
 */
- (void) paymentInfo:(WPPaymentInfo *)paymentInfo
         didTokenize:(WPPaymentToken *)paymentToken;

/**
 *  Called when a tokenization call fails.
 *
 *  @param paymentInfo The payment info that failed tokenization.
 *  @param error       The error which caused the failure.
 */
- (void) paymentInfo:(WPPaymentInfo *)paymentInfo
 didFailTokenization:(NSError *)error;


@optional

/**
 *  Optionally called so that an email address can be provided before a transaction is authorized. If this method is implemented, the transaction cannot proceed until the completion block is executed.
 *  Examples:
 *      completion(@"api@wepay.com");
 *      completion(nil);
 *
 *  @param completion The block to be executed with the payer's email address.
 *  @param email      The payer's email address.
 */
- (void) insertPayerEmailWithCompletion:(void (^)(NSString *email))completion;

@end


/** \protocol WPCardReaderDelegate
 *  This delegate protocol has to be adopted by any class that handles Card Reader responses.
 */
@protocol WPCardReaderDelegate <NSObject>
@required
/**
 *  Called when payment info is successfully obtained from a card.
 *
 *  @param paymentInfo The payment info.
 */
- (void) didReadPaymentInfo:(WPPaymentInfo *)paymentInfo;

/**
 *  Called when an error occurs while reading a card.
 *
 *  @param error The error which caused the failure.
 */
- (void) didFailToReadPaymentInfoWithError:(NSError *)error;

@optional
/**
 *  Called when the card reader changes status.
 *
 *  @param status Current status of the card reader, one of:
 *                kWPCardReaderStatusNotConnected;
 *                kWPCardReaderStatusConnected;
 *                kWPCardReaderStatusCheckingReader;
 *                kWPCardReaderStatusConfiguringReader;
 *                kWPCardReaderStatusWaitingForCard;
 *                kWPCardReaderStatusShouldNotSwipeEMVCard;
 *                kWPCardReaderStatusChipErrorSwipeCard;
 *                kWPCardReaderStatusSwipeDetected;
 *                kWPCardReaderStatusCardDipped;
 *                kWPCardReaderStatusTokenizing;
 *                kWPCardReaderStatusAuthorizing;
 *                kWPCardReaderStatusStopped;

 */
- (void) cardReaderDidChangeStatus:(id)status;

/**
 *  Optionally called when the connected card reader is already configured, to give the app an opportunity to reset the device. If this method is implemented, the transaction cannot proceed until the completion block is executed. The card reader must be reset here if the merchant manually resets the reader via the hardware reset button on the reader.
 *  Examples:
 *      completion(YES);
 *      completion(NO);
 *
 *  @param completion  The block to be executed with the answer to the question: "Should the card reader be reset?".
 *  @param shouldReset The answer to the question: "Should the card reader be reset?".
 */
- (void) shouldResetCardReaderWithCompletion:(void (^)(BOOL shouldReset))completion;

/**
 *  Called when an EMV reader is connected, so that you can provide the amount, currency code and the WePay account Id of the merchant. The transaction cannot proceed until the completion block is executed.
 *  Note: In the staging environment, use amounts of 20.61, 120.61, 23.61 and 123.61 to simulate authorization errors. Amounts of 21.61, 121.61, 22.61, 122.61, 24.61, 124.61, 25.61, and 125.61 will simulate successful auth.
 *  Example:
 *      completion([NSDecimalNumber decimalNumberWithString:@"21.61"], kWPCurrencyCodeUSD, 1234567);
 *
 *  @param completion            The block to be executed with the amount, currency code and merchant account Id for the transaction.
 *  @param amount                The amount for the transaction. For USD amounts, there can be a maximum of two places after the decimal point. (amount.decimalValue._exponent must be >= -2)
 *  @param currencyCode          The 3-character ISO 4217 currency code. The only supported currency code is kWPCurrencyCodeUSD.
 *  @param accountId             The WePay account id of the merchant.
 */
- (void) authorizeAmountWithCompletion:(void (^)(NSDecimalNumber *amount, NSString *currencyCode, long accountId))completion;

@end


/** \protocol WPCheckoutDelegate
 *  This delegate protocol has to be adopted by any class that handles Checkout responses.
 */
@protocol WPCheckoutDelegate <NSObject>

/**
 *  Called when a signature is successfully stored for the given checkout id.
 *
 *  @param signatureUrl The url for the signature image.
 *  @param checkoutId   The checkout id associated with the signature.
 */
- (void) didStoreSignature:(NSString *)signatureUrl
             forCheckoutId:(NSString *)checkoutId;

/**
 *  Called when an error occurs while storing a signature.
 *
 *  @param image        The signature image to be stored.
 *  @param checkoutId   The checkout id associated with the signature.
 *  @param error        The error which caused the failure.
 */
- (void) didFailToStoreSignatureImage:(UIImage *)image
                        forCheckoutId:(NSString *)checkoutId
                            withError:(NSError *)error;

@end


/** \protocol WPBatteryLevelDelegate
 *  This delegate protocol has to be adopted by any class that handles Battery Level responses.
 */
@protocol WPBatteryLevelDelegate <NSObject>

/**
 *  Called when the card reader's battery level is determined.
 *
 *  @param batteryLevel The card reader's battery charge level (0-100%).
 */
- (void) didGetBatteryLevel:(int)batteryLevel;

/**
 *  Called when we fail to determine the card reader's battery level.
 *
 *  @param error    The error which caused the failure.
 */
- (void) didFailToGetBatteryLevelwithError:(NSError *)error;

@end


/**
 *  Main Class containing all public endpoints.
 */
@interface WePay : NSObject

/**
 *  Your WePay config
 */
@property (nonatomic, strong, readonly) WPConfig *config;

/** @name Initialization
 */
///@{

/**
 *  The designated intializer. Use this to initialize the SDK.
 *
 *  @param config A \ref WPConfig instance.
 *
 *  @return A \ref WePay instance, which can be used to access most of the functionality of this sdk.
 */
- (instancetype) initWithConfig:(WPConfig *)config;

///@}

#pragma mark -
#pragma mark Tokenization


/** @name Tokenization
 */
///@{

/**
 *  Creates a payment token from a WPPaymentInfo object.
 *
 *  @param paymentInfo          The payment info obtained from the user in any form.
 *  @param tokenizationDelegate The delegate class which will receive the tokenization response(s) for this call.
 */
- (void) tokenizePaymentInfo:(WPPaymentInfo *)paymentInfo
        tokenizationDelegate:(id<WPTokenizationDelegate>)tokenizationDelegate;

///@}


#pragma mark -
#pragma mark Card Reader

/** @name Card Reader related methods
 */
///@{

/**
 *  Initializes the transaction for reading card info.
 *
 *  The card reader will wait 60 seconds for a card, and then return a timout error if a card is not detected.
 *  The card reader will automatically stop waiting for card if:
 *  - a timeout occurs
 *  - a card is successfully detected
 *  - an unexpected error occurs
 *  - stopCardReader is called
 *
 *  However, if a general error (domain:kWPErrorCategoryCardReader, errorCode:WPErrorCardReaderGeneralError) occurs while reading, after a few seconds delay, the card reader will automatically start waiting again for another 60 seconds. At that time, WPCardReaderDelegate's cardReaderDidChangeStatus: method will be called with kWPCardReaderStatusWaitingForCard, and the user can try to use the card reader again. This behavior can be configured with \ref WPConfig.
 *
 *  WARNING: When this method is called, a (normally inaudible) signal is sent to the headphone jack of the phone, where the card reader is expected to be connected. If headphones are connected instead of the card reader, they may emit a very loud audible tone on receiving this signal. This method should only be called when the user intends to use the card reader.
 *
 *  @param cardReaderDelegate   The delegate class which will receive the response(s) for this call.
 */
- (void) startTransactionForReadingWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate;

/**
 *  Initializes the card reader for reading and then automatically tokenizing card info. If an EMV card is dipped into a connected EMV reader, the card will automatically be authorized.
 *
 *  The card reader will wait 60 seconds for a card, and then return a timout error if a card is not detected.
 *  The card reader will automatically stop waiting for card if:
 *  - a timeout occurs
 *  - a card is successfully detected
 *  - an unexpected error occurs
 *  - stopCardReader is called
 *
 *  However, if a general error (domain:kWPErrorCategoryCardReader, errorCode:WPErrorCardReaderGeneralError) occurs while reading, after a few seconds delay, the card reader will automatically start waiting again for another 60 seconds. At that time, WPCardReaderDelegate's cardReaderDidChangeStatus: method will be called with kWPCardReaderStatusWaitingForCard, and the user can try to use the card reader again. This behavior can be configured with \ref WPConfig.
 *
 *  WARNING: When this method is called, a (normally inaudible) signal is sent to the headphone jack of the phone, where the card reader is expected to be connected. If headphones are connected instead of the card reader, they may emit a very loud audible tone on receiving this signal. This method should only be called when the user intends to use the card reader.
 *
 *  @param cardReaderDelegate    The delegate class which will receive the card reader response(s) for this call.
 *  @param tokenizationDelegate  The delegate class which will receive the tokenization response(s) for this call.
 *  @param authorizationDelegate The delegate class which will receive the authorization response(s) for this call.
 */
- (void) startTransactionForTokenizingWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate
                                        tokenizationDelegate:(id<WPTokenizationDelegate>) tokenizationDelegate
                                       authorizationDelegate:(id<WPAuthorizationDelegate>) authorizationDelegate;

/**
 *  Stops the card reader. In response, WPCardReaderDelegate's cardReaderDidChangeStatus: method will be called with kWPCardReaderStatusStopped.
 *  Any tokenization in progress will not be stopped, and its result will be delivered to the WPTokenizationDelegate.
 */
- (void) stopCardReader;

///@}

#pragma mark -
#pragma mark Checkout

/** @name Checkout related methods
 */
///@{

/**
 *  Stores a signature image associated with a checkout id on WePay's servers.
 *  The signature can be retrieved via a server-to-server call that fetches the checkout object.
 *  The aspect ratio (width:height) of the image must be between 1:4 and 4:1.
 *  If needed, the image will internally be scaled to fit inside 256x256 pixels, while maintaining the original aspect ratio.
 *
 *  @param image                The signature image to be stored.
 *  @param checkoutId           The checkout id associated with this transaction.
 *  @param checkoutDelegate     The delegate class which will receive the response(s) for this call.
 */
- (void) storeSignatureImage:(UIImage *)image
               forCheckoutId:(NSString *)checkoutId
            checkoutDelegate:(id<WPCheckoutDelegate>) checkoutDelegate;

///@}

#pragma mark -
#pragma mark Battery Level

/** @name Battery Level related methods
 */
///@{

/**
 *  Gets the current battery level of the card reader.
 *
 *  @param batteryLevelDelegate the delegate class which will receive the battery level response(s) for this call.
 */
- (void) getCardReaderBatteryLevelWithBatteryLevelDelegate:(id<WPBatteryLevelDelegate>) batteryLevelDelegate;

///@}

@end
