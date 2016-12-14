//
//  WPMockConfig.h
//  WePay
//
//  Created by Jianxin Gao on 7/19/16.
//  Copyright © 2016 WePay. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * The Class MockConfig contains the configuration required when using mock card reader and/or WPClient implementation.
 */
@interface WPMockConfig : NSObject

/**
 * Determines if mock card reader implementation is used. Defaults to YES.
 */
@property BOOL useMockCardReader;

/**e
 * Determines if mock WepayClient implementation is used. Defaults to YES.
 */
@property BOOL useMockWepayClient;

/**
 * Determines if a card reader timeout should be mocked. Defaults to NO.
 */
@property BOOL cardReadTimeOut;

/**
 * Determines if a card reading failure should be mocked. Defaults to NO.
 */
@property BOOL cardReadFailure;

/**
 * Determines if a card tokenization failure should be mocked. Defaults to NO.
 */
@property BOOL cardTokenizationFailure;

/**
 * Determines if an EMV authorization failure should be mocked. Defaults to NO.
 */
@property BOOL EMVAuthFailure;

/**
 * Determines if multiple EMV application should be mocked. Dafaults to NO.
 */
@property BOOL multipleEMVApplication;

/**
 * Determines if a battery info failure should be mocked. Defaults to NO.
 */
@property BOOL batteryLevelError;

/**
 * The payment method to mock. Defaults to kWPPaymentMethodSwipe.
 */
@property NSString *mockPaymentMethod;

@end
