# Getting Started                         {#mainpage}

![WePay logo](https://go.wepay.com/frontend/images/wepay-logo.svg "WePay")

## Introduction
The WePay iOS SDK enables collection of payments via various payment methods.

It is meant for consumption by [WePay](http://www.wepay.com) partners who are developing their own iOS apps aimed at merchants and/or consumers.

Regardless of the payment method used, the SDK will ultimately return a Payment Token, which must be redeemed via a server-to-server [API](http://www.wepay.com/developer) call to complete the transaction.

## Payment methods
There are two types of payment methods:
+ Consumer payment methods - to be used in apps where consumers directly pay and/or make donations
+ Merchant payment methods - to be used in apps where merchants collect payments from their customers
 
The WePay iOS SDK supports the following payment methods
- Card Reader: Using an EMV Card Reader, a merchant can accept in-person payments by prosessing a consumer's EMV-enabled chip card. Traditional magnetic stripe cards can be processed as well.
- Manual Entry (Consumer/Merchant): The Manual Entry payment method lets consumer and merchant apps accept payments by allowing the user to manually enter card info.

## Installation

#### Using [cocoapods](https://cocoapods.org/) (recommended)
+ Add `pod "WePay"` to your podfile
+ Run `pod install`
+ Done!

The [SwiftExample app](https://github.com/wepay/wepay-ios/tree/master/SwiftExample) also utilizes `cocoapods`.

#### Using library binaries
+ Download the latest zip file from our [releases page](https://github.com/wepay/wepay-ios/releases/latest)
+ Unzip the file and copy the contents anywhere inside your project directory
+ In Xcode, go to your app's target settings. On the `Build Phases` tab, expand the `Link Binary With Libraries` section.
+ Include the following iOS frameworks:
    - AudioToolbox.framework
    - AVFoundation.framework
    - ExternalAccessory.framework
    - MediaPlayer.framework
    - SystemConfiguration.framework
    - WebKit.framework
    - libc++.tbd
    - libz.tbd
+ Also include the framework files you copied:
    - WePay.framework
+ Done!

Note: Card reader functionality is not available in this SDK by default. If you are interested in using the WePay Card Reader, please contact your sales representative or account manager.  If you have yet to be in direct contact with WePay, please email sales@wepay.com.

## Documentation
HTML documentation is hosted on our [Github Pages Site](http://wepay.github.io/wepay-ios/).

Pdf documentation is available on the [releases page](https://github.com/wepay/wepay-ios/releases/latest) or as a direct [download](https://github.com/wepay/wepay-ios/raw/master/documentation/wepay-ios.pdf).

General documentation about the WePay mobile point of sale (mPOS) program is available [here](https://developer.wepay.com/mobile/mpos-program-overview).
## SDK Organization

### WePay.h
`WePay.h` is the starting point for consuming the SDK, and contains the primary class you will interact with.
It exposes all the methods you can call to accept payments via the supported payment methods.
Detailed reference documentation is available on the reference page for the `WePay` class.

### Delegate protocols
The SDK uses delegate protocols to respond to API calls. You must adopt the relevant protocols to receive responses to the API calls you make.
Detailed reference documentation is available on the reference page for each protocol:
- `WPAuthorizationDelegate`
- `WPBatteryLevelDelegate`
- `WPCardReaderDelegate`
- `WPCheckoutDelegate`
- `WPTokenizationDelegate`


### Data Models
All other classes in the SDK are data models that are used to exchange data between your app and the SDK. 
Detailed reference documentation is available on the reference page for each class.

## Next Steps
Head over to the [documentation](http://wepay.github.io/wepay-ios/) to see all the API methods available.
When you are ready, look at the samples below to learn how to interact with the SDK.


## Error Handling
`WPError.h` serves as documentation for all errors surfaced by the WePay iOS SDK.

## Samples

 See the [WePayExample app](https://github.com/wepay/wepay-ios/tree/master/WePayExample) for a working implementation of all API methods.

 See the [SwiftExample app](https://github.com/wepay/wepay-ios/tree/master/SwiftExample) for a working implementation of all API methods in a Swift 3 application.
 Note: make sure to open the project using `SwiftApp.xcworkspace` and not `SwiftApp.xcodeproj`.

### Initializing a Bridging Header (for Swift apps)

+ For using Objective-C modules in a Swift application, you will need to create a bridging header.
+ Make sure you are working in `{app_name}.xcworkspace` file.
+ Under your target application folder, create a header file: `{app_name}-Bridging-Header.h`
+ In the Header file, import the modules you need:
~~~{.m}
#import <WePay/WePay.h>
~~~
+ Click on the main application project to get to `Build Settings`.
+ Search for `bridging header` in your target application to find a setting called `Swift Compiler - Code Generation`.
+ Double click in the column next to `Objective-C Bridging Header` and add your Header file: `{app_name}/{app_name}-Bridging-Header.h`
+ There's no need to import the module in your code; you can use the module by calling it directly in your Swift application.

### Initializing the SDK

+ Complete the installation steps (above).
+ Include WePay.h
~~~{.m}
#import <WePay/WePay.h>
~~~
+ Define a property to store the WePay object
~~~{.m}
\@property (nonatomic, strong) WePay *wepay;
~~~
+ Create a WPConfig object
~~~{.m}
WPConfig *config = [[WPConfig alloc] initWithClientId:@"your_client_id" environment:kWPEnvironmentStage];
~~~
+ Initialize the WePay object and assign it to the property
~~~{.m}
self.wepay = [[WePay alloc] initWithConfig:config];
~~~

##### Providing permission to use microphone for card reader communication

+ Open your app's Info.plist file and add an entry for NSMicrophoneUsageDescription.
~~~{.xml}
<key>NSMicrophoneUsageDescription</key>
<string>Microphone permission is required for operating card reader</string>
~~~

#####(optional) Providing permission to use location services for fraud detection

+ In Xcode, go to your projects settings. On the Build Phases tab, expand the Link Binary With Libraries section and include the CoreLocation.framework iOS framework.

+ Open your app's Info.plist file and add entries for NSLocationUsageDescription and NSLocationWhenInUseUsageDescription.
~~~{.xml}
<key>NSLocationUsageDescription</key>
<string>Location information is used for fraud prevention</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location information is used for fraud prevention</string>
~~~
+ Set the option on the config object, before initializing the WePay object
~~~{.m}
config.useLocation = YES;
~~~

### Integrating the Card Reader payment methods (Swipe+Dip)

+ Adopt the WPCardReaderDelegate, WPTokenizationDelegate, and WPAuthorizationDelegate protocols
~~~{.m}
\@interface MyWePayDelegate : NSObject <WPCardReaderDelegate, WPTokenizationDelegate, WPAuthorizationDelegate>
~~~
+ Implement the WPCardReaderDelegate protocol methods
~~~{.m}
- (void) cardReaderDidChangeStatus:(id) status
{
    if (status == kWPCardReaderStatusNotConnected) {
        // show UI that prompts the user to connect the Card Reader
        self.statusLabel.text = @"Connect Card Reader";
    } else if (status == kWPCardReaderStatusWaitingForSwipe) {
        // show UI that prompts the user to swipe
        self.statusLabel.text = @"Swipe Card";
    } else if (status == kWPCardReaderStatusSwipeDetected) {
        // provide feedback to the user that a swipe was detected
        self.statusLabel.text = @"Swipe Detected...";
    } else if (status == kWPCardReaderStatusTokenizing) {
        // provide feedback to the user that the card info is being tokenized/verified
        self.statusLabel.text = @"Tokenizing...";
    }  else if (status == kWPCardReaderStatusStopped) {
        // provide feedback to the user that the swiper has stopped
        self.statusLabel.text = @"Card Reader Stopped";
    } else {
        // handle any other status messages
        self.statusLabel.text = [status description];
    } 
}

- (void) selectCardReader:(NSArray *)cardReaderNames
               completion:(void (^)(NSInteger selectedIndex))completion
{
    // In production apps, the merchant must choose the card reader they want to use.
    // Here, we always select the first card reader in the array
    int selectedIndex = 0;
    completion(selectedIndex);
}

- (void) shouldResetCardReaderWithCompletion:(void (^)(BOOL))completion
{
    // Change this to YES if you want to reset the card reader
    completion(NO);
}

- (void) authorizeAmountWithCompletion:(void (^)(NSDecimalNumber *amount, NSString *currencyCode, long accountId))completion
{
    // obtain transaction info
    double amount = @(10.00);
    NSString *currencyCode = @"USD";
    long accountId = 12345678;

    // execute the completion
    completion(amount, currencyCode, accountId);
}

- (void) selectEMVApplication:(NSArray *)applications
                   completion:(void (^)(NSInteger selectedIndex))completion
{
    // In production apps, the payer must choose the app id they want to use.
    // Here, we always select the first application in the array
    int selectedIndex = 0;
    completion(selectedIndex);
}

- (void) insertPayerEmailWithCompletion:(void (^)(NSString *email))completion
{
    // obtain email
    NSString *email = @"emv@example.com";
    
    // execute the completion
    completion(email);
}

- (void) didReadPaymentInfo:(WPPaymentInfo *)paymentInfo 
{
    // use the payment info (for display/recordkeeping)
    // wait for tokenization(swipe)/authorization(dip) response
}

- (void) didFailToReadPaymentInfoWithError:(NSError *)error   
{
    // Handle the error
}

~~~
+ Implement the WPTokenizationDelegate protocol methods
~~~{.m}
- (void) paymentInfo:(WPPaymentInfo *)paymentInfo didTokenize:(WPPaymentToken *)paymentToken
{
    // Send the tokenId (paymentToken.tokenId) to your server
    // Your server would use the tokenId to make a /checkout/create call to complete the transaction
}

- (void) paymentInfo:(WPPaymentInfo *)paymentInfo didFailTokenization:(NSError *)error
{
	// Handle the error
}
~~~
+ Implement the WPAuthorizationDelegate protocol methods
~~~{.m}
- (void) paymentInfo:(WPPaymentInfo *)paymentInfo
        didAuthorize:(WPAuthorizationInfo *)authorizationInfo
{
    // Send the token Id (authorizationInfo.tokenId) and transaction token (authorizationInfo.transactionToken) to your server
    // Your server must use the tokenId and transactionToken to make a /checkout/create call to complete the transaction
}

- (void) paymentInfo:(WPPaymentInfo *)paymentInfo
didFailAuthorization:(NSError *)error
{
    // Handle the error
}
~~~
+ Make the WePay API call, passing in the instance(s) of the class(es) that implemented the delegate protocols
~~~{.m}
[self.wepay startCardReaderForTokenizingWithCardReaderDelegate:self tokenizationDelegate:self authorizationDelegate:self];
// Show UI asking the user to insert the card reader and wait for it to be ready
~~~
+ That's it! The following sequence of events will occur:
    
1. The user inserts the card reader (or it is already inserted), or powers on their bluetooth card reader.
2. The SDK tries to detect the card reader and initialize it.
    - The `cardReaderDidChangeStatus:` method will be called with `status = kWPCardReaderStatusSearching`.
    - If any card readers are discovered, the `selectCardReader:` method will be called with an array of discovered devices. If anything is plugged into the headphone jack, `"AUDIOJACK"` will be one of the devices discovered.
    - If no card readers are detected, the `cardReaderDidChangeStatus:` method will be called with `status = kWPCardReaderStatusNotConnected`.
    - Once the card reader selection completion block is called, the SDK will attempt to to connect to the selected card reader.
    - If the card reader is successfully connected, then the `cardReaderDidChangeStatus:` method will be called with `status = kWPCardReaderStatusConnected`.
3. Next, the SDK checks if the card reader is correctly configured (the `cardReaderDidChangeStatus:` method will be called with `status = kWPCardReaderStatusCheckingReader`).
    - If the card reader is already configured, the app is given a chance to force configuration. The SDK calls the `shouldResetCardReaderWithCompletion:` method, and the app must execute the completion method, telling the SDK whether or not the reader should be reset.
    - If the reader was not already configured, or the app requested a reset, the `cardReaderDidChangeStatus:` method will be called with `status = kWPCardReaderStatusConfiguringReader` and the card reader is configured.
4. Next, if the card reader is successfully initialized, the SDK asks the app for transaction information by calling the `authorizeAmountWithCompletion:` method. The app must execute the completion method, telling the SDK what the amount, currency code and merchant account id is.
5. Next, the `cardReaderDidChangeStatus:` method will be called with `status = kWPCardReaderStatusWaitingForCard`.
6. If the user swipes a card successfully:
    - The `cardReaderDidChangeStatus:` method will be called with `status = kWPCardReaderStatusSwipeDetected`.
    - The SDK attempts to ask the app for the payer’s email by calling the `insertPayerEmailWithCompletion:` method. If the app implements this optional delegate method, it must execute the completion method and pass in the payer’s email address.
    - The `didReadPaymentInfo:` method is called with the obtained payment info.
    - The `cardReaderDidChangeStatus:` method will be called with `status = kWPCardReaderStatusTokenizing`, and the SDK will automatically send the obtained card info to WePay's servers for tokenization.
    - If tokenization succeeds, the `paymentInfo:didTokenize:` method will be called.
    - If tokenization fails, the `paymentInfo:didFailTokenization:` method will be called with the appropriate error, and processing will stop.
7. Instead, if the user dips a card successfully:
    - The `cardReaderDidChangeStatus:` method will be called with `status = kWPCardReaderStatusCardDipped`
    - If the card has multiple applications on it, the payer must choose one:
        - The SDK calls the `selectEMVApplication:completion:` method with a list of Applications on the card.
        - The app must display these Applications to the payer and allow them to choose which application they want to use.
        - Once the payer has decided, the app must inform the SDK of the choice by executing the completion method and passing in the index of the chosen application.
    - Next, the SDK obtains card data from the chip on the card.
    - The SDK attempts to ask the app for the payer’s email by calling the `insertPayerEmailWithCompletion:` method. If the app implements this optional delegate method, it must execute the completion method and pass in the payer’s email address.
    - The `didReadPaymentInfo:` method is called with the obtained payment info.
    - The `cardReaderDidChangeStatus:` method will be called with `status = kWPCardReaderStatusAuthorizing`, and the SDK will automatically send the obtained EMV card info to WePay's servers for authorization.
    - If authorization succeeds, the `paymentInfo:didAuthorize:` method will be called and processing will stop.
    - If authorization fails, the `paymentInfo:didFailAuthorization:` method will be called.
8. If a recoverable error occurs during swiping or dipping, one of the failure methods will be called. After a few seconds, the `cardReaderDidChangeStatus:` method will be called with `status = kWPCardReaderStatusWaitingForCard` and the card reader will again wait for the user to swipe/dip a card.
9. If an unrecoverable error occurs, or if the SDK is unable to obtain data from the card, one of teh failure methods will be called with the appropriate error.
10. When processing stops, the `cardReaderDidChangeStatus:` method will be called with `status = kWPCardReaderStatusStopped`.
10. Done!

Note: After the card is dipped into the reader, it must not be removed until a successful auth response (or an error) is returned.

### Integrating the Manual payment method

+ Adopt the WPTokenizationDelegate protocol
~~~{.h}
\@interface MyWePayDelegate : NSObject <WPTokenizationDelegate>
~~~
+ Implement the WPTokenizationDelegate protocol methods
~~~{.m}
- (void) paymentInfo:(WPPaymentInfo *)paymentInfo didTokenize:(WPPaymentToken *)paymentToken
{
    // Send the tokenId (paymentToken.tokenId) to your server
    // Your server can use the tokenId to make a /checkout/create call to complete the transaction
}

- (void) paymentInfo:(WPPaymentInfo *)paymentInfo didFailTokenization:(NSError *)error
{
    // Handle error
}
~~~
+ Instantiate a WPPaymentInfo object using the user's credit card and address data
~~~{.m}
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
// Note: the virtualTerminal parameter above should be set to YES if a merchant is collecting payments manually using your app. It should be set to NO if a payer is making a manual payment using your app.
~~~
+ Make the WePay API call, passing in the instance of the class that implemented the WPTokenizationDelegate protocol
~~~{.m}
[self.wepay tokenizeManualPaymentInfo:paymentInfo tokenizationDelegate:self];
~~~
+ That's it! The following sequence of events will occur:
1. The SDK will send the obtained payment info to WePay's servers for tokenization
2. If the tokenization succeeds, the `paymentInfo:didTokenize:` method will be called
3. Otherwise, if the tokenization fails, the `paymentInfo:didFailTokenization:` method will be called with the appropriate error


### Integrating the Store Signature API

+ Adopt the WPCheckoutDelegate protocol
~~~{.h}
\@interface MyWePayDelegate : NSObject <WPCheckoutDelegate>
~~~
+ Implement the WPCheckoutDelegate protocol methods
~~~{.m}
- (void) didStoreSignature:(NSString *)signatureUrl
             forCheckoutId:(NSString *)checkoutId
{
    // success! nothing to do here
}

- (void) didFailToStoreSignatureImage:(UIImage *)image
                        forCheckoutId:(NSString *)checkoutId
                            withError:(NSError *)error
{
    // handle the error
}

~~~
+ Obtain the checkout_id associated with this signature from your server
~~~{.m}
NSString *checkoutId = [self obtainCheckoutId];
~~~
+ Instantiate a UIImage containing the user's signature
~~~{.m}
UIImage *signature = [UIImage imageNamed:@"dd_signature.png"];
~~~
+ Make the WePay API call, passing in the instance of the class that implemented the WPCheckoutDelegate protocol
~~~{.m}
[self.wepay storeSignatureImage:signature 
                  forCheckoutId:checkoutId
               checkoutDelegate:self];
~~~
+ That's it! The following sequence of events will occur:
    1. The SDK will send the obtained signature to WePay's servers
    2. If the operation succeeds, the `didStoreSignature:forCheckoutId:` method will be called
    3. Otherwise, if the operation fails, the `didFailToStoreSignatureImage:forCheckoutId:withError:` method will be called with the appropriate error

### Integrating the the Battery Level API

+ Adopt the WPBatteryLevelDelegate protocol
~~~{.h}
\@interface MyWePayDelegate : NSObject <WPBatteryLevelDelegate>
~~~
+ Implement the WPCheckoutDelegate protocol methods
~~~{.m}
- (void) didGetBatteryLevel:(int)batteryLevel
{
    // success! Show the current level to the user.
}

- (void) didFailToGetBatteryLevelwithError:(NSError *)error
{
    // handle the error
}

~~~
+ Make the WePay API call, passing in the instance(s) of the class(es) that implemented the WPCardReaderDelegate and WPBatteryLevelDelegate protocols
~~~{.m}
[self.wepay getCardReaderBatteryLevelWithCardReaderDelegate:self batteryLevelDelegate:self];
~~~
+ That's it! The following sequence of events will occur:
1. The SDK will attempt to read the battery level of the card reader
2. If the operation succeeds, WPBatteryLevelDelegate's `didGetBatteryLevel:` method will be called with the result
3. Otherwise, if the operation fails, WPBatteryLevelDelegate's `didFailToGetBatteryLevelwithError:` method will be called with the appropriate error

### Configuring the SDK

The experiences described above can be modified by utilizing the configuration options available on the WPConfig object. Detailed descriptions for each configurable property is available in the documentation for WPConfig.

### Test/develop using mock card reader and mock WepayClient

+ To use mock card reader implementation instead of using the real reader, instantiate a MockConfig object and pass it to Config:
~~~{.m}
WPMockConfig *mockConfig = [[WPMockConfig alloc] init];
config.mockConfig = mockConfig;
~~~
+ To use mock WepayClient implementation instead of interacting with the real WePay server, set the corresponding option on the mockConfig object:
~~~{.m}
mockConfig.useMockWepayClient = YES;
~~~
+ Other options are also available:
~~~{.m}
mockConfig.mockPaymentMethod = kWPPaymentMethodSwipe; // Payment method to mock; Defaults to SWIPE.
mockConfig.cardReadTimeOut = YES; // To mock a card reader timeout; Defaults to NO.
mockConfig.cardReadFailure = YES; // To mock a failure for card reading; Defaults to NO.
mockConfig.cardTokenizationFailure = YES; // To mock a failure for card tokenization; Defaults to NO.
mockConfig.EMVAuthFailure = YES; // To mock a failure for EMV authorization; Defaults to NO.
mockConfig.multipleEMVApplication = YES; // To mock multiple EMV applications on card to choose from; Defaults to NO.
mockConfig.batteryLevelError = YES; // To mock an error while fetching battery level; Defaults to NO.
mockConfig.mockCardReaderIsDetected = NO; // To mock a card reader being available for connection; Defaults to YES.
~~~

### Integration tests and unit tests
All the integration tests and unit tests are located in the `/WePayTests/` directory.

##### From Xcode

From the Tests Navigator tab:

+ To run a single test, right-click the test method and select "Test <name>".
+ To run all test methods in a class, right-click the class and select "Run <name>".
+ To run all tests in a directory, right-click the directory and select "Run <name>".
+ To run all tests in the project, use the menu option Product > Test  or press (Cmd + U).

##### From the command line

Go to this repo directory and execute:
~~~
xcodebuild test -project WePay.xcodeproj -scheme "Release Framework"  -destination 'platform=iOS Simulator,name=iPhone 7'
~~~
