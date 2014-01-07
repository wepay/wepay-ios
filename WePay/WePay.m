//
//  WePay.m
//  WePay
//
//  Created by WePay on 10/2/13.
//  Copyright (c) 2013 WePay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WePay.h"


@interface WePay()

@end

@implementation WePay

// Is this on production or stage?
static BOOL onProduction;

// Client id to make API calls.
static NSString * clientId;

// API Version
static NSString * apiVersion;

// Whether to send the user's IP and device id
static BOOL sendIPandDeviceId = YES;

+ (id)alloc
{
    [NSException raise:@"CannotInstantiateStaticClass" format:@"WePay is a static class and cannot be instantiated."];
    return nil;
}

# pragma mark Set Settings


+ (void) setProductionClientId:(NSString *) key {
    clientId = key;
    onProduction = YES;
}


+ (void) setProductionClientId:(NSString *) key apiVersion: (NSString *) aVersion {
    clientId = key;
    onProduction = YES;
    apiVersion = aVersion;
}


+ (void) setProductionClientId:(NSString *) key apiVersion:(NSString *)aVersion sendIPandDeviceId: (BOOL) sendIPandDeviceIdflag {
    clientId = key;
    onProduction = YES;
    apiVersion = aVersion;
    sendIPandDeviceId = sendIPandDeviceIdflag;
}


+ (void) setProductionClientId:(NSString *) key sendIPandDeviceId: (BOOL) sendIPandDeviceIdflag {
    clientId = key;
    onProduction = YES;
    sendIPandDeviceId = sendIPandDeviceIdflag;
}


+ (void) setStageClientId:(NSString *) key  {
    clientId = key;
    onProduction = NO;
}


+ (void) setStageClientId:(NSString *) key  apiVersion: (NSString *) aVersion {
    clientId = key;
    onProduction = NO;
    apiVersion = aVersion;
}


+ (void) setStageClientId:(NSString *) key  apiVersion: (NSString *) aVersion sendIPandDeviceId: (BOOL) sendIPandDeviceIdflag {
    clientId = key;
    onProduction = NO;
    sendIPandDeviceId = sendIPandDeviceIdflag;
    apiVersion = aVersion;
}


+ (void) setStageClientId:(NSString *) key  sendIPandDeviceId: (BOOL) sendIPandDeviceIdflag {
    clientId = key;
    onProduction = NO;
    sendIPandDeviceId = sendIPandDeviceIdflag;
}


# pragma mark Validate Credentials

+ (void) validateCredentials {
    if(clientId == nil || [clientId length] == 0) {
        [NSException raise:@"InvalidCredentials" format:@"Please make sure you add a client ID."];
    }
}


# pragma mark Settings Getters


+ (BOOL) isProduction {
    return onProduction;
}


+ (BOOL) sendDeviceData {
    return sendIPandDeviceId;
}


+ (NSString *) clientId {
    return clientId;
}

+ (NSString *) apiVersion {
    return apiVersion;
}

@end
