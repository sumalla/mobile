//
//  PopoverPresentationController.swift
//  Prototype
//
//  Created by Stephen Silber on 3/13/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation

class PopoverPresentationController: UIPresentationController {
    
    lazy var dimmingView :UIView = {
        let view = UIView(frame: self.containerView!.bounds)
        view.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.75)
        view.alpha = 0.0
        
        let tap = UITapGestureRecognizer()
        view.addGestureRecognizer(tap)
        tap.sav_handler = { [unowned self] (state, point) in
            self.presentingViewController.dismissViewControllerAnimated(true, completion: nil)
        }
        
        return view
        }()
    
    override func presentationTransitionWillBegin() {
        self.dimmingView.frame = self.containerView.bounds
        self.containerView.addSubview(self.dimmingView)
        self.containerView.addSubview(self.presentedView())
        
        // Fade in the dimming view alongside the transition
        if let transitionCoordinator = self.presentingViewController.transitionCoordinator() {
            transitionCoordinator.animateAlongsideTransition({(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
                self.dimmingView.alpha  = 1.0
                }, completion:nil)
        }
    }
    
    override func presentationTransitionDidEnd(completed: Bool)  {
        if !completed {
            self.dimmingView.removeFromSuperview()
        }
    }
    
    override func dismissalTransitionWillBegin()  {
        // Fade out the dimming view alongside the transition
        if let transitionCoordinator = self.presentingViewController.transitionCoordinator() {
            transitionCoordinator.animateAlongsideTransition({(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
                self.dimmingView.alpha  = 0.0
                }, completion:nil)
        }
    }
    
    override func dismissalTransitionDidEnd(completed: Bool) {
        if completed {
            self.dimmingView.removeFromSuperview()
            self.presentingViewController.removeFromParentViewController()
        }
    }
    
    override func frameOfPresentedViewInContainerView() -> CGRect {
        // We don't want the presented view to fill the whole container view, so inset it's frame
        var frame = self.containerView.bounds;
        frame = CGRectInset(frame, 50.0, 50.0)
        
        return frame
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator transitionCoordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: transitionCoordinator)
        
        transitionCoordinator.animateAlongsideTransition({(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
            self.dimmingView.frame = self.containerView.bounds
            }, completion:nil)
    }
}