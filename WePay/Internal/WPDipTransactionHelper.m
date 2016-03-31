//
//  WPDipTransactionHelper.m
//  WePay
//
//  Created by Chaitanya Bagaria on 11/18/15.
//  Copyright © 2015 WePay. All rights reserved.
//

#if defined(__has_include)
#if __has_include("RPx/MPOSCommunicationManager/RDeviceInfo.h") && __has_include("RUA/RUA.h") && __has_include("G4XSwiper/SwiperController.h")

#import "WePay.h"
#import "WePay_CardReader.h"
#import "WPDipTransactionHelper.h"
#import "WPError+internal.h"
#import "WPRoamHelper.h"

@interface WPDipTransactionHelper ()

#define CRYPTOGRAM_INFORMATION_DATA_00 @"00" // AAC (decline)
#define CRYPTOGRAM_INFORMATION_DATA_40 @"40" // TC  (approve)
#define CRYPTOGRAM_INFORMATION_DATA_80 @"80" // ARQC (online)

#define AUTH_RESPONSE_CODE_ONLINE_APPROVE @"00" // any other code is decline
#define MAGIC_TC @"0123456789ABCDEF"

@property (nonatomic, strong) NSDecimalNumber *amount;
@property (nonatomic, assign) long accountId;
@property (nonatomic, strong) NSString *currencyCode;

@property (nonatomic, assign) BOOL shouldReportSwipedEMVCard;
@property (nonatomic, assign) BOOL isFallbackSwipe;
@property (nonatomic, assign) BOOL shouldIssueReversal;

@property (nonatomic, strong) NSString *selectedAID;
@property (nonatomic, strong) NSString *applicationCryptogram;
@property (nonatomic, strong) NSString *issuerAuthenticationData;
@property (nonatomic, strong) NSString *authResponseCode;
@property (nonatomic, strong) NSString *authCode;
@property (nonatomic, strong) NSString *issuerScriptTemplate1;
@property (nonatomic, strong) NSString *issuerScriptTemplate2;
@property (nonatomic, strong) NSString *creditCardId;
@property (nonatomic, strong) NSError *authorizationError;

@property (nonatomic, strong) NSString *wepayEnvironment;
@property (nonatomic, strong) WPPaymentInfo *paymentInfo;
@property (nonatomic, strong) WPDipConfigHelper *dipConfigHelper;
@property (nonatomic, strong) id<RUADeviceManager> roamDeviceManager;

@property (nonatomic, weak) WPRP350XManager *delegate;
@property (nonatomic, weak) NSObject<WPDeviceManagerDelegate> *managerDelegate;
@property (nonatomic, weak) NSObject<WPExternalCardReaderDelegate> *externalDelegate;

@end

@implementation WPDipTransactionHelper

- (instancetype) initWithConfigHelper:(WPDipConfigHelper *)configHelper
                             delegate:(WPRP350XManager *)delegate
                          environment:(NSString *)environment
{
    if (self = [super init]) {
        self.dipConfigHelper = configHelper;
        self.delegate = delegate;
        self.wepayEnvironment = environment;
    }

    return self;
}


#pragma mark - TransactionStartCommand

