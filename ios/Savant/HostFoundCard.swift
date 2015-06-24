//
//  HostFoundCard.swift
//  Savant
//
//  Created by Stephen Silber on 5/7/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import DataSource

class HostFoundCard: CardCell {
    
    var containerView = UIView()
    var topLabel = UILabel(frame: CGRectZero)
    var mainButton = SCUButton(style: .StandardPillDark, title: NSLocalizedString("Select Host", comment: ""))
    var linkButton = SCUButton(style: .UnderlinedTextDark, title: NSLocalizedString("Locate", comment: ""))
    var showingUID = false
    override init(frame: CGRect) {
        super.init(frame: frame)

        setCardHeightForSections(Sizes.row * 18, top: Sizes.row * 36)

        containerView = UIView()
        bottomView.addSubview(containerView)
        bottomView.sav_addFlushConstraintsForView(containerView)
        
        containerView.addSubview(mainButton)
        containerView.sav_pinView(mainButton, withOptions: .CenterX)
        
        containerView.addSubview(linkButton)
        
        containerView.sav_pinView(mainButton, withOptions: .ToTop, withSpace: Sizes.row * 6)

        containerView.sav_setSize(CGSize(width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 20, height: Sizes.row * 5), forView: mainButton, isRelative: false)
        containerView.sav_pinView(linkButton, withOptions: .ToBottom, withSpace: Sizes.row * 3)
        
        containerView.sav_pinView(linkButton, withOptions: .CenterX)
        linkButton.sizeToFit()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        topLabel.text = ""
    }
    
    override func configureWithItem(modelItem: ModelItem) {
        super.configureWithItem(modelItem)
        let item = modelItem as! HostModelItem
        homeLabel.text = item.title
    }
}
