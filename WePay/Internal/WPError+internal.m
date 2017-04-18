//
//  WPError+internal.m
//  WePay
//
//  Created by Chaitanya Bagaria on 12/23/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#import "WPError+internal.h"

NSString * const kWPErrorAPIDomain = @"com.wepay.api";
NSString * const kWPErrorSDKDomain = @"com.wepay.sdk";
NSString * const kWPErrorCategoryKey = @"WPErrorCategoryKey";
NSString * const kWPErrorCategoryNone = @"WPErrorCategoryNone";
NSString * const kWPErrorCategoryCardReader = @"WPErrorCategoryCardReader";
NSString * const kWPErrorCategorySDK = @"WPErrorCategorySDK";


@implementation WPError

@end

@implementation WPError (internal)

+ (NSError *) makeErrorWithCode:(NSInteger)errorCode
                           text:(NSString *)errorText
                       category:(NSString *)errorCategory
                         domain:(NSString *)errorDomain
{
    NSDictionary * details = @{
                               NSLocalizedDescriptionKey:errorText,
                               kWPErrorCategoryKey: errorCategory
                            };

    return [NSError errorWithDomain:errorDomain code:errorCode userInfo:details];
}

+ (NSError *) errorWithApiResponseData:(NSDictionary *)data;
{
    NSInteger errorCode;
    NSString *errorText;
    NSString *errorCategory;
    
    // get error code
    if ([data objectForKey: @"error_code"] != (id)[NSNull null]) {
        errorCode = [[data objectForKey: @"error_code"] intValue];
    } else if (data == nil) {
        // This can happen when api calls fail
        errorCode = WPErrorNoDataReturned;
    }  else {
        // This should not happen
        errorCode = WPErrorUnknown;
        
        #ifdef DEBUG
        // Log unknown error only when in debug builds
        WPLog(@"[WPError] unknown api error: %@", data);
        #endif
    }
    
    // get error text
    if ([data objectForKey: @"error_description"] != (id)[NSNull null] &&
        [[data objectForKey: @"error_description"] length]) {
        errorText = [data objectForKey: @"error_description"];
    } else if (data == nil) {
        // This can happen when api calls fail
        errorText = WPNoDataReturnedErrorMessage;
    } else {
        // This should not happen
        errorText = WPUnexpectedErrorMessage;
    }
    
    // get error category
    if ([data objectForKey: @"error"] != (id)[NSNull null] &&
        [[data objectForKey: @"error"] length]) {
        errorCategory = [data objectForKey: @"error"];
    } else {
        // This should not happen, but we handle it gracefully
        errorCategory = kWPErrorCategoryNone;
    }

    return [WPError makeErrorWithCode:errorCode
                                 text:errorText
                             category:errorCategory
                               domain:kWPErrorAPIDomain];
}

