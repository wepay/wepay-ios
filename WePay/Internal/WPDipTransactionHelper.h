//
//  WPDipTransactionHelper.h
//  WePay
//
//  Created by Chaitanya Bagaria on 11/18/15.
//  Copyright © 2015 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RPx_MFI/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA_MFI/RUA.h") 

#import <Foundation/Foundation.h>
#import "WPDipConfigHelper.h"
#import "WPIngenicoCardReaderManager.h"

@interface WPDipTransactionHelper : NSObject

@property (nonatomic, assign) BOOL isWaitingForCardRemoval;

- (instancetype) initWithConfigHelper:(WPDipConfigHelper *)configHelper
                             delegate:(id<WPTransactionDelegate>)delegate
           externalCardReaderDelegate:(id<WPExternalCardReaderDelegate>)externalDelegate
                               config:(WPConfig *)config;

/**
 *  Starts the transaction on the card reader
 */
- (void) performEMVTransactionStartCommandWithAmount:(NSDecimalNumber *)amount
                                        currencyCode:(NSString *)currencyCode
                                           accountid:(long)accountId
                                   roamDeviceManager:(id<RUADeviceManager>) roamDeviceManager
                                   cardReaderRequest:(CardReaderRequest)request;

@end

#endif
#endif
