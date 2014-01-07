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
 Set Production client id.
 */
+ (void) setProductionClientId:(NSString *) key;

/*
 Set production environment with client id and api version.
 */
+ (void) setProductionClientId:(NSString *) key apiVersion: (NSString *) aVersion;

/*
 Set production environment with client id, api version, and whether to collect user's ip and device id.
 */
+ (void) setProductionClientId:(NSString *) key apiVersion:(NSString *)aVersion sendIPandDeviceId: (BOOL) sendIPandDeviceIdflag;

/*
 Set production environment with client id and whether to collect user's ip and device id.
 */
+ (void) setProductionClientId:(NSString *) key sendIPandDeviceId: (BOOL) sendIPandDeviceIdflag;

/*
 Set Stage environment with client id.
 */
+ (void) setStageClientId:(NSString *) key;

/*
 Set stage environment with client id and whether to collect user's ip and device id.
 */
+ (void) setStageClientId:(NSString *) key  sendIPandDeviceId: (BOOL) sendIPandDeviceIdflag;

/*
 Set stage environment with client id and api version.
 */
+ (void) setStageClientId:(NSString *) key  apiVersion: (NSString *) aVersion;

/*
 Set stage environment with client id, api version, and whether to collect user's ip and device id.
 */
+ (void) setStageClientId:(NSString *) key  apiVersion: (NSString *) aVersion sendIPandDeviceId: (BOOL) sendIPandDeviceIdflag;

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

/*
 Api Version.
 Please see https://www.wepay.com/developer/reference/versioning
 */
+ (NSString *) apiVersion;

@end
