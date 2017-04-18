//
//  WPConfig.h
//  WePay
//
//  Created by Chaitanya Bagaria on 11/7/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WePay/WPMockConfig.h>

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
 *  Determines if the transaction should automatically restart after a successful swipe. The transaction is not restarted after a successful dip. Defaults to NO.
 */
@property (nonatomic, assign) BOOL restartTransactionAfterSuccess;

/**
 *  Determines if the transaction should automatically restart after a swipe/dip general error (domain:kWPErrorCategoryCardReader, errorCode:WPErrorCardReaderGeneralError). Defaults to YES.
 */
@property (nonatomic, assign) BOOL restartTransactionAfterGeneralError;

/**
 *  Determines if the transaction should automatically restart after a swipe/dip error other than general error. Defaults to NO.
 */
@property (nonatomic, assign) BOOL restartTransactionAfterOtherErrors;

/**
 *  Determines if the card reader should automatically stop after an operation is completed. Defaults to YES.
 */
@property (nonatomic, assign) BOOL stopCardReaderAfterOperation;

/**
 *  The log level to be used, one of (all, none). Defaults to kWPLogLevelAll.
 */
@property (nonatomic, strong) NSString *logLevel;

/**
 *  The configuration for using mock card reader and/or mock WepayClient implementation
 */
@property (nonatomic, strong) WPMockConfig* mockConfig;

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
 *  @param restartTransactionAfterSuccess       Flag to determine if the transaction should automatically restart after a successful read.
 *  @param restartTransactionAfterGeneralError  Flag to determine if the transaction should automatically restart after a general error (domain:kWPErrorCategoryCardReader, errorCode:WPErrorCardReaderGeneralError).
 *  @param restartTransactionAfterOtherErrors   Flag to determine if the transaction should automatically restart after an error other than general error.
 *  @param stopCardReaderAfterOperation         Flag to determine if the card reader should automatically stop after an operation is completed.
 *
 *  @return A \ref WPConfig instance which can be used to initialize a \ref WePay instance.
 */
- (instancetype) initWithClientId:(NSString *)clientId
                      environment:(NSString *)environment
                      useLocation:(BOOL)useLocation
                  useTestEMVCards:(BOOL)useTestEMVCards
  callDelegateMethodsOnMainThread:(BOOL)callDelegateMethodsOnMainThread
   restartTransactionAfterSuccess:(BOOL)restartTransactionAfterSuccess
restartTransactionAfterGeneralError:(BOOL)restartTransactionAfterGeneralError
restartTransactionAfterOtherErrors:(BOOL)restartTransactionAfterOtherErrors
     stopCardReaderAfterOperation:(BOOL)stopCardReaderAfterOperation
                         logLevel:(NSString *)logLevel;

@end
