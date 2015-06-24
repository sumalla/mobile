//
//  TipCell.swift
//  Savant
//
//  Created by Stephen Silber on 4/29/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import DataSource

class TipCell: DataSourceCollectionViewCell {
    let card = UIView(frame: CGRectZero)
    let label = UILabel(frame: CGRectZero)
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        label.numberOfLines = 0
        label.font = Fonts.caption1
        label.textColor = Colors.color3shade2
        
        self.backgroundColor = Colors.color1shade1
//        card.backgroundColor = Colors.color1shade1
//        card.layer.cornerRadius = 3
        
        contentView.addSubview(label)
        contentView.sav_addFlushConstraintsForView(label, withPadding: Sizes.row * 3)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
