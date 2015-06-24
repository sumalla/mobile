//
//  ImageViewController.swift
//  Savant
//
//  Created by Cameron Pulsford on 3/24/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {

    let image: UIImage

    init(image i: UIImage) {
        image = i
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let imageView = UIImageView(image: image)
        imageView.contentMode = .ScaleAspectFill
        view.addSubview(imageView)
        view.sav_addFlushConstraintsForView(imageView)
    }

}
