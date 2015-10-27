//
//  RUA.h
//  RUA
//
//  Created by Russell Kondaveti on 10/9/13.
//  Copyright (c) 2013 ROAM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RUADeviceManager.h"
#import "RUAReaderVersionInfo.h"

#define RUA_DEBUG 1

#ifdef RUA_DEBUG
#define RUA_DEBUG_LOG(...) NSLog(__VA_ARGS__)
#else
#define RUA_DEBUG_LOG(...)
#endif


@interface RUA : NSObject

/**
 Enables RUA log messages
 @param enable, TRUE to enable logging
 */
+ (void)enableDebugLogMessages:(BOOL)enable;


/**
 Returns true if RUA log messages are enabled
 */
+ (BOOL)debugLogEnabled;

/**
 Returns the list of roam device types that are supported by the RUA
 <p>
 Usage: <br>
 <code>
 NSArray *supportedDevices = [RUA getSupportedDevices];
 </code>
 </p>
 @return NSArray containing the enumerations of reader types that are supported.
 @see RUADeviceType
 */
+ (NSArray *)getSupportedDevices;

/**
 Returns an instance of the device manager for the connected device and this auto detection works with the readers that have audio jack interface.
 @param RUADeviceType roam reader type enumeration
 @return RUADeviceManager device manager for the device type specified
 @see RUADeviceType
 */
+ (id <RUADeviceManager> )getDeviceManager:(RUADeviceType)type;


/**
 Returns an instance of the device manager for the device type specified.
 <p>
 Usage: <br>
 <code>
 id<RUADeviceManager> mRP750xReader = [RUA getDeviceManager:RUADeviceTypeRP750x];
 </code>
 </p>
 @param RUADeviceType roam reader type enumeration
 @return RUADeviceManager device manager for the device type specified
 @see RUADeviceType
 */

+ (id <RUADeviceManager> )getAutoDetectDeviceManager:(NSArray*)type;

/**
 Returns an version of ROAMReaderUnifiedAPI (RUA)
 @return RUADeviceManager device manager for the device type specified
 */
+ (NSString *) versionString;

+ (BOOL)isUpdateRequired:(NSString*)filePath readerInfo:(RUAReaderVersionInfo*)readerVersionInfo;

/**
 * Returns a boolean to indicate if the UNS files need to be loaded onto the terminal.
 *
 * @return boolean to indicate if the UNS files need to be loaded onto the terminal
 * @see RUAReaderVersionInfo, RUAFileVersionInfo
 *
 */

+ (BOOL)isUpdateRequired:(NSArray*)UNSFiles readerVersionInfo:(RUAReaderVersionInfo*)readerVersionInfo;;

/**
 * Returns a list of file version descriptions for each file
 * contained within the specified UNS file.
 * @see RUAFileVersionInfo
 *
 */

+ (NSArray*)getUnsFileVersionInfo:(NSString*)filePath;

+ (void)getDeviceManagerIfavailable:(id <RUADeviceStatusHandler> )statusHandler deviceList:(NSArray*)list;




@end
