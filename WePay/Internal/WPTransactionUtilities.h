//
//  WPTransactionUtilities.h
//  WePay
//
//  Created by Cameron Alley on 12/7/16.
//  Copyright © 2016 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RUA_MFI/RUA.h")

#import <Foundation/Foundation.h>
#import "WePay_CardReaderDirector.h"

@class WPConfig;
@class WPPaymentInfo;


@protocol WPExternalCardReaderDelegate;

@interface WPTransactionUtilities : NSObject

@property (nonatomic, assign) CardReaderRequest cardReaderRequest;

- (instancetype) initWithConfig:(WPConfig *)config
       externalCardReaderHelper:(id<WPExternalCardReaderDelegate>) externalHelper;

- (void) handleSwipeResponse:(NSDictionary *) responseData
              successHandler:(void (^)(NSDictionary * returnData)) successHandler
                errorHandler:(void (^)(NSError * error)) errorHandler
               finishHandler:(void (^)(void)) finishHandler;
- (void) handlePaymentInfo:(WPPaymentInfo *)paymentInfo
            successHandler:(void (^)(NSDictionary * returnData)) successHandler
              errorHandler:(void (^)(NSError * error)) errorHandler
             finishHandler:(void (^)(void)) finishHandler;

- (void) issueReversalForCreditCardId:(NSNumber *)creditCardId
                            accountId:(NSNumber *)accountId
                         roamResponse:(NSDictionary *)cardInfo;

- (NSError *) validatePaymentInfoForTokenization:(WPPaymentInfo *)paymentInfo;
- (NSError *) validateSwiperInfoForTokenization:(NSDictionary *)swiperInfo;
- (NSError *) validateEMVInfoForTokenization:(NSDictionary *)emvInfo;
- (NSString *) sanitizePAN:(NSString *)pan;
- (NSString *) extractPANfromTrack2:(NSString *)track2;

@end

#endif
#endif
