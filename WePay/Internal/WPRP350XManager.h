//
//  WPRP350XManager.h
//  WePay
//
//  Created by Chaitanya Bagaria on 8/4/15.
//  Copyright (c) 2015 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RPx/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA/RUA.h") && __has_include("G4XSwiper/SwiperController.h")

#import <Foundation/Foundation.h>
#import "WePay_CardReader.h"

@protocol RUADeviceStatusHandler;

@interface WPRP350XManager : NSObject <WPDeviceManager, RUADeviceStatusHandler>

@property (nonatomic, weak) NSObject<WPDeviceManagerDelegate> *managerDelegate;
@property (nonatomic, weak) NSObject<WPExternalCardReaderDelegate> *externalDelegate;

/**
 *  Initializes and instance of the class with the provided config.
 *
 *  @param config The WePay config.
 *
 *  @return An initialized instance of the class.
 */
- (instancetype) initWithConfig:(WPConfig *)config;

@end


#endif
#endif

