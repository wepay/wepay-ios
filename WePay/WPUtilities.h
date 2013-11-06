//
//  WPUtilities.h
//  WePaySDK
//
//  Created by Weina Scott on 11/6/13.
//  Copyright (c) 2013 Weina Scott. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WPUtilities : NSObject

/*
 Returns the user's IP Address
 */
+ (NSString *) ipAddress;

/*
 Returns advertiser identifier for the device. 
 */
+ (NSString *) deviceIdentifier;

@end
