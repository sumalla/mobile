//
//  PopoverPresentationAnimationController.swift
//  Prototype
//
//  Created by Stephen Silber on 3/13/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation

class PopoverPresentationAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    let isPresenting :Bool
    let duration :NSTimeInterval = 0.4
    
    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
        
        super.init()
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return self.duration
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning)  {
        if isPresenting {
            animatePresentationWithTransitionContext(transitionContext)
        }
        else {
            animateDismissalWithTransitionContext(transitionContext)
        }
    }

    func animatePresentationWithTransitionContext(transitionContext: UIViewControllerContextTransitioning) {
        let presentedController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let presentedControllerView = transitionContext.viewForKey(UITransitionContextToViewKey)!
        let containerView = transitionContext.containerView()
        
        containerView.addSubview(presentedControllerView)
        presentedControllerView.layer.opacity = 0

        presentedControllerView.frame.origin.y += 50.0

        UIView.animateWithDuration(self.duration, delay: 0.0, usingSpringWithDamping: 0.98, initialSpringVelocity: 15, options: .AllowUserInteraction, animations: {
        presentedControllerView.frame.origin.y -= 50.0
            presentedControllerView.layer.opacity = 1
            
            }, completion: {(completed: Bool) -> Void in
                transitionContext.completeTransition(completed)
        })
    }
    
    func animateDismissalWithTransitionContext(transitionContext: UIViewControllerContextTransitioning) {
        let presentedControllerView = transitionContext.viewForKey(UITransitionContextFromViewKey)!
        let containerView = transitionContext.containerView()

        containerView.addSubview(presentedControllerView)
        presentedControllerView.layer.opacity = 1

        UIView.animateWithDuration(self.duration, delay: 0.0, usingSpringWithDamping: 0.98, initialSpringVelocity: 15, options: .AllowUserInteraction, animations: {
            presentedControllerView.frame.origin.y += 50.0
            presentedControllerView.layer.opacity = 0
            
            }, completion: {(completed: Bool) -> Void in
                transitionContext.completeTransition(completed)
        })
    }
    
    func setAnchorPoint(anchorPoint: CGPoint, view: UIView) {
        var newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x, view.bounds.size.height * anchorPoint.y);
        var oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x,
        view.bounds.size.height * view.layer.anchorPoint.y);
        
        newPoint = CGPointApplyAffineTransform(newPoint, view.transform);
        oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform);
        
        var position = view.layer.position;
        
        position.x -= oldPoint.x;
        position.x += newPoint.x;
        
        position.y -= oldPoint.y;
        position.y += newPoint.y;
        
        view.layer.position = position;
        view.layer.anchorPoint = anchorPoint;
    }

}