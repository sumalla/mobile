//
//  SceneCell.swift
//  Prototype
//
//  Created by Nathan Trapp on 2/14/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import DataSource

class SceneCell: DataSourceCollectionViewCell {

    let sceneImage = UIImageView()
    let sceneLabel = UILabel()
    let roomsLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        sceneImage.contentMode = .ScaleAspectFill
        sceneImage.clipsToBounds = true

        contentView.addSubview(sceneImage)

        sceneLabel.textColor = Colors.color1shade1
        sceneLabel.font = Fonts.subHeadline3

        contentView.addSubview(sceneLabel)
        contentView.sav_addCenteredConstraintsForView(sceneLabel)

        roomsLabel.textColor = Colors.color1shade1.colorWithAlphaComponent(0.4)
        roomsLabel.font = Fonts.caption1

        contentView.addSubview(roomsLabel)
        contentView.sav_pinView(roomsLabel, withOptions: .ToBottom | .CenterX, ofView: sceneLabel, withSpace: 5)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        sceneImage.frame = self.bounds
    }

    override func configureWithItem(modelItem: ModelItem) {
        if let scene = modelItem.dataObject as? SAVScene {
            sceneLabel.text = scene.name

            if scene.tags.count == 1 {
                roomsLabel.text = NSLocalizedString("1 Room", comment: "")
            } else {
                roomsLabel.text = String(format: NSLocalizedString("%ld Rooms", comment: ""), scene.tags.count)
            }

            sceneImage.image = modelItem.image
        }
    }
    
}
