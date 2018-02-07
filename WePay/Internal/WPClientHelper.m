//
//  WPClientHelper.m
//  WePay
//
//  Created by Chaitanya Bagaria on 11/18/15.
//  Copyright © 2015 WePay. All rights reserved.
//

#import "WPClientHelper.h"

@implementation WPClientHelper

/**
 *  Converts payment info from a card reader into request params for a create_swipe / create_emv request
 *
 *  @param paymentInfo The swiped payment info
 *
 *  @return The request params
 */
+ (NSDictionary *) createCardRequestParamsForPaymentInfo:(WPPaymentInfo *)paymentInfo
                                                clientId:(NSString *)clientId
                                               sessionId:(NSString *)sessionId

{
    NSMutableDictionary *requestParams;
    NSDictionary *cardInfo = nil;

    if (paymentInfo.emvInfo != nil) {
        cardInfo = paymentInfo.emvInfo;
        requestParams = [[self createDipSpecificRequestParamsForCardInfo:cardInfo] mutableCopy];
    } else {
        cardInfo = paymentInfo.swiperInfo;
        requestParams = [[self createSwipeSpecificRequestParamsForCardInfo:cardInfo] mutableCopy];
    }

    ////////////////////////////
    // COMMON PARAMS
    ////////////////////////////

    [requestParams setObject:clientId forKey:@"client_id"];

    [requestParams setObject:[cardInfo objectForKey:@"FullName"] forKey:@"user_name"];
    [requestParams setObject:[cardInfo objectForKey:@"EncryptedTrack"] forKey:@"encrypted_track"];
    [requestParams setObject:[cardInfo objectForKey:@"KSN"] forKey:@"ksn"];
    [requestParams setObject:[cardInfo objectForKey:@"Model"] forKey:@"model"];
    [requestParams setObject:[cardInfo objectForKey:@"AccountId"] forKey:@"account_id"];

    NSString *track1Status = [cardInfo objectForKey:@"track1Status"] ? [cardInfo objectForKey:@"track1Status"] : @"0";
    NSString *track2Status = [cardInfo objectForKey:@"track2Status"] ? [cardInfo objectForKey:@"track2Status"] : @"0";
    [requestParams setObject:track1Status forKey:@"track_1_status"];
    [requestParams setObject:track2Status forKey:@"track_2_status"];

    ////////////////////////////
    // OPTIONAl PARAMS
    ////////////////////////////

    if (sessionId) {
        [requestParams setObject:sessionId forKey:@"device_token"];
    }

    if (paymentInfo.email) {
        [requestParams setObject:paymentInfo.email forKey:@"email"];
    }

    NSNumber *fallback = [cardInfo objectForKey:@"Fallback"];
    if (fallback != nil && ![fallback isEqual:[NSNull null]]) {
        [requestParams setObject:fallback forKey:@"emv_fallback"];
    }
    
    WPLog(@"%@", requestParams);
    
    return requestParams;
}

+ (NSDictionary *) reversalRequestParamsForCardInfo:(NSDictionary *)cardInfo
                                           clientId:(NSString *)clientId
                                       creditCardId:(NSNumber *)creditCardId
                                          accountId:(NSNumber *)accountId
{
    NSMutableDictionary *requestParams = [@{} mutableCopy];
    NSDictionary *emvParams = [self buildEMVTagParamsForCardInfo:cardInfo];

    [requestParams setObject:emvParams forKey:@"emv"];
    [requestParams setObject:clientId forKey:@"client_id"];
    [requestParams setObject:accountId forKey:@"account_id"];
    [requestParams setObject:creditCardId forKey:@"credit_card_id"];

    return requestParams;
}

#pragma mark - private

+ (NSDictionary *) createSwipeSpecificRequestParamsForCardInfo:(NSDictionary *)cardInfo
{
    NSMutableDictionary *requestParams = [@{} mutableCopy];
    NSString *formatID = [cardInfo objectForKey:@"FormatID"] ? [cardInfo objectForKey:@"FormatID"] : @"32";

    [requestParams setObject:[cardInfo objectForKey:@"Amount"] forKey:@"amount"];
    [requestParams setObject:[cardInfo objectForKey:@"CurrencyCode"] forKey:@"currency_code"];
    [requestParams setObject:formatID forKey:@"format_id"];

    return requestParams;
}


