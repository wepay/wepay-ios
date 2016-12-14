//
//  WePay.m
//  WePay
//
//  Created by Chaitanya Bagaria on 10/30/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#import "WePay.h"

#if defined(__has_include)
#if __has_include("RPx/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA/RUA.h") 
#import <WePay_CardReader.h>
#endif

#if __has_include("TrustDefenderMobile/TrustDefenderMobile.h")
#import "WPRiskHelper.h"
#endif

#endif

#import <WePay_Manual.h>
#import "WePay_Checkout.h"
#import "WPError+internal.h"

// forward-class declaration for optional classes
@class WePay_CardReader;
@class WPRiskHelper;

// Environments
NSString * const kWPEnvironmentStage = @"stage";
NSString * const kWPEnvironmentProduction = @"production";

// Payment Methods
NSString * const kWPPaymentMethodSwipe = @"Swipe";
NSString * const kWPPaymentMethodManual = @"Manual";
NSString * const kWPPaymentMethodDip = @"Dip";

// Card Reader status
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

@interface WePay ()

@property(nonatomic, strong) WePay_CardReader *wePayCardReader;
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
    }
    
    return self;
}


- (void) tokenizePaymentInfo:(WPPaymentInfo *)paymentInfo
        tokenizationDelegate:(id<WPTokenizationDelegate>)tokenizationDelegate
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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

#if __has_include("RPx/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA/RUA.h") 
#pragma mark - Card Reader available

- (void) startTransactionForReadingWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (!self.wePayCardReader) {
            self.wePayCardReader = [[WePay_CardReader alloc] initWithConfig:self.config];
        }

        [self.wePayCardReader startTransactionForReadingWithCardReaderDelegate:cardReaderDelegate];
    });
}

- (void) startTransactionForTokenizingWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate
                                        tokenizationDelegate:(id<WPTokenizationDelegate>) tokenizationDelegate
                                       authorizationDelegate:(id<WPAuthorizationDelegate>) authorizationDelegate
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (!self.wePayCardReader) {
            self.wePayCardReader = [[WePay_CardReader alloc] initWithConfig:self.config];
        }

        [self.wePayCardReader startTransactionForTokenizingWithCardReaderDelegate:cardReaderDelegate
                                                             tokenizationDelegate:tokenizationDelegate
                                                            authorizationDelegate:authorizationDelegate
                                                                        sessionId:[self getSessionId]];
    });
}

- (void) stopCardReader
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.wePayCardReader stopCardReader];
    });
}

- (void) getCardReaderBatteryLevelWithBatteryLevelDelegate:(id<WPBatteryLevelDelegate>) batteryLevelDelegate
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (!self.wePayCardReader) {
            self.wePayCardReader = [[WePay_CardReader alloc] initWithConfig:self.config];
        }
        
        [self.wePayCardReader getCardReaderBatteryLevelWithBatteryLevelDelegate:batteryLevelDelegate];
    });
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

- (void) getCardReaderBatteryLevelWithBatteryLevelDelegate:(id<WPBatteryLevelDelegate>) batteryLevelDelegate
{
    NSLog(@"This functionality is not available");
}


#endif // has_include RUA

#if __has_include("TrustDefenderMobile/TrustDefenderMobile.h")
#pragma mark - TrustDefenderMobile available

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
