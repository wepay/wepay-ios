//
//  WePay_CardReader.h
//  WePay
//
//  Created by Chaitanya Bagaria on 11/17/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RPx/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA/RUA.h") && __has_include("G4XSwiper/SwiperController.h")

#import <UIKit/UIKit.h>

#import <RUA/RUAEnumerationHelper.h>
#import <RUA/RUADeviceManager.h>
#import <RUA/RUADevice.h>
#import <RUA/RUA.h>
#import <RUA/RUADeviceSearchListener.h>
#import <RUA/RUADeviceStatusHandler.h>
#import <RUA/RUADeviceResponseHandler.h>

@class WPConfig;
@class WPPaymentInfo;
@protocol WPCardReaderDelegate;
@protocol WPTokenizationDelegate;

@interface WePay_CardReader : NSObject <RUADeviceStatusHandler>

- (instancetype) initWithConfig:(WPConfig *)config;

- (void) startCardReaderForReadingWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDlegate;

- (void) startCardReaderForTokenizingWithCardReaderDelegate:(id<WPCardReaderDelegate>) cardReaderDelegate
                                       tokenizationDelegate:(id<WPTokenizationDelegate>) tokenizationDelegate
                                                  sessionId:(NSString *)sessionId;

- (void) stopCardReader;

- (void) tokenizeSwipedPaymentInfo:(WPPaymentInfo *)paymentInfo
              tokenizationDelegate:(id<WPTokenizationDelegate>)tokenizationDelegate
                         sessionId:(NSString *)sessionId;

@end

#endif
#endif
