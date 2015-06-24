//
//  RoomCell.swift
//  Prototype
//
//  Created by Nathan Trapp on 2/13/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import DataSource

class RoomCell: DataSourceCollectionViewCell {

    let roomImage = UIImageView()
    let roomLabel = UILabel()
    let gradient = SCUGradientView(frame: CGRect.zeroRect, andColors: nil)
    var serviceSelector: ServiceSelectorViewController?
    var lastOrientation = UIDevice.interfaceOrientation()

    let captureView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        roomImage.contentMode = .ScaleAspectFill
        roomImage.clipsToBounds = true

        contentView.addSubview(roomImage)
        contentView.sendSubviewToBack(roomImage)

        gradient.colors = [SCUColors.shared().color03.colorWithAlphaComponent(0.6), SCUColors.shared().color03.colorWithAlphaComponent(0.2), SCUColors.shared().color03.colorWithAlphaComponent(0.8)]
        gradient.locations = [0, 0.65, 1]

        captureView.addSubview(gradient)

        contentView.addSubview(captureView)
        captureView.opaque = false

        roomLabel.textColor = Colors.color1shade1
        roomLabel.font = Fonts.subHeadline2

        contentView.addSubview(roomLabel)
        contentView.sav_pinView(roomLabel, withOptions: .ToTop, withSpace: Sizes.row * 6)
        contentView.sav_pinView(roomLabel, withOptions: .Leading, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 4)
        contentView.sav_pinView(roomLabel, withOptions: .Trailing, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()))
        contentView.bringSubviewToFront(roomLabel)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let rect = self.bounds

        if roomImage.frame != rect {
            roomImage.frame = rect
        }

        if gradient.frame != rect {
            gradient.frame = rect
        }

        if captureView.frame != rect {
            captureView.frame = rect
        }

        if let vc = serviceSelector {
            let newRect = CGRectMake(0, rect.height - Sizes.row * 12, rect.width, Sizes.row * 12)

            let orientationHasChanged: Bool
            let currentOrientation = UIDevice.interfaceOrientation()

            if lastOrientation == currentOrientation {
                orientationHasChanged = false
            } else {
                orientationHasChanged = true
                lastOrientation = currentOrientation
            }

            if orientationHasChanged || vc.collectionView?.frame != newRect {
                vc.collectionView?.frame = newRect
                vc.configureLayoutWithOrientation(UIDevice.interfaceOrientation())
                vc.collectionViewLayout.invalidateLayout()
            }
        }
    }

    override func configureWithItem(modelItem: ModelItem) {
        roomImage.image = modelItem.image

        if let room = modelItem.dataObject as? SAVRoom {
            roomLabel.text = room.roomId
        }

        if let item = modelItem as? RoomsItemModel, ss = item.serviceSelector {
            setNewServiceSelector(ss)
        }

        setHidden(false, animated: false, delay: 0)
    }

    func setHidden(hidden: Bool, animated: Bool, delay: NSTimeInterval) {
        let block = { () -> () in
            if hidden {
                self.serviceSelector?.collectionView?.alpha = 0
                self.roomLabel.alpha = 0
            } else {
                self.serviceSelector?.collectionView?.alpha = 1
                self.roomLabel.alpha = 1
            }
        }

        if animated {
            UIView.animateWithDuration(0.18, delay: delay, options: .CurveEaseInOut, animations: block, completion: nil)
        } else {
            block()
        }
    }

    func setNewServiceSelector(vc: ServiceSelectorViewController) {
        if let currentVC = serviceSelector, cv = currentVC.collectionView {
            if currentVC === vc {
                if let sv = cv.superview {
                    if sv === contentView {
                        lastOrientation = .Unknown
                        setNeedsLayout()
                        return
                    }
                }
            } else {
                for v in contentView.subviews {
                    if v === cv {
                        cv.removeFromSuperview()
                        break
                    }
                }
            }

            self.serviceSelector = nil
        }

        serviceSelector = vc

        if let cv = vc.collectionView {
            contentView.addSubview(cv)
        }
    }

}
