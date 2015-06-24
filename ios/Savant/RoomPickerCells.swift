//
//  PickRoomCell.swift
//  Savant
//
//  Created by Alicia Tams on 5/18/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import DataSource

class PickRoomCell: DataSourceTableViewCell {
	
	let titleLabel = UILabel(frame: CGRectZero)
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		self.selectedBackgroundView = UIView(frame: CGRectZero)
		
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

class PickRoomCellSwitch: PickRoomCell {
	
	let switchView = PulseSwitch(frame: CGRectZero)

	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		switchView.listenToTouches = false
		
		self.addSubview(switchView)
		
		self.sav_pinView(switchView, withOptions: .ToRight, withSpace:Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 4)
		self.sav_pinView(switchView, withOptions: .CenterY)
		self.sav_setSize(CGSizeMake(20,20), forView: switchView, isRelative: false)
	}

	required init(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class PickRoomCellAdd: PickRoomCell {
	
	let imgView = UIImageView(frame: CGRectZero)
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		let selectedBackground = UIView(frame: self.frame)
		selectedBackground.backgroundColor = Colors.color1shade3
		
		self.selectedBackgroundView = selectedBackground
		
		imgView.image = UIImage(named: "Add")?.tintedImageWithColor(Colors.color1shade1)
		
		self.addSubview(imgView)
		
		self.sav_pinView(imgView, withOptions: .ToRight, withSpace:Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 4)
		self.sav_pinView(imgView, withOptions: .CenterY)
		self.sav_setSize(CGSizeMake(20,20), forView: imgView, isRelative: false)
	}
	
	required init(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
}