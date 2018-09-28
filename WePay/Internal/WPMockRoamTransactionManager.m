//
//  WPMockRoamTransactionManager.m
//  WePay
//
//  Created by Jianxin Gao on 7/15/16.
//  Copyright © 2016 WePay. All rights reserved.
//
#if defined(__has_include)
#if __has_include("RUA_MFI/RUA.h")

#import "WPMockRoamTransactionManager.h"
#import "WPMockConfig.h"
#import "WePay.h"

#define PAN1 @"0000111100001111"
#define PAN2 @"0000111100002222"
#define PAN3 @"0000111100003333"
#define PAN4 @"0000111100004444"
#define CARD_HOLDER_NAME @"LAST/FIRST"
#define KSN @"FFFFFF81000133400052"
#define FORMAT_ID @"32"
#define ENCRYPTED_TRACK @"85D0FFBF60286CB3069AA8F751CCC4835CA0E52630FD88261139A28BCF4E4E7FF2FBC0930EDE96D4F893611B62DF49BF249CE2378DE919E7C01FC13726BF314973207869BC1BC9FAACBA187A65B533D47F8D2650F8C55DB5840F5149C5EDDDEA0455E5798FB3285C455BA8D985327B7A"
#define ENCRYPTED_TRACK_BAD @"xxxxFFBF60286CB3069AA8F751CCC4835CA0E52630FD88261139A28BCF4E4E7FF2FBC0930EDE96D4F893611B62DF49BF249CE2378DE919E7C01FC13726BF314973207869BC1BC9FAACBA187A65B533D47F8D2650F8C55DB5840F5149C5EDDDEA0455E5798FB3285C455BA8D985327B7A"
#define AID_VISA @"A000000003"
#define APPLICATION_INTERCHANGE_PROFILE @"5C00"
#define TERMINAL_VERIFICATION_RESULTS @"0080008000"
#define APPLICATION_IDENTIFIER @"A0000000031010"
#define ISSUER_APPLICATION_DATA @"06010A03A00000"
#define APPLICATION_CRYPTOGRAM @"D08AAF84DB5C5CE9"
#define CRYPTOGRAM_INFORMATION_DATA @"80"
#define APPLICATION_TRANSACTION_COUNTER @"0001"
#define UNPREDICTABLE_NUMBER @"80C2328D"

BOOL emvAppAlreadySelected = NO;
int selectedAppIndex = -1;
NSString *transactionDate = nil;
NSString *transactionType = nil;
NSString *transactionCurrencyCode = nil;
NSString *amountAuthorized = nil;
NSString *terminalCountryCode = nil;

@implementation WPMockRoamTransactionManager

- (instancetype) init
{
    if (self = [super init]) {
        self.mockCommandErrorCode = RUAErrorCodeUnknownError;
    }
    
    return self;
}

- (void) resetStates
{
    emvAppAlreadySelected = NO;
    selectedAppIndex = -1;
    transactionDate = nil;
    transactionType = nil;
    transactionCurrencyCode = nil;
    amountAuthorized = nil;
    terminalCountryCode = nil;
}

- (void) waitForCardRemoval:(NSInteger)cardRemovalTimeout response:(OnResponse)response {}

- (void) waitForMagneticCardSwipe:(OnProgress)progress response:(OnResponse)response {}

- (void) stopWaitingForMagneticCardSwipe {}

