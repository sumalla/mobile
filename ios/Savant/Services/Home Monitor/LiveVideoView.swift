//
//  LiveVideoView.swift
//  Prototype
//
//  Created by Joseph Ross on 3/17/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//


public class LiveVideoView : SAVVideoView {
    
    var livePill:UILabel!
    
    public override init() {
        super.init()

        livePill = UILabel()
        livePill.text = NSLocalizedString("LIVE", comment:"")
        livePill.font = Fonts.caption1
        livePill.textAlignment = .Center
        livePill.backgroundColor = Colors.color6shade1.colorWithAlphaComponent(0.9)
        livePill.textColor = Colors.color1shade1
        livePill.layer.cornerRadius = 12
        livePill.clipsToBounds = true
        livePill.opaque = false
        addSubview(livePill)
        
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public required override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        let frame = self.visibleVideoView().frame;
        let xOffset = Sizes.row * 3;
        let yOffsetFromBottom = Sizes.row * 3;
        let width = Sizes.row * 7;
        let height = Sizes.row * 3;
        
        livePill.frame = CGRectMake(frame.origin.x + xOffset, frame.origin.y + frame.size.height - yOffsetFromBottom - height, width, height)
    }
}
