//
//  ViewController.swift
//  Testing123
//
//  Created by Cameron Pulsford on 4/16/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Extensions

class TestViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        if let path = NSBundle.mainBundle().pathForResource("Entry", ofType: "jpg") {
            let roomImage = UIImage(contentsOfFile: path)!

            let imageView = UIImageView(image: roomImage.applySavantBlur())
            imageView.contentMode = .ScaleAspectFill
            view.addSubview(imageView)
            view.sav_addFlushConstraintsForView(imageView)

            NSTimer.sav_scheduledBlockWithDelay(0) {
                let x = dispatch_benchmark(10) {
                    roomImage.applySavantBlur()
                }

                println(x / 1000000)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        println("ruh roh")
    }

}