- (void) sendCommand:(RUACommand)command withParameters:(NSDictionary *)parameters progress:(OnProgress)progress response:(OnResponse)response
{
    progress(RUAProgressMessageCommandSent, nil);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *mockPaymentMethod = self.mockConfig.mockPaymentMethod;
        RUAResponse *ruaResponse = [[RUAResponse alloc] init];
        ruaResponse.command = command;
        ruaResponse.responseCode = RUAResponseCodeSuccess;
        switch (command) {
            case RUACommandEMVStartTransaction:
                
                progress(RUAProgressMessagePleaseInsertCard, nil);
                
                if ([mockPaymentMethod isEqualToString:kWPPaymentMethodDip]) {
                    progress(RUAProgressMessageCardInserted, nil);
                } else {
                    progress(RUAProgressMessageSwipeDetected, nil);
                }
                
                if (self.mockConfig.cardReadFailure) {
                    ruaResponse.responseCode = RUAResponseCodeError;
                    ruaResponse.responseType = RUAResponseTypeUnknown;
                    ruaResponse.errorCode = self.mockCommandErrorCode;
                    break;
                }
                
                transactionDate = [parameters objectForKey:[NSNumber numberWithInteger:RUAParameterTransactionDate]];
                transactionType = [parameters objectForKey:[NSNumber numberWithInteger:RUAParameterTransactionType]];
                transactionCurrencyCode = [parameters objectForKey:[NSNumber numberWithInteger:RUAParameterTransactionCurrencyCode]];
                amountAuthorized = [parameters objectForKey:[NSNumber numberWithInteger:RUAParameterAmountAuthorizedNumeric]];
                terminalCountryCode = [parameters objectForKey:[NSNumber numberWithInteger:RUAParameterTerminalCountryCode]];
                
                if (self.mockConfig.multipleEMVApplication && !emvAppAlreadySelected) {
                    ruaResponse.responseType = RUAResponseTypeListOfApplicationIdentifiers;
                    ruaResponse.listOfApplicationIdentifiers = [[self class] getAppIdArray];
                    
                    emvAppAlreadySelected = YES;
                    break;
                }
                
                if ([mockPaymentMethod isEqualToString:kWPPaymentMethodDip]) {
                    ruaResponse.responseType = RUAResponseTypeContactEMVAmountDOL;
                    NSMutableDictionary *responseData = [@{} mutableCopy];
                    [responseData setObject:AID_VISA forKey:[NSNumber numberWithInteger:RUAParameterApplicationIdentifier]];
                    ruaResponse.responseData = responseData;
                } else {
                    // mockPaymentMethod defaults to Swipe, if not set explicitly
                    ruaResponse.responseType = RUAResponseTypeMagneticCardData;
                    NSMutableDictionary *responseData = [@{} mutableCopy];
                    [responseData setObject:KSN forKey:[NSNumber numberWithInteger:RUAParameterKSN]];
                    [responseData setObject:FORMAT_ID forKey:[NSNumber numberWithInteger:RUAParameterFormatID]];
                    [responseData setObject:PAN1 forKey:[NSNumber numberWithInteger:RUAParameterPAN]];
                    [responseData setObject:CARD_HOLDER_NAME forKey:[NSNumber numberWithInteger:RUAParameterCardHolderName]];
                    if (self.mockConfig.cardTokenizationFailure) {
                        [responseData setObject:ENCRYPTED_TRACK_BAD forKey:[NSNumber numberWithInteger:RUAParameterEncryptedTrack]];
                    } else {
                        [responseData setObject:ENCRYPTED_TRACK forKey:[NSNumber numberWithInteger:RUAParameterEncryptedTrack]];
                    }
                    
                    ruaResponse.responseData = responseData;
                }
                break;
            case RUACommandEMVTransactionData:
            {
                ruaResponse.responseType = RUAResponseTypeContactEMVResponseDOL;
                NSMutableDictionary *responseData = [@{} mutableCopy];
                if (emvAppAlreadySelected && selectedAppIndex != -1) {
                    NSString *selected = [[[self class] getPANs] objectAtIndex:selectedAppIndex];
                    [responseData setObject:selected forKey:[NSNumber numberWithInteger:RUAParameterPAN]];
                } else {
                    [responseData setObject:PAN1 forKey:[NSNumber numberWithInteger:RUAParameterPAN]];
                }
                [responseData setObject:CARD_HOLDER_NAME forKey:[NSNumber numberWithInteger:RUAParameterCardHolderName]];
                [responseData setObject:ENCRYPTED_TRACK forKey:[NSNumber numberWithInteger:RUAParameterEncryptedTrack]];
                [responseData setObject:KSN forKey:[NSNumber numberWithInteger:RUAParameterKSN]];
                [responseData setObject:FORMAT_ID forKey:[NSNumber numberWithInteger:RUAParameterFormatID]];
                // other DIP specific parameters:
                [responseData setObject:APPLICATION_INTERCHANGE_PROFILE forKey:[NSNumber numberWithInteger:RUAParameterApplicationInterchangeProfile]];
                [responseData setObject:TERMINAL_VERIFICATION_RESULTS forKey:[NSNumber numberWithInteger:RUAParameterTerminalVerificationResults]];
                [responseData setObject:transactionDate forKey:[NSNumber numberWithInteger:RUAParameterTransactionDate]];
                [responseData setObject:transactionType forKey:[NSNumber numberWithInteger:RUAParameterTransactionType]];
                [responseData setObject:transactionCurrencyCode forKey:[NSNumber numberWithInteger:RUAParameterTransactionCurrencyCode]];
                [responseData setObject:APPLICATION_IDENTIFIER forKey:[NSNumber numberWithInteger:RUAParameterApplicationIdentifier]];
                [responseData setObject:ISSUER_APPLICATION_DATA forKey:[NSNumber numberWithInteger:RUAParameterIssuerApplicationData]];
                [responseData setObject:terminalCountryCode forKey:[NSNumber numberWithInteger:RUAParameterTerminalCountryCode]];
                [responseData setObject:APPLICATION_CRYPTOGRAM forKey:[NSNumber numberWithInteger:RUAParameterApplicationCryptogram]];
                [responseData setObject:CRYPTOGRAM_INFORMATION_DATA forKey:[NSNumber numberWithInteger:RUAParameterCryptogramInformationData]];
                [responseData setObject:APPLICATION_TRANSACTION_COUNTER forKey:[NSNumber numberWithInteger:RUAParameterApplicationTransactionCounter]];
                [responseData setObject:UNPREDICTABLE_NUMBER forKey:[NSNumber numberWithInteger:RUAParameterUnpredictableNumber]];
                [responseData setObject:amountAuthorized forKey:[NSNumber numberWithInteger:RUAParameterAmountAuthorizedNumeric]];
                
                ruaResponse.responseData = responseData;
                break;
            }
            case RUACommandEMVCompleteTransaction:
                ruaResponse.responseType = RUAResponseTypeUnknown;
                break;
            case RUACommandEMVTransactionStop:
                ruaResponse.responseType = RUAResponseTypeUnknown;
                break;
            case RUACommandEMVFinalApplicationSelection:
            {
                ruaResponse.responseType = RUAResponseTypeUnknown;
                NSString *selectedAID = [parameters objectForKey:[NSNumber numberWithInt:RUAParameterApplicationIdentifier]];
                // last four digits of AID is PIX (Priority Index)
                NSString *lastFourDigits = [selectedAID substringFromIndex:(selectedAID.length - 4)];
                if ([@"1010" isEqualToString:lastFourDigits]) {
                    selectedAppIndex = 0;
                } else if ([@"2010" isEqualToString:lastFourDigits]) {
                    selectedAppIndex = 1;
                } else if ([@"2020" isEqualToString:lastFourDigits]) {
                    selectedAppIndex = 2;
                } else {
                    selectedAppIndex = 3;
                }
            }
                break;
                
            default:
                break;
        }
        
        response(ruaResponse);
    });
}

