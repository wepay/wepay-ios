//
//  WPRoamHelper.m
//  WePay
//
//  Created by Chaitanya Bagaria on 8/4/15.
//  Copyright (c) 2015 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RUA_MFI/RUA.h") 

#import "WPRoamHelper.h"
#import <RUA_MFI/RUAEnumerationHelper.h>

#define ROAM_FIRST_NAME_INDEX 1
#define ROAM_LAST_NAME_INDEX 0

@implementation WPRoamHelper

+ (NSDictionary *)RUAResponse_toDictionary:(RUAResponse *)response
{
    NSMutableDictionary *returnDict = [@{} mutableCopy];
    NSDictionary *responseData = [response responseData];

    [returnDict setObject:[RUAEnumerationHelper RUACommand_toString:[response command]] forKey:[RUAEnumerationHelper RUAParameter_toString:RUAParameterCommand]];
    [returnDict setObject:[RUAEnumerationHelper RUAResponseCode_toString:[response responseCode]] forKey:[RUAEnumerationHelper RUAParameter_toString:RUAParameterResponseCode]];
    [returnDict setObject:[RUAEnumerationHelper RUAResponseType_toString:[response responseType]] forKey:[RUAEnumerationHelper RUAParameter_toString:RUAParameterResponseType]];

    if ([response responseCode] == RUAResponseCodeError) {
        [returnDict setObject:[WPRoamHelper RUAErrorCode_toString:[response errorCode]] forKey:[RUAEnumerationHelper RUAParameter_toString:RUAParameterErrorCode]];
        if ([response additionalErrorDetails] != nil) {
            [returnDict setObject:[response additionalErrorDetails] forKey:[RUAEnumerationHelper RUAParameter_toString:RUAParameterErrorDetails]];
        }
    }

    if (responseData != nil) {
        NSArray *keyArray =  [[response responseData] allKeys];
        int count = (int)[keyArray count];
        RUAParameter param;
        for (int i = 0; i < count; i++) {
            param = (RUAParameter)[[keyArray objectAtIndex:i] intValue];
            [returnDict setObject:[responseData objectForKey:[keyArray objectAtIndex:i]] forKey:[RUAEnumerationHelper RUAParameter_toString:param]];
        }
    }

    return returnDict;
}

+ (NSString *)RUAErrorCode_toString:(RUAErrorCode)errorCode
{
    return [RUAEnumerationHelper RUAErrorCode_toString:errorCode];
}


+ (NSString *)RUAResponse_toString:(RUAResponse *)response
{
    return [[WPRoamHelper RUAResponse_toDictionary:response] description];
}

+ (NSString *) RUAResponseType_toString:(RUAResponseType)code
{
    return [RUAEnumerationHelper RUAResponseType_toString:code];
}

+ (NSString *) RUAParameter_toString:(RUAParameter)param
{
    return [RUAEnumerationHelper RUAParameter_toString:param];
}

+ (NSString *) RUACommand_toString:(RUACommand)command
{
    return [RUAEnumerationHelper RUACommand_toString:command];
}

+ (NSString *)RUAProgressMessage_toString:(RUAProgressMessage)message
{
    return [RUAEnumerationHelper RUAProgressMessage_toString:message];
}

+ (NSString *)RUADeviceType_toString:(RUADeviceType)type
{
    return [RUAEnumerationHelper RUADeviceType_toString:type];
}

+ (NSString *) nameAtIndex:(int)index fromRUAData:(NSDictionary *) ruaData
{
    NSMutableString *encName = [[ruaData objectForKey:@"CardHolderName"] mutableCopy];

    if (encName) {
        CFStringTrimWhitespace((__bridge CFMutableStringRef) encName);
    }

    NSArray *names = [encName componentsSeparatedByString:@"/"];

    NSString *result = @"";

    if (names && [names count] > index) {
        result = names[index];
    }

    return result;
}

+ (NSString *) firstNameFromRUAData:(NSDictionary *) ruaData
{
    return [WPRoamHelper nameAtIndex:ROAM_FIRST_NAME_INDEX fromRUAData:ruaData];
}


+ (NSString *) lastNameFromRUAData:(NSDictionary *) ruaData
{
    return [WPRoamHelper nameAtIndex:ROAM_LAST_NAME_INDEX fromRUAData:ruaData];
}

+ (NSString *) fullNameFromRUAData:(NSDictionary *) ruaData
{
    NSString *firstName = [[self firstNameFromRUAData:ruaData] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *lastName = [[self lastNameFromRUAData:ruaData] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if ([@"" isEqualToString:firstName]) {
        firstName = @"Unknown";
    }

    if ([@"" isEqualToString:lastName]) {
        lastName = @"Unknown";
    }

    NSString *name = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if ([@"" isEqualToString:name] ) {
        return nil;
    }

    return name;
}


@end

#endif
#endif
