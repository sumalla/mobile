//
//  ProgressButtonView.swift
//  Savant
//
//  Created by Stephen Silber on 4/13/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

class ProgressButtonView: UIView {
    
    enum ProgressState {
        case Normal
        case Spinning
        case Progress
    }
    
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    var mainButton: SCUButton
    var cancelButton: SCUButton
    var progressView: CircularProgressView
    var state: ProgressState = .Normal
    var shrunk = false
    
    required init(frame: CGRect, buttonTitle: String, radius: CGFloat, lineWidth: CGFloat, tintColor: UIColor) {
        mainButton = SCUButton(style: .StandardPillDark, title: buttonTitle)
        cancelButton = SCUButton(style: .StandardPillDark)
        progressView = CircularProgressView(frame: frame, radius: radius, lineWidth: lineWidth, tintColor: tintColor)
        
        super.init(frame: frame)
        
        self.addSubview(mainButton)
        self.addSubview(cancelButton)
        self.addSubview(activityIndicator)
        self.addSubview(progressView)
        
        self.sav_addFlushConstraintsForView(mainButton)
        self.sav_addCenteredConstraintsForView(progressView)
        
        setNeedsLayout()
        layoutIfNeeded()

        cancelButton.hidden = true
        cancelButton.setTitleColor(tintColor, forState: .Normal)

        progressView.userInteractionEnabled = false
        activityIndicator.userInteractionEnabled = false
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 26, height: Sizes.row * 5)
    }
    
    func setProgress(progress: CGFloat) {
        progressView.updateProgress(progress)
        setProgressState(.Progress)
    }

    func setProgressState(state: ProgressState) {
        if self.state != state {
            switch state {
            case .Normal:
                setButtonShrunk(false)
                activityIndicator.stopAnimating()
                cancelButton.setTitle("", forState: .Normal)
            case .Spinning:
                setButtonShrunk(true)
                activityIndicator.startAnimating()
                cancelButton.userInteractionEnabled = false
                cancelButton.setTitle("", forState: .Normal)
            case .Progress:
                setButtonShrunk(true)
                cancelButton.userInteractionEnabled = true
                activityIndicator.stopAnimating()
                cancelButton.setTitle("x", forState: .Normal)
            }
            
            self.state = state
        }
    }
    
    private func setActivityIndicatorAnimating(animating: Bool) {
        if animating {
            activityIndicator.alpha = 0
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                self.activityIndicator.alpha = 1
                }, completion: { (finished: Bool) -> Void in
                self.activityIndicator.startAnimating()
            })
        } else {
            activityIndicator.stopAnimating()
        }
    }
    private func setButtonShrunk(shrunk: Bool) {
        if self.shrunk != shrunk {
            self.shrunk = shrunk
            if shrunk {
                mainButton.hidden = true
                cancelButton.hidden = false
                
                cancelButton.frame = mainButton.frame
                cancelButton.center = mainButton.center
                self.activityIndicator.center = self.cancelButton.center
                
                UIView.animateWithDuration(0.25, delay: 0, usingSpringWithDamping: 0.95, initialSpringVelocity: 10, options: nil, animations: { () -> Void in
                    self.cancelButton.frame.size.width = self.cancelButton.frame.height
                    self.cancelButton.center = self.mainButton.center
                    }, completion: { (finished: Bool) -> Void in
                        self.progressView.hidden = false
                        self.progressView.frame.size = self.cancelButton.frame.size
                })
            } else {
                progressView.hidden = true
                progressView.updateProgress(0.0)

                UIView.animateWithDuration(0.25, delay: 0, usingSpringWithDamping: 0.95, initialSpringVelocity: 10, options: nil, animations: { () -> Void in
                    self.cancelButton.frame = self.mainButton.frame
                    self.cancelButton.center = self.mainButton.center
                    }, completion: { (finished: Bool) -> Void in
                        self.cancelButton.hidden = true
                        self.mainButton.hidden = false
                })
            }
        }
    }
}
