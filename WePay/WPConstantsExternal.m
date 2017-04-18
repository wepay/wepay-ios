//
//  WPConstantsExternal.m
//  WePay
//
//  Created by Zach Vega-Perkins on 3/30/17.
//  Copyright © 2017 WePay. All rights reserved.
//

#import "WPConstantsExternal.h"

// Environments
NSString * const kWPEnvironmentStage = @"stage";
NSString * const kWPEnvironmentProduction = @"production";

// Payment Methods
NSString * const kWPPaymentMethodSwipe = @"Swipe";
NSString * const kWPPaymentMethodManual = @"Manual";
NSString * const kWPPaymentMethodDip = @"Dip";

// Card Reader status
NSString * const kWPCardReaderStatusSearching = @"searching for reader";
NSString * const kWPCardReaderStatusNotConnected = @"card reader not connected";
NSString * const kWPCardReaderStatusConnected = @"card reader connected";
NSString * const kWPCardReaderStatusCheckingReader = @"checking reader";
NSString * const kWPCardReaderStatusConfiguringReader = @"configuring reader";
NSString * const kWPCardReaderStatusWaitingForCard = @"waiting for card";
NSString * const kWPCardReaderStatusShouldNotSwipeEMVCard = @"should not swipe EMV card";
NSString * const kWPCardReaderStatusCheckCardOrientation = @"check card orientation";
NSString * const kWPCardReaderStatusChipErrorSwipeCard = @"chip error, swipe card";
NSString * const kWPCardReaderStatusSwipeErrorSwipeAgain = @"swipe error, swipe again";
NSString * const kWPCardReaderStatusSwipeDetected = @"swipe detected";
NSString * const kWPCardReaderStatusCardDipped = @"card dipped";
NSString * const kWPCardReaderStatusTokenizing = @"tokenizing";
NSString * const kWPCardReaderStatusAuthorizing = @"authorizing";
NSString * const kWPCardReaderStatusStopped = @"stopped";

// Currency Codes
NSString * const kWPCurrencyCodeUSD = @"USD";

// SDK log levels
NSString * const kWPLogLevelAll = @"all";
NSString * const kWPLogLevelNone = @"none";
