//
//  WPPaymentToken.m
//  WePay
//
//  Created by Chaitanya Bagaria on 11/7/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#import "WPPaymentToken.h"

@interface WPPaymentToken()

@property (nonatomic, strong) NSString* tokenId;

@end

@implementation WPPaymentToken

- (instancetype) initWithId:(NSString* )tokenId
{
    if (self = [super init]) {
        self.tokenId = tokenId;
    }
    
    return self;
}


- (NSDictionary *) toDict
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [dict setValue:self.tokenId ? self.tokenId : [NSNull null] forKey:@"tokenId"];
    
    return dict;
}

- (NSString *) description {
    
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
