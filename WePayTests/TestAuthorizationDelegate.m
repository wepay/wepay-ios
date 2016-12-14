//
//  TestAuthorizationDelegate.m
//  WePay
//
//  Created by Jianxin Gao on 8/1/16.
//  Copyright © 2016 WePay. All rights reserved.
//

#import "TestAuthorizationDelegate.h"

@implementation TestAuthorizationDelegate

- (void) selectEMVApplication:(NSArray *)applications
                   completion:(void (^)(NSInteger selectedIndex))completion
{
    self.selectEMVApplicationInvoked = YES;
    
    if (self.mockEMVApplicationSelectionError) {
        completion(-1);
    } else {
        completion(applications.count - 1);
    }
}

- (void) paymentInfo:(WPPaymentInfo *)paymentInfo
        didAuthorize:(WPAuthorizationInfo *)authorizationInfo
{
    self.paymentInfo = paymentInfo;
    self.authorizationInfo = authorizationInfo;
    self.successCallBackInvoked = YES;
    
    if (self.authorizationSuccessBlock != nil) {
        self.authorizationSuccessBlock();
    }
}

- (void) paymentInfo:(WPPaymentInfo *)paymentInfo
didFailAuthorization:(NSError *)error
{
    self.error = error;
    self.failureCallBackInvoked = YES;
    
    if (self.authorizationFailureBlock != nil) {
        self.authorizationFailureBlock();
    }
}

@end
