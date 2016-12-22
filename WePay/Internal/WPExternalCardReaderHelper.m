//
//  WPExternalCardReaderHelper.m
//  WePay
//
//  Created by Chaitanya Bagaria on 11/17/15.
//  Copyright © 2015 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RPx_MFI/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA_MFI/RUA.h") 

#import "WPExternalCardReaderHelper.h"

@implementation WPExternalCardReaderHelper

- (instancetype) initWithConfig:(WPConfig *)config
{
    if (self = [super init]) {
        // save the config
        self.config = config;
    }

    return self;
}


#pragma mark - WPExternalCardReaderDelegate methods

- (void) informExternalCardReader:(NSString *)status
{
    dispatch_queue_t queue = self.config.callDelegateMethodsOnMainThread ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        // If the external delegate is listening for status updates, send it
        if (self.externalCardReaderDelegate && [self.externalCardReaderDelegate respondsToSelector:@selector(cardReaderDidChangeStatus:)]) {
            [self.externalCardReaderDelegate cardReaderDidChangeStatus:status];
        }
    });
}

- (void) informExternalCardReaderSuccess:(WPPaymentInfo *)paymentInfo
{
    dispatch_queue_t queue = self.config.callDelegateMethodsOnMainThread ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        // If the external delegate is listening for success, send it
        if (self.externalCardReaderDelegate && [self.externalCardReaderDelegate respondsToSelector:@selector(didReadPaymentInfo:)]) {
            [self.externalCardReaderDelegate didReadPaymentInfo:paymentInfo];
        }
    });
}

- (void) informExternalCardReaderFailure:(NSError *)error
{
    // If the external delegate is listening for errors, send it
    if (self.externalCardReaderDelegate && [self.externalCardReaderDelegate respondsToSelector:@selector(didFailToReadPaymentInfoWithError:)]) {
        [self.externalCardReaderDelegate didFailToReadPaymentInfoWithError:error];
    }
}

- (void) informExternalCardReaderResetCompletion:(void (^)(BOOL shouldReset))completion
{
    dispatch_queue_t queue = self.config.callDelegateMethodsOnMainThread ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        // If the external delegate is listening for device reset, ask for it
        if (self.externalCardReaderDelegate && [self.externalCardReaderDelegate respondsToSelector:@selector(shouldResetCardReaderWithCompletion:)]) {
            [self.externalCardReaderDelegate shouldResetCardReaderWithCompletion:completion];
        } else {
            // execute the completion
            completion(NO);
        }
    });
}

- (void) informExternalCardReaderAmountCompletion:(void (^)(BOOL implemented, NSDecimalNumber *amount, NSString *currencyCode, long accountId))innerCompletion
{
    dispatch_queue_t queue = self.config.callDelegateMethodsOnMainThread ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        // If the external delegate is listening for auth info request, ask for it
        if (self.externalCardReaderDelegate && [self.externalCardReaderDelegate respondsToSelector:@selector(authorizeAmountWithCompletion:)]) {
            [self.externalCardReaderDelegate authorizeAmountWithCompletion:^(NSDecimalNumber *amount, NSString *currencyCode, long accountId) {
                innerCompletion(YES, amount, currencyCode, accountId);
            }];
        } else {
            innerCompletion(NO, 0, nil, 0);
        }
    });
}

- (void) informExternalTokenizerSuccess:(WPPaymentToken *)token forPaymentInfo:(WPPaymentInfo *)paymentInfo
{
    dispatch_queue_t queue = self.config.callDelegateMethodsOnMainThread ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        // If the external delegate is listening for success, send it
        if (self.externalTokenizationDelegate && [self.externalTokenizationDelegate respondsToSelector:@selector(paymentInfo:didTokenize:)]) {
            [self.externalTokenizationDelegate paymentInfo:paymentInfo didTokenize:token];
        }
    });
}

- (void) informExternalTokenizerFailure:(NSError *)error forPaymentInfo:(WPPaymentInfo *)paymentInfo
{
    dispatch_queue_t queue = self.config.callDelegateMethodsOnMainThread ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        // If the external delegate is listening for error, send it
        if (self.externalTokenizationDelegate && [self.externalTokenizationDelegate respondsToSelector:@selector(paymentInfo:didFailTokenization:)]) {
            [self.externalTokenizationDelegate paymentInfo:paymentInfo didFailTokenization:error];
        }
    });
}

- (void) informExternalAuthorizationSuccess:(WPAuthorizationInfo *)authInfo forPaymentInfo:(WPPaymentInfo *)paymentInfo
{
    dispatch_queue_t queue = self.config.callDelegateMethodsOnMainThread ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        // If the external delegate is listening for success, send it
        if (self.externalAuthorizationDelegate && [self.externalAuthorizationDelegate respondsToSelector:@selector(paymentInfo:didAuthorize:)]) {
            [self.externalAuthorizationDelegate paymentInfo:paymentInfo didAuthorize:authInfo];
        }
    });
}

- (void) informExternalAuthorizationFailure:(NSError *)error forPaymentInfo:(WPPaymentInfo *)paymentInfo
{
    dispatch_queue_t queue = self.config.callDelegateMethodsOnMainThread ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        // If the external delegate is listening for error, send it
        if (self.externalAuthorizationDelegate && [self.externalAuthorizationDelegate respondsToSelector:@selector(paymentInfo:didFailAuthorization:)]) {
            [self.externalAuthorizationDelegate paymentInfo:paymentInfo didFailAuthorization:error];
        }
    });
}

- (void) informExternalAuthorizationApplications:(NSArray *)applications
                                      completion:(void (^)(NSInteger selectedIndex))completion
{
    dispatch_queue_t queue = self.config.callDelegateMethodsOnMainThread ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        // If the external delegate is listening for app ID selection, send it
        if (self.externalAuthorizationDelegate && [self.externalAuthorizationDelegate respondsToSelector:@selector(selectEMVApplication:completion:)]) {
            [self.externalAuthorizationDelegate selectEMVApplication:applications completion:completion];
        }
    });
}

- (void) informExternalTokenizerEmailCompletion:(void (^)(NSString *email))completion
{
    dispatch_queue_t queue = self.config.callDelegateMethodsOnMainThread ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        // If the external delegate is listening for email request, ask for it
        if (self.externalTokenizationDelegate && [self.externalTokenizationDelegate respondsToSelector:@selector(insertPayerEmailWithCompletion:)]) {
            [self.externalTokenizationDelegate insertPayerEmailWithCompletion:completion];
        } else {
            // execute the completion
            completion(nil);
        }
    });
}

@end

#endif
#endif
