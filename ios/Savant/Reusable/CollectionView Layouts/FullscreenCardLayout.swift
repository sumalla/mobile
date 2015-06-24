//
//  FullscreenCardFlowLayout.swift
//  Savant
//
//  Created by Stephen Silber on 3/26/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation
import UIKit

class FullscreenCardFlowLayout : UICollectionViewLayout {
    
    var height: CGFloat = 0
    var width: CGFloat = 0
    var widthPercentage: CGFloat = 1.0
    var interspace: CGFloat = 20.0
    var animate = true
    var sticky = true
    var vertical = false
    var pan: UIPanGestureRecognizer?
    
    private var pickerContentOffset: CGFloat = 0
    private var panOffset: CGFloat = 0
    private var currentPage: CGFloat = 1
    
    private var contentSize = CGSizeZero
    private var layoutAttributes = [UICollectionViewLayoutAttributes]()
    private var layoutInfo = [String: UICollectionViewLayoutAttributes]()
    private let flickVelocity = 0.1
    
    required init(interspace: CGFloat, width: CGFloat, height: CGFloat) {
        super.init()
        self.interspace = interspace
        self.width = width
        self.height = height
    }
    
    convenience override init() {
        self.init(interspace: 15, width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 36, height: Sizes.row * 50)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func pageWidth() -> CGFloat {
        return cardWidth() + interspace
    }
    
    func pageHeight() -> CGFloat {
        return vertical ? cardHeight() + interspace : collectionView!.bounds.height
    }
    
    func cardWidth() -> CGFloat {
        return width
    }
    
    func cardHeight() -> CGFloat {
        return height
    }
    
    func keyForIndexPath(indexPath: NSIndexPath) -> String {
        return "\(indexPath.section)-\(indexPath.row)"
    }
    
    func frameForCardAtIndexPath(indexPath: NSIndexPath) -> CGRect {
        if vertical {
            let initialY: CGFloat = 0
            var positionY = initialY + (pageHeight() * CGFloat(indexPath.row))

            return CGRectMake((collectionView!.bounds.width / 2) - (cardWidth() / 2), positionY, cardWidth(), cardHeight())

        } else {
            
            let initialX = (collectionView!.bounds.width - cardWidth()) / 2
            var positionX = initialX + (pageWidth() * CGFloat(indexPath.row))

            return CGRectMake(positionX, (pageHeight() - cardHeight()) / 2, cardWidth(), cardHeight())
        }
    }
    
    override func prepareLayout() {
        if let cv = collectionView where pan == nil && sticky {
            pan = UIPanGestureRecognizer(target: self, action: "handlePan:")
            cv.addGestureRecognizer(pan!)
            cv.panGestureRecognizer.enabled = false
        }
        
        if collectionView!.numberOfSections() > 0 {
            var cellLayoutInfo = [String: UICollectionViewLayoutAttributes]()
            var indexPath = NSIndexPath(forItem: 0, inSection: 0)
            
            let itemCount = collectionView?.numberOfItemsInSection(0)
            for (var item = 0; item < itemCount; item++) {
                indexPath = NSIndexPath(forItem: item, inSection: 0)
                var attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
                attributes.frame = frameForCardAtIndexPath(indexPath)
                
                let key = keyForIndexPath(indexPath)
                cellLayoutInfo[key] = attributes
            }
            
            self.layoutInfo = cellLayoutInfo
            contentSize = collectionViewContentSize()
        }
    }
    
    override func collectionViewContentSize() -> CGSize {
        if vertical {
            let initialX = (collectionView!.bounds.width - cardWidth()) / 2.0
            let width = pageWidth()
            let height = CGFloat(self.layoutInfo.count) * pageHeight()
            return CGSizeMake(width, height)
        } else {
            let initialX = (collectionView!.bounds.width - cardWidth()) / 2.0
            let width = CGFloat(self.layoutInfo.count) * pageWidth() + (initialX * 2) - interspace
            let height = (pageHeight() - cardHeight()) / 2
            return CGSizeMake(width, height)
        }
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        let key = keyForIndexPath(indexPath)
        return self.layoutInfo[key]
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
        var allAttributes = [AnyObject]()
        for (elementIdentifier, attributes) in layoutInfo {
            if CGRectIntersectsRect(rect, attributes.frame) {
                allAttributes.append(attributes)
            }
        }
        
        return allAttributes
    }

    override func initialLayoutAttributesForAppearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.initialLayoutAttributesForAppearingItemAtIndexPath(itemIndexPath)
        if animate {
            if let attributes = attributes {
                var centerPoint: CGPoint = attributes.center
                centerPoint.y += CGRectGetHeight(collectionView!.frame)
                attributes.center = centerPoint
            }
        }
        
        return attributes
    }
    
    override func finalLayoutAttributesForDisappearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.finalLayoutAttributesForDisappearingItemAtIndexPath(itemIndexPath)
        if animate {
            if let attributes = attributes {
                var centerPoint: CGPoint = attributes.center
                centerPoint.y = 1000//+= CGRectGetHeight(collectionView!.frame)
                attributes.center = centerPoint
            }
        }
        
