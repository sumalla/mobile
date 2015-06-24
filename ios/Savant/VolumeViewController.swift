//
//  VolumeViewController.swift
//  Savant
//
//  Created by Cameron Pulsford on 6/8/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

class VolumeViewController: UIViewController {
    
    private let volumeModel: VolumeModel
    private let doneButton = SCUButton(style: .Custom, title: Strings.done.uppercaseString)
    private var volumeTableViewController: VolumeTableViewController?
    private var doneHeight: [NSLayoutConstraint]?
    private var doneHidden = false
    var dismissalBlock: (() -> ())?
    
    init(volumeModel vm: VolumeModel) {
        volumeModel = vm
        doneButton.titleLabel?.font = Fonts.caption1
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .Custom
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    
        doneButton.color = Colors.color1shade1
        doneButton.selectedColor = Colors.color1shade2
        doneButton.backgroundColor = UIColor.sav_colorWithRGBValue(0x202020)
        doneButton.selectedBackgroundColor = UIColor.sav_colorWithRGBValue(0x202020)
        doneButton.target = self
        doneButton.releaseAction = "dismiss"
        
        view.addSubview(doneButton)
        view.sav_pinView(doneButton, withOptions: .ToBottom | .Horizontally)
        updateDoneButtonWithNumberOfItems(0)
        
        let vc = VolumeTableViewController(volumeModel: volumeModel)
        vc.numberOfItemsDidChangeCallback = { [unowned self] in
            self.updateDoneButtonWithNumberOfItems($0)
        }
        
        sav_addChildViewController(vc)
        view.sav_pinView(vc.view, withOptions: .ToTop | .Horizontally)
        view.sav_pinView(vc.view, withOptions: .ToTop, ofView: doneButton, withSpace: 0)
        volumeTableViewController = vc
        
        let tap = UITapGestureRecognizer(target: self, action: "handleTap:")
        vc.view.addGestureRecognizer(tap)
        tap.delegate = self
    }
    
    func handleTap(tap: UITapGestureRecognizer) {
        dismiss()
    }
    
    func dismiss() {
        if let dismissalBlock = dismissalBlock {
            dismissalBlock()
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func updateDoneButtonWithNumberOfItems(numberOfItems: Int) {
        let hidden: Bool
        let height: CGFloat
        
        if numberOfItems <= 4 {
            hidden = true
            height = 0
        } else {
            hidden = false
            height = Sizes.row * 9
        }
        
        if hidden != doneHidden {
            doneHidden = hidden
            doneButton.hidden = hidden
            
            if let height = doneHeight {
                view.removeConstraints(height)
                doneHeight = nil
            }
            
            let heightConstraint = NSLayoutConstraint.constraintsWithVisualFormat("V:[done(height)]|",
                options: NSLayoutFormatOptions(0),
                metrics: ["height": height],
                views: ["done": doneButton])
            
            view.addConstraints(heightConstraint)
            doneHeight = heightConstraint as? [NSLayoutConstraint]
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        // Don't keep the volume up when rotating.
        dismiss()
    }

}

extension VolumeViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let vc = volumeTableViewController {
            return !vc.isTapOnCell(gestureRecognizer as! UITapGestureRecognizer)
        } else {
            return true
        }
    }
    
}
