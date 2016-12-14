//
//  TestCheckoutDelegate.h
//  WePay
//
//  Created by Jianxin Gao on 8/2/16.
//  Copyright © 2016 WePay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WePay.h"

typedef void(^StoreSignatureSuccessBlock)(void);
typedef void(^StoreSignatureFailureBlock)(void);

@interface TestCheckoutDelegate : NSObject <WPCheckoutDelegate>

@property (nonatomic, assign) BOOL successCallBackInvoked;
@property (nonatomic, assign) BOOL failureCallBackInvoked;
@property (nonatomic, strong) StoreSignatureSuccessBlock storeSignatureSuccessBlock;
@property (nonatomic, strong) StoreSignatureFailureBlock storeSignatureFailureBlock;
@property (nonatomic, strong) NSError *error;

@end
