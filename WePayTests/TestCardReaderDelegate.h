//
//  TestCardReaderDelegate.h
//  WePay
//
//  Created by Jianxin Gao on 7/27/16.
//  Copyright © 2016 WePay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WePay.h"

typedef void(^StatusChangeBlock)(id status);
typedef void(^ReadSuccessBlock)(void);
typedef void(^ReadFailureBlock)(void);

@interface TestCardReaderDelegate : NSObject <WPCardReaderDelegate>

@property (nonatomic, assign) BOOL successCallBackInvoked;
@property (nonatomic, assign) BOOL failureCallBackInvoked;
@property (nonatomic, assign) BOOL cardReaderStatusNotConnectedInvoked;
@property (nonatomic, assign) BOOL cardReaderStatusConfiguringReaderInvoked;
@property (nonatomic, assign) BOOL cardReaderStatusStoppedInvoked;
@property (nonatomic, assign) BOOL shouldResetCardReaderInvoked;
@property (nonatomic, assign) BOOL shouldResetCardReader;
@property (nonatomic, assign) BOOL returnFromAuthorizeAmount;
@property (nonatomic, strong) StatusChangeBlock statusChangeBlock;
@property (nonatomic, strong) ReadSuccessBlock readSuccessBlock;
@property (nonatomic, strong) ReadFailureBlock readFailureBlock;
@property (nonatomic, strong) WPPaymentInfo *paymentInfo;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSString *authorizedAmount;
@property (nonatomic, assign) long accountId;

@end
