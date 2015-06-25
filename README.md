# Deprecation Notice
This beta version (1.x.x) of the WePay iOS SDK is now deprecated. A new 2.0.0 version will be released soon. The new version will *NOT* be backwards compatible with this older version. 

The old version will continue to be available for use via [master-v1-deprecated](http://github.com/wepay/wepay-ios/tree/master-v1-deprecated) but will have limited support for existing functionality. All new functionality will only be added to the new SDK moving forward.

![alt text](https://static.wepay.com/img/logos/wepay.png "WePay")
===========================================================
WePay's IOS SDK makes it easy for you to accept payments in your mobile application. Using our SDK instead of handling the card details directly on your server greatly reduces your PCI compliance scope because WePay stores the user's credit card details for you and sends your server a token to charge the card.

## Requirements
- ARC
- AdSupport.framework

## Installation
You can install the IOS SDK by adding the **WePay** directory to your project. 
You will need to add the AdSupport.framework to your application. Please see the Notes section (at the end of this Readme) for information about why you need to add this framework.

## Structure

Descriptor classes, located in the [WePay/Descriptors](https://github.com/wepay/wepay-ios/blob/master/WePay/Descriptors/ "WePay/Descriptors") folder, facilitate the passing of parameters to API call classes. API calls through the IOS SDK generally take three arguments: a descriptor object argument, a success callback (a function executed if the API call is successful) argument, and an error callback (a function executed when an error occurs) argument. 

Currently, this SDK only supports one API call, the [/credit_card/create](https://www.wepay.com/developer/reference/credit_card#create "Credit Card Create API call") API call, that allows you to pass a customer's credit card details to WePay and receive back a credit_card_id (card token) that you can then send to your servers for charge.

Please see sample code below.

## Usage

### Configuration

For all requests, you must initialize the SDK with your Client ID, into either Staging or Production mode. All API calls made against WePay's staging environment mirror production in functionality, but do not actually move money. This allows you to develop your application and test the checkout experience from the perspective of your customers without spending any money on payments. 

**Note:** Staging and Production are two completely independent environments and share NO data with each other. This means that in order to use staging, you must register at stage.wepay.com and get a set of API keys for your Staging application, and must do the same on Production when you are ready to go live. API keys and access tokens granted on stage can not be used on Production, and vice-versa.

Use of our IOS SDK will require you to apply for tokenization approval. Please apply for approval on your application's dashboard.

After you have created an API application on either stage.wepay.com or wepay.com, add the following to the `- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions` in your APPDelegate file:

If you want to use our production (wepay.com) environment:

```objectivec
[WePay setProductionClientId: @"YOUR_CLIENT_ID"];
```

If you want to use our testing (stage.wepay.com) environment:

```objectivec
[WePay setStageClientId: @"YOUR_CLIENT_ID"]; 
```

To set an [API-Version](https://www.wepay.com/developer/reference/versioning) for your call request, use:

for Production:
```objectivec
[WePay setProductionClientId: @"YOUR_CLIENT_ID" apiVersion: @"API_VERSION"];
```

for Stage:
```objectivec
[WePay setStageClientId: @"YOUR_CLIENT_ID" apiVersion: @"API_VERSION"];
```

### Tokenize a card

```objectivec
#import "WPCreditCard.h"
```

#### Code

```objectivec
// Pass in the customer's address to the address descriptor
// For US customers, WePay allows you to only send the zipcode
// as long as the "Enable Zip-only billing address" option is checked 
// on the app configuration page
WPAddressDescriptor * addressDescriptor = [[WPAddressDescriptor alloc] initWithZip: @"94085"];

/* 

If the customer has a non-US billing address, we require you to send their
full billing address; however, if he/she has a US billing address, only
their zipcode is required. If you only want to send the zipcode, you must
make sure the "Enable ZIP-only billing address" option is checked on the 
app configuration page.

WPAddressDescriptor * addressDescriptor = [[WPAddressDescriptor alloc] init];
addressDescriptor.address1 = @"Main Street";
addressDescriptor.city = @"Sunnyvale";
addressDescriptor.state = @"CA";
addressDescriptor.country = @"US";
addressDescriptor.zip = @"94085";

*/

// Pass in the customer's name, email, and address descriptor to the user descriptor
WPUserDescriptor * userDescriptor = [[WPUserDescriptor alloc] init];
userDescriptor.name = @"Bill Clerico";
userDescriptor.email = @"test@wepay.com";
userDescriptor.address = addressDescriptor;

// Pass in the customer's credit card details to the card descriptor
WPCreditCardDescriptor * cardDescriptor = [[WPCreditCardDescriptor alloc] init];
cardDescriptor.number = @"4242424242424242";
cardDescriptor.expirationMonth = 2;
cardDescriptor.expirationYear = 2020;
cardDescriptor.securityCode = @"313";
cardDescriptor.user = userDescriptor;

// Send the customer's card details to WePay and retrieve a token
[WPCreditCard createCardWithDescriptor: cardDescriptor success: ^(WPCreditCard * tokenizedCard) {

    NSString * token = tokenizedCard.creditCardId;

    // Card token from WePay.
    NSLog(@"Token: %@", token);
  
    // Add code here to send token to your servers
    
} failure:^(NSError * error) {

    NSLog(@"Error trying to create token: %@", [error localizedDescription]);

}];
```

### Error Handling

As shown in the example above, you call the `createCardWithDescriptor` static method with the following parameters: card descriptor, success callback function, and error callback function. *createCardWithDescriptor* validates the customer's input before sending to WePay. 

It generates NSError objects for the following errors and sends these objects to the error callback function.

1. Client Side Validation Errors (i.e. invalid card number, invalid security code, etc)
2. WePay API errors (from WePay.com)
3. Network Errors

Network and NSUrlConnection errors are in the `NSUrlErrorDomain`. Client-side validation errors are in the `WePaySDKDomain`. WePay API errors are in the `WePayAPIDomain`. 

All errors have a localizable user-facing error message that can be retrieved by calling `[error localizedDescription]`. You can edit the **WePay/Resources/Base.lproj/WePay.strings** file to change the client-side validation error messages.

#### WePay API Errors

The SDK converts WePay API errors (https://www.wepay.com/developer/reference/errors) into NSError objects with the same error codes and descriptions. The userInfo dictionary `WPErrorCategoryKey` key value is the same as the **error** category sent by WePay.

#### Validation

The SDK validates all user input before sending to WePay. Each descriptor class has several validation functions you can use to validate the input yourself. Please check the header files for a list of all of these validation functions. For example, in the `WPCreditCardDescriptor` class, you will find the following validation functions:

```objectivec
- (BOOL) validateNumber:(id *)ioValue error:(NSError * __autoreleasing *)outError;
- (BOOL) validateSecurityCode:(id *)ioValue error:(NSError * __autoreleasing *)outError;
- (BOOL) validateUser:(id *)ioValue error:(NSError * __autoreleasing *)outError;
- (BOOL) validateExpirationMonth:(id *)ioValue error:(NSError * __autoreleasing *)outError;
- (BOOL) validateExpirationYear:(id *)ioValue error:(NSError * __autoreleasing *)outError;
```

These methods follow the validation method convention used by [key value validation](https://developer.apple.com/library/mac/documentation/cocoa/conceptual/KeyValueCoding/Articles/Validation.html "Key Value Validation"). You can call the validation methods directly, or by invoking validateKey:forKey:error: and specifying the key. 

#### (Advanced) How to differentiate between errors

You can check the error domain to differentiate between Network, WePay API, and Client-side validation errors. Network and NSUrlConnection errors are in the `NSURLErrorDomain`. WePay API errors are in the `
WePayAPIDomain`. Client Side validation errors are in the `WePaySDKDomain`.

Each WePay API error object has one of the following values for the `WPErrorCategoryKey` userInfo dictionary key that is the same as the **error** category from the [WePay API Errors page](https://www.wepay.com/developer/reference/errors "WePay API errors"):
- invalid_request
- access_denied
- invalid_scope
- invalid_client
- processing_error

Each client side validation error object has one of the following values for the `WPErrorCategoryKey` userInfo dictionary key that corresponds to the descriptor class that generated the error object:
- WPErrorCategoryCardValidation (for WPCreditCardDescriptor validation errors)
- WPErrorCategoryUserValidation (for WPUserDescriptor validation errors)
- WPErrorCategoryAddressValidation (for WPAddressDescriptor validation errors)

Please see the file **WePay/WPError.h** for more information.

### iOS Example
Run the WePay-Example target. This sample application shows you how to accept payments in your mobile app.

### Notes

To help us prevent fraud, WePay IOS SDK automatically sends the user's IP and [Advertiser Identifier](https://developer.apple.com/library/IOs/documentation/AdSupport/Reference/ASIdentifierManager_Ref/ASIdentifierManager.html "Advertiser Identifier") when they make a payment. If you want to disable the collection of these two pieces of information, you can use the functions below instead when setting your application client Id:

Testing:
```objectivec
+ (void) setStageClientId:(NSString *) key  sendIPandDeviceId: (BOOL) sendIPandDeviceIdflag;
```

Production:
```objectivec
+ (void) setProductionClientId:(NSString *) key  sendIPandDeviceId: (BOOL) sendIPandDeviceIdflag;
```

If you disable the sending of ip and device id, you don't have to add the `AdSupport.framework` to your application.
