//
//  PulsingIconView.swift
//  Savant
//
//  Created by Stephen Silber on 4/24/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

class PulsingIconView: UIView {

    var imageView = UIImageView(image: UIImage(named: "SmartHost")?.tintedImageWithColor(Colors.color1shade1))
    var timer: NSTimer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(imageView)
        self.sav_addFlushConstraintsForView(imageView)

        startAnimating()
        
        let tap = UITapGestureRecognizer(target: self, action: "pulse")
        imageView.addGestureRecognizer(tap)
    }
    
//    convenience init(frame: CGRect, image: UIImage) {
//        smartHostView = UIImageView(image: image)
//        self.init(frame: frame)
//    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func borderAnimation() -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "borderWidth")
        animation.toValue = UIScreen.screenPixel()
        animation.delegate = self
        animation.duration = 1
        animation.timingFunction = CATransaction.animationTimingFunction()
        animation.removedOnCompletion = true
        return animation
    }

    func transformAnimation() -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1
        animation.toValue = 1.5
        animation.delegate = self
        animation.duration = 1
        animation.timingFunction = CATransaction.animationTimingFunction()
        animation.removedOnCompletion = true
        return animation
    }

    func alphaAnimation() -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0
        animation.delegate = self
        animation.duration = 1
        animation.timingFunction = CATransaction.animationTimingFunction()
        animation.removedOnCompletion = true
        return animation
    }
    
    override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        if let layer = anim.valueForKey("animationLayer") as? CALayer {
            layer.removeFromSuperlayer()
        }
    }
    
    func pulse() {
        var pulseLayer = CALayer()
        pulseLayer.bounds = CGRect(x: 0, y: 0, width: imageView.frame.width, height: imageView.frame.height)
        pulseLayer.backgroundColor = UIColor.clearColor().CGColor
        pulseLayer.cornerRadius = imageView.frame.width / 2
        pulseLayer.borderColor = Colors.color1shade1.CGColor
        pulseLayer.borderWidth = 3
        pulseLayer.position = imageView.center
        
        self.layer.addSublayer(pulseLayer)
        
        pulseLayer.addAnimation(self.borderAnimation(), forKey: "borderAnimation")
        pulseLayer.addAnimation(self.transformAnimation(), forKey: "transformAnimation")
        pulseLayer.addAnimation(self.alphaAnimation(), forKey: "alphaAnimation")
    }
    
    func startAnimating() {
        timer?.invalidate()
        timer = NSTimer.sav_scheduledTimerWithTimeInterval(1.5, repeats: true, block: { () -> Void in
            self.pulse()
            NSTimer.sav_scheduledBlockWithDelay(0.5, block: { () -> Void in
                self.pulse()
            })
        })
        timer?.fire()
    }
    
    func stopAnimating() {
        timer?.invalidate()
        self.layer.removeAllAnimations()
    }
}
