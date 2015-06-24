//
//  RightImageCell.swift
//  Prototype
//
//  Created by Cameron Pulsford on 3/2/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import DataSource

class RightImageCell: DefaultCell {

    let rightImageView = UIImageView()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(rightImageView)
        rightImageView.contentMode = .Center
        contentView.sav_pinView(rightImageView, withOptions: .ToRight, withSpace: SAVViewAutoLayoutStandardSpace)
        contentView.sav_pinView(rightImageView, withOptions: .Vertically)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureWithItem(modelItem: ModelItem) {
        super.configureWithItem(modelItem)
        rightImageView.image = modelItem.image?.tintedImageWithColor(Colors.color1shade1)
    }
    
}

