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

static BOOL sendIPandDeviceId = YES;

+ (id)alloc
{
    [NSException raise:@"CannotInstantiateStaticClass" format:@"WePay is a static class and cannot be instantiated."];
    return nil;
}

# pragma mark Set Settings

/*
 Use production environment. Set application client ID.
 */
+ (void) setProductionClientId:(NSString *) key {
    clientId = key;
    onProduction = YES;
}


/*
 Use production environment. Set application client ID. Specify whether to send user's device id and IP when they make a payment
 */
+ (void) setProductionClientId:(NSString *) key sendIPandDeviceId: (BOOL) sendIPandDeviceIdflag {
    clientId = key;
    onProduction = YES;
    sendIPandDeviceId = sendIPandDeviceIdflag;
}


/*
 Use stage environment. Set application client ID.
 */
+ (void) setStageClientId:(NSString *) key  {
    clientId = key;
    onProduction = NO;
}


/*
 Use stage environment. Set application client ID. Specify whether to send user's device id and IP when they make a payment
 */
+ (void) setStageClientId:(NSString *) key  sendIPandDeviceId: (BOOL) sendIPandDeviceIdflag {
    clientId = key;
    onProduction = NO;
    sendIPandDeviceId = sendIPandDeviceIdflag;
}


# pragma mark Validate Credentials

/*
 Throws an Exception if developer does not set his client id.
 */
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

@end
