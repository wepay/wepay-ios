//
//  WPConfig.h
//  WePay
//
//  Created by Chaitanya Bagaria on 11/7/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * The configuration object used for initializing a \ref WePay instance.
 */
@interface WPConfig : NSObject

/**
 *  Your WePay clientId for the specified environment
 */
@property (nonatomic, strong, readonly) NSString *clientId;

/**
 *  The environment to be used, one of (staging, production)
 */
@property (nonatomic, strong, readonly) NSString *environment;

/**
 *  Determines if we should use location services. Defaults to NO.
 */
@property (nonatomic, assign) BOOL useLocation;

/**
 *  Determines if the card reader should accept test EMV cards. Defaults to NO. This should never be turned on in production.
 */
@property (nonatomic, assign) BOOL useTestEMVCards;

/**
 *  Determines if delegate methods should be called on the main(UI) thread. If set to NO, delegate methods will be called on a new background thread. Defaults to YES.
 */
@property (nonatomic, assign) BOOL callDelegateMethodsOnMainThread;

/**
 *  Determines if the card reader should automatically restart after a successful swipe. The card reader is not restarted after a successful dip. Defaults to NO.
 */
@property (nonatomic, assign) BOOL restartCardReaderAfterSuccess;

/**
 *  Determines if the card reader should automatically restart after a swipe/dip general error (domain:kWPErrorCategoryCardReader, errorCode:WPErrorCardReaderGeneralError). Defaults to YES.
 */
@property (nonatomic, assign) BOOL restartCardReaderAfterGeneralError;

/**
 *  Determines if the card reader should automatically restart after a swipe/dip error other than general error. Defaults to NO.
 */
@property (nonatomic, assign) BOOL restartCardReaderAfterOtherErrors;

/**
 *  A convenience initializer
 *
 *  @param clientId    Your WePay clientId.
 *  @param environment The environment to be used, one of (kWPEnvironmentStage, kWPEnvironmentProduction).
 *
 *  @return A \ref WPConfig instance which can be used to initialize a \ref WePay instance.
 */
- (instancetype) initWithClientId:(NSString *)clientId
                      environment:(NSString *)environment;

/**
 *  The designated initializer
 *
 *  @param clientId                             Your WePay clientId.
 *  @param environment                          The environment to be used, one of (kWPEnvironmentStage, kWPEnvironmentProduction).
 *  @param useLocation                          Flag to determine if we should use location services.
 *  @param useTestEMVCards                      Flag to determine if we should use test EMV cards.
 *  @param callDelegateMethodsOnMainThread      Flag to determine if delegate methods should be called on the main(UI) thread.
 *  @param restartCardReaderAfterSuccess        Flag to determine if the card reader should automatically restart after a successful read.
 *  @param restartCardReaderAfterGeneralError   Flag to determine if the card reader should automatically restart after a general error (domain:kWPErrorCategoryCardReader, errorCode:WPErrorCardReaderGeneralError).
 *  @param restartCardReaderAfterOtherErrors    Flag to determine if the card reader should automatically restart after an error other than general error.
 *
 *  @return A \ref WPConfig instance which can be used to initialize a \ref WePay instance.
 */
- (instancetype) initWithClientId:(NSString *)clientId
                      environment:(NSString *)environment
                      useLocation:(BOOL)useLocation
                  useTestEMVCards:(BOOL)useTestEMVCards
  callDelegateMethodsOnMainThread:(BOOL)callDelegateMethodsOnMainThread
    restartCardReaderAfterSuccess:(BOOL)restartCardReaderAfterSuccess
restartCardReaderAfterGeneralError:(BOOL)restartCardReaderAfterGeneralError
restartCardReaderAfterOtherErrors:(BOOL)restartCardReaderAfterOtherErrors;

@end
