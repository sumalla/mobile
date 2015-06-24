//
//  ServiceSelectorCollectionViewCell.swift
//  Prototype
//
//  Created by Cameron Pulsford on 2/26/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import DataSource

class ServiceSelectorCollectionViewCellBase: DataSourceCollectionViewCell {

    let imageView = UIImageView()
    let mainLabel = LeftAlignedLabel()
    let activeDot = UIView.sav_viewWithColor(Colors.color1shade3)

    override init(frame: CGRect) {
        super.init(frame: frame)

        mainLabel.textColor = Colors.color1shade1
        mainLabel.textAlignment = .Center
        mainLabel.minimumScaleFactor = 0.8
        mainLabel.adjustsFontSizeToFitWidth = true
        activeDot.layer.cornerRadius = 4
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureWithItem(modelItem: ModelItem) {
        if let item = modelItem as? ServiceSelectorModelItem {
            if count(item.imageName) > 0 {
                imageView.image = UIImage.sav_imageNamed(item.imageName, tintColor: Colors.color1shade1)
            } else {
                imageView.image = nil
            }

            activeDot.hidden = !item.enabled

            if let title = item.title {
                mainLabel.attributedText = attributedTemperatureFromTemperature(title)
            } else {
                mainLabel.attributedText = nil
            }

        }
    }

    func attributedTemperatureFromTemperature(temperature: String) -> NSAttributedString {
        fatalError("implement")
    }

}

class ServiceSelectorCollectionViewCellFull: ServiceSelectorCollectionViewCellBase {

    let supplementaryLabel = LeftAlignedLabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        supplementaryLabel.font = Fonts.caption1
        supplementaryLabel.textColor = Colors.color1shade1
        supplementaryLabel.textAlignment = .Center

        contentView.addSubview(imageView)
        contentView.sav_setSize(CGSize(width: Sizes.row * 8, height: Sizes.row * 8), forView: imageView, isRelative: false)
        contentView.sav_pinView(imageView, withOptions: .ToTop, withSpace: Sizes.row * 3)
        contentView.sav_pinView(imageView, withOptions: .CenterX)

        contentView.addSubview(mainLabel)
        contentView.sav_setHeight(Sizes.row * 8, forView: mainLabel, isRelative: false)
        contentView.sav_pinView(mainLabel, withOptions: .ToTop, withSpace: Sizes.row * 3)
        contentView.sav_pinView(mainLabel, withOptions: .Horizontally)

        contentView.addSubview(activeDot)
        contentView.sav_setSize(CGSize(width: 8, height: 8), forView: activeDot, isRelative: false)

        contentView.addSubview(supplementaryLabel)
        contentView.sav_pinView(supplementaryLabel, withOptions: .ToBottom, ofView: imageView, withSpace: Sizes.row * 1)
        contentView.sav_pinView(supplementaryLabel, withOptions: .CenterX)
        contentView.addConstraints(NSLayoutConstraint.sav_constraintsWithMetrics(
            nil,
            views: ["dot": activeDot, "text": supplementaryLabel],
            formats: ["dot.centerY = text.centerY", "dot.right = text.left - 3", "text.left >= super.left @1000", "text.right <= super.right @1000"]))
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureWithItem(modelItem: ModelItem) {
        super.configureWithItem(modelItem)

        if let item = modelItem as? ServiceSelectorModelItem {
            supplementaryLabel.text = item.supplementaryText
        }
    }

    override func attributedTemperatureFromTemperature(temperature: String) -> NSAttributedString {
        return SAVHVACEntity.addDegreeSuffix(temperature, baseFont: Fonts.subHeadline1, degreeFont: Fonts.body, withDegreeOffset: 18)
    }

}

class ServiceSelectorCollectionViewCellCompact: ServiceSelectorCollectionViewCellBase {

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(mainLabel)
        contentView.addSubview(activeDot)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let mainSize = Sizes.row * 6
        let totalWidth = self.frame.width

        var imageRect = CGRect(x: (totalWidth - mainSize) / 2, y: 0, width: mainSize, height: mainSize)
        imageView.frame = imageRect

        var labelRect = CGRect(x: 0, y: 0, width: totalWidth, height: mainSize)
        mainLabel.frame = labelRect

        var activeRect = CGRect(x: (totalWidth - 8) / 2, y: Sizes.row * 9, width: 8, height: 8)
        activeDot.frame = activeRect
    }

    override func attributedTemperatureFromTemperature(temperature: String) -> NSAttributedString {
        return SAVHVACEntity.addDegreeSuffix(temperature, baseFont: Fonts.subHeadline2, degreeFont: Fonts.body, withDegreeOffset: 7)
    }

}

class LeftAlignedLabel: UILabel {

    override func drawTextInRect(rect: CGRect) {
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, UIEdgeInsets(top: 0, left: -1, bottom: 0, right: -4)))
    }

}