+ (NSDictionary *) createDipSpecificRequestParamsForCardInfo:(NSDictionary *)cardInfo
{
    NSMutableDictionary *requestParams = [@{} mutableCopy];

    NSString *formatID = [cardInfo objectForKey:@"FormatID"] ? [cardInfo objectForKey:@"FormatID"] : @"99";

    // Decryption fails if 77 or 78 is used, and works if 99 is used.
    // We can remove this workaround after Roam fixes the decryption service
    if ([@"77" isEqualToString:formatID] || [@"78" isEqualToString:formatID]) {
        formatID = @"99";
    }

    [requestParams setObject:formatID forKey:@"format_id"];

    // set emv tag params
    NSDictionary *emvParams = [self buildEMVTagParamsForCardInfo:cardInfo];
    [requestParams setObject:emvParams forKey:@"emv"];

    return requestParams;
}


+ (NSDictionary *) buildEMVTagParamsForCardInfo:(NSDictionary *)cardInfo
{
    NSMutableDictionary *emvParams = [@{} mutableCopy];

    [emvParams setObject:[cardInfo objectForKey:@"ApplicationInterchangeProfile"] forKey:@"application_interchange_profile"];
    [emvParams setObject:[cardInfo objectForKey:@"TerminalVerificationResults"] forKey:@"terminal_verification_results"];
    [emvParams setObject:[cardInfo objectForKey:@"TransactionDate"] forKey:@"transaction_date"];
    [emvParams setObject:[cardInfo objectForKey:@"TransactionType"] forKey:@"transaction_type"];
    [emvParams setObject:[cardInfo objectForKey:@"TransactionCurrencyCode"] forKey:@"transaction_currency_code"];
    [emvParams setObject:[cardInfo objectForKey:@"AmountAuthorizedNumeric"] forKey:@"amount_authorised"];
    [emvParams setObject:[cardInfo objectForKey:@"ApplicationIdentifier"] forKey:@"application_identifier"];
    [emvParams setObject:[cardInfo objectForKey:@"IssuerApplicationData"] forKey:@"issuer_application_data"];
    [emvParams setObject:[cardInfo objectForKey:@"TerminalCountryCode"] forKey:@"terminal_country_code"];
    [emvParams setObject:[cardInfo objectForKey:@"ApplicationCryptogram"] forKey:@"application_cryptogram"];
    [emvParams setObject:[cardInfo objectForKey:@"CryptogramInformationData"] forKey:@"cryptogram_information_data"];
    [emvParams setObject:[cardInfo objectForKey:@"ApplicationTransactionCounter"] forKey:@"application_transaction_counter"];
    [emvParams setObject:[cardInfo objectForKey:@"UnpredictableNumber"] forKey:@"unpredictable_number"];

    ////////////////////////////
    // OPTIONAl PARAMS
    ////////////////////////////

    NSString *panSequenceNumber = [cardInfo objectForKey:@"PANSequenceNumber"];
    if (panSequenceNumber != nil && ![panSequenceNumber isEqualToString:@"00"] && ![panSequenceNumber isEqualToString:@"FF"]) {
        // if panSequenceNumber is present and not 00/FF, send it
        // this is a Vantiv-specific param name
        [emvParams setObject:panSequenceNumber forKey:@"card_sequence_terminal_number"];
    }

    NSString *amountOther = [cardInfo objectForKey:@"AmountOtherNumeric"];
    if (amountOther != nil && ![amountOther isEqual:[NSNull null]]) {
        [emvParams setObject:amountOther forKey:@"amount_other"];
    }

    NSString *applicationIdentifier = [cardInfo objectForKey:@"ApplicationIdentifier"];
    if (applicationIdentifier != nil && ![applicationIdentifier isEqual:[NSNull null]]) {
        [emvParams setObject:applicationIdentifier forKey:@"application_identifier_icc"];
    }

    NSString *terminalCapabilities = [cardInfo objectForKey:@"TerminalCapabilities"];
    if (terminalCapabilities != nil && ![terminalCapabilities isEqual:[NSNull null]]) {
        [emvParams setObject:terminalCapabilities forKey:@"terminal_capabilities"];
    }

    NSString *transactionStatusInformation = [cardInfo objectForKey:@"TransactionStatusInformation"];
    if (transactionStatusInformation != nil && ![transactionStatusInformation isEqual:[NSNull null]]) {
        [emvParams setObject:transactionStatusInformation forKey:@"transaction_status_information"];
    }

    NSString *terminalType = [cardInfo objectForKey:@"TerminalType"];
    if (terminalType != nil && ![terminalType isEqual:[NSNull null]]) {
        [emvParams setObject:terminalType forKey:@"terminal_type"];
    }
    
    NSString *applicationLabel = [cardInfo objectForKey:@"ApplicationLabel"];
    if (applicationLabel != nil && ![applicationLabel isEqual:[NSNull null]]) {
        [emvParams setObject:applicationLabel forKey:@"application_label"];
    }

    return emvParams;
}

@end
