//
//  ViewController.swift
//  SwiftApp
//
//  Created by Amy Lin on 10/26/15.
//  Copyright © 2015 WePay. All rights reserved.
//

import UIKit

let SETTINGS_CLIENT_ID_KEY = "settingClientId"
let SETTINGS_ENVIRONMENT_KEY = "settingEnvironment"

class ViewController: UIViewController, WPCardReaderDelegate, WPTokenizationDelegate, WPCheckoutDelegate {
    
    var wepay = WePay()
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    @IBOutlet var containerView: UIView!
    @IBOutlet var textView: UITextView!
    @IBOutlet var statusLabel: UILabel!
    
    @IBOutlet var swipeInfoBtn: UIButton!
    @IBOutlet var swipeTokenBtn: UIButton!
    @IBOutlet var stopReaderBtn: UIButton!
    @IBOutlet var manualEntryBtn: UIButton!
    @IBOutlet var submitSignatureBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize WePay Config with your clientId and environment
        let clientId: String = self.fetchClientIdFromSettings()
        let environment: String = self.fetchEnvironmentFromSettings()
        let config: WPConfig = WPConfig(
            clientId: clientId,
            environment: environment
        )
        
        // Allow WePay to use location services
        config.useLocation = true
        
        // Initialize WePay
        self.wepay = WePay(config: config)
        
