//
//  WPClient.m
//  WePay
//
//  Created by Chaitanya Bagaria on 12/15/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#import "WePay.h"
#import "WPClient.h"
#import "WPConfig.h"
#import "WPError+internal.h"

@implementation WPClient

static NSString * const SDK_VERSION = @"v7.0.1";
static NSString * const WEPAY_API_VERSION = @"2017-05-31";

#pragma mark config class property

static WPConfig *config;

+ (WPConfig *) config
{
    return config;
}

+ (void) setConfig:(WPConfig *)value
{
    config = value;
}

#pragma mark convenience api calls

+ (void) creditCardCreate:(NSDictionary *) params
             successBlock:(void (^)(NSDictionary * returnData)) successHandler
             errorHandler:(void (^)(NSError * error)) errorHandler
{
    [WPClient makeRequestToEndPoint:[WPClient apiUrlWithEndpoint:@"credit_card/create"]
                             values:params
                        accessToken:nil
                       successBlock:successHandler
                       errorHandler:errorHandler
     ];
}

+ (void) creditCardCreateSwipe:(NSDictionary *) params
                  successBlock:(void (^)(NSDictionary * returnData)) successHandler
                  errorHandler:(void (^)(NSError * error)) errorHandler
{
    [WPClient makeRequestToEndPoint:[WPClient apiUrlWithEndpoint:@"credit_card/create_swipe"]
                             values:params
                        accessToken:nil
                       successBlock:successHandler
                       errorHandler:errorHandler
     ];
}

+ (void) creditCardCreateEMV:(NSDictionary *) params
                  successBlock:(void (^)(NSDictionary * returnData)) successHandler
                  errorHandler:(void (^)(NSError * error)) errorHandler
{
    [WPClient makeRequestToEndPoint:[WPClient apiUrlWithEndpoint:@"credit_card/create_emv"]
                             values:params
                        accessToken:nil
                       successBlock:successHandler
                       errorHandler:errorHandler
     ];
}

+ (void) creditCardAuthReverse:(NSDictionary *) params
                successBlock:(void (^)(NSDictionary * returnData)) successHandler
                errorHandler:(void (^)(NSError * error)) errorHandler
{
    [WPClient makeRequestToEndPoint:[WPClient apiUrlWithEndpoint:@"credit_card/auth_reverse"]
                             values:params
                        accessToken:nil
                       successBlock:successHandler
                       errorHandler:errorHandler
     ];
}


+ (void) checkoutSignatureCreate:(NSDictionary *) params
                    successBlock:(void (^)(NSDictionary * returnData)) successHandler
                    errorHandler:(void (^)(NSError * error)) errorHandler
{
    [WPClient makeRequestToEndPoint:[WPClient apiUrlWithEndpoint:@"checkout/signature/create"]
                             values:params
                        accessToken:nil
                       successBlock:successHandler
                       errorHandler:errorHandler
     ];
}

#pragma mark API URL helper

// Returns an NSURL for API Call Endpoint
+ (NSURL *) apiUrlWithEndpoint: (NSString *) endpoint
{
    NSString *serverUrl = nil;
    // Use environment config to set the endpoint
    if ([kWPEnvironmentStage compare:config.environment options:NSCaseInsensitiveSearch] == NSOrderedSame) {
        serverUrl = @"https://stage.wepayapi.com/v2/";
    } else if ([kWPEnvironmentProduction compare:config.environment options:NSCaseInsensitiveSearch] == NSOrderedSame) {
        serverUrl = @"https://wepayapi.com/v2/";
    } else {
        // Use @"https://vm.wepay.com/v2/" for vm
        serverUrl = config.environment;
    }


    return [[NSURL URLWithString: [NSString stringWithFormat: @"%@", serverUrl]] URLByAppendingPathComponent: endpoint];
}

#pragma mark HTTP Call handlers

