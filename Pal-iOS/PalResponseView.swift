//
//  PalResponseView.swift
//  Pal-iOS
//
//  Created by Brian Charous on 2/6/15.
//  Copyright (c) 2015 The Best Comps Team. All rights reserved.
//

import UIKit
import AVFoundation

class PalResponseView: UIView {
    
    @IBOutlet var queryLabel: UILabel? = UILabel()
    @IBOutlet var responseLabel: UILabel? = UILabel()

    var query: String? {
        didSet {
            self.queryLabel?.text = self.query
        }
    }
    
    var response: NSDictionary? {
        didSet {
            if let result = self.response?.objectForKey("result") as? NSDictionary {
                if let summary = result.objectForKey("summary") as? String {
                    self.responseLabel?.text = summary
                    let synthesizer = AVSpeechSynthesizer()
                    let utterance = AVSpeechUtterance(string: summary)
                    let voice = AVSpeechSynthesisVoice()
                    println(AVSpeechSynthesisVoice.speechVoices())
                    utterance.rate = AVSpeechUtteranceDefaultSpeechRate
                    synthesizer.speakUtterance(utterance)
                }
            }
        }
    }

    
    convenience init(frame: CGRect, query: String, response: NSDictionary) {
        self.init(frame: frame)
        self.query = String()
        self.response = NSDictionary()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(NSBundle.mainBundle().loadNibNamed("PalResponseView", owner: self, options: nil)[0] as UIView)
//        self.addSubview(
//            UINib(
//                nibName: "PalResponseView",
//                bundle: NSBundle.mainBundle()
//            ).instantiateWithOwner(nil, options: nil)[0] as UIView
//        )
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.setTranslatesAutoresizingMaskIntoConstraints(false)
    }
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "PalResponseView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as UIView
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        self.addSubview(responseLabel)
        self.setTranslatesAutoresizingMaskIntoConstraints(false)
        let centerX = NSLayoutConstraint(
            item: responseLabel,
            attribute: NSLayoutAttribute.CenterX,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self,
            attribute: NSLayoutAttribute.CenterX,
            multiplier: 1,
            constant: 0)
        let centerY = NSLayoutConstraint(
            item: responseLabel,
            attribute: NSLayoutAttribute.CenterY,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self,
            attribute: NSLayoutAttribute.CenterY,
            multiplier: 1,
            constant: 0)
        self.addConstraint(centerX)
    }
    */
}

