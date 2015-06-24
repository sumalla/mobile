//
//  AddRoomCells.swift
//  Savant
//
//  Created by Julian Locke on 5/21/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import DataSource

class AddRoomCell: DataSourceTableViewCell {
    
    let titleLabel = UILabel(frame: CGRectZero)
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = UITableViewCellSelectionStyle.None
        
        titleLabel.font = Fonts.body
        titleLabel.textColor = Colors.color1shade1
        
        self.addSubview(titleLabel)
        
        self.sav_pinView(titleLabel, withOptions: .ToLeft, withSpace:Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 4)
        self.sav_pinView(titleLabel, withOptions: .CenterY)
    }
    
    override func configureWithItem(modelItem: ModelItem) {
        titleLabel.text = modelItem.title
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class AddRoomCellSwitch: AddRoomCell {
    
    let switchView = PulseSwitch(frame: CGRectZero)
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.addSubview(switchView)
        
        self.sav_pinView(switchView, withOptions: .ToRight, withSpace:Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 4)
        self.sav_pinView(switchView, withOptions: .CenterY)
        self.sav_setSize(CGSizeMake(20,20), forView: switchView, isRelative: false)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}