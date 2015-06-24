//
//  PopOverController.swift
//  Prototype
//
//  Created by Stephen Silber on 3/13/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation

enum IndicatorDirection:Int, Equatable {
    case Top
    case Bottom
    case None
}

class PopoverController : UIViewController, UIViewControllerTransitioningDelegate {
    
    var container: UIView = UIView()
    var visible = false
    var completionBlock: (() -> ())?
    private var arrowLayer: CAShapeLayer?

    init () {
        super.init(nibName: nil, bundle: nil)
        
        self.modalPresentationStyle = .Custom
        self.transitioningDelegate = self
        
        view.userInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.sav_handler = { [unowned self] (state, point) in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        view.addGestureRecognizer(tapGesture)
        
        container.clipsToBounds = true
        container.layer.cornerRadius = 2.0
        container.backgroundColor = Colors.color3shade4

        view.addSubview(container)
        view.sav_addFlushConstraintsForView(container)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func contentSize() -> CGSize {
        return CGSizeMake(0, 0)
    }
    
    func showFromView(fromView: UIView) {
        showFromView(fromView, index: 0, columns: 0, columnWidth: 0, completionClosure: nil)
    }
    
    internal func showFromView(fromView: UIView, index: Int, columns: Int) {
        showFromView(fromView, index: index, columns: columns, columnWidth: 0, completionClosure: nil)
    }
    
    internal func showFromView(fromView: UIView, index: Int, columns: Int, columnWidth: CGFloat, completionClosure: (() ->())?) {
        if !visible {
            
            visible = true
            
            self.completionBlock = completionClosure
            
            let fromFrame = fromView.convertRect(fromView.bounds, toView: RootViewController.view)
            let direction: IndicatorDirection = isRectOnTopHalfOfView(fromFrame, view: fromView) ? .Top : .Bottom
            let width = CGFloat(self.contentSize().width)
            
            var frame = CGRectZero
            frame.size = self.contentSize()
            frame.origin.y = direction == .Bottom ? CGRectGetMinY(fromFrame) - CGRectGetHeight(frame) - Sizes.row : CGRectGetMaxY(fromFrame) + Sizes.row
            frame.origin.x = 0
            view.frame = frame
            
            
            self.drawIndicator(contentSize().width / 2, direction: direction)
            
            RootViewController.presentViewController(self, animated: true, completion: nil)

        } else {
            println("Cannot show PopOver because it is already on the screen")
        }
    }
    
    func drawIndicator(origin: CGFloat, direction: IndicatorDirection) {
        if let arrowLayer = arrowLayer {
            arrowLayer.removeFromSuperlayer()
        }

        var path = UIBezierPath()
        path.lineJoinStyle = kCGLineJoinRound
        path.lineCapStyle  = kCGLineCapRound
        
        let height = self.contentSize().height
        
        if direction == .Bottom {
            path.moveToPoint(CGPointMake(origin - (1.5 * Sizes.row), height))
            path.addArcWithCenter(CGPointMake(origin, height + Sizes.row), radius: 2, startAngle: CGFloat(M_PI * (5/6)), endAngle: CGFloat(M_PI * (1/6)), clockwise: false)
            path.addLineToPoint(CGPointMake(origin + (1.5 * Sizes.row), height))
        } else if direction == .Top {
            path.moveToPoint(CGPointMake(origin - (1.5 * Sizes.row), 0))
            path.addArcWithCenter(CGPointMake(origin, -Sizes.row), radius: 2, startAngle: CGFloat(M_PI * (7/6)), endAngle: CGFloat(M_PI * (11/6)), clockwise: true)
            path.addLineToPoint(CGPointMake(origin + (1.5 * Sizes.row), 0))
        } else {
            return
        }

        path.closePath()
        
        arrowLayer = CAShapeLayer()
        arrowLayer!.fillColor = Colors.color1shade4.CGColor
        arrowLayer!.path = path.CGPath
        view.layer.addSublayer(arrowLayer)
    }
    
    func isRectOnTopHalfOfView(rect: CGRect, view: UIView) -> Bool {
        if CGRectGetMaxY(rect) > CGRectGetMidY(view.frame) {
            return false;
        }
        
        return true;
    }

    // UIViewControllerTransitioningDelegate methods
    func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController!, sourceViewController source: UIViewController) -> UIPresentationController? {
        
        if presented == self {
            return PopoverPresentationController(presentedViewController: presented, presentingViewController: presenting)
        }
        
        return nil
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if presented == self {
            return PopoverPresentationAnimationController(isPresenting: true)
        }
        else {
            return nil
        }
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if dismissed == self {
            return PopoverPresentationAnimationController(isPresenting: false)
        }
        else {
            return nil
        }
    }

}