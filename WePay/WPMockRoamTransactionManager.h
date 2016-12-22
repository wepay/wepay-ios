//
//  WPMockRoamTransactionManager.h
//  WePay
//
//  Created by Jianxin Gao on 7/15/16.
//  Copyright © 2016 WePay. All rights reserved.
//
#if defined(__has_include)
#if __has_include("RPx_MFI/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA_MFI/RUA.h")

#import <Foundation/Foundation.h>
#import <RUA_MFI/RUA.h>

@class WPMockConfig;

@interface WPMockRoamTransactionManager : NSObject <RUATransactionManager>

@property id<RUADeviceStatusHandler> deviceStatusHandler;
@property WPMockConfig* mockConfig;

- (void) resetStates;

@end

#endif
#endif