- (NSDictionary *)getEMVStartTransactionParameters {
    NSMutableDictionary *transactionParameters = [[NSMutableDictionary alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];

    NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"yyMMdd"];
    [dateFormat setLocale:enUSPOSIXLocale];

    NSDateFormatter *timeFormat = [[NSDateFormatter alloc]init];
    [timeFormat setDateFormat:@"HHmmss"];
    [timeFormat setLocale:enUSPOSIXLocale];

    NSString *dateStr = [dateFormat stringFromDate:[NSDate date]];

    // // // // // // //
    // Required params:
    // // // // // // //

    [transactionParameters setObject:[self convertToEMVCurrencyCode:self.currencyCode] forKey:[NSNumber numberWithInt:RUAParameterTransactionCurrencyCode]];
    [transactionParameters setObject:@"00" forKey:[NSNumber numberWithInt:RUAParameterTransactionType]];

    [transactionParameters setObject:dateStr forKey:[NSNumber numberWithInt:RUAParameterTransactionDate]];
    [transactionParameters setObject:@"E028C8" forKey:[NSNumber numberWithInt:RUAParameterTerminalCapabilities]];
    [transactionParameters setObject:@"22" forKey:[NSNumber numberWithInt:RUAParameterTerminalType]];
    [transactionParameters setObject:@"6000008001" forKey:[NSNumber numberWithInt:RUAParameterAdditionalTerminalCapabilities]];
    [transactionParameters setObject:@"9F3704" forKey:[NSNumber numberWithInt:RUAParameterDefaultValueForDDOL]]; // Input for offline data authentication - this is the typical value
    [transactionParameters setObject:@"59315A3159325A3259335A333030303530313034" forKey:[NSNumber numberWithInt:RUAParameterAuthorizationResponseCodeList]];

    // // // // // // //
    // Optional Params:
    // // // // // // //

    [transactionParameters setObject:@"0840" forKey:[NSNumber numberWithInt:RUAParameterTerminalCountryCode]];
    [transactionParameters setObject:[self convertToEMVAmount:self.amount] forKey:[NSNumber numberWithInt:RUAParameterAmountAuthorizedNumeric]];
    [transactionParameters setObject:@"000000000000" forKey:[NSNumber numberWithInt:RUAParameterAmountOtherNumeric]];

    NSLog(@"getEMVStartTransactionParameters:\n%@", transactionParameters);

    return transactionParameters;
}

- (void) performEMVTransactionStartCommandWithAmount:(NSDecimalNumber *)amount
                                        currencyCode:(NSString *)currencyCode
                                           accountid:(long)accountId
                                   roamDeviceManager:(id<RUADeviceManager>) roamDeviceManager
                                     managerDelegate:(id<WPDeviceManagerDelegate>) managerDeletage
                                    externalDelegate:(id<WPExternalCardReaderDelegate>) externalDelegate

{
    NSLog(@"performEMVTransactionStartCommand");
    
    // save transaction info
    self.amount = amount;
    self.currencyCode = currencyCode;
    self.accountId = accountId;
    self.roamDeviceManager = roamDeviceManager;
    self.externalDelegate = externalDelegate;
    self.managerDelegate = managerDeletage;
    [self startTransaction];
}

