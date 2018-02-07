//
//  WPUserDefaultsHelper.m
//  WePay
//
//  Created by Zach Vega-Perkins on 2/17/17.
//  Copyright © 2017 WePay. All rights reserved.
//

#import "WPUserDefaultsHelper.h"

#define WEPAY_REMEMBERED_CARDREADER_KEY @"wepay.cardreader.remembered" // Key for remembered card reader entry in NSUserDefaults.
#define WEPAY_CONFIG_HASH_KEY @"wepay.config.hashes"

NSString * const kWPCardReaderIdentifierEmpty = @"";

@implementation WPUserDefaultsHelper

+ (void) storeConfigHash:(NSString *)currentHash forKey:(NSString *)key
{
    if (key == nil || [key length] <= 1) {
        return;
    }
    
    // fetch hashes
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *configHashes = [defaults objectForKey:WEPAY_CONFIG_HASH_KEY];
    if (configHashes == nil) {
        configHashes = @{};
    }
    
    // update hash
    NSMutableDictionary *updatedConfig = [configHashes mutableCopy];
    [updatedConfig setValue:currentHash forKey:key];
    
    [defaults setObject:updatedConfig forKey:WEPAY_CONFIG_HASH_KEY];
    [defaults synchronize];
}

+ (NSString *) getStoredConfigHashForKey:(NSString *)key
{
    // fetch saved hashes
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *configHashes = [defaults objectForKey:WEPAY_CONFIG_HASH_KEY];
    if (configHashes == nil) {
        configHashes = @{};
    }
    
    // extract hash for current key
    return [configHashes objectForKey:key];
}

+ (void) rememberCardReaderWithIdentifier:(NSString *)name
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *entry = [defaults objectForKey:WEPAY_REMEMBERED_CARDREADER_KEY];
    
    if (!name) {
        name = kWPCardReaderIdentifierEmpty;
    }
    
    entry = name;
    
    [defaults setObject:entry forKey:WEPAY_REMEMBERED_CARDREADER_KEY];
    
    if (![defaults synchronize]) {
        WPLog(@"Failed to immediately save card reader with name %@. It may be written to disk at a later time.", name);
    }
}

+ (NSString *) getRememberedCardReader
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *entry = [defaults objectForKey:WEPAY_REMEMBERED_CARDREADER_KEY];
    
    if (entry && [entry isEqualToString:kWPCardReaderIdentifierEmpty])
    {
        // Since we can't actually store nil, we need to fake it on lookup.
        entry = nil;
    }
    
    return entry;
}

+ (void) forgetRememberedCardReader
{
    [self rememberCardReaderWithIdentifier:kWPCardReaderIdentifierEmpty];
}

@end
