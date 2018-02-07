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
let SETTINGS_ACCOUNT_ID_KEY = "settingAccountId"

let EMV_AMOUNT_STRING = "22.61" // Magic success amount
let EMV_READER_SHOULD_RESET = false
let EMV_SELECT_APP_INDEX = 0

class ViewController: UIViewController, WPAuthorizationDelegate, WPCardReaderDelegate, WPCheckoutDelegate, WPTokenizationDelegate , WPBatteryLevelDelegate, UIActionSheetDelegate {
    
    var wepay = WePay()
    let userDefaults = UserDefaults.standard
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var statusLabel: UILabel!
    
    var accountId = Int()
    var selectCardReaderCompletion: ((Int) -> Void)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize WePay config with your clientId and environment
        let clientId: String = self.fetchSetting(SETTINGS_CLIENT_ID_KEY, withDefault: "171482")
        let environment: String = self.fetchSetting(SETTINGS_ENVIRONMENT_KEY, withDefault: kWPEnvironmentStage)
        self.accountId = Int(self.fetchSetting(SETTINGS_ACCOUNT_ID_KEY, withDefault: "1170640190"))!
        let config: WPConfig = WPConfig(clientId: clientId, environment: environment)
        
        // Allow WePay to use location services
        config.useLocation = true
        config.stopCardReaderAfterOperation = false
        config.restartTransactionAfterOtherErrors = false
        
        // Initialize WePay
        self.wepay = WePay(config: config)
        
        // Do any additional setup after loading the view, typically from a nib
        self.setupUserInterface()
        