- (void) startTransaction
{
    self.shouldReportSwipedEMVCard = NO;
    self.isFallbackSwipe = NO;
    self.shouldIssueReversal = NO;

    self.selectedAID = nil;
    self.authCode = nil;
    self.issuerAuthenticationData = nil;
    self.authResponseCode = nil;
    self.applicationCryptogram = nil;
    self.issuerScriptTemplate1 = nil;
    self.issuerScriptTemplate2 = nil;
    self.creditCardId = nil;
    self.authorizationError = nil;

    id <RUATransactionManager> tmgr = [self.roamDeviceManager getTransactionManager];

    NSDictionary *params = [self getEMVStartTransactionParameters];

    [tmgr sendCommand:RUACommandEMVStartTransaction
       withParameters:params
             progress: ^(RUAProgressMessage messageType, NSString* additionalMessage) {
                 NSLog(@"RUAProgressMessage: %@",[WPRoamHelper RUAProgressMessage_toString:messageType]);
                 switch (messageType) {
                     case RUAProgressMessagePleaseInsertCard:
                         if (self.shouldReportSwipedEMVCard) {
                             // tell the app an emv card was swiped
                             [self.externalDelegate informExternalCardReader:kWPCardReaderStatusShouldNotSwipeEMVCard];
                         } else {
                             // inform delegate we are waiting for card
                             [self.externalDelegate informExternalCardReader:kWPCardReaderStatusWaitingForCard];

                             // next time we get this progress message, it is because user is swiping EMV card
                             self.shouldReportSwipedEMVCard = YES;
                         }
                         break;
                     case RUAProgressMessagePleaseRemoveCard:
                         [self.externalDelegate informExternalCardReader:kWPCardReaderStatusCheckCardOrientation];
                         break;
                     case RUAProgressMessageCardInserted:
                         [self.externalDelegate informExternalCardReader:kWPCardReaderStatusCardDipped];
                         break;
                     case RUAProgressMessageSwipeDetected:
                         [self.externalDelegate informExternalCardReader:kWPCardReaderStatusSwipeDetected];
                         break;
                     case RUAProgressMessageICCErrorSwipeCard:
                         [self.externalDelegate informExternalCardReader:kWPCardReaderStatusChipErrorSwipeCard];
                         self.isFallbackSwipe = YES;
                         break;
                     case RUAProgressMessageSwipeErrorReswipeMagStripe:
                         [self.externalDelegate informExternalCardReader:kWPCardReaderStatusSwipeErrorSwipeAgain];
                         break;
                     default:
                         // Do nothing on progress, react to the response when it comes
                         break;
                 }
             }
             response: ^(RUAResponse *ruaResponse) {
                 NSLog(@"RUAResponse: %@", [WPRoamHelper RUAResponse_toDictionary:ruaResponse]);

                 if ([ruaResponse responseType] == RUAResponseTypeMagneticCardData) {
                     NSMutableDictionary *responseData = [[WPRoamHelper RUAResponse_toDictionary:ruaResponse] mutableCopy];
                     NSString *fullName = [WPRoamHelper fullNameFromRUAData:responseData];

                     [responseData setObject:(fullName ? fullName : [NSNull null]) forKey:@"FullName"];
                     [responseData setObject:kRP350XModelName forKey:@"Model"];
                     [responseData setObject:@(self.isFallbackSwipe) forKey:@"Fallback"];
                     [responseData setObject:@(self.accountId) forKey:@"AccountId"];
                     [responseData setObject:self.currencyCode forKey:@"CurrencyCode"];
                     [responseData setObject:self.amount forKey:@"Amount"];

                     [self.managerDelegate handleSwipeResponse:responseData];

                     NSError *error = [self.managerDelegate validateSwiperInfoForTokenization:responseData];
                     [self reactToError:error forPaymentMethod:kWPPaymentMethodSwipe];

                 } else if ([ruaResponse responseType] == RUAResponseTypeListOfApplicationIdentifiers) {
                     NSArray *appIds = [ruaResponse listOfApplicationIdentifiers];
                     NSMutableArray *appLabels = [@[] mutableCopy];

                     for (RUAApplicationIdentifier *appID in appIds) {
                         [appLabels addObject:appID.applicationLabel];

                     }

                     // call delegate method for app selection
                     [self.externalDelegate informExternalAuthorizationApplications:appLabels
                                                                         completion:^(NSInteger selectedIndex) {
                                                                             if (selectedIndex < 0 || selectedIndex >= [appLabels count]) {
                                                                                 NSError *error = [WPError errorInvalidApplicationId];
                                                                                 [self reportAuthorizationSuccess:nil orError:error forPaymentInfo:self.paymentInfo];
                                                                                 [self reactToError:error];
                                                                             } else {
                                                                                 RUAApplicationIdentifier *selectedAppId = [appIds objectAtIndex:selectedIndex];
                                                                                 [self performSelectAppIdCommand:selectedAppId];
                                                                             }
                                                                         }];

                 } else {
                     [self handleEMVStartTransactionResponse:ruaResponse];
                 }
             }
     ];

    // WORKAROUND: Roam's SDK does not properly handle assigned timeouts. We're working around that by immediately restarting the swiper when it timesout on its own.
    // when Roam fixes their SDK, we should handle timeouts correctly - ie, timeout at the correct time as configured, or never timeout if configured as such.
    // TODO: Roam has fixed their issue. We only need to set the timeout time properly up front //self.restartCardReaderAfterOtherErrors ? TIMEOUT_INFINITE_SEC : TIMEOUT_DEFAULT_SEC

}

/**
 *  Handle EMV Start Transaction response from Roam
 *
 *  @param ruaResponse The response
 */
- (void) handleEMVStartTransactionResponse:(RUAResponse *) ruaResponse
{
    NSDictionary *responseData = [WPRoamHelper RUAResponse_toDictionary:ruaResponse];
    NSError *error = [self validateEMVResponse:responseData];

    if (error != nil) {
        [self reportAuthorizationSuccess:nil orError:error forPaymentInfo:self.paymentInfo];
        [self reactToError:error];
    } else {
        NSString *selectedAID = [responseData objectForKey:[WPRoamHelper RUAParameter_toString:RUAParameterApplicationIdentifier]];
        
        // RUAParameterApplicationIdentifier can be null if application selection was performed
        if (selectedAID != nil && ![selectedAID isEqual:[NSNull null]]) {
            self.selectedAID = selectedAID;
        }
        
        [self performEMVTransactionDataCommand];
    }
}

