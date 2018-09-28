//
//  WPMockRoamConfigurationManager.m
//  WePay
//
//  Created by Jianxin Gao on 7/15/16.
//  Copyright © 2016 WePay. All rights reserved.
//
#if defined(__has_include)
#if __has_include("RUA_MFI/RUA.h")

#import "WPMockRoamConfigurationManager.h"

#define SERIAL_NUMBER @"S6RP350X50X-02?15271RP1000136500"
#define TERMINAL_CAPABILITIES @"19C3000000000100000000010053365250333530583530582D30323F313532373152503130303031333635303000"

@implementation WPMockRoamConfigurationManager

- (BOOL) activateDevice:(RUADevice *)device
{
    return YES;
}

- (void) clearAIDSList:(OnProgress)progress response:(OnResponse)response
{
    [self returnFromReaderWithRUACommand:RUACommandClearAIDsList withProgress:progress andResponse:response];
}

- (void) clearPublicKeys:(OnProgress)progress response:(OnResponse)response
{
    [self returnFromReaderWithRUACommand:RUACommandClearPublicKeys withProgress:progress andResponse:response];
}

- (void) generateBeep:(OnProgress)progress response:(OnResponse)response {}

- (void) getReaderCapabilities:(OnProgress)progress response:(OnResponse)response
{
    dispatch_async(dispatch_get_main_queue(), ^{
        RUAResponse *ruaResponse = [[RUAResponse alloc] init];
        ruaResponse.command = RUACommandReadCapabilities;
        ruaResponse.responseType = RUAResponseTypeUnknown;
        ruaResponse.responseCode = RUAResponseCodeSuccess;
        NSDictionary *data = @{
                               @(RUAParameterInterfaceDeviceSerialNumber) : SERIAL_NUMBER,
                               @(RUAParameterTerminalCapabilities) : TERMINAL_CAPABILITIES
                               };
        ruaResponse.responseData = data;
        progress(RUAProgressMessageCommandSent, nil);
        response(ruaResponse);
    });
}

- (void) readVersion:(OnProgress)progress response:(OnResponse)response {}

- (void) resetDevice:(OnProgress)progress response:(OnResponse)response {}

- (void) retrieveKSN:(OnProgress)progress response:(OnResponse)response {}

- (void) revokePublicKey:(RUAPublicKey *)key progress:(OnProgress)progress response:(OnResponse)response {}

- (void) setAmountDOL:(NSArray *)list progress:(OnProgress)progress response:(OnResponse)response
{
    [self returnFromReaderWithRUACommand:RUACommandConfigureAmountDOLData withProgress:progress andResponse:response];
}

- (void) setExpectedAmountDOL:(NSArray *)list {}

- (void) setCommandTimeout:(int)timeout {}

- (void) setOnlineDOL:(NSArray *)list progress:(OnProgress)progress response:(OnResponse)response
{
    [self returnFromReaderWithRUACommand:RUACommandConfigureOnlineDOLData withProgress:progress andResponse:response];
}

- (void) setExpectedOnlineDOL:(NSArray *)list {}

- (void) setResponseDOL:(NSArray *)list progress:(OnProgress)progress response:(OnResponse)response
{
    [self returnFromReaderWithRUACommand:RUACommandConfigureResponseDOLData withProgress:progress andResponse:response];
}

- (void) setExpectedResponseDOL:(NSArray *)list {}

- (void) setUserInterfaceOptions:(OnProgress)progress response:(OnResponse)response
{
    [self returnFromReaderWithRUACommand:RUACommandConfigureUserInterfaceOptions withProgress:progress andResponse:response];
}

- (void) setUserInterfaceOptions:(int) cardInsertionTimeout
         withDefaultLanguageCode:(RUALanguageCode)languageCode
               withPinPadOptions:(Byte) pinPadOptions
            withBackLightControl:(Byte) backlightControl
                        progress:(OnProgress)progress
                        response:(OnResponse)response
{
    [self setUserInterfaceOptions:progress response:response];
}

- (void) setUserInterfaceOptions:(int) cardInsertionTimeout
         withDefaultLanguageCode:(RUALanguageCode)languageCode
   withCardHolderLanguageSupport:(BOOL) cardHolderLanguageSupport
      withSupportedLanguageCodes:(NSArray *) supportedLanguageCodes
               withPinPadOptions:(Byte) pinPadOptions
            withBackLightControl:(Byte) backlightControl
    withCurrencyFormattingOption:(Byte) currencyFormattingOption
      withCurrencyGroupingOption:(Byte) currencyGroupingOption
                        progress:(OnProgress)progress
                        response:(OnResponse)response
{
    [self setUserInterfaceOptions:progress response:response];
}

