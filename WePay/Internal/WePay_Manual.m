//
//  WePay_Manual.m
//  WePay
//
//  Created by Chaitanya Bagaria on 12/15/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#import "WePay_Manual.h"
#import "WePay.h"
#import "WPClient.h"

@interface WePay_Manual ()

@property (nonatomic, strong) WPConfig *config;
@property (nonatomic, strong) NSString *sessionId;

@property (nonatomic, weak) id<WPTokenizationDelegate> externalTokenizationDelegate;

@end

@implementation WePay_Manual

- (instancetype) initWithConfig:(WPConfig *)config
{
    if (self = [super init]) {
        // set the clientId
        self.config = config;

        // pass the config to the client
        WPClient.config = config;
    }
    
    return self;
}

- (void) tokenizeManualPaymentInfo:(WPPaymentInfo *)paymentInfo
              tokenizationDelegate:(id<WPTokenizationDelegate>)tokenizationDelegate
                         sessionId:(NSString *)sessionId
{
    self.externalTokenizationDelegate = tokenizationDelegate;
    self.sessionId = sessionId;

    [self tokenWithPaymentInfo:paymentInfo];
}

#pragma mark - private

/**
 *  Tokenizes provided payment info. Triggers WPTokenizationDelegate callbacks on success/failure.
 *
 *  @param paymentInfo The payment info.
 */
- (void) tokenWithPaymentInfo:(WPPaymentInfo *)paymentInfo
{
    [WPClient creditCardCreate:[self createTokenizationRequestParamsForPaymentInfo:paymentInfo]
                  successBlock:^(NSDictionary * returnData) {
                      NSNumber *credit_card_id = [returnData objectForKey:@"credit_card_id"];
                      WPPaymentToken *token = [[WPPaymentToken alloc] initWithId:[credit_card_id stringValue]];

                      // inform external success
                      [self informExternalTokenizerSuccess:token forPaymentInfo:paymentInfo];
                  }
                  errorHandler:^(NSError * error) {
                      // inform external failure
                      [self informExternalTokenizerFailure:error forPaymentInfo:paymentInfo];
                  }
     ];
}

#pragma mark - inform external

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

#pragma mark - helpers

/**
 *  Converts manually entered card data into request params for a /credit_card/create request
 *
 *  @param paymentInfo The card data from user
 *
 *  @return The request params
 */
- (NSDictionary *) createTokenizationRequestParamsForPaymentInfo:(WPPaymentInfo *)paymentInfo
{
    NSString *name = [self fullNameFromPaymentInfo:paymentInfo];
    NSDictionary *manualInfo = (NSDictionary *)paymentInfo.manualInfo;
    
    NSMutableDictionary *requestParams = [@{
                                    @"client_id":self.config.clientId,
                                    @"cc_number":[manualInfo objectForKey:@"cc_number"],
                                    @"cvv":[manualInfo objectForKey:@"cvv"],
                                    @"expiration_month":[manualInfo objectForKey:@"expiration_month"],
                                    @"expiration_year":[manualInfo objectForKey:@"expiration_year"],
                                    @"user_name": name ? name : [NSNull null],
                                    @"email": paymentInfo.email ? paymentInfo.email : [NSNull null],
                                    @"address": [paymentInfo.billingAddress toDict]
                                    } mutableCopy];
    if (paymentInfo.isVirtualTerminal) {
        [requestParams setObject:@"mobile" forKey:@"virtual_terminal"];
    }

    if (self.sessionId) {
        [requestParams setObject:self.sessionId forKey:@"device_token"];
    }

    return requestParams;
}

- (NSString *) fullNameFromPaymentInfo:(WPPaymentInfo *)paymentInfo
{
    NSString *firstName = paymentInfo.firstName ? paymentInfo.firstName : @"";
    NSString *lastName = paymentInfo.lastName ? paymentInfo.lastName : @"";

    NSString *fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    fullName = [fullName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if ([@"" isEqualToString:fullName]) {
        return nil;
    } else {
        return fullName;
    }
}

@end
