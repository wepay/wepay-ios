//
//  TestCardReaderDelegate.m
//  WePay
//
//  Created by Jianxin Gao on 7/27/16.
//  Copyright © 2016 WePay. All rights reserved.
//

#import "TestCardReaderDelegate.h"
#import "WPError+internal.h"

@implementation TestCardReaderDelegate

- (instancetype) init
{
    if (self = [super init]) {
        self.authorizedAmount = @"24.61";
        self.shouldResetCardReader = NO;
        self.accountId = 1170640190;
        self.selectedCardReaderIndex = 0;
    }
    return self;
}

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
        self.readFailureBlock(error);
    }
}

- (void) selectCardReader:(NSArray *)cardReaderNames
               completion:(void (^)(NSInteger selectedIndex))completion {
    self.selectCardReaderInvoked = YES;
    if (self.selectCardReaderBlock) {
        self.selectCardReaderBlock(^ (NSInteger selectedIndex) {
            completion(selectedIndex);
        });
    } else {
        completion(self.selectedCardReaderIndex);
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
