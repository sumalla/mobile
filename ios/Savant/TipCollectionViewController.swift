//
//  TipsCollectionViewController.swift
//  Savant
//
//  Created by Stephen Silber on 4/29/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import DataSource
import Coordinator

class TipCollectionViewController: FakeNavBarModelCollectionViewController {
    var tipModel: TipViewModel!
    let bottomButton = SCUButton(style: .UnderlinedText, title: NSLocalizedString("Help", comment: ""))
    let coordinator:CoordinatorReference<HostOnboardingState>
    let topLabel = UILabel(frame: CGRectZero)
    var currentConstraints = Set<NSLayoutConstraint>()

    init(coordinator:CoordinatorReference<HostOnboardingState>, tips: [String]) {
        self.coordinator = coordinator
        self.tipModel = TipViewModel(tipItems: tips)
        let layout = FullscreenCardFlowLayout(interspace: Sizes.row * 2, width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 36, height: Sizes.row * 18)
        
        if UIDevice.isPad() {
            layout.sticky = false
            layout.vertical = true
            layout.height = Sizes.row * 20
            layout.width = Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 36
        }
        
        super.init(collectionViewLayout: layout)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.backgroundColor = UIColor.clearColor()
        collectionView?.backgroundView = UIView()

        navigationController?.setNavigationBarHidden(true, animated: false)
        
        topLabel.font = Fonts.subHeadline2
        topLabel.textColor = Colors.color1shade1
        topLabel.textAlignment = .Center
        topLabel.text = NSLocalizedString("Host Not Found", comment: "")
        
        view.addSubview(topLabel)
        view.sav_pinView(topLabel, withOptions: .Horizontally, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 4)
        view.sav_pinView(topLabel, withOptions: .CenterX)

        
        bottomButton.addTarget(self, action: "handleHelpButton", forControlEvents: .TouchUpInside)
        
        view.addSubview(bottomButton)
        view.sav_pinView(bottomButton, withOptions: .CenterX)
    }
    
    internal override func viewDataSource() -> DataSource {
        return self.tipModel
    }
    
    internal func handleHelpButton() {
        coordinator.transitionToState(.Start)
    }
    
    func setupConstraints() {
        setupConstraints(UIDevice.interfaceOrientation())
        
        if UIDevice.isPad() {
            universalPadConstraints()
        }
    }
    
    func setupConstraints(orientation: UIInterfaceOrientation) {
        if currentConstraints.count > 0 {
            view.removeConstraints(Array(currentConstraints))
        }
        
        let beforeConstraints = Set(view.constraints() as! [NSLayoutConstraint])
        
        if UIDevice.isPad() {
            if orientation == .Portrait || orientation == .PortraitUpsideDown {
                padPortraitConstraints()
            } else {
                padLandscapeConstraints()
            }
        } else {
            phoneConstraints()
        }
        
        let afterConstraints = Set(view.constraints() as! [NSLayoutConstraint])
        currentConstraints = afterConstraints.subtract(beforeConstraints)
        
        collectionViewLayout.invalidateLayout()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        self.animateInterfaceRotationChangeWithCoordinator(coordinator, block: { (orientation: UIInterfaceOrientation) -> Void in
            self.setupConstraints(orientation)
        })
    }
    
    func universalPadConstraints() {

    }
    
    func padPortraitConstraints() {

    }
    
    func padLandscapeConstraints() {

    }
    
    func phoneConstraints() {

    }

    override func registerCells() {
        registerCell(type: 0, cellClass: TipCell.self)
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: TipCell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! TipCell
        let modelItem = tipModel.itemForIndexPath(indexPath) as! TipModelItem
        
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 12
        
        var attrString = NSMutableAttributedString(string: "\(modelItem.tipNumberText.uppercaseString)\(modelItem.tipText)")
        attrString.addAttribute(NSParagraphStyleAttributeName, value:paragraphStyle, range:NSMakeRange(0, attrString.length))
        attrString.addAttribute(NSFontAttributeName, value:Fonts.bookFontOfSize(Scale.baseValue * 1.3), range:NSMakeRange(0, count(modelItem.tipNumberText)))
        
        cell.label.attributedText = attrString
        cell.layer.cornerRadius = 3

        return cell
    }
    
    override func handleBack() {
        self.coordinator.transitionToState(.Start)
    }
}