#pragma mark - SelectAppIdCommand

- (void) performSelectAppIdCommand:(RUAApplicationIdentifier *)selectedAppId {
    if (selectedAppId == nil || [selectedAppId isEqual:[NSNull null]]) {
        NSError *error = [WPError errorInvalidApplicationId];
        [self reportAuthorizationSuccess:nil orError:error forPaymentInfo:self.paymentInfo];
        [self reactToError:error];
    } else {
        // save the selected app id
        self.selectedAID = selectedAppId.aid;
        id <RUATransactionManager> tmgr = [self.roamDeviceManager getTransactionManager];
        NSDictionary *params = @{[NSNumber numberWithInt:RUAParameterApplicationIdentifier]: selectedAppId.aid};
        
        NSLog(@"performSelectAppIdCommandParameters:\n%@", params);
        
        [tmgr  sendCommand:RUACommandEMVFinalApplicationSelection
            withParameters:params
                  progress: ^(RUAProgressMessage messageType, NSString* additionalMessage) {
                      NSLog(@"RUAProgressMessage: %@",[WPRoamHelper RUAProgressMessage_toString:messageType]);
                  }
         
                  response: ^(RUAResponse *ruaResponse) {
                      NSLog(@"RUAResponse: %@", [WPRoamHelper RUAResponse_toDictionary:ruaResponse]);
                      [self handleEMVStartTransactionResponse:ruaResponse];
                  }
         ];
    }
}

#pragma mark - TransactionDataCommand

- (NSDictionary *)getEMVTransactionDataParameters {
    NSMutableDictionary *transactionParameters = [[NSMutableDictionary alloc] init];

    // select TACs based on selected AID
    NSArray *tacs = [self.dipConfigHelper TACsForAID:self.selectedAID];
    NSString *tacDenial = tacs[0];
    NSString *tacOnline = tacs[1];
    NSString *tacDefault = tacs[2];

    // // // // // // //
    // Required params:
    // // // // // // //

    [transactionParameters setObject:@"00000000" forKey:[NSNumber numberWithInt:RUAParameterTerminalFloorLimit]];
    [transactionParameters setObject:@"00000000" forKey:[NSNumber numberWithInt:RUAParameterThresholdvalue]];
    [transactionParameters setObject:@"00" forKey:[NSNumber numberWithInt:RUAParameterTargetpercentage]];
    [transactionParameters setObject:@"00" forKey:[NSNumber numberWithInt:RUAParameterMaximumtargetpercentage]];

    [transactionParameters setObject:tacDenial forKey:[NSNumber numberWithInt:RUAParameterTerminalActionCodeDenial]];
    [transactionParameters setObject:tacOnline forKey:[NSNumber numberWithInt:RUAParameterTerminalActionCodeOnline]];
    [transactionParameters setObject:tacDefault forKey:[NSNumber numberWithInt:RUAParameterTerminalActionCodeDefault]];

    NSLog(@"getEMVTransactionDataParameters:\n%@", transactionParameters);

    return transactionParameters;
}


- (void)performEMVTransactionDataCommand {
    NSLog(@"performEMVTransactionDataCommand");

    id <RUATransactionManager> tmgr = [self.roamDeviceManager getTransactionManager];
    NSDictionary *params = [self getEMVTransactionDataParameters];

    [tmgr sendCommand:RUACommandEMVTransactionData withParameters:params
             progress: ^(RUAProgressMessage messageType, NSString* additionalMessage) {
                 NSLog(@"RUAProgressMessage: %@ %@", [WPRoamHelper RUAProgressMessage_toString:messageType], additionalMessage);
             }

             response: ^(RUAResponse *ruaResponse) {
                 NSLog(@"RUAResponse: %@", [WPRoamHelper RUAResponse_toString:ruaResponse]);

                 [self handleEMVTransactionDataResponse:ruaResponse];
             }
     ];
}

/**
 *  Handle EMV Data Transaction response from Roam
 *
 *  @param ruaResponse The response
 */
