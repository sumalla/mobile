//
//  TitleAndPromptNavigationView.swift
//  Prototype
//
//  Created by Cameron Pulsford on 3/5/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

public class TitleAndPromptNavigationView: UIView {

    let prompt = UILabel()
    let title = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(title)
        self.addSubview(prompt)

        prompt.textAlignment = .Center
        title.textAlignment = .Center
        prompt.font = Fonts.caption2
        prompt.textColor = Colors.color1shade1.colorWithAlphaComponent(0.4)
        title.font = Fonts.caption1
        title.textColor = Colors.color1shade1

        let configuration = SAVViewDistributionConfiguration()
        configuration.vertical = true
        configuration.interSpace = 0
        configuration.distributeEvenly = true

        self.sav_distributeViewsEvenly([prompt, title], withConfiguration: configuration)
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }
    
}
