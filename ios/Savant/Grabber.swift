//
//  Grabber.swift
//  Prototype
//
//  Created by Nathan Trapp on 2/26/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

class Grabber: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)

        let views = [UIView(), UIView(), UIView()]

        for view in views {
            addSubview(view)
            view.backgroundColor = Colors.color1shade1
            sav_setHeight(UIScreen.screenPixel() * 2, forView: view, isRelative: false)
            sav_setWidth(CGRectGetWidth(frame), forView: view, isRelative: false)
        }

        let configuration = SAVViewDistributionConfiguration()
        configuration.vertical = true
        configuration.interSpace = 6

        self.sav_distributeViewsEvenly(views, withConfiguration: configuration)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