        return attributes
    }
    
    func handleHorizontalPan(pan: UIPanGestureRecognizer) {
        let velocity: CGFloat = pan.velocityInView(collectionView!.superview).x
        let point = pan.locationInView(collectionView!.superview)
        
        let direction: PanDirection = velocity > 0 ? .Right : .Left
        let layout = collectionView?.collectionViewLayout as! FullscreenCardFlowLayout
        let flickVelocity: CGFloat = 500
        
        switch pan.state {
        case .Began:
            panOffset = point.x
            pickerContentOffset = collectionView!.contentOffset.x
        case .Changed:
            if collectionView?.contentOffset.x < 0 {
                collectionView?.contentOffset.x = (-point.x + panOffset + pickerContentOffset) - ((-point.x + panOffset + pickerContentOffset) * 0.7)
            } else {
                collectionView?.contentOffset.x = -point.x + panOffset + pickerContentOffset
            }
            collectionView?.contentOffset.x = -point.x + panOffset + pickerContentOffset
        case .Ended, .Failed, .Cancelled:
            var pageOffset: CGFloat = 0
            if ((direction == .Left && ((layout.pageWidth() / 2) - point.x) >= 0.35)) || (direction == .Left && fabs(velocity) > flickVelocity) {
                pageOffset = 1
            } else if (direction == .Right && ((layout.pageWidth() / 2) - point.x) < 0.35) || (direction == .Right && fabs(velocity) > flickVelocity) {
                pageOffset = -1
            }
            
            currentPage += pageOffset
            if currentPage < 1 {
                currentPage = 1
            }
            
            let numberOfItems: CGFloat
            
            if collectionView!.numberOfSections() > 0 {
                numberOfItems = CGFloat(collectionView!.numberOfItemsInSection(0))
            } else {
                numberOfItems = 0
            }
            
            if currentPage > numberOfItems {
                currentPage = numberOfItems
            }
            
            let currentPoint: CGFloat = self.collectionView!.contentOffset.x
            let finalPoint: CGFloat = (self.currentPage - 1) * layout.pageWidth()
            let distance: CGFloat = finalPoint - currentPoint
            var duration: NSTimeInterval = 0.25
            var animationVelocity: CGFloat = velocity / (distance / CGFloat(duration))
            
            UIView.animateWithDuration(duration, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: animationVelocity, options: .AllowUserInteraction, animations: {
                self.collectionView?.contentOffset.x = (self.currentPage - 1) * layout.pageWidth()
                }, completion: nil)
            
        default:
            break
        }
        
    }

    func handleVerticalPan(pan: UIPanGestureRecognizer) {
        let velocity: CGFloat = pan.velocityInView(collectionView!.superview).y
        let point = pan.locationInView(collectionView!.superview)
        
        let direction: PanDirection = velocity > 0 ? .Down : .Up
        let layout = collectionView?.collectionViewLayout as! FullscreenCardFlowLayout
        let flickVelocity: CGFloat = 500
        
        switch pan.state {
        case .Began:
            panOffset = point.y
            pickerContentOffset = collectionView!.contentOffset.y
        case .Changed:
            if collectionView?.contentOffset.y < 0 {
                collectionView?.contentOffset.y = (-point.y + panOffset + pickerContentOffset) - ((-point.y + panOffset + pickerContentOffset) * 0.7)
            } else {
                collectionView?.contentOffset.y = -point.y + panOffset + pickerContentOffset
            }
            collectionView?.contentOffset.y = -point.y + panOffset + pickerContentOffset
        case .Ended, .Failed, .Cancelled:
            var pageOffset: CGFloat = 0
            if ((direction == .Down && ((layout.pageWidth() / 2) - point.y) >= 0.35)) || (direction == .Down && fabs(velocity) > flickVelocity) {
                pageOffset = 1
            } else if (direction == .Up && ((layout.pageWidth() / 2) - point.y) < 0.35) || (direction == .Up && fabs(velocity) > flickVelocity) {
                pageOffset = -1
            }
            
            currentPage += pageOffset
            if currentPage < 1 {
                currentPage = 1
            }
            
            let numberOfItems: CGFloat
            
            if collectionView!.numberOfSections() > 0 {
                numberOfItems = CGFloat(collectionView!.numberOfItemsInSection(0))
            } else {
                numberOfItems = 0
            }
            
            if currentPage > numberOfItems
            {
                currentPage = numberOfItems
            }
            
            let currentPoint: CGFloat = self.collectionView!.contentOffset.y
            let finalPoint: CGFloat = (self.currentPage - 1) * layout.pageHeight()
            let distance: CGFloat = finalPoint - currentPoint
            var duration: NSTimeInterval = 0.25
            var animationVelocity: CGFloat = velocity / (distance / CGFloat(duration))
            
            UIView.animateWithDuration(duration, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: animationVelocity, options: .AllowUserInteraction, animations: {
                self.collectionView?.contentOffset.y = (self.currentPage - 1) * layout.pageHeight()
                }, completion: nil)
        default:
            break
        }

    }
    
    func handlePan(pan: UIPanGestureRecognizer) {
        if vertical {
            handleVerticalPan(pan)
        } else {
            handleHorizontalPan(pan)
        }
    }
    
}