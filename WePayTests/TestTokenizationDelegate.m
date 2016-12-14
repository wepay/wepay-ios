//
//  TestTokenizationDelegate.m
//  WePay
//
//  Created by Jianxin Gao on 7/27/16.
//  Copyright © 2016 WePay. All rights reserved.
//

#import "TestTokenizationDelegate.h"
#import "WePay.h"

@implementation TestTokenizationDelegate

- (void) paymentInfo:(WPPaymentInfo *)paymentInfo
         didTokenize:(WPPaymentToken *)paymentToken
{
    self.paymentInfo = paymentInfo;
    self.paymentToken = paymentToken;
    self.successCallBackInvoked = YES;
    
    if (self.tokenizationSuccessBlock != nil) {
        self.tokenizationSuccessBlock();
    }
}

- (void) paymentInfo:(WPPaymentInfo *)paymentInfo
 didFailTokenization:(NSError *)error
{
    self.error = error;
    self.failureCallBackInvoked = YES;
    
    if (self.tokenizationFailureBlock != nil) {
        self.tokenizationFailureBlock();
    }
}

- (void) insertPayerEmailWithCompletion:(void (^)(NSString *email))completion
{
    completion(@"a@b.com");
}

@end
