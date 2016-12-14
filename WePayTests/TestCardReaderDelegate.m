//
//  TestCardReaderDelegate.m
//  WePay
//
//  Created by Jianxin Gao on 7/27/16.
//  Copyright © 2016 WePay. All rights reserved.
//

#import "TestCardReaderDelegate.h"

@implementation TestCardReaderDelegate

- (instancetype) init
{
    if (self = [super init]) {
        self.authorizedAmount = @"24.61";
        self.shouldResetCardReader = NO;
        self.accountId = 1170640190;
    }
    return self;
}

- (void) didReadPaymentInfo:(WPPaymentInfo *)paymentInfo
{
    self.paymentInfo = paymentInfo;
    self.successCallBackInvoked = YES;
    
    if (self.readSuccessBlock != nil) {
        self.readSuccessBlock();
    }
}

- (void) didFailToReadPaymentInfoWithError:(NSError *)error
{
    self.error = error;
    self.failureCallBackInvoked = YES;
    
    if (self.readFailureBlock != nil) {
        self.readFailureBlock();
    }
}

- (void) cardReaderDidChangeStatus:(id)status
{
    if (status == kWPCardReaderStatusNotConnected) {
        self.cardReaderStatusNotConnectedInvoked = YES;
    } else if (status == kWPCardReaderStatusConfiguringReader) {
        self.cardReaderStatusConfiguringReaderInvoked = YES;
    } else if (status == kWPCardReaderStatusStopped) {
        self.cardReaderStatusStoppedInvoked = YES;
    }
    
    if (self.statusChangeBlock != nil) {
        self.statusChangeBlock(status);
    }
}

- (void) shouldResetCardReaderWithCompletion:(void (^)(BOOL shouldReset))completion
{
    self.shouldResetCardReaderInvoked = YES;

    completion(self.shouldResetCardReader);
}

- (void) authorizeAmountWithCompletion:(void (^)(NSDecimalNumber *amount, NSString *currencyCode, long accountId))completion
{
    if (self.returnFromAuthorizeAmount) {
        return;
    }
    completion([NSDecimalNumber decimalNumberWithString:self.authorizedAmount], kWPCurrencyCodeUSD, self.accountId);
}



@end
