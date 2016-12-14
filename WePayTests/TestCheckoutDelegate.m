//
//  TestCheckoutDelegate.m
//  WePay
//
//  Created by Jianxin Gao on 8/2/16.
//  Copyright © 2016 WePay. All rights reserved.
//

#import "TestCheckoutDelegate.h"

@implementation TestCheckoutDelegate

- (void) didStoreSignature:(NSString *)signatureUrl
             forCheckoutId:(NSString *)checkoutId
{
    self.successCallBackInvoked = YES;
    
    if (self.storeSignatureSuccessBlock != nil) {
        self.storeSignatureSuccessBlock();
    }
}

- (void) didFailToStoreSignatureImage:(UIImage *)image
                        forCheckoutId:(NSString *)checkoutId
                            withError:(NSError *)error
{
    self.failureCallBackInvoked = YES;
    self.error = error;
    
    if (self.storeSignatureFailureBlock != nil) {
        self.storeSignatureFailureBlock();
    }
}

@end
