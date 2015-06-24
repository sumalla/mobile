//
//  VolumeCell.swift
//  Savant
//
//  Created by Cameron Pulsford on 6/6/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import DataSource

class VolumeCell: DataSourceTableViewCell {
    
    let muteButton = SCUButton(style: .Custom, image: UIImage(named: "volumeMute"))
    private let roomLabel = LeftAlignedLabel()
    private let separator = UIView.sav_viewWithColor(Colors.color3shade3)
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        muteButton.color = Colors.color3shade5
        muteButton.selectedColor = Colors.color4shade1
        roomLabel.font = Fonts.caption1
        roomLabel.textColor = Colors.color3shade1
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(muteButton)
        contentView.addSubview(roomLabel)
        contentView.addSubview(separator)
        selectionStyle = .None
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let column = Sizes.columnForOrientation(UIDevice.interfaceOrientation())
        
        var labelFrame = CGRectZero
        labelFrame.origin.x = (column * 2)
        labelFrame.origin.y = Sizes.row * 2.8
        labelFrame.size.width = frame.width - (labelFrame.origin.x * 2)
        labelFrame.size.height = Sizes.row * 1.2
        roomLabel.frame = labelFrame
        
        var muteFrame = CGRectZero
        muteFrame.origin.x = column * 2.5
        muteFrame.origin.y = Sizes.row * 7
        muteFrame.size.width = column * 4
        muteFrame.size.height = Sizes.row * 3
        muteButton.frame = muteFrame
        
        var separatorFrame = CGRectZero
        separatorFrame.size.height = Sizes.pixel
        separatorFrame.size.width = frame.width
        separator.frame = separatorFrame
    }
    
    override func configureWithItem(modelItem: ModelItem) {
        if let item = modelItem as? VolumeModelItem {
            textLabel?.text = nil
            roomLabel.text = item.title?.uppercaseString
            muteButton.selected = item.status.muted
        }
    }

}

class DiscreteVolumeCell: VolumeCell {
    
    let slider = SCUSlider(style: .StylePlain, frame: CGRectZero)
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        slider.maximumValue = 50
        slider.showsIndicator = true
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(slider)
        
        let column = Sizes.columnForOrientation(UIDevice.interfaceOrientation())
        contentView.sav_pinView(slider, withOptions: .ToLeft, withSpace: column * 8)
        contentView.sav_pinView(slider, withOptions: .ToRight, withSpace: column * 2)
        contentView.sav_pinView(slider, withOptions: .ToTop, withSpace: Sizes.row * 7)
        contentView.sav_setHeight(Sizes.row * 3, forView: slider, isRelative: false)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configureWithItem(modelItem: ModelItem) {
        super.configureWithItem(modelItem)
        if let item = modelItem as? VolumeModelItem {
            slider.value = CGFloat(item.status.volume)
            
            if item.status.muted {
                slider.fillColor = Colors.color3shade3
                slider.thumb.borderColor = Colors.color3shade2
            } else {
                slider.fillColor = Colors.color4shade1
                slider.thumb.borderColor = Colors.color4shade1
            }
        }
    }
    
}

class RelativeVolumeCell: VolumeCell {
    
    let decrementButton = SCUButton(style: .StandardPill, image: UIImage(named: "VolumeMinus"))
    let incrementButton = SCUButton(style: .StandardPill, image: UIImage(named: "VolumePlus"))
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        for button in [decrementButton, incrementButton] {
            button.color = Colors.color3shade2
            button.selectedColor = Colors.color3shade2.colorWithAlphaComponent(0.6)
            button.borderColor = Colors.color3shade2
            button.selectedBackgroundColor = UIColor.clearColor()
            button.borderWidth = Sizes.pixel
        }
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let distConfiguration = SAVViewDistributionConfiguration()
        distConfiguration.distributeEvenly = true
        
        let column = Sizes.columnForOrientation(UIDevice.interfaceOrientation())
        
        if UIDevice.isPhone() {
            distConfiguration.interSpace = column * 2
        } else {
            distConfiguration.interSpace = column * 4
        }
        
        let container = UIView.sav_viewWithEvenlyDistributedViews([decrementButton, incrementButton], withConfiguration: distConfiguration)
        contentView.addSubview(container)
        
        contentView.sav_pinView(container, withOptions: .ToTop, withSpace: Sizes.row * 6)
        contentView.sav_pinView(container, withOptions: .ToLeft, withSpace: column * 8)
        contentView.sav_pinView(container, withOptions: .ToRight, withSpace: column * 2)
        contentView.sav_setHeight(Sizes.row * 5, forView: container, isRelative: false)
        contentView.addSubview(container)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

class MasterVolumeCell: RelativeVolumeCell {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        separator.backgroundColor = UIColor.sav_colorWithRGBValue(0xd9d9d9)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
