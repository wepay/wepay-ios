//
//  WPConfig.m
//  WePay
//
//  Created by Chaitanya Bagaria on 11/7/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#import "WPConfig.h"

@interface WPConfig ()

@property (nonatomic, strong, readwrite) NSString *clientId;
@property (nonatomic, assign, readwrite) enum WPEnvironment environment;
@end


@implementation WPConfig


- (instancetype) initWithClientId:(NSString *)clientId
                      environment:(enum WPEnvironment)environment
{
    NSAssert(environment != WPEnvironmentCustom, @"You must use the designated initializer when using WPEnvironmentCustom.");
    
    return [self initWithClientId:clientId
                      environment:environment
             customEnvironmentUrl:nil
                      useLocation:NO
    restartCardReaderAfterSuccess:NO
restartCardReaderAfterGeneralError:YES
restartCardReaderAfterOtherErrors: NO];
}


- (instancetype) initWithClientId:(NSString *)clientId
                      environment:(enum WPEnvironment)environment
             customEnvironmentUrl:(NSString *)customEnvironmentUrl
                      useLocation:(BOOL)useLocation
    restartCardReaderAfterSuccess:(BOOL)restartCardReaderAfterSuccess
restartCardReaderAfterGeneralError:(BOOL)restartCardReaderAfterGeneralError
restartCardReaderAfterOtherErrors:(BOOL)restartCardReaderAfterOtherErrors
{
    
    
    NSAssert((environment != WPEnvironmentCustom) || (environment == WPEnvironmentCustom && customEnvironmentUrl != nil),
             @"You must provide a customEnvironmentUrl when using WPEnvironmentCustom.");
    
    if (self = [super init])
    {
        self.clientId = clientId;
        self.environment = environment;
        self.useLocation = useLocation;
        self.restartCardReaderAfterSuccess = restartCardReaderAfterSuccess;
        self.restartCardReaderAfterGeneralError = restartCardReaderAfterGeneralError;
        self.restartCardReaderAfterOtherErrors = restartCardReaderAfterOtherErrors;
    }
    
    return self;
}

- (NSDictionary *) toDict
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [dict setValue:self.clientId ? self.clientId : [NSNull null] forKey:@"clientId"];
    [dict setValue:@(self.environment) forKey:@"environment"];
    [dict setValue:@(self.useLocation) forKey:@"useLocation"];
    [dict setValue:@(self.restartCardReaderAfterSuccess) forKey:@"restartCardReaderAfterSuccess"];
    [dict setValue:@(self.restartCardReaderAfterGeneralError) forKey:@"restartCardReaderAfterGeneralError"];
    [dict setValue:@(self.restartCardReaderAfterOtherErrors) forKey:@"restartCardReaderAfterOtherErrors"];
    
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
