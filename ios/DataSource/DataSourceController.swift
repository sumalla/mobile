//
//  ModelCollectionViewController.swift
//  Prototype
//
//  Created by Cameron Pulsford on 2/26/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation

public protocol DataSourceController {

    /**
    *  Override this method to return your DataSource. This method is called from viewDidLoad, so you must be ready to return your DataSource before then.
    */
    func viewDataSource() -> DataSource

    /**
    *  Register all your cell classes.
    */
    func registerCells()

}
