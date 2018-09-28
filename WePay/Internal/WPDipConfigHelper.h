//
//  WPDipConfigHelper.h
//  WePay
//
//  Created by Chaitanya Bagaria on 11/18/15.
//  Copyright © 2015 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RUA_MFI/RUA.h") 

#import <Foundation/Foundation.h>

@interface WPDipConfigHelper : NSObject

@property (nonatomic, strong, readonly) NSArray *aidsList;
@property (nonatomic, strong, readonly) NSArray *publicKeyList;

@property (nonatomic, strong, readonly) NSArray *amountDOL;
@property (nonatomic, strong, readonly) NSArray *onlineDOL;
@property (nonatomic, strong, readonly) NSArray *responseDOL;


- (instancetype) initWithConfig:(WPConfig *)config;

/**
 *  Compares the current config hash with the stored hash for the given key.
 *
 *  @param key       The key against which the config hash is stored.
 *
 *  @return YES if hash is different or not stored, NO otherwise.
 */
- (BOOL) compareStoredConfigHashForKey:(NSString *)key;

/**
 *  Stores the current config hash for the given key.
 *
 *  @param key       The key against which the config hash will be stored.
 */
- (void) storeConfigHashForKey:(NSString *)key;

/**
 *  Clears the current config hash for the given key.
 *
 *  @param key       The key against which the config hash will be cleared.
 */
- (void) clearConfigHashForKey:(NSString *)key;


- (NSArray *) TACsForAID:(NSString* )aid;

@end

#endif
#endif
