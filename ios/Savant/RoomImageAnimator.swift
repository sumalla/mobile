//
//  FullScreenAnimator.swift
//  Prototype
//
//  Created by Nathan Trapp on 2/26/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import DataSource

class RoomImageAnimator: PullDownAnimator {
    var modelItem: ModelItem?
    var cellImage: UIImage?
    var cellFrame = CGRectZero
    var navBarImage: UIImage?

    private var finalPoint: CGPoint = .zeroPoint
    private var previousPoint: CGPoint = .zeroPoint
    private var startPoint: CGPoint = .zeroPoint

    override func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return presenting ? 0.35 : 0.2
    }
    
    override func handleAnimation(transitionContext: UIViewControllerContextTransitioning, completion: ((Bool) -> Void)) {
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)
        let containerView = transitionContext.containerView()

        let roomViewController = presenting ? toViewController : fromViewController

        if let fullScreenView = roomViewController as? RoomController, cellImage = cellImage, toView = toViewController?.view, fromView = fromViewController?.view, modelItem = modelItem, navBarImage = navBarImage {

            let transitioningView = UIView()
            transitioningView.backgroundColor = SCUColors.shared().color03
            transitioningView.clipsToBounds = true

            let roomImageView = UIImageView()
            roomImageView.contentMode = .ScaleAspectFill
            transitioningView.addSubview(roomImageView)
            transitioningView.sav_addFlushConstraintsForView(roomImageView)

            let blurredRoomImageView = UIImageView()
            blurredRoomImageView.contentMode = .ScaleAspectFill
            transitioningView.addSubview(blurredRoomImageView)
            transitioningView.sav_addFlushConstraintsForView(blurredRoomImageView)

            let blurredImage = Savant.images().imageForKey(modelItem.title, type: .RoomImage, size: .Large, blurred: true)

            if let blurredImage = blurredImage, image = modelItem.image {
                fullScreenView.roomImage = blurredImage
                roomImageView.image = image
                blurredRoomImageView.image = blurredImage
            }

            let cellImageView = UIImageView()
            cellImageView.contentMode = .ScaleAspectFill
            cellImageView.image = cellImage
            transitioningView.addSubview(cellImageView)
            transitioningView.sav_addFlushConstraintsForView(cellImageView)

            let roomCapturedImageView = UIImageView()
            roomCapturedImageView.contentMode = .ScaleAspectFill
            transitioningView.addSubview(roomCapturedImageView)
            transitioningView.sav_addFlushConstraintsForView(roomCapturedImageView)

            // Capture the fullScreenView in a UIImage, without a background image
            containerView.addSubview(fullScreenView.view)
            fullScreenView.view.layoutIfNeeded()

            roomCapturedImageView.image = fullScreenView.captureView.sav_rasterizedImage()

            var curve: UIViewAnimationOptions = .CurveEaseOut

            if (interactive) {
                curve = .CurveLinear
            }

            let navBarBacker = UIView()
            navBarBacker.backgroundColor = Colors.color2shade1
            navBarBacker.alpha = 0
            containerView.addSubview(navBarBacker)
            containerView.sav_pinView(navBarBacker, withOptions: .ToTop | .Horizontally)
            containerView.sav_setHeight(Sizes.row * 8 + 20, forView: navBarBacker, isRelative: false)

            let navBarImageView = UIImageView(image: navBarImage)
            navBarImageView.alpha = 0
            navBarImageView.contentMode = .ScaleAspectFill
            containerView.addSubview(navBarImageView)
            containerView.sav_pinView(navBarImageView, withOptions: .ToTop | .Horizontally)
            containerView.sav_setHeight(Sizes.row * 8 + 20, forView: navBarImageView, isRelative: false)

            // Handle presenting animation
            if presenting {
                let originalFrame = cellFrame
                let endFrame = toView.bounds

                containerView.addSubview(fromView)
                containerView.addSubview(toView)
                containerView.addSubview(transitioningView)

                transitioningView.frame = originalFrame
                transitioningView.layoutIfNeeded()

                blurredRoomImageView.alpha = 0
                roomCapturedImageView.alpha = 0
                toView.alpha = 0

                finalPoint = CGPointMake(CGRectGetMidX(endFrame), CGRectGetMidY(endFrame))

                UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, options: curve, animations: {
                    cellImageView.alpha = 0
                    roomCapturedImageView.alpha = 1
                    roomImageView.alpha = 0
                    blurredRoomImageView.alpha = 1

                    fromView.transform = CGAffineTransformMakeScale(0.8, 0.8)

                    transitioningView.frame = endFrame
                    transitioningView.layoutIfNeeded()
                    }) { (complete) in
                        let completed = !transitionContext.transitionWasCancelled()

                        transitioningView.removeFromSuperview()
                        navBarImageView.removeFromSuperview()
                        navBarBacker.removeFromSuperview()

                        toView.alpha = 1
                        fromView.transform = CGAffineTransformMakeScale(1, 1)

                        if completed {
                            fromView.removeFromSuperview()
                        } else {
                            toView.removeFromSuperview()
                        }

                        completion(complete)

                }

                // Handle dismissal animation
            } else {
                var originalFrame = toView.bounds
                var endFrame = cellFrame

                containerView.addSubview(fromView)
                containerView.addSubview(toView)
                containerView.bringSubviewToFront(navBarBacker)
                containerView.addSubview(transitioningView)
                containerView.bringSubviewToFront(navBarImageView)

                transitioningView.frame = originalFrame
                transitioningView.layoutIfNeeded()

                let belowNavBar = CGRectGetMinY(self.cellFrame) < Sizes.row * 8 + 20

                cellImageView.alpha = 0
                fromView.alpha = 0
                roomImageView.alpha = 0

                if belowNavBar {
                    navBarBacker.alpha = 1
                }

                finalPoint = CGPointMake(CGRectGetMidX(endFrame), CGRectGetMidY(endFrame))

                // If mid point is too high (below the nav bar), target the bottom
                if finalPoint.y < 100 {
                    finalPoint = CGPointMake(CGRectGetMaxX(endFrame), CGRectGetMaxY(endFrame))
                }

                toView.transform = CGAffineTransformMakeScale(0.8, 0.8)

                UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, options: curve, animations: {
                    cellImageView.alpha = 1
                    roomCapturedImageView.alpha = 0
                    blurredRoomImageView.alpha = 0
                    roomImageView.alpha = 1

                    // Animate in navbar if the room is below it
                    if belowNavBar {
                        navBarImageView.alpha = 1
                    }

                    toView.transform = CGAffineTransformMakeScale(1, 1)

                    transitioningView.frame = endFrame
                    transitioningView.layoutIfNeeded()
                    }) { (complete) in
                        let completed = !transitionContext.transitionWasCancelled()

                        transitioningView.removeFromSuperview()
                        navBarImageView.removeFromSuperview()
                        navBarBacker.removeFromSuperview()

                        fromView.alpha = 1

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

    override func handlePan(recognizer: UIPanGestureRecognizer) {
        if animatingWindow == nil {
            animatingWindow = UIApplication.sharedApplication().keyWindow
        }

        let velocity = recognizer.velocityInView(animatingWindow);
        let location = recognizer.locationInView(animatingWindow!);

        let scale = (startPoint.y - location.y) / (startPoint.y - finalPoint.y)

        let finished = scale >= 1 || ((previousPoint.y < finalPoint.y && location.y > finalPoint.y || previousPoint.y > finalPoint.y && location.y < finalPoint.y) && previousPoint.y != 0)

        switch recognizer.state {
        case .Began:
            startPoint = location
            beginInteractiveTransition()
        case .Changed:
            // End when the center point is reached or crossed over
            if finished {
                recognizer.enabled = false
                recognizer.enabled = true
                return
            }

            previousPoint = location

            updateInteractiveTransition(scale)
        case .Ended:
            fallthrough
        case .Cancelled:
            if finished || velocity.y > 0 && location.y < finalPoint.y || velocity.y < 0 && location.y > finalPoint.y || velocity.y == 0 && scale > 0.5 {
                finishInteractiveTransition()
            } else {
                cancelInteractiveTransition()
            }

            startPoint = .zeroPoint
            previousPoint = .zeroPoint
        default:
            break
        }
    }
}
