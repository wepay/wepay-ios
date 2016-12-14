//
//  TestTokenizationDelegate.h
//  WePay
//
//  Created by Jianxin Gao on 7/27/16.
//  Copyright © 2016 WePay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WePay.h"

typedef void(^TokenizationSuccessBlock)(void);
typedef void(^TokenizationFailureBlock)(void);

@interface TestTokenizationDelegate : NSObject <WPTokenizationDelegate>

@property (nonatomic, assign) BOOL successCallBackInvoked;
@property (nonatomic, assign) BOOL failureCallBackInvoked;
@property (nonatomic, strong) TokenizationSuccessBlock tokenizationSuccessBlock;
@property (nonatomic, strong) TokenizationFailureBlock tokenizationFailureBlock;
@property (nonatomic, strong) WPPaymentInfo *paymentInfo;
@property (nonatomic, strong) WPPaymentToken *paymentToken;
@property (nonatomic, strong) NSError *error;

@end
