//
//  ViewController.h
//  WePayExample
//
//  Created by Chaitanya Bagaria on 10/30/14.
//  Copyright (c) 2014 WePay. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WePay/WePay.h"

@interface ViewController : UIViewController <WPAuthorizationDelegate, WPCardReaderDelegate, WPCheckoutDelegate, WPTokenizationDelegate>


@end

