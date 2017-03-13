//
//  WePay.m
//  WePay
//
//  Created by Chaitanya Bagaria on 10/30/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#import "WePay.h"

#if defined(__has_include)
#if __has_include("RPx_MFI/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA_MFI/RUA.h")
#import <WePay_CardReaderDirector.h>
#endif

#if __has_include("TrustDefender/TrustDefender.h")
#import "WPRiskHelper.h"
#endif

#endif

#import <WePay_Manual.h>
#import "WePay_Checkout.h"
#import "WPError+internal.h"

// forward-class declaration for optional classes
@class WePay_CardReaderDirector;
@class WPRiskHelper;

// Environments
NSString * const kWPEnvironmentStage = @"stage";
NSString * const kWPEnvironmentProduction = @"production";

// Payment Methods
NSString * const kWPPaymentMethodSwipe = @"Swipe";
NSString * const kWPPaymentMethodManual = @"Manual";
NSString * const kWPPaymentMethodDip = @"Dip";

// Card Reader status
NSString * const kWPCardReaderStatusSearching = @"searching for reader";
NSString * const kWPCardReaderStatusNotConnected = @"card reader not connected";
NSString * const kWPCardReaderStatusConnected = @"card reader connected";
NSString * const kWPCardReaderStatusCheckingReader = @"checking reader";
NSString * const kWPCardReaderStatusConfiguringReader = @"configuring reader";
NSString * const kWPCardReaderStatusWaitingForCard = @"waiting for card";
NSString * const kWPCardReaderStatusShouldNotSwipeEMVCard = @"should not swipe EMV card";
NSString * const kWPCardReaderStatusCheckCardOrientation = @"check card orientation";
NSString * const kWPCardReaderStatusChipErrorSwipeCard = @"chip error, swipe card";
NSString * const kWPCardReaderStatusSwipeErrorSwipeAgain = @"swipe error, swipe again";
NSString * const kWPCardReaderStatusSwipeDetected = @"swipe detected";
NSString * const kWPCardReaderStatusCardDipped = @"card dipped";
NSString * const kWPCardReaderStatusTokenizing = @"tokenizing";
NSString * const kWPCardReaderStatusAuthorizing = @"authorizing";
NSString * const kWPCardReaderStatusStopped = @"stopped";

// Currency Codes
NSString * const kWPCurrencyCodeUSD = @"USD";

@interface WePay () {
    dispatch_queue_t serialQueue;
}

@property(nonatomic, strong) WePay_CardReaderDirector *wePayCardReaderDirector;
@property(nonatomic, strong) WePay_Checkout *wePayCheckout;
@property(nonatomic, strong) WePay_Manual *wePayManual;
@property(nonatomic, strong) WPRiskHelper *riskHelper;

@property(nonatomic, strong, readwrite) WPConfig *config;

@end

@implementation WePay

- (instancetype) initWithConfig:(WPConfig *)config
{
    if (self = [super init]) {
        self.config = config;
        serialQueue = dispatch_queue_create("com.wepay.StartOperation", NULL);
    }
    
    return self;
}


- (void) tokenizePaymentInfo:(WPPaymentInfo *)paymentInfo
        tokenizationDelegate:(id<WPTokenizationDelegate>)tokenizationDelegate
{
    dispatch_async(serialQueue, ^{
        if ([kWPPaymentMethodManual isEqualToString:paymentInfo.paymentMethod]) {
            if (!self.wePayManual) {
                self.wePayManual = [[WePay_Manual alloc] initWithConfig:self.config];
            }
            
            [self.wePayManual tokenizeManualPaymentInfo:paymentInfo
                                   tokenizationDelegate:tokenizationDelegate
                                              sessionId:[self getSessionId]];
        } else {
            NSError *error = [WPError errorPaymentMethodCannotBeTokenized];
            dispatch_queue_t queue = self.config.callDelegateMethodsOnMainThread ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            dispatch_async(queue, ^{
                // If the external delegate is listening for error, send it
                if (tokenizationDelegate && [tokenizationDelegate respondsToSelector:@selector(paymentInfo:didFailTokenization:)]) {
                    [tokenizationDelegate paymentInfo:paymentInfo didFailTokenization:error];
                }
            });
        }
    });
}

#if defined(__has_include)

#if __has_include("RPx_MFI/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA_MFI/RUA.h") 
#pragma mark - Card Reader available