        // Do any additional setup after loading the view, typically from a nib.
        self.setupUserInterface()
    }
    
    func fetchClientIdFromSettings() -> String {
        userDefaults.synchronize()
        var clientId: String = userDefaults.stringForKey(SETTINGS_CLIENT_ID_KEY) ?? "171482"
        
        // Default to 171482
        if clientId.isEmpty {
            clientId = "171482"
            userDefaults.setObject(clientId, forKey: SETTINGS_CLIENT_ID_KEY)
            userDefaults.synchronize()
        }
        return clientId
    }
    
    func fetchEnvironmentFromSettings() -> String {
        userDefaults.synchronize()
        var env: String = userDefaults.stringForKey(SETTINGS_ENVIRONMENT_KEY) ?? kWPEnvironmentStage
        
        // Default to stage
        if env.isEmpty {
            env = kWPEnvironmentStage
            userDefaults.setObject(env, forKey: SETTINGS_ENVIRONMENT_KEY)
            userDefaults.synchronize()
        }
        return env
    }
    
    func setupUserInterface() {        
        self.statusLabel.text = "Choose a payment method"
    }
    
    @IBAction func swipeInfoBtnPressed(sender: AnyObject) {
        // Change status label
        self.statusLabel.text = "Please wait..."
        
        // Print message to screen
        let str: NSAttributedString = NSAttributedString(
            string: "Info from credit card selected",
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0.2, blue: 0, alpha: 1)]
        )
        self.consoleLog(str)
        
        // Make WePay API call
        self.wepay.startCardReaderForReadingWithCardReaderDelegate(self)
    }
    
    @IBAction func swipeTokenButtonPressed(sender: AnyObject) {
        // Change status label
        self.statusLabel.text = "Please wait..."
        
        // Print message to screen
        let str: NSAttributedString = NSAttributedString(
            string: "Tokenize credit card selected",
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0.2, blue: 0, alpha: 1)]
        )
        self.consoleLog(str)
        
        // Make WePay API call
        self.wepay.startCardReaderForTokenizingWithCardReaderDelegate(self, tokenizationDelegate: self)
    }
    
    @IBAction func stopCardReaderButtonPressed(sender: AnyObject) {
        // Change status label
        self.statusLabel.text = "Stopping Card Reader"
        
        // Print message to screen
        let str: NSAttributedString = NSAttributedString(
            string: "Stop Card Reader selected",
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0.2, blue: 0, alpha: 1)]
        )
        self.consoleLog(str)
        
        // Make WePay API call
        self.wepay.stopCardReader()
    }
    
    @IBAction func manualEntryButtonPressed(sender: AnyObject) {
        // Obtain card information
        let paymentInfo: WPPaymentInfo = WPPaymentInfo(
            firstName: "WPiOS",
            lastName: "Example",
            email: "wp.ios.example@wepay.com",
            billingAddress: WPAddress(zip: "94306"),
            shippingAddress: nil,
            cardNumber: "5496198584584769",
            cvv: "123",
            expMonth: "04",
            expYear: "2020",
            virtualTerminal: true
        )
        
        // Change status label
        self.statusLabel.text = "Please wait..."
        
        // Print message to screen
        let str: NSMutableAttributedString = NSMutableAttributedString(
            string: "Manual entry selected. Using sample info: \n",
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0.2, blue: 0, alpha: 1)]
        )
        let info: NSAttributedString = NSAttributedString(
            string: paymentInfo.description,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0, blue: 1, alpha: 1)]
        )
        str.appendAttributedString(info)
        self.consoleLog(str)
        
        // Make WePay API call
        self.wepay.tokenizePaymentInfo(paymentInfo, tokenizationDelegate: self)
    }
    
    @IBAction func storeSignatureButtonPressed(sender: AnyObject) {
        // Change status label
        self.statusLabel.text = "Storing Signature"
        
        // Print message to screen
        let str: NSAttributedString = NSAttributedString(
            string: "Store signature selected",
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0.2, blue: 0, alpha: 1)]
        )
        self.consoleLog(str)
        
        let signature: UIImage = UIImage(named: "dd_signature.png")!
        
        // Below, use a checkoutId from a checkout you created recently (via a /checkout/create API call), otherwise an error will occur.
        // If you do obtain a valid checkout ID, remember to change the clientId above to the one associated with the checkout.
        // The placeholder checkoutId below is invalid, and will result in an appropriate error.
        let checkoutId: String = "12345678"
        self.wepay.storeSignatureImage(
            signature,
            forCheckoutId: checkoutId,
            checkoutDelegate: self
        )
    }
    
    @IBAction func consoleLog(data: NSAttributedString) {
        // Fetch current text
        let text: NSMutableAttributedString = self.textView.attributedText.mutableCopy() as! NSMutableAttributedString
        
        // Create and append date string
        let format: NSDateFormatter = NSDateFormatter()
        format.dateStyle = .MediumStyle
        let dateStr: String = format.stringFromDate(NSDate())
        text.appendAttributedString(NSAttributedString(string: "\n[\(dateStr)] "))
        
        // Append new string
        text.appendAttributedString(data)
        self.textView.attributedText = text
        
        // Scroll the text view to the bottom
        self.textView.scrollRangeToVisible(NSMakeRange(self.textView.text.characters.count, 0))
        
        // Log to console as well
        NSLog("%@", data.string)
    }
    
    func didReadPaymentInfo(paymentInfo: WPPaymentInfo) {
        // Print message to screen
        let str: NSMutableAttributedString = NSMutableAttributedString(string: "didReadPaymentInfo: \n")
        let info: NSAttributedString = NSAttributedString(
            string: paymentInfo.description,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0, blue: 1, alpha: 1)]
        )
        str.appendAttributedString(info)
        self.consoleLog(str)
        
        // Change status label
        self.statusLabel.text = "Got payment info!"
    }
    
    func didFailToReadPaymentInfoWithError(error: NSError) {
        // Print message to screen
        let str: NSMutableAttributedString = NSMutableAttributedString(string: "didFailToReadPaymentInfoWithError: \n")
        let info: NSAttributedString = NSAttributedString(
            string: error.localizedDescription,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0, alpha: 1)]
        )
        str.appendAttributedString(info)
        self.consoleLog(str)
        
        // Change status label
        self.statusLabel.text = "Card Reader error"
    }
    
    func cardReaderDidChangeStatus(status: AnyObject) {
        // Print message to screen
        let str: NSMutableAttributedString = NSMutableAttributedString(string: "cardReaderDidChangeStatus: ")
        let info: NSAttributedString = NSAttributedString(
            string: status.description,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0, blue: 1, alpha: 1)]
        )
        str.appendAttributedString(info)
        self.consoleLog(str)
        
        // Change status label
        switch status as! String {
            case kWPCardReaderStatusNotConnected:
                self.statusLabel.text = "Connect Card Reader"
            case kWPCardReaderStatusWaitingForSwipe:
                self.statusLabel.text = "Swipe Card"
            case kWPCardReaderStatusSwipeDetected:
                self.statusLabel.text = "Swipe Detected..."
            case kWPCardReaderStatusTokenizing:
                self.statusLabel.text = "Tokenizing..."
            case kWPCardReaderStatusStopped:
                self.statusLabel.text = "Card Reader Stopped"
            default:
                break
        }
    }
    
    func paymentInfo(paymentInfo: WPPaymentInfo, didTokenize paymentToken: WPPaymentToken) {
        // Change status label
        self.statusLabel.text = "Tokenized!"
        
        // Print message to console
        let str: NSMutableAttributedString = NSMutableAttributedString(string: "paymentInfo:didTokenize: \n")
        let info: NSAttributedString = NSAttributedString(
            string: paymentToken.description,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0, blue: 1, alpha: 1)]
        )
        str.appendAttributedString(info)
        self.consoleLog(str)
    }
    
    func paymentInfo(paymentInfo: WPPaymentInfo, didFailTokenization error: NSError) {
        // Change status label
        self.statusLabel.text = "Tokenization error"
        
        // Print message to console
        let str: NSMutableAttributedString = NSMutableAttributedString(string: "paymentInfo:didFailTokenization: \n")
        let info: NSAttributedString = NSAttributedString(
            string: error.localizedDescription,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0, alpha: 1)]
        )
        str.appendAttributedString(info)
        self.consoleLog(str)
    }
    
    func didStoreSignature(signatureUrl: String, forCheckoutId checkoutId: String) {
        // Change status label
        self.statusLabel.text = "Signature success!"
        
        // Print message to console
        let str: NSMutableAttributedString = NSMutableAttributedString(string: "didStoreSignature: \n")
        let info: NSAttributedString = NSAttributedString(
            string: signatureUrl,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0, blue: 1, alpha: 1)]
        )
        str.appendAttributedString(info)
        self.consoleLog(str)
    }
    
    func didFailToStoreSignatureImage(image: UIImage, forCheckoutId checkoutId: String, withError error: NSError) {
        // Change status label
        self.statusLabel.text = "Signature error"
        
        // Print message to console
        let str: NSMutableAttributedString = NSMutableAttributedString(string: "didFailToStoreSignatureImage: \n")
        let info: NSAttributedString = NSAttributedString(
            string: error.localizedDescription,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0, alpha: 1)]
        )
        str.appendAttributedString(info)
        self.consoleLog(str)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}