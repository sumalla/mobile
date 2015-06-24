//
//  FakeNavBarModelCollectionViewController.swift
//  Savant
//
//  Created by Cameron Pulsford on 4/2/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import DataSource

class FakeNavBarModelCollectionViewController: ModelCollectionViewController {

    private let chevron = SCUButton(style: .Light, image: UIImage.sav_imageNamed("ChevronBack", tintColor: Colors.color1shade1))
    var rightButton = SCUButton(style: .Light, title: "")
    private let titleLabel = UILabel()
    
    override var title: String? {
        didSet {
            titleLabel.text = title?.uppercaseString
        }
    }

    deinit {
        chevron.removeFromSuperview()
        titleLabel.removeFromSuperview()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.textAlignment = .Center
        titleLabel.font = Fonts.caption1
        titleLabel.textColor = Colors.color1shade1

        chevron.target = self
        chevron.releaseAction = "handleBack"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if animated {
            UIView.animateWithDuration(0.05) {
                self.titleLabel.alpha = 1
                self.chevron.alpha = 1
                self.rightButton.alpha = 1
            }
        } else {
            titleLabel.alpha = 1
            chevron.alpha = 1
            rightButton.alpha = 1
        }
        placeViewsInView(UIView.sav_topView())
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if animated {
            UIView.animateWithDuration(0.05) {
                self.titleLabel.alpha = 0
                self.chevron.alpha = 0
                self.rightButton.alpha = 0
            }
        } else {
            titleLabel.alpha = 0
            chevron.alpha = 0
            rightButton.alpha = 0
        }
    }

    func handleBack() {
        fatalError("override")
    }
    
    
    func setRightImage(image: UIImage) {
        rightButton.setImage(image, forState: .Normal)
    }
    
    func setRightTitle(title: String) {
        rightButton.title = title
    }

    private func placeViewsInView(parentView: UIView) {
        chevron.removeFromSuperview()
        parentView.addSubview(chevron)
        parentView.sav_pinView(chevron, withOptions: .ToTop, withSpace: Sizes.row * 5)
        
        rightButton.removeFromSuperview()
        parentView.addSubview(rightButton)
        parentView.sav_pinView(rightButton, withOptions: .CenterY, ofView: chevron, withSpace: 0)
        
        titleLabel.removeFromSuperview()
        parentView.addSubview(titleLabel)
        parentView.sav_pinView(titleLabel, withOptions: .CenterY, ofView: chevron, withSpace: 0)
        parentView.addConstraints(NSLayoutConstraint.sav_constraintsWithMetrics(
            ["inset": Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 2],
            views: ["title": titleLabel, "chevron": chevron, "rightButton" : rightButton],
            formats: [
                "chevron.left = super.left + inset @ 1000",
                "title.left >= chevron.right + 8 @ 1000",
                "title.width <= super.width * .7 @ 1000",
                "title.right <= rightButton.left - 8 @ 1000",
                "rightButton.right = super.right - inset @ 1000",
                "title.centerX = super.centerX @ 1000"]))
    }

}