- (void) startTransactionForReadingWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate
{
    dispatch_async(serialQueue, ^{
        if (!self.wePayCardReaderDirector) {
            self.wePayCardReaderDirector = [[WePay_CardReaderDirector alloc] initWithConfig:self.config];
        }

        [self.wePayCardReaderDirector startTransactionForReadingWithCardReaderDelegate:cardReaderDelegate];
    });
}

- (void) startTransactionForTokenizingWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate
                                        tokenizationDelegate:(id<WPTokenizationDelegate>) tokenizationDelegate
                                       authorizationDelegate:(id<WPAuthorizationDelegate>) authorizationDelegate
{
    dispatch_async(serialQueue, ^{
        if (!self.wePayCardReaderDirector) {
            self.wePayCardReaderDirector = [[WePay_CardReaderDirector alloc] initWithConfig:self.config];
        }

        [self.wePayCardReaderDirector startTransactionForTokenizingWithCardReaderDelegate:cardReaderDelegate
                                                                     tokenizationDelegate:tokenizationDelegate
                                                                    authorizationDelegate:authorizationDelegate
                                                                                sessionId:[self getSessionId]];
    });
}

- (void) stopCardReader
{
    dispatch_async(serialQueue, ^{
        [self.wePayCardReaderDirector stopCardReader];
    });
}

- (void) getCardReaderBatteryLevelWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate
                                    batteryLevelDelegate:(id<WPBatteryLevelDelegate>) batteryLevelDelegate
{
    dispatch_async(serialQueue, ^{
        if (!self.wePayCardReaderDirector) {
            self.wePayCardReaderDirector = [[WePay_CardReaderDirector alloc] initWithConfig:self.config];
        }
        
        [self.wePayCardReaderDirector getCardReaderBatteryLevelWithCardReaderDelegate:cardReaderDelegate
                                                                 batteryLevelDelegate:batteryLevelDelegate];
    });
}

- (NSString *) getRememberedCardReader
{
    if (!self.wePayCardReaderDirector) {
        self.wePayCardReaderDirector = [[WePay_CardReaderDirector alloc] initWithConfig:self.config];
    }
    
    return [self.wePayCardReaderDirector getRememberedCardReader];
}

- (void) forgetRememberedCardReader
{
    if (!self.wePayCardReaderDirector) {
        self.wePayCardReaderDirector = [[WePay_CardReaderDirector alloc] initWithConfig:self.config];
    }
    
    [self.wePayCardReaderDirector forgetRememberedCardReader];
}


#else
#pragma mark - Card Reader not available

- (void) startTransactionForReadingWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate
{
    NSLog(@"This functionality is not available");
}

- (void) startTransactionForTokenizingWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate
                                        tokenizationDelegate:(id<WPTokenizationDelegate>) tokenizationDelegate
                                       authorizationDelegate:(id<WPAuthorizationDelegate>) authorizationDelegate
{
    NSLog(@"This functionality is not available");
}

- (void) stopCardReader
{
    NSLog(@"This functionality is not available");
}

- (void) getCardReaderBatteryLevelWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate
                                    batteryLevelDelegate:(id<WPBatteryLevelDelegate>) batteryLevelDelegate
{
    NSLog(@"This functionality is not available");
}

- (NSString *) getRememberedCardReader
{
    NSLog(@"This functionality is not available");
    return nil;
}

- (void) forgetRememberedCardReader
{
    NSLog(@"This functionality is not available");
}


#endif // has_include RUA

#if __has_include("TrustDefender/TrustDefender.h")
#pragma mark - TrustDefender available

- (NSString *) getSessionId
{
    if (!self.riskHelper) {
        self.riskHelper = [[WPRiskHelper alloc] initWithConfig:self.config];
    }
    
    return [self.riskHelper sessionId];
}

#else
#pragma mark - TrustDefenderMobile not available

- (NSString *) getSessionId
{
    return nil;
}

#endif // has_include TrustDefenderMobile
#endif // defined


#pragma mark - Checkout


- (void) storeSignatureImage:(UIImage *)image
               forCheckoutId:(NSString *)checkoutId
            checkoutDelegate:(id<WPCheckoutDelegate>) checkoutDelegate
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (!self.wePayCheckout) {
            self.wePayCheckout = [[WePay_Checkout alloc] initWithConfig:self.config];
        }

        [self.wePayCheckout storeSignatureImage:image
                                  forCheckoutId:checkoutId
                               checkoutDelegate:checkoutDelegate];
    });
}

@end