+ (NSError *) errorWithCardReaderResponseData:(NSDictionary *)data;
{
    NSInteger errorCode;
    NSString *errorText;
    NSString *errorCategory = kWPErrorCategoryCardReader;
    
    // get error code
    if ([data objectForKey: @"ErrorCode"] != (id)[NSNull null]) {
        if ([[data objectForKey: @"ErrorCode"] isEqualToString:@"CardReaderGeneralError"]) {
            errorCode = WPErrorCardReaderGeneralError;
        }  else {
            errorCode = WPErrorUnknown;
            
            #ifdef DEBUG
            // Log unknown error only when in debug builds
            WPLog(@"[WPError] unknown card reader error: %@", data);
            #endif
            
        }
    } else {
        // This should not happen
        errorCode = WPErrorUnknown;
    }
    
    // get error text
    if (errorCode == WPErrorCardReaderGeneralError) {
        errorText = WPCardReaderGeneralErrorMessage;
    } else {
        // This should not happen
        errorText = WPUnexpectedErrorMessage;
    }

    return [WPError makeErrorWithCode:errorCode
                                 text:errorText
                             category:errorCategory
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorInitializingCardReader
{
    NSString *errorText = WPCardReaderInitializationErrorMessage;
    return [WPError makeErrorWithCode:WPErrorCardReaderInitialization
                                 text:errorText
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorForCardReaderTimeout
{
    NSString *errorText = WPCardReaderTimeoutErrorMessage;
    return [WPError makeErrorWithCode:WPErrorCardReaderTimeout
                                 text:errorText
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorForCardReaderStatusErrorWithMessage:(NSString *)message
{
    #ifdef DEBUG
    // Log status error only when in debug builds
    WPLog(@"[WPError] card reader status error: %@", message);
    #endif
    
    return [WPError makeErrorWithCode:WPErrorCardReaderStatusError
                                 text:message
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorInvalidSignatureImage
{
    NSString *errorText = WPSignatureInvalidImageErrorMessage;
    return [WPError makeErrorWithCode:WPErrorInvalidSignatureImage
                                 text:errorText
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorNameNotFound
{
    NSString *errorText = WPNameNotFoundErrorMessage;
    return [WPError makeErrorWithCode:WPErrorNameNotFound
                                 text:errorText
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorInvalidCardData
{
    NSString *errorText = WPInvalidCardDataErrorMessage;
    return [WPError makeErrorWithCode:WPErrorInvalidCardData
                                 text:errorText
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorCardNotSupported
{
    NSString *errorText = WPCardNotSupportedErrorMessage;
    return [WPError makeErrorWithCode:WPErrorCardNotSupported
                                 text:errorText
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorForEMVTransactionErrorWithMessage:(NSString *)message
{
    #ifdef DEBUG
    // Log status error only when in debug builds
    WPLog(@"[WPError] card reader emv transaction error: %@", message);
    #endif

    return [WPError makeErrorWithCode:WPErrorEMVTransactionError
                                 text:message
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorInvalidApplicationId
{
    NSString *errorText = WPInvalidApplicationIdErrorMessage;
    return [WPError makeErrorWithCode:WPErrorInvalidApplicationId
                                 text:errorText
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorDeclinedByCard
{
    NSString *errorText = WPDeclinedByCardErrorMessage;
    return [WPError makeErrorWithCode:WPErrorDeclinedByCard
                                 text:errorText
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorCardBlocked
{
    NSString *errorText = WPCardBlockedErrorMessage;
    return [WPError makeErrorWithCode:WPErrorCardBlocked
                                 text:errorText
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorDeclinedByIssuer
{
    NSString *errorText = WPDeclinedByIssuerErrorMessage;
    return [WPError makeErrorWithCode:WPErrorDeclinedByIssuer
                                 text:errorText
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorIssuerUnreachable
{
    NSString *errorText = WPIssuerUnreachableErrorMessage;
    return [WPError makeErrorWithCode:WPErrorIssuerUnreachable
                                 text:errorText
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorInvalidAuthInfo
{
    NSString *errorText = WPInvalidAuthInfoErrorMessage;
    return [WPError makeErrorWithCode:WPErrorInvalidAuthInfo
                                 text:errorText
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorAuthInfoNotProvided
{
    NSString *errorText = WPAuthInfoNotProvidedErrorMessage;
    return [WPError makeErrorWithCode:WPErrorAuthInfoNotProvided
                                 text:errorText
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorPaymentMethodCannotBeTokenized
{
    NSString *errorText = WPPaymentMethodCannotBeTokenizedErrorMessage;
    return [WPError makeErrorWithCode:WPErrorPaymentMethodCannotBeTokenized
                                 text:errorText
                             category:kWPErrorCategorySDK
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorFailedToGetBatteryLevel
{
    NSString *errorText = WPFailedToGetBatteryLevelErrorMessage;
    return [WPError makeErrorWithCode:WPErrorFailedToGetBatteryLevel
                                 text:errorText
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorCardReaderNotConnected
{
    NSString *errorText = WPCardReaderNotConnectedErrorMessage;
    return [WPError makeErrorWithCode:WPErrorCardReaderNotConnected
                                 text:errorText
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorCardReaderUnknownError
{
    NSString *errorText = WPUnexpectedErrorMessage;
    return [WPError makeErrorWithCode:WPErrorUnknown
                                 text:errorText
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorCardReaderModelNotSupported
{
    NSString *errorText = WPCardReaderModelNotSupportedErrorMessage;
    return [WPError makeErrorWithCode:WPErrorCardReaderModelNotSupported
                                 text:errorText
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorInvalidTransactionAmount
{
    NSString *errorText = WPErrorInvalidTransactionAmountErrorMessage;
    return [WPError makeErrorWithCode:WPErrorInvalidTransactionAmount
                                 text:errorText
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorInvalidTransactionCurrencyCode
{
    NSString *errorText = WPErrorInvalidTransactionCurrencyCodeErrorMessage;
    return [WPError makeErrorWithCode:WPErrorInvalidTransactionCurrencyCode
                                 text:errorText
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorInvalidTransactionAccountID
{
    NSString *errorText = WPErrorInvalidTransactionAccountIDErrorMessage
    return [WPError makeErrorWithCode:WPErrorInvalidTransactionAccountID
                                 text:errorText
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorCardReaderBatteryTooLow
{
    NSString *errorText = WPErrorCardReaderBatteryTooLowErrorMessage;
    return [WPError makeErrorWithCode:WPErrorCardReaderBatteryTooLow
                                 text:errorText
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorInvalidCardReaderSelection
{
    NSString *errorText = WPErrorInvalidCardReaderSelectionErrorMessage;
    return [WPError makeErrorWithCode:WPErrorInvalidCardReaderSelection
                                 text:errorText
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}

+ (NSError *) errorCardReaderUnableToConnect
{
    NSString *errorText = WPErrorCardReaderUnableToConnectErrorMessage
    return [WPError makeErrorWithCode:WPErrorCardReaderUnableToConnect
                                 text:errorText
                             category:kWPErrorCategoryCardReader
                               domain:kWPErrorSDKDomain];
}


@end
