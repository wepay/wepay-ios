//
//  WPConfig.h
//  WePay
//
//  Created by Chaitanya Bagaria on 11/7/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#import <Foundation/Foundation.h>

// Environments
typedef NS_ENUM(NSInteger, WPEnvironment) {
    WPEnvironmentStage,
    WPEnvironmentProduction,
    WPEnvironmentCustom // Set customEnvironmentUrl when using this option
};

/**
 * The configuration object used for initializing a \ref WePay instance.
 */
@interface WPConfig : NSObject

/**
 *  Your WePay clientId for the specified environment
 */
@property (nonatomic, strong, readonly) NSString *clientId;

/**
 *  The environment to be used, one of (WPEnvironmentStage, WPEnvironmentProduction, WPEnvironmentCustom). You must set customEnvironmentUrl if using WPEnvironmentCustom.
 */
@property (nonatomic, assign, readonly) enum WPEnvironment environment;

/**
 *  The URL of the environment to use when environment is set to WPEnvironmentCustom.
 */
@property (nonatomic, assign, readonly) NSString *customEnvironmentUrl;

/**
 *  Determines if we should use location services. Defaults to NO.
 */
@property (nonatomic, assign) BOOL useLocation;

/**
 *  Determines if the card reader should automatically restart after a successful read. Defaults to NO.
 */
@property (nonatomic, assign) BOOL restartCardReaderAfterSuccess;

/**
 *  Determines if the card reader should automatically restart after a general error (domain:kWPErrorCategoryCardReader, errorCode:WPErrorCardReaderGeneralError). Defaults to YES.
 */
@property (nonatomic, assign) BOOL restartCardReaderAfterGeneralError;

/**
 *  Determines if the card reader should automatically restart after an error other than general error. Defaults to NO.
 */
@property (nonatomic, assign) BOOL restartCardReaderAfterOtherErrors;

/**
 *  A convenience initializer
 *
 *  @param clientId    Your WePay clientId.
 *  @param environment The environment to be used, one of (WPEnvironmentStage, WPEnvironmentProduction). You must use the designated initializer when delcaring WPEnvironmentCustom.
 *
 *  @return A \ref WPConfig instance which can be used to initialize a \ref WePay instance.
 */
- (instancetype) initWithClientId:(NSString *)clientId
                      environment:(enum WPEnvironment)environment;

/**
 *  The designated initializer
 *
 *  @param clientId                             Your WePay clientId.
 *  @param environment                          The environment to be used, one of (WPEnvironmentStage, kWPEnvironmentProduction).
 *  @param customEnvironmentUrl                 The url to use when environment is set to WPEnvironmentCustom
 *  @param useLocation                          Flag to determine if we should use location services.
 *  @param restartCardReaderAfterSuccess        Flag to determine if the card reader should automatically restart after a successful read.
 *  @param restartCardReaderAfterGeneralError   Flag to determine if the card reader should automatically restart after a general error (domain:kWPErrorCategoryCardReader, errorCode:WPErrorCardReaderGeneralError).
 *  @param restartCardReaderAfterOtherErrors    Flag to determine if the card reader should automatically restart after an error other than general error.
 *
 *  @return A \ref WPConfig instance which can be used to initialize a \ref WePay instance.
 */
- (instancetype) initWithClientId:(NSString *)clientId
                      environment:(enum WPEnvironment)environment
             customEnvironmentUrl:(NSString *)customEnvironmentUrl
                      useLocation:(BOOL)useLocation
    restartCardReaderAfterSuccess:(BOOL)restartCardReaderAfterSuccess
restartCardReaderAfterGeneralError:(BOOL)restartCardReaderAfterGeneralError
restartCardReaderAfterOtherErrors:(BOOL)restartCardReaderAfterOtherErrors;

@end
