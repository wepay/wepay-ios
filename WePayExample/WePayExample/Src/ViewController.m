//
//  ViewController.m
//  WePayExample
//
//  Created by Chaitanya Bagaria on 10/30/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#import "ViewController.h"
#import <WePay/WePay.h>

#define SETTINGS_CLIENT_ID_KEY @"settingClientId"
#define SETTINGS_ENVIRONMENT_KEY @"settingEnvironment"
#define SETTINGS_ACCOUNT_ID_KEY @"settingAccountId"

#define EMV_AMOUNT_DOUBLE 12.34
#define EMV_READER_SHOULD_RESET NO
#define EMV_SELECT_APP_INDEX 0

@interface ViewController ()

@property (nonatomic, strong) WePay *wepay;

@property (nonatomic, weak) IBOutlet UIButton *swipeInfoBtn;
@property (nonatomic, weak) IBOutlet UIButton *swipeTokenBtn;
@property (nonatomic, weak) IBOutlet UIButton *stopReaderBtn;
@property (nonatomic, weak) IBOutlet UIButton *manualEntryBtn;
@property (nonatomic, weak) IBOutlet UIButton *submitSignatureBtn;

@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet UIView *containerView;

@property (assign, nonatomic) long accountId;

@end

@implementation ViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    // Initialize WePay Config with your clientId and environment
    NSString *clientId = [self fetchSetting:SETTINGS_CLIENT_ID_KEY withDefault:@"171482"];
    NSString *environment = [self fetchSetting:SETTINGS_ENVIRONMENT_KEY withDefault:kWPEnvironmentStage];
    self.accountId = (long)[[self fetchSetting:SETTINGS_ACCOUNT_ID_KEY withDefault:@"1170640190"] longLongValue];
    WPConfig *config = [[WPConfig alloc] initWithClientId:clientId environment:environment];

    // Allow WePay to use location services
    config.useLocation = YES;

    // Initialize WePay
    self.wepay = [[WePay alloc] initWithConfig:config];
    
    // Do any additional setup after loading the view, typically from a nib.
    [self setupUserInterface];
    
    // Print config to screen
    NSAttributedString *str = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Environment: %@", environment]
                                                              attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0 green:0.2 blue:0 alpha:1]}];
    [self consoleLog:str];
    str = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"ClientId: %@", clientId]
                                          attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0 green:0.2 blue:0 alpha:1]}];
    [self consoleLog:str];
    
    str = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"AccountId: %ld", self.accountId]
                                          attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0 green:0.2 blue:0 alpha:1]}];
    [self consoleLog:str];

}

- (NSString *) fetchSetting:(NSString *)key withDefault:(NSString *)value
{
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSString *clientId = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    
    if (clientId == nil || [clientId isEqualToString:@""]) {
        clientId = value;
        [[NSUserDefaults standardUserDefaults] setObject:clientId forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    return clientId;
}

- (void) setupUserInterface
{
    self.containerView.layer.borderWidth = 1.0;
    self.containerView.layer.cornerRadius = 8;
    
    self.swipeInfoBtn.layer.borderWidth = 1.0;
    self.swipeInfoBtn.layer.cornerRadius = 8;
    
    self.swipeTokenBtn.layer.borderWidth = 1.0;
    self.swipeTokenBtn.layer.cornerRadius = 8;

    self.stopReaderBtn.layer.borderWidth = 1.0;
    self.stopReaderBtn.layer.cornerRadius = 8;
    
    self.manualEntryBtn.layer.borderWidth = 1.0;
    self.manualEntryBtn.layer.cornerRadius = 8;

    self.submitSignatureBtn.layer.borderWidth = 1.0;
    self.submitSignatureBtn.layer.cornerRadius = 8;
    
    self.statusLabel.layer.borderWidth = 1.0;
    self.statusLabel.layer.cornerRadius = 8;
    
    self.textView.layer.borderWidth = 1.0;
    self.textView.layer.cornerRadius = 8;
    
    [self showStatus:@"Choose a payment method"];
}

- (IBAction) swipeInfoBtnPressed:(id)sender
{
    // Change status label
    [self showStatus:@"Please wait..."];
    
    // Print message to screen
    NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"Info from credit card selected"
                                                              attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0 green:0.2 blue:0 alpha:1]}
                               ];
    [self consoleLog:str];

    // Make WePay API call
    [self.wepay startCardReaderForReadingWithCardReaderDelegate:self];
}

