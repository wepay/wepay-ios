//
//  WPUserDefaultsHelper.h
//  WePay
//
//  Created by Zach Vega-Perkins on 2/17/17.
//  Copyright © 2017 WePay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WPUserDefaultsHelper : NSObject

+ (void) storeConfigHash:(NSString *)currentHash forKey:(NSString *)key;
+ (NSString *) getStoredConfigHashForKey:(NSString *)key;
+ (void) rememberCardReaderWithIdentifier:(NSString *)name;
+ (NSString *) getRememberedCardReader;
+ (void) forgetRememberedCardReader;

@end
