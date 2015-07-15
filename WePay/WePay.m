//
//  WePay.m
//  WePay
//
//  Created by Chaitanya Bagaria on 10/30/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#import "WePay.h"

#if defined(__has_include)
#if __has_include("RPx/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA/RUA.h") && __has_include("G4XSwiper/SwiperController.h")
#import <WePay_CardReader.h>
#endif
#endif

#import <WePay_Manual.h>
#import "WePay_Checkout.h"
#import "WPRiskHelper.h"


// Environments
NSString * const kWPEnvironmentStage = @"stage";
NSString * const kWPEnvironmentProduction = @"production";

// Payment Methods
NSString * const kWPPaymentMethodSwipe = @"Swipe";
NSString * const kWPPaymentMethodManual = @"Manual";

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
    if ([kWPPaymentMethodManual isEqualToString:paymentInfo.paymentMethod]) {
        if (!self.wePayManual) {
            self.wePayManual = [[WePay_Manual alloc] initWithConfig:self.config];
        }
        
        [self.wePayManual tokenizeManualPaymentInfo:paymentInfo
                               tokenizationDelegate:tokenizationDelegate
                                          sessionId:[self getSessionId]];
    } else if ([kWPPaymentMethodSwipe isEqualToString:paymentInfo.paymentMethod]) {
        if (!self.wePayCardReader) {
            self.wePayCardReader = [[WePay_CardReader alloc] initWithConfig:self.config];
        }
        
        [self.wePayCardReader tokenizeSwipedPaymentInfo:paymentInfo
                               tokenizationDelegate:tokenizationDelegate
                                          sessionId:[self getSessionId]];
    }
}


#pragma mark -
#pragma mark Card Reader - Swipe

#if defined(__has_include)
#if __has_include("RPx/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA/RUA.h") && __has_include("G4XSwiper/SwiperController.h")

- (void) startCardReaderForReadingWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate
{
    if (!self.wePayCardReader) {
        self.wePayCardReader = [[WePay_CardReader alloc] initWithConfig:self.config];
    }
    
    [self.wePayCardReader startCardReaderForReadingWithCardReaderDelegate:cardReaderDelegate];
}

- (void) startCardReaderForTokenizingWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate
                                       tokenizationDelegate:(id<WPTokenizationDelegate>) tokenizationDelegate
{
    if (!self.wePayCardReader) {
        self.wePayCardReader = [[WePay_CardReader alloc] initWithConfig:self.config];
    }
    
    [self.wePayCardReader startCardReaderForTokenizingWithCardReaderDelegate:cardReaderDelegate
                                                    tokenizationDelegate:tokenizationDelegate
                                                               sessionId:[self getSessionId]];
}

- (void) stopCardReader
{
    [self.wePayCardReader stopCardReader];
}

#endif // has_include
#endif // defined


#pragma mark -
#pragma mark Checkout


- (void) storeSignatureImage:(UIImage *)image
               forCheckoutId:(NSString *)checkoutId
            checkoutDelegate:(id<WPCheckoutDelegate>) checkoutDelegate
{
    if (!self.wePayCheckout) {
        self.wePayCheckout = [[WePay_Checkout alloc] initWithConfig:self.config];
    }
    
    [self.wePayCheckout storeSignatureImage:image
                            forCheckoutId:checkoutId
                         checkoutDelegate:checkoutDelegate];
}


#pragma mark -
#pragma mark Helpers

- (NSString *) getSessionId
{
    if (!self.riskHelper) {
        self.riskHelper = [[WPRiskHelper alloc] initWithConfig:self.config];
    }
    
    return [self.riskHelper sessionId];
}


@end
