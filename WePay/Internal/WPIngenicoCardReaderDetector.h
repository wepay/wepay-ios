//
//  WPIngenicoCardReaderDetector.h
//  WePay
//
//  Created by Cameron Alley on 12/12/16.
//  Copyright © 2016 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RPx_MFI/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA_MFI/RUA.h")

#import <Foundation/Foundation.h>
#import "WePay_CardReaderDirector.h"


@protocol WPCardReaderDetectionDelegate

- (void) onCardReaderDevicesDetected:(NSArray *)devices;

@end


@interface WPIngenicoCardReaderDetector : NSObject <RUADeviceSearchListener>

@property (nonatomic, weak) id<WPCardReaderDetectionDelegate> delegate;

- (void) findAvailablCardReadersWithConfig:(WPConfig *)config deviceDetectionDelegate:(id<WPCardReaderDetectionDelegate>)delegate;
- (void) stopFindingCardReaders;

@end

#endif
#endif
