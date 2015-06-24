//
//  Sizes.swift
//  Prototype
//
//  Created by Cameron Pulsford on 3/3/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

let Sizes = SizeManager()

class SizeManager: NSObject {

    let pixel: CGFloat = UIScreen.screenPixel()

    let row: CGFloat = Scale.baseValue * 0.8
    
    func columnForOrientation(orientation: UIInterfaceOrientation) -> CGFloat {
        let rect = UIScreen.mainScreen().bounds
        
        if UIInterfaceOrientationIsPortrait(orientation) {
            return min(rect.height, rect.width) / numberOfColumnsForOrientation(orientation)
        } else {
            return max(rect.height, rect.width) / numberOfColumnsForOrientation(orientation)
        }
    }
    
    private func numberOfColumnsForOrientation(orientation: UIInterfaceOrientation) -> CGFloat {
        if UIDevice.isPhone() {
            return 50
        } else {
            if UIInterfaceOrientationIsPortrait(orientation) {
                return 62
            } else {
                return 74
            }
        }
    }
    
    private override init() {}
    
}
