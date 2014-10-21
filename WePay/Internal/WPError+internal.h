//
//  WPError+internal.h
//  WePay
//
//  Created by Chaitanya Bagaria on 12/23/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#import "WPError.h"


@interface WPError : NSError

@end


@interface WPError (internal)

/**
 *  Converts API Call Error into an NSError object.
 *
 *  @param data WePay API json response.
 *
 *  @return NSError object representing the error.
 */

+ (NSError *) errorWithApiResponseData:(NSDictionary *)data;

/**
 *  Converts card reader Error data into an NSError object.
 *
 *  @param data card reader response.
 *
 *  @return NSError object representing the error.
 */
+ (NSError *) errorWithCardReaderResponseData:(NSDictionary *)data;

/**
 *  Creates an NSError object representing card reader initialization failure.
 *
 *  @return NSError object representing the error.
 */
+ (NSError *) errorInitializingCardReader;

/**
 *  Creates an NSError object representing card reader timeout.
 *
 *  @return NSError object representing the error.
 */
+ (NSError *) errorForCardReaderTimeout;

/**
 *  Creates an NSError object representing card reader status = error
 *
 *  @param message Error message from card reader.
 *
 *  @return NSError object representing the error.
 */
+ (NSError *) errorForCardReaderStatusErrorWithMessage:(NSString *)message;

/**
 *  Creates an NSError object representing invalid signature image error.
 *
 *  @return object representing the error.
 */
+ (NSError *) errorInvalidSignatureImage;

/**
 *  Creates an NSError object representing name not found error.
 *
 *  @return object representing the error.
 */
+ (NSError *) errorCardReaderNameNotFound;


@end
