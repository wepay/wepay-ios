//
//  WPMockConfig.m
//  WePay
//
//  Created by Jianxin Gao on 7/19/16.
//  Copyright © 2016 WePay. All rights reserved.
//

#import "WPMockConfig.h"
#import "WePay.h"

@implementation WPMockConfig

- (instancetype) init
{
    if (self = [super init]) {
        self.useMockCardReader = YES;
        self.useMockWepayClient = YES;
        self.mockPaymentMethod = kWPPaymentMethodSwipe;
    }
    return self;
}

@end
