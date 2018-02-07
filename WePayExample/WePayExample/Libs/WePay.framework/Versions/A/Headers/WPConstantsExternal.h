//
//  WPConstantsExternal.h
//  WePay
//
//  Created by Zach Vega-Perkins on 3/30/17.
//  Copyright © 2017 WePay. All rights reserved.
//

#import <Foundation/Foundation.h>

// Environments
extern NSString * const kWPEnvironmentStage;
extern NSString * const kWPEnvironmentProduction;

// Payment Methods
extern NSString * const kWPPaymentMethodSwipe;
extern NSString * const kWPPaymentMethodManual;
extern NSString * const kWPPaymentMethodDip;

// Card Reader status
extern NSString * const kWPCardReaderStatusSearching;
extern NSString * const kWPCardReaderStatusNotConnected;
extern NSString * const kWPCardReaderStatusConnected;
extern NSString * const kWPCardReaderStatusCheckingReader;
extern NSString * const kWPCardReaderStatusConfiguringReader;
extern NSString * const kWPCardReaderStatusWaitingForCard;
extern NSString * const kWPCardReaderStatusShouldNotSwipeEMVCard;
extern NSString * const kWPCardReaderStatusCheckCardOrientation;
extern NSString * const kWPCardReaderStatusChipErrorSwipeCard;
extern NSString * const kWPCardReaderStatusSwipeErrorSwipeAgain;
extern NSString * const kWPCardReaderStatusSwipeDetected;
extern NSString * const kWPCardReaderStatusCardDipped;
extern NSString * const kWPCardReaderStatusTokenizing;
extern NSString * const kWPCardReaderStatusAuthorizing;
extern NSString * const kWPCardReaderStatusStopped;

// Currency Codes
extern NSString * const kWPCurrencyCodeUSD;

// SDK log levels
extern NSString * const kWPLogLevelAll;
extern NSString * const kWPLogLevelNone;