- (IBAction) swipeTokenButtonPressed:(id)sender
{
    // Change status label
    [self showStatus:@"Please wait..."];
    
    // Print message to screen
    NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"Tokenize credit card selected"
                                                              attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0 green:0.2 blue:0 alpha:1]}
                               ];
    [self consoleLog:str];

    // Make WePay API call
    [self.wepay startCardReaderForTokenizingWithCardReaderDelegate:self
                                              tokenizationDelegate:self
                                             authorizationDelegate:self];
}

- (IBAction) stopCardReaderButtonPressed:(id)sender
{
    // Change status label
    [self showStatus:@"Stopping Card Reader"];

    // Print message to screen
    NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"Stop Card Reader selected"
                                                              attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0 green:0.2 blue:0 alpha:1]}
                               ];
    [self consoleLog:str];

    // Make WePay API call
    [self.wepay stopCardReader];
}

- (IBAction) manualEntryButtonPressed:(id)sender
{
    // obtain card info
    WPPaymentInfo *paymentInfo = [[WPPaymentInfo alloc] initWithFirstName:@"WPiOS"
                                                                 lastName:@"Example"
                                                                    email:@"wp.ios.example@wepay.com"
                                                           billingAddress:[[WPAddress alloc] initWithZip:@"94306"]
                                                          shippingAddress:nil
                                                               cardNumber:@"5496198584584769"
                                                                      cvv:@"123"
                                                                 expMonth:@"04"
                                                                  expYear:@"2020"
                                                          virtualTerminal:YES];

    // Change status label
    [self showStatus:@"Please wait..."];
    
    // Print message to screen
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@"Manual entry selected. Using sample info: \n"
                                                                            attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0 green:0.2 blue:0 alpha:1]}
                               ];
    NSAttributedString *info = [[NSAttributedString alloc] initWithString:[paymentInfo description]
                                                               attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0 green:0 blue:1 alpha:1]}
                                ];
    
    [str appendAttributedString:info];
    [self consoleLog:str];

    // Make WePay API call
    [self.wepay tokenizePaymentInfo:paymentInfo tokenizationDelegate:self];
}

- (IBAction) storeSignatureButtonPressed:(id)sender
{
    // Change status label
    [self showStatus:@"Storing Signature"];

    // Print message to screen
    NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"Store signature selected"
                                                              attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0 green:0.2 blue:0 alpha:1]}
                               ];
    [self consoleLog:str];


    UIImage *signature = [UIImage imageNamed:@"dd_signature.png"];

    // Below, use a checkoutId from a checkout you created recently (via a /checkout/create API call), otherwise an error will occur.
    // If you do obtain a valid checkout id, remember to change the clientId above to the one associated with the checkout.
    // The placeholder checkoutId below is invalid, and will result in an appropriate error.

    NSString *checkoutId = @"12345678";
    [self.wepay storeSignatureImage:signature forCheckoutId:checkoutId checkoutDelegate:self];
}

- (void) consoleLog:(NSAttributedString *)data
{
    // fetch current text
    NSMutableAttributedString *text = [self.textView.attributedText mutableCopy];

    // create and append date string
    NSDateFormatter *format = [[NSDateFormatter alloc]init];
    [format setDateFormat:@"HH:mm:ss"];
    NSString *dateStr = [format stringFromDate:[NSDate date]];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n[%@] ",dateStr]]];

    // append new string
    [text appendAttributedString:data];
    self.textView.attributedText = text;

    // scroll the text view to the bottom
    [self.textView scrollRangeToVisible:NSMakeRange([self.textView.text length], 0)];

    // log to console as well
    NSLog(@"%@",data.string);
}

