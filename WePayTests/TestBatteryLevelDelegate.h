//
//  TestBatteryLevelDelegate.h
//  WePay
//
//  Created by Chaitanya Bagaria on 9/8/16.
//  Copyright © 2016 WePay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WePay.h"

typedef void(^BatteryLevelSuccessBlock)(void);
typedef void(^BatteryLevelFailureBlock)(void);

@interface TestBatteryLevelDelegate : NSObject <WPBatteryLevelDelegate>

@property (nonatomic, assign) BOOL successCallBackInvoked;
@property (nonatomic, assign) BOOL failureCallBackInvoked;
@property (nonatomic, strong) BatteryLevelSuccessBlock batteryLevelSuccessBlock;
@property (nonatomic, strong) BatteryLevelFailureBlock batteryLevelFailureBlock;
@property (nonatomic, strong) NSError *error;

@end
