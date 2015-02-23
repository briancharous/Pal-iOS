//
//  ViewController.swift
//  Pal-iOS
//
//  Created by Brian Charous on 2/5/15.
//  Copyright (c) 2015 The Best Comps Team. All rights reserved.
//

import CoreLocation
import UIKit
import Social
import Accounts

class PalViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate, UIWebViewDelegate {
    
    @IBOutlet weak var inputTextBox:UITextField?
    @IBOutlet weak var textBoxYConstraint:NSLayoutConstraint?
    @IBOutlet weak var textBoxWidth:NSLayoutConstraint?
    @IBOutlet weak var prompt:UILabel?
    
    let palConnection = PalConnection()
    let palResponseView = UIWebView(frame: CGRectZero)

    // constants
    let kTextBoxWidth:CGFloat = 300.0
    
    let locationManager = CLLocationManager()
    var pendingRequest:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        inputTextBox?.delegate = self
        self.view.setTranslatesAutoresizingMaskIntoConstraints(false)
        locationManager.delegate = self
        palResponseView.delegate = self
        let singleTapRecognizer = UITapGestureRecognizer(target: palResponseView, action: "showPrompt")
        singleTapRecognizer.numberOfTapsRequired = 1
        singleTapRecognizer.cancelsTouchesInView = false
        palResponseView.addGestureRecognizer(singleTapRecognizer)
        // WebKit framework appears to be broken, remove this to use UIWebView
//        palResponseView.navigationDelegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func asyncQueryPal(query: String, location: String?) {
        dispatch_async(dispatch_queue_create("com.pal.pal", nil), {
            if let response = self.palConnection.queryPal(query, location: location) {
                dispatch_async(dispatch_get_main_queue(), {
                    self.updateResponseView(query, response: response)
                })
            }
        })
    }
    
    func updateResponseView(query: NSString, response: NSDictionary) {
        // add constraints to put response view in main view
        self.inputTextBox?.resignFirstResponder()

        palResponseView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.view.addSubview(palResponseView)
        palResponseView.scalesPageToFit = true
        var viewsDict = Dictionary<String, UIView>()
        viewsDict["responseView"] = palResponseView
        viewsDict["textbox"] = inputTextBox
        // place the response view below the text box, extending to the bottom of the scren
        let c1:Array = NSLayoutConstraint
                .constraintsWithVisualFormat("V:[textbox]-[responseView]-|",
                options: NSLayoutFormatOptions(0),
                metrics: nil,
                views: viewsDict)
        // constrain the response view to be equal to the width of the parent view
        let c2:Array = NSLayoutConstraint
                .constraintsWithVisualFormat("H:|-0-[responseView]-0-|",
                options: NSLayoutFormatOptions(0),
                metrics: nil,
                views: viewsDict)
        self.view.addConstraints(c1)
        self.view.addConstraints(c2)
        
        if let result = response.objectForKey("result") as? NSDictionary {
            let data = result.objectForKey("data") as? String
            if let status = result.objectForKey("status") as? Int {
                switch status {
                case 1:
                    // success, just update the response view
                    if let summary = result.objectForKey("summary") as? String {
                        let responseString = formatResponse(query as NSString, summary: summary, data: data)
                        webViewLoadHTMLString(responseString)
                    }
                case 3:
                    handleClientDataResponse(query, result: result)
                case 4:
                    handleExternalAction(result.objectForKey("external") as String, payload: result.objectForKey("payload") as NSDictionary)
                    // do something about external actions
                default: ()
                }
            }
        }
    }
    
    func handleClientDataResponse(query: String, result: NSDictionary) {
        // it needs more data from the client, figure out what's needed
        let needs = result.objectForKey("needs_client") as NSDictionary
        for need in needs.allKeys {
            let n = needs.objectForKey(need) as NSDictionary
            for nkey in n.allKeys {
                let type = n.objectForKey(nkey) as String
                switch type {
                case "loc":
                    resendWithLocation(query)
                default: ()
                }
            }
        }
    }
    
    func resendWithLocation(query: String) {
        // send new query with location data attached
        let authStatus = CLLocationManager.authorizationStatus()
        println("location: \(locationManager.location), status:\(authStatus)")
        if authStatus == CLAuthorizationStatus.AuthorizedWhenInUse || authStatus == CLAuthorizationStatus.Authorized {
            // already authorized, start updating location, resend query in callback
            if (locationManager.location != nil) {
                var lastLocation = locationManager.location
                let delta = lastLocation.timestamp.timeIntervalSinceNow
                if abs(delta) < 60 {
                    // if the location is less than 1 minute old, just resend right now
                    let locData = "\(lastLocation.coordinate.latitude),\(lastLocation.coordinate.longitude)"
                    asyncQueryPal(query, location: locData)
                }
                else {
                    locationManager.startUpdatingLocation()
                    pendingRequest = query
                }
            }
            else {
                locationManager.startUpdatingLocation()
                pendingRequest = query
            }
        }
        else if authStatus == CLAuthorizationStatus.NotDetermined {
            // requset authorization
            locationManager.requestWhenInUseAuthorization()
            pendingRequest = query
        }
        else {
            let notAuthorizedAlert = UIAlertView(title: "Not authorized to use location",
                message: "PAL can't process your request because you haven't authorized PAL to use your location.",
                delegate: nil,
                cancelButtonTitle: "Dismiss")
            notAuthorizedAlert.show()
        }
    }
    
    // handle actions requested by the server
    func handleExternalAction(action: String, payload: NSDictionary) {
        switch action {
        case "facebook":
            println("facebook time")
            if let message = payload.objectForKey("data") as? String {
                postToFacebook(message)
            }
            println(payload)
        default:
            return
        }
    }
    
    // post a message to facebook
    func postToFacebook(message: String) {
        let accountStore = ACAccountStore()
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierFacebook)
        let initialOptions = [ACFacebookAppIdKey : "363891403803678", ACFacebookPermissionsKey : ["email"], ACFacebookAudienceKey : ACFacebookAudienceFriends]
        accountStore.requestAccessToAccountsWithType(accountType, options: initialOptions, completion: {
            granted, error in
            if granted {
                let options = [ACFacebookAppIdKey : "363891403803678", ACFacebookPermissionsKey : ["publish_actions"], ACFacebookAudienceKey : ACFacebookAudienceFriends]
                accountStore.requestAccessToAccountsWithType(accountType, options: options, completion: {
                    granted, error in
                    if granted {
                        let accounts = accountStore.accountsWithAccountType(accountType)
                        if accounts.count > 0 {
                            let fbaccount = accounts[0] as ACAccount
                            let params = ["access_token" : fbaccount.credential.oauthToken, "message" : message]
                            let feedUrl = NSURL(string: "https://graph.facebook.com/me/feed")
                            let post = SLRequest(forServiceType: SLServiceTypeFacebook, requestMethod: SLRequestMethod.POST, URL: feedUrl, parameters: params)
                            post.performRequestWithHandler({
                                response, urlResponse, postError in
                                if (postError == nil) {
                                    let responseString = self.formatResponse("", summary: "OK, I'll post that to Facebook", data: nil)
                                    self.webViewLoadHTMLString(responseString)
                                }
                                else {
                                    let responseString = self.formatResponse("", summary: postError.localizedDescription, data: nil)
                                    self.webViewLoadHTMLString(responseString)
                                }
                            })
                        }
                        else {
                            let responseString = self.formatResponse("",
                                summary: "Sorry, I was unable to post. It looks like you don't have a Facebook account setup on this device.",
                                data: nil)
                            self.webViewLoadHTMLString(responseString)
                        }
                    }
                    else {
                        let responseString = self.formatResponse("",
                            summary: "Sorry, I was unable to post. \(error.localizedDescription)",
                            data: nil)
                        self.webViewLoadHTMLString(responseString)
                    }
                })
            }
            else {
                let responseString = self.formatResponse("",
                    summary: "Sorry, I was unable to post. \(error.localizedDescription)",
                    data: nil)
                self.webViewLoadHTMLString(responseString)
            }
        })
    }
    
    // read HTML template from file, format the response
    func formatResponse(query: String, summary: String, data: String?) -> String {
        let templatePath = NSBundle.mainBundle().pathForResource("ResponseTemplate", ofType: "html")
        let templateString = String(contentsOfFile: templatePath!, encoding: NSUTF8StringEncoding, error: nil)
        var responseString = templateString!.stringByReplacingOccurrencesOfString("{0}", withString: query, options: NSStringCompareOptions.LiteralSearch, range: nil)
        if (data != nil) {
            let dataDiv = "<div class=\"data\">\(data)</div>"
            let summaryString = "\(summary)\(data!)"
            responseString = responseString.stringByReplacingOccurrencesOfString("{1}", withString: summaryString, options: NSStringCompareOptions.LiteralSearch, range: nil)
        }
        else {
            responseString = responseString.stringByReplacingOccurrencesOfString("{1}", withString: summary, options: NSStringCompareOptions.LiteralSearch, range: nil)
        }
        return responseString
    }
    
    func webViewLoadHTMLString(string: String) {
        let templatePath = NSBundle.mainBundle().pathForResource("ResponseTemplate", ofType: "html")
        let requestUrl = NSURL(string: templatePath!)
        let request = NSURLRequest(URL: requestUrl!)
        self.palResponseView.loadHTMLString(string, baseURL: NSBundle.mainBundle().bundleURL)
    }
    
    // UITextField Delegate stuff
    
    func textFieldDidBeginEditing(textField: UITextField) {
        let halfHeight = self.view.frame.size.height/2;
        let textboxOffset:CGFloat = 50;
        self.view.layoutIfNeeded()
        UIView.animateWithDuration(0.35, animations: {
            // move text box to top, grow text box, hide prompt
            self.textBoxYConstraint?.constant = halfHeight - textboxOffset
            self.textBoxWidth?.constant = self.view.frame.size.width - 4
            self.prompt?.alpha = 0
            self.view.layoutIfNeeded()
        })
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // allow return if text in box not empty
        if textField.text != "" {
            asyncQueryPal(textField.text, location: nil)
            return true
        }
        return false
    }
    

    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        self.view.endEditing(true)
        showPrompt()
    }
    
    func showPrompt() {
        UIView.animateWithDuration(0.35, animations: {
            // revert ui to unselected state
            self.textBoxYConstraint?.constant = 0
            self.textBoxWidth?.constant = self.kTextBoxWidth
            self.prompt?.alpha = 1
            self.palResponseView.removeFromSuperview()
            self.palResponseView.removeConstraints(self.palResponseView.constraints())
            self.view.layoutIfNeeded()
        })

    }
    
    // CLLocationManagerDelegate stuff
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        println("updated location")
        if let location = locations.reverse()[0] as? CLLocation { // most recent location
            if (pendingRequest != nil) {
                let locData = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
                asyncQueryPal(pendingRequest!, location: locData)
                pendingRequest = nil
                manager.stopUpdatingLocation()
            }
        }
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if (pendingRequest != nil) {
            locationManager.startUpdatingLocation()
        }
    }
    
    // UIWebViewStuff
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == UIWebViewNavigationType.LinkClicked {
            UIApplication.sharedApplication().openURL(request.URL)
            return false
        }
        return true
    }
    
    // WebKit view is broken, doesn't load local CSS
    // WKNavigationDelegate stuff
    /*
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        // open all links in safari
        if navigationAction.navigationType == WKNavigationType.LinkActivated {
            UIApplication.sharedApplication().openURL(navigationAction.request.URL)
            decisionHandler(WKNavigationActionPolicy.Cancel)
        }
        decisionHandler(WKNavigationActionPolicy.Allow)
    }
    */
}
