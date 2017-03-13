//
//  TestAuthorizationDelegate.h
//  WePay
//
//  Created by Jianxin Gao on 8/1/16.
//  Copyright © 2016 WePay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WePay.h"

typedef void(^AuthorizationSuccessBlock)(void);
typedef void(^AuthorizationFailureBlock)(void);

@interface TestAuthorizationDelegate : NSObject <WPAuthorizationDelegate>

@property (nonatomic, assign) BOOL successCallBackInvoked;
@property (nonatomic, assign) BOOL failureCallBackInvoked;
@property (nonatomic, strong) AuthorizationSuccessBlock authorizationSuccessBlock;
@property (nonatomic, strong) AuthorizationFailureBlock authorizationFailureBlock;
@property (nonatomic, strong) WPAuthorizationInfo *authorizationInfo;
@property (nonatomic, strong) WPPaymentInfo *paymentInfo;
@property (nonatomic, strong) NSError *error;

@end
