//
//  WPClientHelper.h
//  WePay
//
//  Created by Chaitanya Bagaria on 11/18/15.
//  Copyright © 2015 WePay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WPConfig.h"
#import "WPPaymentInfo.h"

@interface WPClientHelper : NSObject

+ (NSDictionary *) createCardRequestParamsForPaymentInfo:(WPPaymentInfo *)paymentInfo
                                                clientId:(NSString *)clientId
                                               sessionId:(NSString *)sessionId;

+ (NSDictionary *) reversalRequestParamsForCardInfo:(NSDictionary *)cardInfo
                                           clientId:(NSString *)clientId
                                       creditCardId:(NSNumber *)creditCardId
                                          accountId:(NSNumber *)accountId;
@end
