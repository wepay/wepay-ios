//
//  WPBatteryHelper.h
//  WePay
//
//  Created by Chaitanya Bagaria on 8/31/16.
//  Copyright © 2016 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RUA_MFI/RUA.h") 

#import <Foundation/Foundation.h>
#import <RUA_MFI/RUA.h>
#import "WePay.h"

@interface WPBatteryHelper : NSObject <RUADeviceStatusHandler>

- (void) getCardReaderBatteryLevelWithBatteryLevelDelegate:(id<WPBatteryLevelDelegate>) batteryLevelDelegate
                                                    config:(WPConfig *)config;

@end

#endif
#endif