- (void) submitAIDList:(NSArray *)aids progress:(OnProgress)progress response:(OnResponse)response
{
    [self returnFromReaderWithRUACommand:RUACommandSubmitAIDsList withProgress:progress andResponse:response];
}

- (void) submitPublicKey:(RUAPublicKey *)publicKey progress:(OnProgress)progress response:(OnResponse)response
{
    [self returnFromReaderWithRUACommand:RUACommandSubmitPublicKey withProgress:progress andResponse:response];
}

- (void) sendRawCommand:(NSString *)rawCommand progress:(OnProgress)progress response:(OnResponse)response {}

- (id<RUADisplayControl>) getDisplayControl
{
    return nil;
}

- (id<RUAKeypadControl>) getKeypadControl
{
    return nil;
}

- (void) loadSessionKey:(int) keyLength
  withSessionKeyLocator: (NSString *) sessionKeyLocator
   withMasterKeyLocator: (NSString *) masterKeyLocator
       withEncryptedKey:(NSString *) encryptedKey
         withCheckValue: (NSString *) checkValue
                 withId:(NSString *) ID
               response:(OnResponse)response {}

- (void) setContactlessResponseDOL:(NSArray *)list progress:(OnProgress)progress response:(OnResponse)response {}

- (void) setExpectedContactlessResponseDOL:(NSArray *)list {}

- (void) setContactlessOnlineDOL:(NSArray *)list progress:(OnProgress)progress response:(OnResponse)response {}

- (void) setExpectedContactlessOnlineDOL:(NSArray *)list {}

- (void) submitContactlessAIDList:(NSArray *)aids progress:(OnProgress)progress response:(OnResponse)response {}

- (void) enableContactless:(OnResponse)response {}

- (void) disableContactless:(OnResponse)response {}

- (void) configureContactlessTransactionOptions: (BOOL) supportCVM
                                    supportAMEX: (BOOL) supportAMEX
                             enableCryptogram17: (BOOL) enableCryptogram17
                         enableOnlineCryptogram: (BOOL) enableOnlineCryptogram
                                   enableOnline: (BOOL) enableOnline
                                enableMagStripe: (BOOL) enableMagStripe
                                  enableMagChip: (BOOL) enableMagChip
                                    enableQVSDC: (BOOL) enableQVSDC
                                      enableMSD: (BOOL) enableMSD
                  contactlessOutcomeDisplayTime: (int) contactlessOutcomeDisplayTime
                                       response: (OnResponse) response {}

- (void) setEnergySaverModeTime:(int)seconds res:(OnResponse)response {}

- (void) setShutDownModeTime:(int)seconds res:(OnResponse)response {}

- (void) returnFromReaderWithRUACommand:(RUACommand) command
                           withProgress:(OnProgress)progress
                            andResponse:(OnResponse)response
{
    dispatch_async(dispatch_get_main_queue(), ^{
        RUAResponse *ruaResponse = [[RUAResponse alloc] init];
        ruaResponse.command = command;
        ruaResponse.responseType = RUAResponseTypeUnknown;
        ruaResponse.responseCode = RUAResponseCodeSuccess;
        if (progress != nil) {
            progress(RUAProgressMessageCommandSent, nil);
        }
        response(ruaResponse);
    });
}

- (void) readKeyMapping:(OnProgress)progress response:(OnResponse)response {}

- (void) readCertificateFilesVersion:(OnProgress)progress response:(OnResponse)response {}

- (void) enableRKIMode:(OnResponse)response {}

- (void) triggerRKIWithGroupName:(NSString *)groupName progress:(OnProgress)progress response:(OnResponse)response {}

- (void) configureContactlessTransactionOptions:(BOOL)supportCVM
                                   supportAMEX:(BOOL)supportAMEX
                            enableCryptogram17:(BOOL)enableCryptogram17
                        enableOnlineCryptogram:(BOOL)enableOnlineCryptogram
                                  enableOnline:(BOOL)enableOnline
                               enableMagStripe:(BOOL)enableMagStripe
                                 enableMagChip:(BOOL)enableMagChip
                                   enableQVSDC:(BOOL)enableQVSDC
                                     enableMSD:(BOOL)enableMSD
                                 enableDPASEMV:(BOOL)enableDPASEMV
                                 enableDPASMSR:(BOOL)enableDPASMSR
                 contactlessOutcomeDisplayTime:(int)contactlessOutcomeDisplayTime
                                      response:(OnResponse)response {}

@end

#endif
#endif
