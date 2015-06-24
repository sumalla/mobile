//
//  CardCell.swift
//  Savant
//
//  Created by Stephen Silber on 4/6/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import DataSource

class CardCell: DataSourceCollectionViewCell {
    
    let topImageView: UIImageView
    let homeLabel: UILabel
    let bottomView: UIView
    
    override init(frame: CGRect) {
        
        topImageView = UIImageView()
        topImageView.backgroundColor = Colors.color5shade1
        
        bottomView = UIView()
        bottomView.backgroundColor = Colors.color1shade1
        
        homeLabel = UILabel()
        homeLabel.numberOfLines = 2
        homeLabel.textColor = Colors.color1shade1
        
        super.init(frame: frame)
        
        contentView.addSubview(homeLabel)
        contentView.sav_pinView(homeLabel, withOptions: .ToTop, withSpace: Sizes.row * 8)
        contentView.sav_pinView(homeLabel, withOptions: .CenterX)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setCardHeightForSections(bottom: CGFloat, top: CGFloat) {
        topImageView.removeFromSuperview()
        bottomView.removeFromSuperview()
        
        contentView.addSubview(topImageView)
        contentView.addSubview(bottomView)
        
        contentView.sav_pinView(topImageView, withOptions: .ToTop | .Horizontally)
        contentView.sav_pinView(topImageView, withOptions: .ToTop, ofView: bottomView, withSpace: 0)
        contentView.sav_pinView(bottomView, withOptions: .ToBottom | .Horizontally)
        
        contentView.sav_setHeight(bottom, forView: bottomView, isRelative: false)
//        contentView.sav_setHeight(top, forView: homeImageView, isRelative: false)
        
        contentView.bringSubviewToFront(homeLabel)
    }
    
    override func configureWithItem(modelItem: ModelItem) {
        super.configureWithItem(modelItem)
        let item = modelItem
        homeLabel.text = item.title
    }
}
