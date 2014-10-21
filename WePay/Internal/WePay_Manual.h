//
//  WePay_Manual.h
//  WePay
//
//  Created by Chaitanya Bagaria on 12/15/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WPConfig;
@class WPPaymentInfo;
@protocol WPTokenizationDelegate;

@interface WePay_Manual : NSObject

- (instancetype) initWithConfig:(WPConfig *)config;

- (void) tokenizeManualPaymentInfo:(WPPaymentInfo *)paymentInfo
              tokenizationDelegate:(id<WPTokenizationDelegate>)tokenizationDelegate
                        sessionId:(NSString *)sessionId;


@end
