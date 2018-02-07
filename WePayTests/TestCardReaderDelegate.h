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
typedef void(^ReadFailureBlock)(NSError *);
typedef void (^SelectCardReaderBlock)(void (^didSelectIndex) (NSInteger));

@interface TestCardReaderDelegate : NSObject <WPCardReaderDelegate>

@property (nonatomic, assign) BOOL selectEMVApplicationInvoked;
@property (nonatomic, assign) BOOL mockEMVApplicationSelectionError;
@property (nonatomic, assign) BOOL successCallBackInvoked;
@property (nonatomic, assign) BOOL failureCallBackInvoked;
@property (nonatomic, assign) BOOL cardReaderStatusNotConnectedInvoked;
@property (nonatomic, assign) BOOL cardReaderStatusConfiguringReaderInvoked;
@property (nonatomic, assign) BOOL cardReaderStatusStoppedInvoked;
@property (nonatomic, assign) BOOL shouldResetCardReaderInvoked;
@property (nonatomic, assign) BOOL shouldResetCardReader;
@property (nonatomic, assign) BOOL returnFromAuthorizeAmount;
@property (nonatomic, assign) BOOL selectCardReaderInvoked;
@property (nonatomic, strong) StatusChangeBlock statusChangeBlock;
@property (nonatomic, strong) ReadSuccessBlock readSuccessBlock;
@property (nonatomic, strong) ReadFailureBlock readFailureBlock;
@property (nonatomic, strong) SelectCardReaderBlock selectCardReaderBlock;
@property (nonatomic, strong) WPPaymentInfo *paymentInfo;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSString *authorizedAmount;
@property (nonatomic, assign) long accountId;
@property (nonatomic, assign) NSInteger selectedCardReaderIndex;

@end
