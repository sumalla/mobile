//
//  ExtraTallNavBar.swift
//  Prototype
//
//  Created by Cameron Pulsford on 3/12/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

class ExtraTallNavBar: UINavigationBar {

    override func layoutSubviews() {
        super.layoutSubviews()
        self.translucent = false

        if let subviews = self.subviews as? [UIView] {
            for view in subviews {
                if view.userInteractionEnabled {
                    var rect = view.frame
                    rect.origin.y -= 14
                    view.frame = rect
                }
            }
        }
    }
    
    override func sizeThatFits(size: CGSize) -> CGSize {
        var size = super.sizeThatFits(size)
        size.height = Sizes.row * 9
        return size
    }
    
}
