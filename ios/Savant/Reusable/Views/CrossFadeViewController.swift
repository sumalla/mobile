//
//  CrossFadeViewController.swift
//  Savant
//
//  Created by Cameron Pulsford on 4/2/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

class CrossFadeViewController: UIViewController {

    private let imageView = UIImageView()
    var image: UIImage? {
        didSet {
            imageView.image = image // Cross fade not implemented yet
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(imageView)
        view.sav_addFlushConstraintsForView(imageView)
        imageView.contentMode = .ScaleAspectFill
    }

}