- (void) handleEMVTransactionDataResponse:(RUAResponse *) ruaResponse
{
    NSMutableDictionary *responseData = [[WPRoamHelper RUAResponse_toDictionary:ruaResponse] mutableCopy];

    NSString *fullName = [WPRoamHelper fullNameFromRUAData:responseData];
    [responseData setObject:(fullName ? fullName : [NSNull null]) forKey:@"FullName"];
    [responseData setObject:kRP350XModelName forKey:@"Model"];
    [responseData setObject:@(self.accountId) forKey:@"AccountId"];


    NSError *error = [self validateEMVResponse:responseData];

    if (error != nil) {
        [self reportAuthorizationSuccess:nil orError:error forPaymentInfo:self.paymentInfo];
        [self reactToError:error];
    } else {
        // handle success
        if ([ruaResponse responseType] == RUAResponseTypeContactEMVResponseDOL || [ruaResponse responseType] == RUAResponseTypeContactEMVOnlineDOL) {

            NSString *firstName = [WPRoamHelper firstNameFromRUAData:responseData];
            NSString *lastName = [WPRoamHelper lastNameFromRUAData:responseData];
            NSString *pan = [self.managerDelegate sanitizePAN:[responseData objectForKey:@"PAN"]];

            // save application cryptogram for later use
            self.applicationCryptogram = [responseData objectForKey:@"ApplicationCryptogram"];

            NSDictionary *info = @{@"firstName"         : firstName ? firstName : [NSNull null],
                                   @"lastName"          : lastName ? lastName : [NSNull null],
                                   @"paymentDescription": pan ? pan : [NSNull null],
                                   @"emvInfo"           : responseData
                                   };

            self.paymentInfo = [[WPPaymentInfo alloc] initWithEMVInfo:info];

            // return payment info to delegate
            [self.managerDelegate handlePaymentInfo:self.paymentInfo
                                     successHandler:^(NSDictionary *returnData) {
                                         NSString *authCode = [returnData objectForKey:@"authorisation_code"];
                                         if (authCode != nil && ![authCode isEqual:[NSNull null]]) {
                                             self.authCode = [authCode stringByPaddingToLength:12 withString:@"0" startingAtIndex:0];
                                         } else {
                                             // a 12-digit auth code is required, even all-zeros works
                                             self.authCode = [@"" stringByPaddingToLength:12 withString:@"0" startingAtIndex:0];
                                         }

                                         NSString *issuerAuthenticationData = [returnData objectForKey:@"issuer_authentication_data"];
                                         NSString *authResponseCode = [returnData objectForKey:@"authorisation_response_code"];
                                         if ([@"217" isEqualToString:authResponseCode]) {
                                             // 217 is an error code that comes back in case of a processor timeout
                                             // This should be treated as a no-response
                                             authResponseCode = nil;
                                         }


                                         NSNumber *creditCardId = [returnData objectForKey:@"credit_card_id"] == [NSNull null] ? nil : [returnData objectForKey:@"credit_card_id"];

                                         NSString *issuerScriptTemplate1 = [returnData objectForKey:@"issuer_script_template1"];
                                         if (issuerScriptTemplate1 != nil && ![issuerScriptTemplate1 isEqual:[NSNull null]]) {
                                             self.issuerScriptTemplate1 = issuerScriptTemplate1;
                                         }

                                         NSString *issuerScriptTemplate2 = [returnData objectForKey:@"issuer_script_template2"];
                                         if (issuerScriptTemplate2 != nil && ![issuerScriptTemplate2 isEqual:[NSNull null]]) {
                                             self.issuerScriptTemplate2 = issuerScriptTemplate2;
                                         }


                                         [self consumeIssuerAuthenticationData:issuerAuthenticationData
                                                              authResponseCode:authResponseCode
                                                                  creditCardId:[creditCardId stringValue]];
                                     }
                                       errorHandler:^(NSError * error) {
                                           self.authorizationError = error;

                                           [self consumeIssuerAuthenticationData:nil
                                                                authResponseCode:nil
                                                                    creditCardId:nil];
                                       }];

        } else {
            NSLog(@"[performEMVTransactionDataCommand] Stopping, unhandled response");
            NSError *error = [WPError errorInvalidCardData];
            [self reportAuthorizationSuccess:nil orError:error forPaymentInfo:self.paymentInfo];
            [self reactToError:error];
        }
    }
}

