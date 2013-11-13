//
//  WePay.h
//  WePay
//
//  Created by WePay on 10/2/13.
//  Copyright (c) 2013 WePay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WePay : NSObject

/*
 Set Stage client id.
 */
+ (void) setStageClientId:(NSString *) key;

/*
 Set Production client id.
 */
+ (void) setProductionClientId:(NSString *) key;

/*
 Set stage client Id and specify whether to collect user's ip and device id.
 WePay uses the user's IP and device id to help prevent fraud.
 */
+ (void) setStageClientId:(NSString *) key  sendIPandDeviceId: (BOOL) sendIPandDeviceIdflag;

/*
 Set Production client Id and specify whether to collect user's ip and device id.
 */
+ (void) setProductionClientId:(NSString *) key sendIPandDeviceId: (BOOL) sendIPandDeviceIdflag;

/*
 Is client id set or throw error?
 */
+ (void) validateCredentials;

/*
 Static method other classes call to check if API calls should be made on Production.
 */
+ (BOOL) isProduction;

/*
 Static method other classes call to get client id.
 */
+ (NSString *) clientId;

/*
 Whether to send the user's IP and device id
 */
+ (BOOL) sendDeviceData;

@end
