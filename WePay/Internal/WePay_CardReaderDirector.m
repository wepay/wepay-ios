//
//  WePay_CardReaderDirector.m
//  WePay
//
//  Created by Chaitanya Bagaria on 11/17/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RPx_MFI/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA_MFI/RUA.h")

#import "WePay_CardReaderDirector.h"
#import "WePay.h"
#import "WPConfig.h"
#import "WPClient.h"
#import "WPIngenicoCardReaderManager.h"
#import "WPError+internal.h"
#import "WPRoamHelper.h"
#import "WPExternalCardReaderHelper.h"
#import "WPClientHelper.h"
#import "WPBatteryHelper.h"
#import "WPUserDefaultsHelper.h"

@interface WePay_CardReaderDirector ()

@property (nonatomic, strong) WPConfig *config;
@property (nonatomic, strong) NSString *sessionId;

@property (nonatomic, strong) id<WPCardReaderManager> cardReaderManager;
@property (nonatomic, strong) id<WPExternalCardReaderDelegate> externalHelper;
@property (nonatomic, assign) CardReaderRequest cardReaderRequest;

@end

@implementation WePay_CardReaderDirector

- (instancetype) initWithConfig:(WPConfig *)config
{
    if (self = [super init]) {
        // pass the config to the client
        WPClient.config = config;
        
        // save the config
        self.config = config;

        // create the external helper
        self.externalHelper = [[WPExternalCardReaderHelper alloc] initWithConfig:self.config];
        
        // configure RUA
        #ifdef DEBUG
            // Log response only when in debug builds
            [RUA enableDebugLogMessages:YES];
        #else
            [RUA enableDebugLogMessages:NO];
        #endif
    }
    
    return self;
}

- (void) initializeCardReaderManager
{
    self.cardReaderManager = [[WPIngenicoCardReaderManager alloc] initWithConfig:self.config
                                            externalCardReaderDelegate:self.externalHelper];
    [self.cardReaderManager setCardReaderRequest:self.cardReaderRequest];
    [self.cardReaderManager startCardReader];
}

- (void) startTransactionForReadingWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate
{
    self.externalHelper.externalTokenizationDelegate = nil;
    self.externalHelper.externalCardReaderDelegate = cardReaderDelegate;
    self.sessionId = nil;
    self.cardReaderRequest = CardReaderForReading;
    
    if ([self isCardReaderConnected] || [self isCardReaderSearching]) {
        [self.cardReaderManager setCardReaderRequest:self.cardReaderRequest];
        [self.cardReaderManager processCardReaderRequest];
    }
    else {
        [self initializeCardReaderManager];
    }
}

- (void) startTransactionForTokenizingWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate
                                        tokenizationDelegate:(id<WPTokenizationDelegate>) tokenizationDelegate
                                       authorizationDelegate:(id<WPAuthorizationDelegate>) authorizationDelegate
                                                   sessionId:(NSString *)sessionId
{
    self.externalHelper.externalCardReaderDelegate = cardReaderDelegate;
    self.externalHelper.externalTokenizationDelegate = tokenizationDelegate;
    self.externalHelper.externalAuthorizationDelegate = authorizationDelegate;
    self.sessionId = sessionId;
    self.cardReaderRequest = CardReaderForTokenizing;

    
    if ([self isCardReaderConnected] || [self isCardReaderSearching]) {
        [self.cardReaderManager setCardReaderRequest:self.cardReaderRequest];
        [self.cardReaderManager processCardReaderRequest];
    }
    else {
        [self initializeCardReaderManager];
    }
}

- (BOOL) isCardReaderConnected {
    return self.cardReaderManager != nil && [self.cardReaderManager isConnected];
}

- (BOOL) isCardReaderSearching {
    return self.cardReaderManager != nil && [self.cardReaderManager isSearching];
}

/**
 *  Stops the Roam card reader completely, and informs the delegate.
 */
- (void) stopCardReader
{
    if (![self isCardReaderConnected] && ![self isCardReaderSearching]) {
        [self.externalHelper informExternalCardReader:kWPCardReaderStatusStopped];
    } else {
        [self.cardReaderManager stopCardReader];
    }
}


- (void) getCardReaderBatteryLevelWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate
                                    batteryLevelDelegate:(id<WPBatteryLevelDelegate>) batteryLevelDelegate
{
    self.externalHelper.externalCardReaderDelegate = cardReaderDelegate;
    self.externalHelper.externalBatteryLevelDelegate = batteryLevelDelegate;
    self.cardReaderRequest = CardReaderForBatteryLevel;
    
    if ([self isCardReaderConnected] || [self isCardReaderSearching]) {
        [self.cardReaderManager setCardReaderRequest:self.cardReaderRequest];
        [self.cardReaderManager processCardReaderRequest];
    } else {
        [self initializeCardReaderManager];
    }
}

- (NSString *) getRememberedCardReader
{
    NSString *rememberedCardReader = [WPUserDefaultsHelper getRememberedCardReader];
    
    return rememberedCardReader;
}

- (void) forgetRememberedCardReader
{
    [WPUserDefaultsHelper forgetRememberedCardReader];
}


@end

#endif
#endif