- (BOOL) shouldExecuteMagicNumbers
{
    BOOL isMagicSuccessAmount = [@[@(21.61), @(121.61), @(22.61), @(122.61), @(24.61), @(124.61), @(25.61), @(125.61)] containsObject:self.amount];

    // YES, if not in production and amount is magic amount
    return (![kWPEnvironmentProduction isEqualToString:self.wepayEnvironment] && isMagicSuccessAmount);
}

- (void) consumeIssuerAuthenticationData:(NSString *)issuerAuthenticationData
                        authResponseCode:(NSString *)authResponseCode
                            creditCardId:(NSString *)creditCardId
{

    if (issuerAuthenticationData != nil && ![issuerAuthenticationData isEqual:[NSNull null]]) {
        self.issuerAuthenticationData = issuerAuthenticationData;
    } else if ([self shouldExecuteMagicNumbers]) {
        // simulate successful auth when not in production environment.
        self.issuerAuthenticationData = MAGIC_TC;
    }

    if (authResponseCode == nil || [authResponseCode isEqual:[NSNull null]]) {
        if ([self shouldExecuteMagicNumbers]) {
            // simulate successful auth when not in production environment.
            self.authResponseCode = @"00";
        }
    } else {
        self.authResponseCode = authResponseCode;
    }

    if (creditCardId == nil || [creditCardId isEqual:[NSNull null]]) {
        if ([self shouldExecuteMagicNumbers]) {
            // simulate successful auth when not in production environment.
            self.creditCardId = @"1234567890";
        }
    } else {
        self.creditCardId = creditCardId;
    }


    if ([self shouldExecuteMagicNumbers]) {
        // inform external success
        [self reportAuthorizationSuccess:[self createAuthInfoWithTC:MAGIC_TC creditCardId:self.creditCardId] orError:nil forPaymentInfo:self.paymentInfo];
        [self reactToError:nil];

    } else {
        // complete the transaction
        [self performEMVCompleteTransactionCommand];
    }

}

#pragma mark - CompleteTransactionCommand

- (NSDictionary *)getEMVCompleteTransactionParameters {

    NSMutableDictionary *transactionParameters = [[NSMutableDictionary alloc] init];

    if (self.issuerAuthenticationData == nil && self.authResponseCode == nil) {
        // did not go online
        [transactionParameters setObject:@"02" forKey:[NSNumber numberWithInt:RUAParameterResultofOnlineProcess]];
    } else {
        // went online

        // // // // // // //
        // Required params:
        // // // // // // //

        [transactionParameters setObject:@"01" forKey:[NSNumber numberWithInt:RUAParameterResultofOnlineProcess]];

        // this can this be absent in degraded mode?
        if (self.issuerAuthenticationData != nil) {
            [transactionParameters setObject:self.issuerAuthenticationData forKey:[NSNumber numberWithInt:RUAParameterIssuerAuthenticationData]];
        }

        [transactionParameters setObject:[self convertResponseCodeToHexString:self.authResponseCode] forKey:[NSNumber numberWithInt:RUAParameterAuthorizationResponseCode]];

        // // // // // // //
        // Optional params:
        // // // // // // //

        if (self.issuerScriptTemplate1 != nil) {
            [transactionParameters setObject:self.issuerScriptTemplate1 forKey:[NSNumber numberWithInt:RUAParameterIssuerScript1]];
        }

        if (self.issuerScriptTemplate2 != nil) {
            [transactionParameters setObject:self.issuerScriptTemplate2 forKey:[NSNumber numberWithInt:RUAParameterIssuerScript2]];
        }

        if (self.authCode != nil) {
            [transactionParameters setObject:self.authCode forKey:[NSNumber numberWithInt:RUAParameterAuthorizationCode]];
        }
    }

    NSLog(@"getEMVCompleteTransactionParameters:\n%@", transactionParameters);
    return transactionParameters;
}

/**
 *  Completes the transaction
 */
- (void) performEMVCompleteTransactionCommand
{
    NSLog(@"performEMVCompleteTransactionCommand");

    id <RUATransactionManager> tmgr = [self.roamDeviceManager getTransactionManager];
    NSDictionary *params = [self getEMVCompleteTransactionParameters];

    [tmgr  sendCommand:RUACommandEMVCompleteTransaction
        withParameters:params
              progress: ^(RUAProgressMessage messageType, NSString* additionalMessage) {
                  NSLog(@"onCompleteTX RUAProgressMessage: %@ %@", [WPRoamHelper RUAProgressMessage_toString:messageType], additionalMessage);
              }
              response: ^(RUAResponse *ruaResponse) {
                  NSLog(@"onCompleteTX RUAResponse: %@", [WPRoamHelper RUAResponse_toString:ruaResponse]);

                  [self handleEMVCompleteTransactionResponse:ruaResponse];
              }
     ];
}



