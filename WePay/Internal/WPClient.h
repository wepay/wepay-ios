//
//  WPClient.h
//  WePay
//
//  Created by Chaitanya Bagaria on 12/15/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WPClient : NSObject

+ (void) setConfig:(WPConfig *)value;



/**
 *  Makes the /credit_card/create api call.
 *
 *  @param params         The request params.
 *  @param successHandler The success handler.
 *  @param errorHandler   The error handler.
 */
+ (void) creditCardCreate:(NSDictionary *) params
             successBlock:(void (^)(NSDictionary * returnData)) successHandler
             errorHandler:(void (^)(NSError * error)) errorHandler;


/**
 *  Makes the /credit_card/create_swipe api call.
 *
 *  @param params         The request params.
 *  @param successHandler The success handler.
 *  @param errorHandler   The error handler.
 */
+ (void) creditCardCreateSwipe:(NSDictionary *) params
                  successBlock:(void (^)(NSDictionary * returnData)) successHandler
                  errorHandler:(void (^)(NSError * error)) errorHandler;

/**
 *  Makes the /checkout/signature/create api call.
 *
 *  @param params         The request params.
 *  @param successHandler The success handler.
 *  @param errorHandler   The error handler.
 */
+ (void) checkoutSignatureCreate:(NSDictionary *) params
                    successBlock:(void (^)(NSDictionary * returnData)) successHandler
                    errorHandler:(void (^)(NSError * error)) errorHandler;


+ (void) makeRequestToEndPoint: (NSURL *) endpoint
                        values: (NSDictionary *) params
                   accessToken: (NSString *) accessToken
                  successBlock: (void (^)(NSDictionary * returnData)) successHandler
                  errorHandler: (void (^)(NSError * error)) errorHandler;

@end
