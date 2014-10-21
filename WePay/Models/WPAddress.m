//
//  WPAddress.m
//  WePay
//
//  Created by Chaitanya Bagaria on 4/28/15.
//  Copyright (c) 2015 WePay. All rights reserved.
//

#import "WPAddress.h"

@interface WPAddress ()

@property (nonatomic, strong, readwrite) NSString *address1;
@property (nonatomic, strong, readwrite) NSString *address2;
@property (nonatomic, strong, readwrite) NSString *city;
@property (nonatomic, strong, readwrite) NSString *country;
@property (nonatomic, strong, readwrite) NSString *postcode;
@property (nonatomic, strong, readwrite) NSString *region;
@property (nonatomic, strong, readwrite) NSString *state;
@property (nonatomic, strong, readwrite) NSString *zip;

@end

static NSString *kCountryCodeUS = @"US";

@implementation WPAddress

- (instancetype) initWithZip:(NSString *)zip
{
    return [self initWithAddress1:nil address2:nil city:nil state:nil zip:zip];
}

- (instancetype) initWithAddress1:(NSString *)address1
                         address2:(NSString *)address2
                             city:(NSString *)city
                            state:(NSString *)state
                              zip:(NSString *)zip;
{
    if (self = [super init])
    {
        self.address1 = address1;
        self.address2 = address2;
        self.city = city;
        self.state = state;
        self.zip = zip;
        self.country = kCountryCodeUS;
    }

    return self;
}

- (instancetype) initWithAddress1:(NSString *)address1
                         address2:(NSString *)address2
                             city:(NSString *)city
                           region:(NSString *)region
                         postcode:(NSString *)postcode
                          country:(NSString *)country;
{
    if (self = [super init])
    {
        self.address1 = address1;
        self.address2 = address2;
        self.city = city;
        self.region = region;
        self.postcode = postcode;
        self.country = country;
    }

    return self;
}

- (NSDictionary *) toDict
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    [dict setValue:self.address1        ? self.address1     : [NSNull null] forKey:@"address1"];
    [dict setValue:self.address2        ? self.address2     : [NSNull null] forKey:@"address2"];
    [dict setValue:self.city            ? self.city         : [NSNull null] forKey:@"city"];

    if ([self.country isEqualToString:kCountryCodeUS]) {
        [dict setValue:self.state       ? self.state        : [NSNull null] forKey:@"state"];
        [dict setValue:self.zip         ? self.zip          : [NSNull null] forKey:@"zip"];
    } else {
        [dict setValue:self.region      ? self.region       : [NSNull null] forKey:@"region"];
        [dict setValue:self.postcode    ? self.postcode     : [NSNull null] forKey:@"postcode"];
    }

    [dict setValue:self.country         ? self.country      : [NSNull null] forKey:@"country"];


    return dict;
}

- (NSString *)description
{

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
