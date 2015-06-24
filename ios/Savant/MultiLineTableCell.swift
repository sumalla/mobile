//
//  MultiLineTableCell.swift
//  Prototype
//
//  Created by Cameron Pulsford on 2/13/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import DataSource

class MultiLineTableCell: DefaultCell {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        textLabel?.numberOfLines = 0
        textLabel?.lineBreakMode = .ByWordWrapping
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
