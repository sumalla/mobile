//
//  SlideAnimator.swift
//  Savant
//
//  Created by Stephen Silber on 4/14/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

enum SlideFromDirection {
    case Left
    case Right
    case Up
    case Down
}

class SlideAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    var fromDirection: SlideFromDirection = .Right
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 0.25
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let containerView = transitionContext.containerView()
        
        let animationDuration = self .transitionDuration(transitionContext)
        
        if let toView = toViewController.view, fromView = fromViewController.view {
            var curve: UIViewAnimationOptions = .CurveEaseOut
            
            var startFrame = toView.frame
            
            toView.frame = startFrame
            fromView.frame = startFrame;
            
            transitionContext.containerView().addSubview(fromView)
            transitionContext.containerView().addSubview(toView)
            
            switch fromDirection {
            case .Right:
                toView.frame.origin.x += CGRectGetWidth(startFrame)
                UIView.animateWithDuration(animationDuration, animations: { () -> Void in
                    toView.frame.origin.x -= CGRectGetWidth(startFrame)
                    fromView.frame.origin.x -= CGRectGetWidth(startFrame)
                    
                    }) { (finished) -> Void in
                        transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
                        let completed = !transitionContext.transitionWasCancelled()
                        
                        if completed {
                            fromView.removeFromSuperview()
                        } else {
                            toView.removeFromSuperview()
                        }
                    }
            case .Left:
                toViewController.view.frame = fromViewController.view.frame
                toViewController.view.frame.origin.x -= CGRectGetWidth(toViewController.view.frame)
                UIView.animateWithDuration(animationDuration, animations: { () -> Void in
                    toViewController.view.frame.origin.x += CGRectGetWidth(toViewController.view.frame)
                    fromViewController.view.frame.origin.x += CGRectGetWidth(toViewController.view.frame)
                    }) { (finished) -> Void in
                        transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
                }
            case .Up:
                println("")
            case .Down:
                println("")
            }
        }
    }
}
