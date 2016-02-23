//
//  WPAuthorizationInfo.m
//  WePay
//
//  Created by Chaitanya Bagaria on 7/17/15.
//  Copyright (c) 2015 WePay. All rights reserved.
//

#import "WPAuthorizationInfo.h"

@interface WPAuthorizationInfo()

@property (nonatomic, readwrite) double amount;
@property (nonatomic, strong, readwrite) NSString* currencyCode;
@property (nonatomic, strong, readwrite) NSString* transactionToken;


@end

@implementation WPAuthorizationInfo

- (instancetype) initWithAmount:(double) amount
                   currencyCode:(NSString *)currencyCode
               transactionToken:(NSString *)transactionToken
                        tokenId:(NSString* )tokenId
{
    if (self = [super initWithId:tokenId]) {
        self.amount = amount;
        self.currencyCode = currencyCode;
        self.transactionToken = transactionToken;
    }

    return self;
}

- (NSDictionary *) toDict
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    [dict setValue:self.tokenId ? self.tokenId : [NSNull null] forKey:@"tokenId"];
    [dict setValue:self.amount ? @(self.amount) : [NSNull null] forKey:@"amount"];
    [dict setValue:self.currencyCode ? self.currencyCode : [NSNull null] forKey:@"currencyCode"];
    [dict setValue:self.transactionToken ? self.transactionToken : [NSNull null] forKey:@"transactionToken"];

    return dict;
}

- (NSString *)description {

    NSError *error = nil;
    NSData *json;

    NSDictionary *dict = [self toDict];

    if ([NSJSONSerialization isValidJSONObject:dict])
    {
        // Serialize the dictionary
        json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];

        // If no errors, return the JSON
        if (json != nil && error == nil)
        {
            return [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        }
    }

    return (NSString *)self;
}

@end