- (void) showStatus:(NSString *)message
{
    self.statusLabel.text = message;
}

#pragma mark - WPCardReaderDelegateMethods

- (void) didReadPaymentInfo:(WPPaymentInfo *)paymentInfo
{
    // Print message to screen
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@"didReadPaymentInfo: \n"];
    NSAttributedString *info = [[NSAttributedString alloc] initWithString:[paymentInfo description]
                                                               attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0 green:0 blue:1 alpha:1]}
    ];
    
    [str appendAttributedString:info];
    [self consoleLog:str];
    
    // Change status label
    [self showStatus:@"Got payment info!"];
}

- (void) didFailToReadPaymentInfoWithError:(NSError *)error
{
    // Print message to screen
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@"didFailToReadPaymentInfoWithError: \n"];
    NSAttributedString *info = [[NSAttributedString alloc] initWithString:[error localizedDescription]
                                                               attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:1 green:0 blue:0 alpha:1]}
                                ];
    
    [str appendAttributedString:info];
    
    [self consoleLog:str];
    
    // Change status label
    [self showStatus:@"Card Reader error"];
}

- (void) cardReaderDidChangeStatus:(id)status
{
    // Print message to screen
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@"cardReaderDidChangeStatus: "];
    NSAttributedString *info = [[NSAttributedString alloc] initWithString:[status description]
                                                               attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0 green:0 blue:1 alpha:1]}
                                ];
    
    [str appendAttributedString:info];
    
    [self consoleLog:str];
    
    // Change status label
    if (status == kWPCardReaderStatusNotConnected) {
        [self showStatus:@"Connect Card Reader"];
    } else if (status == kWPCardReaderStatusWaitingForCard) {
        [self showStatus:@"Swipe/Dip Card"];
    } else if (status == kWPCardReaderStatusSwipeDetected) {
        [self showStatus:@"Swipe Detected..."];
    } else if (status == kWPCardReaderStatusTokenizing) {
        [self showStatus:@"Tokenizing..."];
    } else if (status == kWPCardReaderStatusStopped) {
        [self showStatus:@"Card Reader Stopped"];
    } else {
        [self showStatus:[status description]];
    }
}

- (void) shouldResetCardReaderWithCompletion:(void (^)(BOOL))completion
{
    // Change this to YES if you want to reset the card reader
    completion(EMV_READER_SHOULD_RESET);
}

- (void) authorizeAmountWithCompletion:(void (^)(double amount, NSString *currencyCode, long accountId))completion
{
    double amount = EMV_AMOUNT_DOUBLE;
    NSString *currencyCode = kWPCurrencyCodeUSD;
    
    // Change status label
    [self showStatus:@"Providing auth info"];
    
    // Print message to console
    NSString *infoString = [NSString stringWithFormat:@"amount: %.2f, currency: %@, accountId: %ld", amount, currencyCode, self.accountId];
    NSAttributedString *str = [[NSAttributedString alloc] initWithString:[@"Providing auth info: " stringByAppendingString:infoString]
                                                              attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0 green:0.2 blue:0 alpha:1]}
                               ];
    [self consoleLog:str];
    
    // execute the completion
    completion(amount, currencyCode, self.accountId);
}

#pragma mark - WPTokenizationDelegate methods

- (void) paymentInfo:(WPPaymentInfo *)paymentInfo
         didTokenize:(WPPaymentToken *)paymentToken
{
    [self showStatus:@"Tokenized!"];
    
    // Print message to console
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@"paymentInfo:didTokenize: \n"];
    NSAttributedString *info = [[NSAttributedString alloc] initWithString:[paymentToken description]
                                                               attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0 green:0 blue:1 alpha:1]}
                                ];
    
    [str appendAttributedString:info];
    
    [self consoleLog:str];
}

