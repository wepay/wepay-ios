//
//  WPPaymentInfo.m
//  WePay
//
//  Created by Chaitanya Bagaria on 11/5/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#import "WPPaymentInfo.h"
#import "WePay.h"

extern NSString * NSStringFromWPPaymentMethod(WPPaymentMethod paymentMethod) {
    switch (paymentMethod) {
        case WPPaymentMethodManual:
            return @"Manual";
        case WPPaymentMethodSwipe:
            return @"Swipe";
    }
}

@interface WPPaymentInfo ()

@property (nonatomic, strong, readwrite) NSString *firstName;
@property (nonatomic, strong, readwrite) NSString *lastName;
@property (nonatomic, strong, readwrite) NSString *email;
@property (nonatomic, strong, readwrite) NSString *paymentDescription;
@property (nonatomic, readwrite) BOOL isVirtualTerminal;
@property (nonatomic, assign, readwrite) enum WPPaymentMethod paymentMethod;
@property (nonatomic, strong, readwrite) WPAddress *billingAddress;
@property (nonatomic, strong, readwrite) WPAddress *shippingAddress;
@property (nonatomic, strong, readwrite) id swiperInfo;
@property (nonatomic, strong, readwrite) id manualInfo;

@end

@implementation WPPaymentInfo

- (instancetype) initWithSwipedInfo:(id)swipedInfo
{
    if (self = [super init]) {
        NSDictionary *info = (NSDictionary *)swipedInfo;
        
        self.firstName = (NSString *)[info objectForKey:@"firstName"];
        self.lastName = (NSString *)[info objectForKey:@"lastName"];
        self.paymentDescription = (NSString *)[info objectForKey:@"paymentDescription"];
        self.swiperInfo = [info objectForKey:@"swiperInfo"];
        self.paymentMethod = WPPaymentMethodSwipe;
    }
    
    return self;
}

- (instancetype) initWithFirstName:(NSString *)firstName
                          lastName:(NSString *)lastName
                             email:(NSString *)email
                    billingAddress:(WPAddress *)billingAddress
                   shippingAddress:(WPAddress *)shippingAddress
                        cardNumber:(NSString *)cardNumber
                               cvv:(NSString *)cvv
                          expMonth:(NSString *)expMonth
                           expYear:(NSString *)expYear
                   virtualTerminal:(BOOL)virtualTerminal
{
    if (self = [super init]) {
        self.firstName = firstName;
        self.lastName = lastName;
        self.email = email;
        self.paymentDescription = nil;
        self.paymentMethod = WPPaymentMethodManual;
        self.isVirtualTerminal = virtualTerminal;

        self.billingAddress = billingAddress;
        self.shippingAddress = shippingAddress;

        self.manualInfo = @{
                                @"cc_number": cardNumber,
                                @"cvv": cvv,
                                @"expiration_month": expMonth,
                                @"expiration_year": expYear,
                            };

        // For virtual terminal, name is optional. We insert a placeholder name if not provided.
        if (self.isVirtualTerminal) {
            if (self.firstName == nil && self.lastName == nil) {
                self.firstName = @"Virtual Terminal";
                self.lastName = @"User";
            }
        }
    }
    
    return self;
}

- (void) addEmail:(NSString *)email
{
    if (self.email == nil) {
        self.email = email;
    }
}

- (NSDictionary *) toDict
{
    NSString *paymentMethodString = NSStringFromWPPaymentMethod(self.paymentMethod);
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [dict setValue:self.firstName           ? self.firstName            : [NSNull null] forKey:@"firstName"];
    [dict setValue:self.lastName            ? self.lastName             : [NSNull null] forKey:@"lastName"];
    [dict setValue:self.email               ? self.email                : [NSNull null] forKey:@"email"];

    [dict setValue:self.paymentDescription  ? self.paymentDescription   : [NSNull null] forKey:@"paymentDescription"];
    [dict setValue:self.paymentMethod       ? paymentMethodString       : [NSNull null] forKey:@"paymentMethod"];

    [dict setValue:self.billingAddress      ? [self.billingAddress toDict]  : [NSNull null] forKey:@"billingAddress"];
    [dict setValue:self.shippingAddress     ? [self.shippingAddress toDict] : [NSNull null] forKey:@"shippingAddress"];

    [dict setValue:self.isVirtualTerminal   ? @(self.isVirtualTerminal) : [NSNull null] forKey:@"virtualTerminal"];
    
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
