//
//  VerticalFlowLayout.swift
//  Prototype
//
//  Created by Cameron Pulsford on 3/4/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

class VerticalFlowLayout: SCUAnimationFixFlowLayout {

    var columns: CGFloat = 1
    var height: CGFloat = Sizes.row * 10
    var interspace: CGFloat = Sizes.row
    var horizontalInset: CGFloat = 0

    override func prepareLayout() {
        super.prepareLayout()
        self.collectionView?.alwaysBounceVertical = true
        let oldInset = self.collectionView!.contentInset
        self.collectionView?.contentInset = UIEdgeInsets(top: oldInset.top, left: horizontalInset, bottom: oldInset.bottom, right: horizontalInset)
        self.minimumLineSpacing = interspace
        self.minimumInteritemSpacing = interspace
        var width = self.collectionView!.bounds.width
        width -= (columns - 1) * interspace
        width -= horizontalInset * 2
        itemSize = CGSize(width: width / columns, height: height)
    }

}