/**
 *  Handle EMV Complete Transaction response from Roam. This can also be called in case of offline auth to handle the EMV Transaction Data command response.
 *
 *  @param ruaResponse The response
 */
- (void) handleEMVCompleteTransactionResponse:(RUAResponse *) ruaResponse
{
    // get response data
    NSDictionary *responseData = [WPRoamHelper RUAResponse_toDictionary:ruaResponse];
    NSError *error = [self validateEMVResponse:responseData];

    if (error != nil) {
        if (self.shouldIssueReversal) {
            // shouldIssueReversal is set inside the validator
            [self.managerDelegate issueReversalForCreditCardId:@([self.creditCardId longLongValue])
                                                     accountId:@(self.accountId)
                                                  roamResponse:responseData];

        }

        // we found an error, return it
        [self reportAuthorizationSuccess:nil orError:error forPaymentInfo:self.paymentInfo];
        [self reactToError:error];
    } else {
        // handle success
        NSString *tc = [responseData objectForKey:@"ApplicationCryptogram"];

        // inform external success
        [self reportAuthorizationSuccess:[self createAuthInfoWithTC:tc creditCardId:self.creditCardId] orError:nil forPaymentInfo:self.paymentInfo];
        [self reactToError:nil];
    }
}

- (WPAuthorizationInfo *) createAuthInfoWithTC:(NSString *)tc creditCardId:(NSString *)creditCardId
{
    // build a transaction token by using the formula: base64("tc"+delimiter+"credit_card_id")
    NSString *compoundedString = [NSString stringWithFormat:@"%@+%@", tc, creditCardId];
    NSString *transactionToken = [[compoundedString dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];

    WPAuthorizationInfo *authInfo =
    [[WPAuthorizationInfo alloc] initWithAmount:self.amount
                                   currencyCode:self.currencyCode
                               transactionToken:transactionToken
                                        tokenId:creditCardId];

    return authInfo;
}

#pragma mark - stopTransaction

- (void) stopTransactionWithCompletion:(void (^)(void))completion
{
    id <RUATransactionManager> tmgr = [self.roamDeviceManager getTransactionManager];

    [tmgr sendCommand:RUACommandEMVTransactionStop withParameters:nil
             progress: ^(RUAProgressMessage messageType, NSString* additionalMessage) {
                 NSLog(@"onStopTX RUAProgressMessage: %@",[WPRoamHelper RUAProgressMessage_toString:messageType]);
             }
             response: ^(RUAResponse *ruaResponse) {
                 NSLog(@"onStopTX RUAResponseMessage: %@",[WPRoamHelper RUAResponse_toDictionary:ruaResponse]);
                 if (completion != nil) {
                     completion();
                 }
             }
     ];
}


#pragma mark - EMV Helpers

- (NSError *) validateEMVResponse:(NSDictionary*) responseData
{
    NSError *error = nil;
    NSString *errorCode = [responseData objectForKey: @"ErrorCode"];

    // TODO: use [WPError errorWithCardReaderResponseData]
    if (errorCode != nil ) {
        if ([errorCode isEqualToString:[WPRoamHelper RUAErrorCode_toString:RUAErrorCodeRSAKeyNotFound]]) {
            error = [WPError errorCardNotSupported];
        } else if ([errorCode isEqualToString:[WPRoamHelper RUAErrorCode_toString:RUAErrorCodeNonEMVCardOrCardError]]) {
            // This is only known to happen when "Conditions of Use Not Satisfied" e.g. geographical restrictions.
            error = [WPError errorCardNotSupported];
        } else if ([errorCode isEqualToString:[WPRoamHelper RUAErrorCode_toString:RUAErrorCodeApplicationBlocked]]) {
            error = [WPError errorCardBlocked];
        } else if ([errorCode isEqualToString:[WPRoamHelper RUAErrorCode_toString:RUAErrorCodeTimeoutExpired]]) {
            error = [WPError errorForCardReaderTimeout];
        } else {
            // TODO: define more specific errors
            error = [WPError errorForEMVTransactionErrorWithMessage:errorCode];
        }
    } else {
        //no error, but response may still be invalid for us.

        // check cryptogram
        NSString *command = [responseData objectForKey:[WPRoamHelper RUAParameter_toString:RUAParameterCommand]];
        NSString *cryptogramInformationData = [responseData objectForKey:[WPRoamHelper RUAParameter_toString:RUAParameterCryptogramInformationData]];

        BOOL isCompleteTx = [command isEqualToString:[WPRoamHelper RUACommand_toString:RUACommandEMVCompleteTransaction]];
        BOOL isTxData = [command isEqualToString:[WPRoamHelper RUACommand_toString:RUACommandEMVTransactionData]];
        BOOL isCardDecline = [cryptogramInformationData isEqualToString:CRYPTOGRAM_INFORMATION_DATA_00];
        BOOL isIssuerReachable = (self.authResponseCode != nil);
        BOOL isIssuerDecline = (self.authResponseCode != nil) && ![self.authResponseCode isEqualToString:AUTH_RESPONSE_CODE_ONLINE_APPROVE]; // non-nil code that is NOT the approval code "00"

        if (isCompleteTx && !isIssuerReachable) {
            // could not reach issuer, should be declined, even if card approves
            // If an error was returned, use it. Otherwise create a generic error.
            error  = (self.authorizationError != nil) ? self.authorizationError : [WPError errorIssuerUnreachable];
        } else if (isCompleteTx && isIssuerDecline && isCardDecline) {
            // online decline, card confirmed decline
            error = [WPError errorDeclinedByIssuer];
        } else if (isCompleteTx && isIssuerReachable && isCardDecline) {
            // online approved, declined by card
            error = [WPError errorDeclinedByCard];

            // must issue reversal here
            self.shouldIssueReversal = YES;
        } else if (isCompleteTx && !isIssuerReachable && isCardDecline) {
            // issuer unreachable, declined by card
            error = [WPError errorIssuerUnreachable];
        } else if (isTxData && isCardDecline) {
            // offline declined
            error = [WPError errorDeclinedByCard];
        }
    }
    
    return error;
}

- (void) reportAuthorizationSuccess:(WPAuthorizationInfo *)authInfo orError:(NSError *)error forPaymentInfo:(WPPaymentInfo *)paymentInfo
{
    if (authInfo != nil) {
        [self.externalDelegate informExternalAuthorizationSuccess:authInfo forPaymentInfo:paymentInfo];
    } else if (error != nil) {
        if (paymentInfo != nil) {
            [self.externalDelegate informExternalAuthorizationFailure:error forPaymentInfo:paymentInfo];
        } else {
            [self.externalDelegate informExternalCardReaderFailure:error];
        }
    }
}

- (void) reactToError:(NSError *)error
{
    [self reactToError:error forPaymentMethod:kWPPaymentMethodDip];
}

- (void) reactToError:(NSError *)error forPaymentMethod:(NSString *)paymentMethod
{
    if ([self.delegate shouldKeepWaitingForCardAfterError:error forPaymentMethod:paymentMethod]) {
        // restart transaction
        [self startTransaction];
    } else {
        // stop reader
        [self.delegate stopDevice];
    }
}

- (NSString *) convertToEMVAmount:(NSDecimalNumber *)amount
{
    int intAmount = [[amount decimalNumberByMultiplyingByPowerOf10:2] intValue];
    return [NSString stringWithFormat:@"%012d", intAmount];
}

- (NSString *) convertToEMVCurrencyCode:(NSString *) currencyCode
{
    if ([@"USD" isEqualToString:currencyCode]) {
        return @"0840";
    }
    
    //default
    return nil;
}

- (NSString *) convertResponseCodeToHexString:(NSString *)responseCode
{
    NSString *result = @"";
    
    unsigned long len = [responseCode length];
    unichar buffer[len];
    
    [responseCode getCharacters:buffer range:NSMakeRange(0, len)];
    
    for(int i = 0; i < len; ++i) {
        char current = buffer[i];
        result = [result stringByAppendingString:[NSString stringWithFormat:@"%X", current]];
    }
    
    return result;
}

@end

#endif
#endif