//
//  ModelViewController.swift
//  Prototype
//
//  Created by Cameron Pulsford on 3/6/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit


public class ModelViewController: UIViewController {

    public func viewModelSource() -> ViewModelProtocol {
        fatalError("implement")
    }

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        viewModelSource().willAppear()
    }

    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        viewModelSource().didAppear()
    }

    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        viewModelSource().willDisappear()
    }

    public override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        viewModelSource().didDisappear()
    }

}