- (void) paymentInfo:(WPPaymentInfo *)paymentInfo
 didFailTokenization:(NSError *)error
{
    [self showStatus:@"Tokenization error"];
    
    // Print message to console
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@"paymentInfo:didFailTokenization: \n"];
    NSAttributedString *info = [[NSAttributedString alloc] initWithString:[error localizedDescription]
                                                               attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:1 green:0 blue:0 alpha:1]}
                                ];
    
    [str appendAttributedString:info];
    
    [self consoleLog:str];
}

#pragma mark - WPCheckoutDelegate methods

- (void) didStoreSignature:(NSString *)signatureUrl
             forCheckoutId:(NSString *)checkoutId
{
    [self showStatus:@"Signature success!"];

    // Print message to console
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@"didStoreSignature: \n"];
    NSAttributedString *info = [[NSAttributedString alloc] initWithString:[signatureUrl description]
                                                               attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0 green:0 blue:1 alpha:1]}
                                ];

    [str appendAttributedString:info];

    [self consoleLog:str];

}

- (void) didFailToStoreSignatureImage:(UIImage *)image
                        forCheckoutId:(NSString *)checkoutId
                            withError:(NSError *)error
{
    [self showStatus:@"Signature error"];
    
    // Print message to console
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@"didFailToStoreSignatureImage: \n"];
    NSAttributedString *info = [[NSAttributedString alloc] initWithString:[error localizedDescription]
                                                               attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:1 green:0 blue:0 alpha:1]}
                                ];

    [str appendAttributedString:info];

    [self consoleLog:str];

}

#pragma mark - WPAuthorizationDelegate methods

- (void) selectEMVApplication:(NSArray *)applications
                   completion:(void (^)(NSInteger selectedIndex))completion
{
    // In production apps, the payer must choose the application they want to use.
    // Here, we always select the first application in the array
    int selectedIndex = (int)EMV_SELECT_APP_INDEX;

    // Print message to console
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@"Select App Id: \n"];
    NSAttributedString *info = [[NSAttributedString alloc] initWithString:[applications description]
                                                               attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0 green:0 blue:1 alpha:1]}
                                ];

    [str appendAttributedString:info];
    [self consoleLog:str];

    str = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Selected App Id index: %d", selectedIndex]];
    [self consoleLog:str];

    // execute the completion
    completion(selectedIndex);
}

- (void) insertPayerEmailWithCompletion:(void (^)(NSString *email))completion
{
    NSString *email = @"emv@example.com";

    // Print message to console
    NSAttributedString *str = [[NSAttributedString alloc] initWithString:[@"Providing email: " stringByAppendingString:email]
                                                              attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0 green:0.2 blue:0 alpha:1]}
                               ];
    [self consoleLog:str];

    completion(email);
}

- (void) paymentInfo:(WPPaymentInfo *)paymentInfo
        didAuthorize:(WPAuthorizationInfo *)authorizationInfo
{
    // Print message to screen
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@"didAuthorize: \n"];
    NSAttributedString *info = [[NSAttributedString alloc] initWithString:[authorizationInfo description]
                                                               attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0 green:0 blue:1 alpha:1]}
                                ];

    [str appendAttributedString:info];
    [self consoleLog:str];


    // Change status label
    [self showStatus:@"Authorized"];

}

- (void) paymentInfo:(WPPaymentInfo *)paymentInfo
didFailAuthorization:(NSError *)error
{
    // Print message to screen
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@"didFailAuthorization: \n"];
    NSAttributedString *info = [[NSAttributedString alloc] initWithString:[error localizedDescription]
                                                               attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:1 green:0 blue:0 alpha:1]}
                                ];

    [str appendAttributedString:info];

    [self consoleLog:str];

    // Change status label
    [self showStatus:@"Authorization failed"];
}

@end