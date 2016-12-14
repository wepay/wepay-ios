//
//  WPDipTransactionHelper.h
//  WePay
//
//  Created by Chaitanya Bagaria on 11/18/15.
//  Copyright © 2015 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RPx/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA/RUA.h") 

#import <Foundation/Foundation.h>
#import "WPDipConfigHelper.h"
#import "WPRP350XManager.h"

@interface WPDipTransactionHelper : NSObject

- (instancetype) initWithConfigHelper:(WPDipConfigHelper *)configHelper
                             delegate:(WPRP350XManager *)delegate
                          environment:(NSString *)environment;

/**
 *  Starts the transaction on the card reader
 */
- (void) performEMVTransactionStartCommandWithAmount:(NSDecimalNumber *)amount
                                        currencyCode:(NSString *)currencyCode
                                           accountid:(long)accountId
                                   roamDeviceManager:(id<RUADeviceManager>) roamDeviceManager
                                     managerDelegate:(id<WPDeviceManagerDelegate>) managerDeletage
                                    externalDelegate:(id<WPExternalCardReaderDelegate>) externalDelegate;
@end

#endif
#endif
