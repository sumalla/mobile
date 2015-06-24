//
//  Fonts.swift
//  Prototype
//
//  Created by Cameron Pulsford on 2/27/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

let Fonts = FontManager()

class FontManager: NSObject {

    private override init() {}

    let headline = _lightFontOfSize(Scale.baseValue * 6.8)
    let subHeadline1 = _lightFontOfSize(Scale.baseValue * 4.5)
    let subHeadline2 = _lightFontOfSize(Scale.baseValue * 3.0)
    let subHeadline3 = _bookFontOfSize(Scale.baseValue * 2.5)
    let body = _bookFontOfSize(Scale.baseValue * 2.0)
    let caption1 = _bookFontOfSize(Scale.baseValue * 1.3)
    let caption2 = _bookFontOfSize(Scale.baseValue * 1.2)

    func lightFontOfSize(size: CGFloat) -> UIFont {
        return _lightFontOfSize(size)
    }

    func bookFontOfSize(size: CGFloat) -> UIFont {
        return _bookFontOfSize(size)
    }

}

private func _lightFontOfSize(size: CGFloat) -> UIFont {
    return UIFont(name: "Gotham-Light", size: size)!
}

private func _bookFontOfSize(size: CGFloat) -> UIFont {
    return UIFont(name: "Gotham-Book", size: size)!
}