+ (void) makeRequestToEndPoint: (NSURL *) endpoint
                        values: (NSDictionary *) params
                   accessToken: (NSString *) accessToken
                  successBlock: (void (^)(NSDictionary * returnData)) successHandler
                  errorHandler: (void (^)(NSError * error)) errorHandler
{
    WPMockConfig *mockConfig = config.mockConfig;
    if (mockConfig != nil && mockConfig.useMockWepayClient) {
        [self mockRequestToEndpoint:endpoint mockConfig:mockConfig successBlock:successHandler errorHandler:errorHandler];
        return;
    }
    
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL: endpoint];
    
    [request setHTTPMethod: @"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"utf-8" forHTTPHeaderField:@"charset"];
    [request setValue:WEPAY_API_VERSION forHTTPHeaderField:@"Api-Version"];

    [request setValue: [NSString stringWithFormat: @"WePay iOS SDK %@", SDK_VERSION] forHTTPHeaderField:@"User-Agent"];
    
    // Set access token
    if(accessToken != nil) {
        [request setValue: [NSString stringWithFormat: @"Bearer: %@", accessToken] forHTTPHeaderField:@"Authorization"];
    }
    
    NSError *parseError = nil;
    
    // Get json from nsdictionary parameter
    NSData *requestData = [NSJSONSerialization dataWithJSONObject: params options: kNilOptions error: &parseError];
    [request setHTTPBody: requestData];
    
    if (parseError) {
        errorHandler(parseError);
    } else {
        NSOperationQueue *queue = [NSOperationQueue mainQueue];
        
        [NSURLConnection sendAsynchronousRequest: request
                                           queue: queue
                               completionHandler:^(NSURLResponse *response, NSData  *data, NSError * requestError) {
                                   // Process response from server.
                                   [self processResponse:response data: data error: requestError successBlock:successHandler errorHandler: errorHandler];
                                   
                               }];
    }
}

/**
 *  Processes Request Response
 *
 *  @param response     The NSURLResponse for the http request
 *  @param data         The NSData returned by the request
 *  @param error        The NSError returned by the request
 *  @param successBlock The success block to be called if the request succeeded
 *  @param errorHandler The error block to be called if the request failed
 */
+ (void) processResponse: (NSURLResponse *) response
                    data: (NSData *) data
                   error: (NSError *) error
            successBlock: (void (^)(NSDictionary * returnData)) successHandler
            errorHandler: (void (^)(NSError * error))  errorHandler
{
    // extract dictionary from raw data
    NSDictionary * dictionary = nil;
    if([data length] >= 1) {
        dictionary = [NSJSONSerialization JSONObjectWithData: data options: kNilOptions error: nil];
    }
    
#ifdef DEBUG
    // Log response only when in debug builds
    WPLog(@"[WPClient] error: %@, response: %@, data: %@",error,response, dictionary);
#endif
    
    if (dictionary != nil && error == nil) {
        // no error reported by api
        
        // get status code
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        
        // if status code is 200, return success, else return error
        if (statusCode == 200) {
            successHandler(dictionary);
        } else {
            errorHandler([WPError errorWithApiResponseData:dictionary]);
        }
    } else if (dictionary != nil && error != nil) {
        // api returned error, extract and send it
        errorHandler([WPError errorWithApiResponseData:dictionary]);
    } else if (dictionary == nil && error == nil) {
        // if no response, return error
        errorHandler([WPError errorWithApiResponseData:dictionary]);
    } else if (error != nil) {
        // if the request returned an error, pass it on
        errorHandler(error);
    }
}

+ (void) mockRequestToEndpoint: (NSURL *) endpoint
                    mockConfig:(WPMockConfig *) mockConfig
                  successBlock: (void (^)(NSDictionary * returnData)) successHandler
                  errorHandler: (void (^)(NSError * error)) errorHandler
{
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] init];
    NSData *data = nil;
    NSString *dataStr = nil;
    BOOL isSuccess = YES;
    if ([@"/v2/credit_card/create" isEqualToString:endpoint.path]) {
        if (mockConfig.cardTokenizationFailure) {
            isSuccess = NO;
            dataStr = @"{ \"error\" : \"invalid_request\", \"error_code\" : 1003, \"error_description\" : \"Invalid credit card number\" }";
        } else {
            dataStr = @"{ \"credit_card_id\": 1234567890, \"state\" : \"new\" }";
        }
    } else if ([@"/v2/credit_card/create_swipe" isEqualToString:endpoint.path]) {
        if (mockConfig.cardTokenizationFailure) {
            isSuccess = NO;
            dataStr = @"{ \"error\" : \"invalid_request\", \"error_code\" : 1003, \"error_description\" : \"Invalid credit card number\" }";
        } else {
            dataStr = @"{ \"credit_card_id\": 1234567890, \"state\" : \"new\" }";
        }
    } else if ([@"/v2/credit_card/create_emv" isEqualToString:endpoint.path]) {
        if (mockConfig.EMVAuthFailure) {
            isSuccess = NO;
            [self processResponse:nil
                             data:nil
                            error:nil
                     successBlock:successHandler
                     errorHandler:errorHandler];
            return;
        }
    } else if ([@"/v2/checkout/signature/create" isEqualToString:endpoint.path]) {
        dataStr = @"{ \"signature_url\": \"<signature url>\" }";
    }
    response = [[NSHTTPURLResponse alloc] initWithURL:endpoint statusCode:(isSuccess ? 200 : 400) HTTPVersion:nil headerFields:nil];
    data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    [self processResponse:response data:data error:nil successBlock:successHandler errorHandler:errorHandler];
}

@end
