//
//  DefaultCell.swift
//  Prototype
//
//  Created by Nathan Trapp on 2/14/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import DataSource

enum DefaultCellSelectionStyle {
    case Default
    case Lighten
}

class DefaultCell: DataSourceTableViewCell {

    var labelInset: CGFloat?
    var customSelectionStyle = DefaultCellSelectionStyle.Default

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        textLabel?.font = Fonts.body
        textLabel?.textColor = Colors.color1shade1
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if let label = textLabel, inset = labelInset {
            var frame = label.frame
            if inset < frame.origin.x {
                let diff = frame.origin.x - inset
                frame.origin.x = inset
                frame.size.width += diff
            } else if inset > frame.origin.x {
                let diff = inset - frame.origin.x
                frame.origin.x = inset
                frame.size.width -= diff
            }

            label.frame = frame
        }
    }

    override func setHighlighted(highlighted: Bool, animated: Bool) {
        if customSelectionStyle == .Default {
            super.setHighlighted(highlighted, animated: animated)
            return
        }

        var block: dispatch_block_t = {
            if highlighted {
                self.alpha = 0.6
            } else {
                self.alpha = 1
            }
        }

        if animated {
            UIView.animateWithDuration(0.2) {
                block()
            }
        } else {
            block()
        }
    }

}