- (void) cancelLastCommand {}

#pragma mark - (private)

+ (NSArray *) getAppIdArray
{
    static NSArray *appIds;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        RUAApplicationIdentifier *appId1 = [[RUAApplicationIdentifier alloc] init];
        appId1.aid = AID_VISA;
        appId1.pix = @"1010";
        appId1.applicationLabel = @"Label 1";
        
        RUAApplicationIdentifier *appId2 = [[RUAApplicationIdentifier alloc] init];
        appId2.aid = AID_VISA;
        appId2.pix = @"2010";
        appId2.applicationLabel = @"Label 2";
        
        RUAApplicationIdentifier *appId3 = [[RUAApplicationIdentifier alloc] init];
        appId3.aid = AID_VISA;
        appId3.pix = @"2020";
        appId3.applicationLabel = @"Label 3";
        
        RUAApplicationIdentifier *appId4 = [[RUAApplicationIdentifier alloc] init];
        appId4.aid = AID_VISA;
        appId4.pix = @"8010";
        appId4.applicationLabel = @"Label 4";
        
        appIds = @[appId1, appId2, appId3, appId4];
    });
    
    return appIds;
}

+ (NSArray *) getPANs
{
    static NSArray *pans;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pans = @[PAN1, PAN2, PAN3, PAN4];
    });
    return pans;
}
@end

#endif
#endif
