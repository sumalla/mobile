//
//  DeviceFoundCard.swift
//  Savant
//
//  Created by Stephen Silber on 5/18/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import DataSource

class DeviceFoundCard: CardCell {

    var containerView = UIView()
    var topLabel = UILabel(frame: CGRectZero)
    var mainButton = SCUButton(style: .StandardPillDark, title: NSLocalizedString("Select Room", comment: ""))
    var mainButtonText = "Select Room" { didSet { mainButton.title = mainButtonText } }
    var linkButton = SCUButton(style: .UnderlinedTextDark, title: NSLocalizedString("Locate", comment: ""))
    var deleteButton = SCUButton(image: UIImage(named: "x"))
    let textField = ResizingTextField(frame: CGRectZero, maxWidth: Sizes.row * 30)
    let blinkingLabel = UILabel(frame: CGRectZero)
    var showingUID = false
    var animating = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setCardHeight()
        
        contentView.addSubview(textField)
        contentView.sav_pinView(textField, withOptions: .CenterX)
        contentView.sav_pinView(textField, withOptions: .ToTop, withSpace: Sizes.row * 8)
        
        homeLabel.hidden = true

        containerView = UIView()
        bottomView.addSubview(containerView)
        bottomView.sav_addFlushConstraintsForView(containerView)
        
        deleteButton.color = Colors.color1shade1

        blinkingLabel.textColor = Colors.color1shade1
        blinkingLabel.text = Strings.blinkingString.uppercaseString
        blinkingLabel.font = Fonts.caption1
        blinkingLabel.alpha = 0
        
        contentView.addSubview(blinkingLabel)
        contentView.sav_pinView(blinkingLabel, withOptions: .CenterX)
        
        contentView.addSubview(deleteButton)
        contentView.sav_pinView(deleteButton, withOptions: .ToLeft, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 3)
        contentView.sav_pinView(deleteButton, withOptions: .ToTop, withSpace: Sizes.row * 2)

        containerView.addSubview(mainButton)
        containerView.sav_pinView(mainButton, withOptions: .CenterX)
        
        containerView.addSubview(linkButton)
        containerView.sav_pinView(linkButton, withOptions: .CenterX)
        
        linkButton.sizeToFit()

        setupConstraints()

        addTriangleToButton(mainButton)
	}
    
    func setupConstraints() {
        contentView.sav_pinView(blinkingLabel, withOptions: .ToTop, withSpace: Sizes.row * 31)
        containerView.sav_pinView(mainButton, withOptions: .ToTop, withSpace: Sizes.row * 4)
        containerView.sav_setSize(CGSize(width: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 26, height: Sizes.row * 5), forView: mainButton, isRelative: false)
        containerView.sav_pinView(linkButton, withOptions: .ToTop, withSpace: Sizes.row * 12)
    }
    
    func setCardHeight() {
        setCardHeightForSections(Sizes.row * 18, top: Sizes.row * 36)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        animating = false
        showingUID = false
        topLabel.text = ""
    }
    
    func blinkLED() {
        if !animating {
            animating = true
            UIView.animateWithDuration(0.2, animations: { [unowned self] in
                self.blinkingLabel.alpha = 1
                }) { (finished: Bool) in
                    UIView.animateWithDuration(0.2, delay: 10, options: nil, animations: { () -> Void in
                        self.blinkingLabel.alpha = 0
                        }, completion: { (finished: Bool) in
                            self.animating = false
                        })
            }
        }
    }
    
    override func configureWithItem(modelItem: ModelItem) {
        super.configureWithItem(modelItem)
        let item = modelItem as! DeviceModelItem
        textField.text = item.title
    }
    
    func addTriangleToButton(button: SCUButton) {
        let triangle = triangleWithPoints([CGPoint(x: 0, y: 0),
            CGPoint(x: 12, y: 0),
            CGPoint(x: 6, y: 6)])
        
        button.layer.addSublayer(triangle)
        triangle.frame.origin.x = Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 22.5
        triangle.frame.origin.y = 18
    }
    
    func triangleWithPoints(points: [CGPoint]) -> CAShapeLayer {
        let path = UIBezierPath()
        path.moveToPoint(points[0])
        path.addLineToPoint(points[1])
        path.addLineToPoint(points[2])
        path.closePath()
        
        let triangle = CAShapeLayer()
        triangle.path = path.CGPath
        triangle.fillColor = Colors.color3shade2.CGColor
        return triangle
    }
}
