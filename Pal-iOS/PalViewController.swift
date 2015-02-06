//
//  ViewController.swift
//  Pal-iOS
//
//  Created by Brian Charous on 2/5/15.
//  Copyright (c) 2015 The Best Comps Team. All rights reserved.
//

import UIKit

class PalViewController: UIViewController {
    
    @IBOutlet weak var inputTextBox:UITextField?
    @IBOutlet weak var textBoxYConstraint:NSLayoutConstraint?
    @IBOutlet weak var textBoxWidth:NSLayoutConstraint?
    @IBOutlet weak var prompt:UILabel?
    
    // constants
    let kTextBoxWidth:CGFloat = 300.0

    override func viewDidLoad() {
        super.viewDidLoad()
//        println("(\(self.view.center.x), \(self.view.center.y))")

//        inputTextBox!.center = self.view.center
        // Do any additional setup after loading the view, typically from a nib.
        let p = PalConnection()
        println(p.queryPal("weather in Northfield"))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func textFieldStartedEditing(sender: UITextField) {
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
    
}