        var str: NSAttributedString = NSAttributedString(
            string: "Environment: \(environment)",
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0.2, blue: 0, alpha: 1)]
        )
        self.consoleLog(str)
        
        str = NSAttributedString(
            string: "ClientId: \(clientId)",
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0.2, blue: 0, alpha: 1)]
        )
        self.consoleLog(str)
        
        str = NSAttributedString(
            string: "AccountId: \(self.accountId)",
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0.2, blue: 0, alpha: 1)]
        )
        self.consoleLog(str)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func fetchSetting(_ key: String, withDefault value: String) -> String {
        userDefaults.synchronize()
        var settings: String? = userDefaults.string(forKey: key)
        if settings == nil || settings!.isEmpty {
            settings = value
            userDefaults.set(settings, forKey: key)
            userDefaults.synchronize()
        }
        return settings!
    }
    
    func setupUserInterface() {        
        self.showStatus("Choose a payment method")
    }
    
    @IBAction func swipeInfoBtnPressed(_ sender: AnyObject) {
        // Change status label
        self.showStatus("Please wait...")
        
        // Print message to screen
        let str: NSAttributedString = NSAttributedString(
            string: "Info from credit card selected",
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0.2, blue: 0, alpha: 1)]
        )
        self.consoleLog(str)
        
        // Make WePay API call
        self.wepay.startTransactionForReading(with: self)
    }
    
    @IBAction func swipeTokenButtonPressed(_ sender: AnyObject) {
        // Change status label
        self.showStatus("Please wait...")
        
        // Print message to screen
        let str: NSAttributedString = NSAttributedString(
            string: "Tokenize credit card selected",
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0.2, blue: 0, alpha: 1)]
        )
        self.consoleLog(str)
        
        // Make WePay API call
        self.wepay.startTransactionForTokenizing(with: self, tokenizationDelegate: self, authorizationDelegate: self)
    }
    
    @IBAction func stopCardReaderButtonPressed(_ sender: AnyObject) {
        // Change status label
        self.showStatus("Stopping Card Reader")
        
        // Print message to screen
        let str: NSAttributedString = NSAttributedString(
            string: "Stop Card Reader selected",
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0.2, blue: 0, alpha: 1)]
        )
        self.consoleLog(str)
        
        // Make WePay API call
        self.wepay.stopCardReader()
    }
    
    @IBAction func manualEntryButtonPressed(_ sender: AnyObject) {
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
        self.showStatus("Please wait...")
        
        // Print message to screen
        let str: NSMutableAttributedString = NSMutableAttributedString(
            string: "Manual entry selected. Using sample info: \n",
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0.2, blue: 0, alpha: 1)]
        )
        let info: NSAttributedString = NSAttributedString(
            string: paymentInfo.description,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0, blue: 1, alpha: 1)]
        )
        str.append(info)
        self.consoleLog(str)
        
        // Make WePay API call
        self.wepay.tokenizePaymentInfo(paymentInfo, tokenizationDelegate: self)
    }
    
    @IBAction func storeSignatureButtonPressed(_ sender: AnyObject) {
        // Change status label
        self.showStatus("Storing Signature")
        
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
    
    @IBAction func batteryLevelButtonPressed(_ sender: AnyObject) {
        // Change status label
        self.showStatus("Checking Battery")
        
        // Print message to screen
        let str: NSAttributedString = NSAttributedString(
            string: "Check battery selected",
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0.2, blue: 0, alpha: 1)]
        )
        self.consoleLog(str)
        
        self.wepay.getCardReaderBatteryLevel(with: self, batteryLevelDelegate: self)
    }
    
    @IBAction func getRememberedCardReaderButtonPressed(_ sender: AnyObject) {
        self.showStatus("Getting remembered card reader")
        let cardReader = self.wepay.getRememberedCardReader()
        var rememberedCardReaderMessage = "No remembered card reader exists"
        
        if (cardReader != nil) {
            rememberedCardReaderMessage = String(format: "Remembered card reader is %@", cardReader!)
        }
        
        let str: NSAttributedString = NSAttributedString(
            string: rememberedCardReaderMessage,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0.2, blue: 0, alpha: 1)]
        )
        self.consoleLog(str);
    }
    
    @IBAction func forgetRememberedCardReaderButtonPressed(_ sender: AnyObject) {
        self.showStatus("Forgetting remembered card reader")
        self.wepay.forgetRememberedCardReader()
        
        let str: NSAttributedString = NSAttributedString(
            string: "Forgot the remembered card reader",
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0.2, blue: 0, alpha: 1)]
        )
        self.consoleLog(str);
    }
    
    func consoleLog(_ data: NSAttributedString) {
        // Fetch current text
        let text: NSMutableAttributedString = self.textView.attributedText.mutableCopy() as! NSMutableAttributedString
        
        // Create and append date string
        let format: DateFormatter = DateFormatter()
        format.dateStyle = .medium
        let dateStr: String = format.string(from: Date())
        text.append(NSAttributedString(string: "\n[\(dateStr)] "))
        
        // Append new string
        text.append(data)
        self.textView.attributedText = text
        
        // Scroll the text view to the bottom
        self.textView.scrollRangeToVisible(NSMakeRange(self.textView.text.characters.count, 0))
        
        // Log to console as well
        NSLog("%@", data.string)
    }
    
    func showStatus(_ message: String) {
        self.statusLabel.text = message
    }
    
    // MARK: WPCardReaderDelegate methods
    
    public func selectEMVApplication(_ applications: [Any]!, completion: ((Int) -> Void)!) {
        // In production apps, the payer must choose the application they want to use.
        // Here, we always select the first application in the array
        let selectedIndex: Int = Int(EMV_SELECT_APP_INDEX)
        
        // Print message to console
        var str: NSMutableAttributedString = NSMutableAttributedString(string: "Select App Id: \n")
        let info: NSAttributedString = NSAttributedString(
            string: applications.description,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0, blue: 1, alpha: 1)]
        )
        str.append(info)
        self.consoleLog(str)
        
        str = NSMutableAttributedString(string: "Selected App Id index: \(selectedIndex)")
        self.consoleLog(str)
        
        // Execute the completion
        completion(selectedIndex)
    }
    
    func didRead(_ paymentInfo: WPPaymentInfo) {
        // Print message to screen
        let str: NSMutableAttributedString = NSMutableAttributedString(string: "didReadPaymentInfo: \n")
        let info: NSAttributedString = NSAttributedString(
            string: paymentInfo.description,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0, blue: 1, alpha: 1)]
        )
        str.append(info)
        self.consoleLog(str)
        
        // Change status label
        self.showStatus("Got payment info!")
    }
    
    func didFailToReadPaymentInfoWithError(_ error: Error) {
        // Print message to screen
        let str: NSMutableAttributedString = NSMutableAttributedString(string: "didFailToReadPaymentInfoWithError: \n")
        let info: NSAttributedString = NSAttributedString(
            string: error.localizedDescription,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0, alpha: 1)]
        )
        str.append(info)
        self.consoleLog(str)
        
        // Change status label
        self.showStatus("Card Reader error")
    }
    
    func cardReaderDidChangeStatus(_ status: Any) {
        // Print message to screen
        let str: NSMutableAttributedString = NSMutableAttributedString(string: "cardReaderDidChangeStatus: ")
        let info: NSAttributedString = NSAttributedString(
            string: (status as! String).description,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0, blue: 1, alpha: 1)]
        )
        str.append(info)
        self.consoleLog(str)
        
        // Change status label
        switch status as! String {
            case kWPCardReaderStatusNotConnected:
                self.showStatus("Connect Card Reader")
            case kWPCardReaderStatusWaitingForCard:
                self.showStatus("Swipe/Dip Card")
            case kWPCardReaderStatusSwipeDetected:
                self.showStatus("Swipe Detected...")
            case kWPCardReaderStatusTokenizing:
                self.showStatus("Tokenizing...")
            case kWPCardReaderStatusStopped:
                self.showStatus("Card Reader Stopped")
            default:
                self.showStatus((status as! String).description)
        }
    }
    
    @objc func shouldResetCardReader(completion: ((Bool) -> Void)!) {
        // Change this to true if you want to reset the card reader
        completion(EMV_READER_SHOULD_RESET)
    }
    
    func authorizeAmount(completion: ((NSDecimalNumber?, String?, Int) -> Void)!) {
        let amount: NSDecimalNumber = NSDecimalNumber(string: EMV_AMOUNT_STRING)
        let currencyCode: String = kWPCurrencyCodeUSD
        
        // Change status label
        self.showStatus("Providing auth info")
        
        // Print message to console
        let infoString: String = "amount: \(amount), currency: \(currencyCode), accountId: \(self.accountId)"
        let str: NSAttributedString = NSAttributedString(
            string: "Providing auth info: " + infoString,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0.2, blue: 0, alpha: 1)]
        )
        self.consoleLog(str)
        
        // execute the completion
        completion(amount, currencyCode, self.accountId)
    }
    
    func selectCardReader(_ cardReaderNames: [Any]!, completion: ((Int) -> Void)!) {
        let cardReaderNameStrings = cardReaderNames as! [String]
        let selectController = UIActionSheet(title: "Choose a card reader device", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil)
        selectController.actionSheetStyle = .default
        
        for cardreaderName in cardReaderNameStrings as [String] {
            selectController.addButton(withTitle: cardreaderName)
        }
        
        self.selectCardReaderCompletion = completion
        selectController.show(in: self.view)
    }
    
    // MARK: UIActionSheetDelegate
    
    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
        self.selectCardReaderCompletion(buttonIndex - 1)
    }
    
    // MARK: WPTokenizationDelegate methods
    
    func paymentInfo(_ paymentInfo: WPPaymentInfo, didTokenize paymentToken: WPPaymentToken) {
        // Change status label
        self.showStatus("Tokenized!")
        
        // Print message to console
        let str: NSMutableAttributedString = NSMutableAttributedString(string: "paymentInfo:didTokenize: \n")
        let info: NSAttributedString = NSAttributedString(
            string: paymentToken.description,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0, blue: 1, alpha: 1)]
        )
        str.append(info)
        self.consoleLog(str)
    }
    
    func paymentInfo(_ paymentInfo: WPPaymentInfo, didFailTokenization error: Error) {
        // Change status label
        self.showStatus("Tokenization error")
        
        // Print message to console
        let str: NSMutableAttributedString = NSMutableAttributedString(string: "paymentInfo:didFailTokenization: \n")
        let info: NSAttributedString = NSAttributedString(
            string: error.localizedDescription,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0, alpha: 1)]
        )
        str.append(info)
        self.consoleLog(str)
    }
    
    // MARK: WPCheckoutDelegate methods
    
    func didStoreSignature(_ signatureUrl: String, forCheckoutId checkoutId: String) {
        // Change status label
        self.showStatus("Signature success!")
        
        // Print message to console
        let str: NSMutableAttributedString = NSMutableAttributedString(string: "didStoreSignature: \n")
        let info: NSAttributedString = NSAttributedString(
            string: signatureUrl,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0, blue: 1, alpha: 1)]
        )
        str.append(info)
        self.consoleLog(str)
    }
    
    func didFail(toStoreSignatureImage image: UIImage, forCheckoutId checkoutId: String, withError error: Error) {
        // Change status label
        self.showStatus("Signature error")
        
        // Print message to console
        let str: NSMutableAttributedString = NSMutableAttributedString(string: "didFailToStoreSignatureImage: \n")
        let info: NSAttributedString = NSAttributedString(
            string: error.localizedDescription,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0, alpha: 1)]
        )
        str.append(info)
        self.consoleLog(str)
    }
    
    // MARK: WPAuthorizationDelegate methods
    
    func insertPayerEmail(completion: ((String?) -> Void)!) {
        let email: String = "emv@example.com"
        
        // Print message to console
        let str: NSAttributedString = NSAttributedString(
            string: "Providing email: " + email,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0.2, blue: 0, alpha: 1)]
        )
        self.consoleLog(str)
        
        completion(email)
    }
    
    func paymentInfo(_ paymentInfo: WPPaymentInfo, didAuthorize authorizationInfo: WPAuthorizationInfo) {
        // Print message to screen
        let str: NSMutableAttributedString = NSMutableAttributedString(string: "didAuthorize: \n")
        let info: NSAttributedString = NSAttributedString(
            string: authorizationInfo.description,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0, blue: 1, alpha: 1)]
        )
        str.append(info)
        self.consoleLog(str)
        
        // Change status label
        self.showStatus("Authorized")
    }
    
    func paymentInfo(_ paymentInfo: WPPaymentInfo, didFailAuthorization error: Error) {
        // Print message to screen
        let str: NSMutableAttributedString = NSMutableAttributedString(string: "didFailAuthorization: \n")
        let info: NSAttributedString = NSAttributedString(
            string: error.localizedDescription,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0, alpha: 1)]
        )
        str.append(info)
        self.consoleLog(str)
        
        // Change status label
        self.showStatus("Authorization failed")
    }
    
    // MARK: WPBatteryLevelDelegate methods
    
    func didGetBatteryLevel(_ batteryLevel: Int32) {
        // Print message to screen
        let str: NSMutableAttributedString = NSMutableAttributedString(string: "didGetBatteryLevel: \n")
        let info: NSAttributedString = NSAttributedString(
            string: batteryLevel.description,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 0, green: 0, blue: 1, alpha: 1)]
        )
        str.append(info)
        self.consoleLog(str)
        
        // Change status label
        self.showStatus("Battery Level: \(batteryLevel)")
    }
    
    func didFail(toGetBatteryLevelwithError error: Error!) {
        // Print message to screen
        let str: NSMutableAttributedString = NSMutableAttributedString(string: "didFailToGetBatteryLevelwithError: \n")
        let info: NSAttributedString = NSAttributedString(
            string: error.localizedDescription,
            attributes: [NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0, alpha: 1)]
        )
        str.append(info)
        self.consoleLog(str)
        
        // Change status label
        self.showStatus("Battery Level error")
    }
}
