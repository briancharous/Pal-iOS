//
//  ViewController.swift
//  Pal-iOS
//
//  Created by Brian Charous on 2/5/15.
//  Copyright (c) 2015 The Best Comps Team. All rights reserved.
//

import UIKit
import WebKit

class PalViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var inputTextBox:UITextField?
    @IBOutlet weak var textBoxYConstraint:NSLayoutConstraint?
    @IBOutlet weak var textBoxWidth:NSLayoutConstraint?
    @IBOutlet weak var prompt:UILabel?
    
    let palConnection = PalConnection()
//    let palResponseView = PalResponseView.instanceFromNib() as PalResponseView
    let palResponseView = WKWebView(frame: CGRectZero)
    
    // constants
    let kTextBoxWidth:CGFloat = 300.0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        inputTextBox?.delegate = self
        self.view.setTranslatesAutoresizingMaskIntoConstraints(false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func asyncQueryPal(query: String) {
        dispatch_async(dispatch_queue_create("com.pal.pal", nil), {
            if let response = self.palConnection.queryPal(query) {
                dispatch_async(dispatch_get_main_queue(), {
                    self.updateResponseView(query, response: response)
                })
            }
        })
    }
    
    func updateResponseView(query: NSString, response: NSDictionary) {
        // add constraints to put response view in main view
        self.inputTextBox?.resignFirstResponder()
//        self.view.addSubview(palResponseView)
//        palResponseView.backgroundColor = UIColor.orangeColor()
//        palResponseView.query = query as String
//        palResponseView.response = response
//        palResponseView.frame.size = CGSizeMake(5, 5)
//        palResponseView.center = self.view.center
        palResponseView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.view.addSubview(palResponseView)
        palResponseView.scrollView.scrollEnabled = false
        var viewsDict = Dictionary<String, UIView>()
        viewsDict["responseView"] = palResponseView
        viewsDict["textbox"] = inputTextBox
        // place the response view below the text box, extending to the bottom of the scren
        let c1:Array = NSLayoutConstraint
                .constraintsWithVisualFormat("V:[textbox]-20-[responseView]-|",
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
            if let summary = result.objectForKey("summary") as? String {
                palResponseView.loadHTMLString(formatResponse(query as NSString, summary: summary)!, baseURL: NSBundle.mainBundle().bundleURL)
            }
        }
    }
    
    func formatResponse(query: String, summary: String) -> String? {
        let templatePath = NSBundle.mainBundle().pathForResource("ResponseTemplate", ofType: "html")
        let templateString = String(contentsOfFile: templatePath!, encoding: NSUTF8StringEncoding, error: nil)
        var responseString = templateString?.stringByReplacingOccurrencesOfString("{0}", withString: query, options: NSStringCompareOptions.LiteralSearch, range: nil)
        responseString = responseString?.stringByReplacingOccurrencesOfString("{1}", withString: summary, options: NSStringCompareOptions.LiteralSearch, range: nil)
        return responseString
    }
    
//    @IBAction func textFieldStartedEditing(sender: UITextField) {
//        let halfHeight = self.view.frame.size.height/2;
//        let textboxOffset:CGFloat = 50;
//        self.view.layoutIfNeeded()
//        UIView.animateWithDuration(0.35, animations: {
//            // move text box to top, grow text box, hide prompt
//            self.textBoxYConstraint?.constant = halfHeight - textboxOffset
//            self.textBoxWidth?.constant = self.view.frame.size.width - 4
//            self.prompt?.alpha = 0
//            self.view.layoutIfNeeded()
//        })
//    }

    @IBAction func textFieldEndedEditing(sender: UITextField) {
        self.view.layoutIfNeeded()
        UIView.animateWithDuration(0.35, animations: {
            // revert ui to unselected state
            self.textBoxYConstraint?.constant = 0
            self.textBoxWidth?.constant = self.kTextBoxWidth
            self.prompt?.alpha = 1
            self.view.layoutIfNeeded()
        })
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        // end editing if touches up anywhere but the text box
        inputTextBox?.endEditing(true)
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
            asyncQueryPal(textField.text)
            return true
        }
        return false
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        
    }
}
