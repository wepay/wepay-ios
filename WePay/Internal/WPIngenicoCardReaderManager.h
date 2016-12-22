//
//  WPIngenicoCardReaderManager.h
//  WePay
//
//  Created by Chaitanya Bagaria on 8/4/15.
//  Copyright (c) 2015 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RPx_MFI/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA_MFI/RUA.h") 

#import <Foundation/Foundation.h>
#import "WePay_CardReaderDirector.h"
#import "WPIngenicoCardReaderDetector.h"

@interface WPIngenicoCardReaderManager : NSObject <WPCardReaderManager, WPTransactionDelegate, WPCardReaderDetectionDelegate, RUADeviceStatusHandler>

/**
 *  Initializes an instance of the class with the provided config.
 *
 *  @param config The WePay config.
 *
 *  @return An initialized instance of the class.
 */
- (instancetype) initWithConfig:(WPConfig *)config
     externalCardReaderDelegate:(NSObject<WPExternalCardReaderDelegate> *)delegate;

@end


#endif
#endif

