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


@implementation WPError

@end

@implementation WPError (internal)

+ (NSError *) errorWithApiResponseData:(NSDictionary *)data;
{
    NSInteger errorCode;
    NSString * errorText;
    NSString * errorCategory;
    
    // get error code
    if ([data objectForKey: @"error_code"] != (id)[NSNull null]) {
        errorCode = [[data objectForKey: @"error_code"] intValue];
    } else if (data == nil) {
        // This should not happen, but we handle it gracefully
        errorCode = WPErrorNoDataReturned;
    }  else {
        // This should not happen
        errorCode = WPErrorUnknown;
        
        #ifdef DEBUG
        // Log unknown error only when in debug builds
        NSLog(@"[WPError] unknown api error: %@", data);
        #endif
    }
    
    // get error text
    if ([data objectForKey: @"error_description"] != (id)[NSNull null] &&
        [[data objectForKey: @"error_description"] length]) {
        errorText = [data objectForKey: @"error_description"];
    } else if (data == nil) {
        // This should not happen, but we handle it gracefully
        errorText = WPNoDataReturnedErrorMessage;
    } else {
        // This should really not happen
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
    
    NSMutableDictionary * details = [NSMutableDictionary dictionary];
    [details setValue: errorText forKey: NSLocalizedDescriptionKey];
    [details setValue: errorCategory forKey: kWPErrorCategoryKey];
    
    return [NSError errorWithDomain:kWPErrorAPIDomain code:errorCode userInfo:details];
}

+ (NSError *) errorWithCardReaderResponseData:(NSDictionary *)data;
{
    NSInteger errorCode;
    NSString * errorText;
    NSString * errorCategory = kWPErrorCategoryCardReader;
    
    // get error code
    if ([data objectForKey: @"ErrorCode"] != (id)[NSNull null]) {
        if ([[data objectForKey: @"ErrorCode"] isEqualToString:@"CardReaderGeneralError"]) {
            errorCode = WPErrorCardReaderGeneralError;
        }  else {
            errorCode = WPErrorUnknown;
            
            #ifdef DEBUG
            // Log unknown error only when in debug builds
            NSLog(@"[WPError] unknown card reader error: %@", data);
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
    
    NSMutableDictionary * details = [NSMutableDictionary dictionary];
    [details setValue: errorText forKey: NSLocalizedDescriptionKey];
    [details setValue: errorCategory forKey: kWPErrorCategoryKey];
    
    return [NSError errorWithDomain:kWPErrorSDKDomain code:errorCode userInfo:details];
}

+ (NSError *) errorInitializingCardReader
{
    NSInteger errorCode = WPErrorCardReaderInitialization;
    NSString * errorText = WPCardReaderInitializationErrorMessage;
    NSString * errorCategory = kWPErrorCategoryCardReader;
    
    NSMutableDictionary * details = [NSMutableDictionary dictionary];
    [details setValue: errorText forKey: NSLocalizedDescriptionKey];
    [details setValue: errorCategory forKey: kWPErrorCategoryKey];
    
    return [NSError errorWithDomain:kWPErrorSDKDomain code:errorCode userInfo:details];
}

+ (NSError *) errorForCardReaderTimeout
{
    NSInteger errorCode = WPErrorCardReaderTimeout;
    NSString * errorText = WPCardReaderTimeoutErrorMessage;
    NSString * errorCategory = kWPErrorCategoryCardReader;
    
    NSMutableDictionary * details = [NSMutableDictionary dictionary];
    [details setValue: errorText forKey: NSLocalizedDescriptionKey];
    [details setValue: errorCategory forKey: kWPErrorCategoryKey];
    
    return [NSError errorWithDomain:kWPErrorSDKDomain code:errorCode userInfo:details];
}

+ (NSError *) errorForCardReaderStatusErrorWithMessage:(NSString *)message
{
    #ifdef DEBUG
    // Log status error only when in debug builds
    NSLog(@"[WPError] card reader status error: %@", message);
    #endif
    
    NSInteger errorCode = WPErrorCardReaderStatusError;
    NSString * errorText = message;
    NSString * errorCategory = kWPErrorCategoryCardReader;
    
    NSMutableDictionary * details = [NSMutableDictionary dictionary];
    [details setValue: errorText forKey: NSLocalizedDescriptionKey];
    [details setValue: errorCategory forKey: kWPErrorCategoryKey];
    
    return [NSError errorWithDomain:kWPErrorSDKDomain code:errorCode userInfo:details];
}

+ (NSError *) errorInvalidSignatureImage
{
    NSInteger errorCode = WPErrorInvalidSignatureImage;
    NSString * errorText = WPSignatureInvalidImageErrorMessage;
    NSString * errorCategory = kWPErrorCategoryCardReader;

    NSMutableDictionary * details = [NSMutableDictionary dictionary];
    [details setValue: errorText forKey: NSLocalizedDescriptionKey];
    [details setValue: errorCategory forKey: kWPErrorCategoryKey];

    return [NSError errorWithDomain:kWPErrorSDKDomain code:errorCode userInfo:details];
}

+ (NSError *) errorCardReaderNameNotFound
{
    NSInteger errorCode = WPErrorNameNotFound;
    NSString * errorText = WPNameNotFoundErrorMessage;
    NSString * errorCategory = kWPErrorCategoryCardReader;

    NSMutableDictionary * details = [NSMutableDictionary dictionary];
    [details setValue: errorText forKey: NSLocalizedDescriptionKey];
    [details setValue: errorCategory forKey: kWPErrorCategoryKey];

    return [NSError errorWithDomain:kWPErrorSDKDomain code:errorCode userInfo:details];
}


@end
