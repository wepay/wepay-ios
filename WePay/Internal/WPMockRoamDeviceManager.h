//
//  WPMockRoamDeviceManager.h
//  WePay
//
//  Created by Jianxin Gao on 7/15/16.
//  Copyright © 2016 WePay. All rights reserved.
//
#if defined(__has_include)
#if __has_include("RUA_MFI/RUA.h")

#import <Foundation/Foundation.h>
#import <RUA_MFI/RUA.h>

@class WPMockConfig;

@interface WPMockRoamDeviceManager : NSObject <RUADeviceManager>

+ (id<RUADeviceManager>) getDeviceManager;

@property id<RUADeviceStatusHandler> deviceStatusHandler;
@property WPMockConfig* mockConfig;

- (void) mockCardReaderDisconnect;
- (void) mockCardReaderConnect;
- (void) mockCardReaderError:(NSString *)message;

@end

#endif
#endif
