//
//  ZoomOutAnimator.swift
//  Prototype
//
//  Created by Stephen Silber on 3/10/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation

class ZoomOutAnimator: PullDownAnimator {
	
	var toAlpha:CGFloat
	
    override func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 0.3
    }
	
	init(toAlpha:CGFloat = 0.5) {
		self.toAlpha = toAlpha
	}
	
    override func handleAnimation(transitionContext: UIViewControllerContextTransitioning, completion: ((Bool) -> Void)) {
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)
        
        if let toView = toViewController?.view, fromView = fromViewController?.view {
            var curve: UIViewAnimationOptions = .CurveEaseOut
            
            if (interactive) {
                curve = .CurveLinear
            }
            
            if presenting {
                var startFrame = toView.frame
                
                toView.frame = startFrame
                fromView.frame = startFrame;
                
                transitionContext.containerView().addSubview(fromView)
                transitionContext.containerView().addSubview(toView)
                
                toView.transform = CGAffineTransformMakeScale(1.65, 1.65)
                toView.alpha = 0.15
                
                UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, options: curve, animations: { () -> Void in
                    toView.transform = CGAffineTransformMakeScale(1, 1)
                    fromView.transform = CGAffineTransformMakeScale(0.8, 0.8)
                    toView.alpha = 1
                    fromView.alpha = self.toAlpha
                    
                    }) { (complete) in
                        let completed = !transitionContext.transitionWasCancelled()
                        
                        if completed {
                            fromView.removeFromSuperview()
                            fromView.transform = CGAffineTransformMakeScale(1, 1)
                        } else {
                            toView.removeFromSuperview()
                            toView.transform = CGAffineTransformMakeScale(1, 1)
                        }
						
                        completion(complete)
                }
            } else {
                var endFrame = fromView.frame
                
                transitionContext.containerView().addSubview(toView)
                transitionContext.containerView().addSubview(fromView)
                
                fromView.transform = CGAffineTransformMakeScale(1, 1)
                toView.transform = CGAffineTransformMakeScale(0.8, 0.8)
                fromView.alpha = 1
                toView.alpha = self.toAlpha
                
                UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, options: curve, animations: { () -> Void in
                    fromView.transform = CGAffineTransformMakeScale(1.65, 1.65)
                    fromView.alpha = 0
                    toView.transform = CGAffineTransformMakeScale(1, 1)
                    toView.alpha = 1
                    }) { (complete) in
                        let completed = !transitionContext.transitionWasCancelled()
                        
                        if completed {
                            fromView.removeFromSuperview()
                            fromView.transform = CGAffineTransformMakeScale(1, 1)
                        } else {
                            toView.removeFromSuperview()
                            toView.transform = CGAffineTransformMakeScale(1, 1)
                        }
                        
                        completion(complete)
                }
            }
        }
    }
}
