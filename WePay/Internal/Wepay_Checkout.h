//
//  Wepay_Checkout.h
//  WePay
//
//  Created by Chaitanya Bagaria on 7/1/15.
//  Copyright (c) 2015 WePay. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WPConfig;
@protocol WPCheckoutDelegate;

@interface WePay_Checkout : NSObject

- (instancetype) initWithConfig:(WPConfig *)config;

- (void) storeSignatureImage:(UIImage *)image
               forCheckoutId:(NSString *)checkoutId
            checkoutDelegate:(id<WPCheckoutDelegate>) checkoutDelegate;

@end
