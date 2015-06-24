//
//  PullDownAnimator.swift
//  Prototype
//
//  Created by Nathan Trapp on 3/1/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

enum PullDownMode: Equatable, Printable {
    case Above
    case Below

    var description: String {
        get {
            switch self {
            case .Above:
                return "Above"
            case .Below:
                return "Below"
            }
        }
    }
}

protocol PullDownAnimatorDelegate: class {
    func pullDownDidBegin(animator: PullDownAnimator)
    func pullDownDidCancel(animator: PullDownAnimator)
    func pullDownDidUpdate(animator: PullDownAnimator, percentComplete: CGFloat)
    func pullDownDidFinish(animator: PullDownAnimator)
}

class PullDownAnimator: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning, UIGestureRecognizerDelegate {
    weak var delegate: PullDownAnimatorDelegate?

    let panGesture = UIPanGestureRecognizer()
    var mode: PullDownMode = .Below

    var presenting = false

    var animatingWindow: UIWindow?
    private(set) var interactive = false
    private(set) var animating = false

    override init() {
        super.init()
        panGesture.addTarget(self, action: "handlePan:")
        panGesture.delegate = self
    }

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 0.35
    }

    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        animating = true

        handleAnimation(transitionContext) { (complete) in
            self.animating = false

            transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        }
    }

    func handleAnimation(transitionContext: UIViewControllerContextTransitioning, completion: ((Bool) -> Void)) {
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)

        if let toView = toViewController?.view, fromView = fromViewController?.view {
            var curve: UIViewAnimationOptions = .CurveEaseOut

            if (interactive) {
                curve = .CurveLinear
            }

            if presenting {
                var startFrame = toView.frame

                if mode == .Below {
                    startFrame.origin.y += CGRectGetMaxY(startFrame)
                } else {
                    startFrame.origin.y -= CGRectGetMaxY(startFrame)
                }

                toView.frame = startFrame

                transitionContext.containerView().addSubview(fromView)
                transitionContext.containerView().addSubview(toView)
                fromView.transform = CGAffineTransformMakeScale(1, 1)
                UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, options: curve, animations: {
                    toView.frame = fromView.frame
                    fromView.transform = CGAffineTransformMakeScale(0.9, 0.9)
                    }) { (complete) in
                        let completed = !transitionContext.transitionWasCancelled()

                        if completed {
                            fromView.removeFromSuperview()
                            fromView.transform = CGAffineTransformMakeScale(1, 1)
                        } else {
                            toView.removeFromSuperview()
                        }

                        completion(complete)
                }
            } else {
                var endFrame = fromView.frame

                if mode == .Below {
                    endFrame.origin.y += CGRectGetMaxY(endFrame)
                } else {
                    endFrame.origin.y -= CGRectGetMaxY(endFrame)
                }

                transitionContext.containerView().addSubview(toView)
                transitionContext.containerView().addSubview(fromView)

                toView.transform = CGAffineTransformMakeScale(0.9, 0.9)
                UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, options: curve, animations: {
                    fromView.frame = endFrame
                    toView.transform = CGAffineTransformMakeScale(1, 1)
                    }) { (complete) in
                        let completed = !transitionContext.transitionWasCancelled()

                        if completed {
                            fromView.removeFromSuperview()
                        } else {
                            toView.removeFromSuperview()
                        }

                        completion(complete)
                }
            }
        }
    }

    func handlePan(recognizer: UIPanGestureRecognizer) {
        if animatingWindow == nil {
            animatingWindow = UIApplication.sharedApplication().keyWindow
        }

        let velocity = recognizer.velocityInView(animatingWindow);
        let translation = recognizer.translationInView(animatingWindow!).y;
        let scale = translation / CGRectGetHeight(animatingWindow!.bounds);

        switch recognizer.state {
        case .Began:
            beginInteractiveTransition()
        case .Changed:
            // Bail if we move out of range
            if (scale < 0 || scale > 1)
            {
                panGesture.enabled = false
                panGesture.enabled = true
                break
            }

            updateInteractiveTransition(scale)
        case .Ended:
            if velocity.y > 0 || velocity.y == 0 && scale > 0.5 {
                finishInteractiveTransition()
            } else {
                cancelInteractiveTransition()
            }
        case .Cancelled:
            cancelInteractiveTransition()
        default:
            break
        }
    }

    func beginInteractiveTransition() {
        interactive = true

        if let delegate = delegate {
            delegate.pullDownDidBegin(self)
        }
    }

    override func updateInteractiveTransition(percentComplete: CGFloat) {
        super.updateInteractiveTransition(percentComplete)

        if let delegate = delegate {
            delegate.pullDownDidUpdate(self, percentComplete: percentComplete)
        }
    }

    override func finishInteractiveTransition() {
        super.finishInteractiveTransition()

        if let delegate = delegate {
            delegate.pullDownDidFinish(self)
        }

        animatingWindow = nil
        interactive = false
    }

    override func cancelInteractiveTransition() {
        super.cancelInteractiveTransition()

        if let delegate = delegate {
            delegate.pullDownDidCancel(self)
        }

        animatingWindow = nil
        interactive = false
    }

    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = pan.velocityInView(pan.view)
            
            if abs(velocity.x) < abs(velocity.y) {
                return true
            }
        }
        
        return false
    }
}
