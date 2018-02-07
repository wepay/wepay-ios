//
//  TestBatteryLevelDelegate.m
//  WePay
//
//  Created by Chaitanya Bagaria on 9/8/16.
//  Copyright © 2016 WePay. All rights reserved.
//

#import "TestBatteryLevelDelegate.h"

@implementation TestBatteryLevelDelegate

- (void) didGetBatteryLevel:(int)batteryLevel
{
    self.successCallBackInvoked = YES;
    self.batteryLevel = batteryLevel;
    
    if (self.batteryLevelSuccessBlock != nil) {
        self.batteryLevelSuccessBlock();
    }
}

- (void) didFailToGetBatteryLevelwithError:(NSError *)error
{
    self.failureCallBackInvoked = YES;
    self.error = error;
    
    if (self.batteryLevelFailureBlock != nil) {
        self.batteryLevelFailureBlock();
    }
}

@end
