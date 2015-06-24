//
//  CircularProgressView.swift
//  Savant
//
//  Created by Stephen Silber on 4/10/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

class CircularProgressView: UIView {

    var progressCircle = CAShapeLayer()
    var circlePath = UIBezierPath()
    var circleRadius: CGFloat = 0.0
    var progress: CGFloat = 0.0
    var width: CGFloat = 0.0
    var color: CGColor
    
    required init(frame: CGRect, radius: CGFloat, lineWidth: CGFloat, tintColor: UIColor) {
        color = tintColor.CGColor
        circleRadius = radius
        width = lineWidth
        
        super.init(frame: frame)
        
        drawCircle()
    }
    
    func drawCircle() {
        circlePath = UIBezierPath(arcCenter: CGPointZero, radius: circleRadius, startAngle: CGFloat(-0.5 * M_PI), endAngle: CGFloat(1.5 * M_PI), clockwise: true)
        progressCircle = CAShapeLayer()
        progressCircle.path = circlePath.CGPath
        progressCircle.strokeColor = color
        progressCircle.lineWidth = width
        progressCircle.fillColor = UIColor.clearColor().CGColor
        progressCircle.strokeStart = 0
        progressCircle.strokeEnd = 0
        
        layer.addSublayer(progressCircle)
    }
    
    func updateProgress(progress: CGFloat) {
        self.progress = progress
        progressCircle.strokeEnd = progress
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
