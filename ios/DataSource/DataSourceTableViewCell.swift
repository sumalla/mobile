//
//  ModelCollectionViewController.swift
//  Prototype
//
//  Created by Cameron Pulsford on 2/26/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

public class DataSourceTableViewCell: UITableViewCell {

    public func configureWithItem(modelItem: ModelItem) {
        textLabel?.text = modelItem.title
        detailTextLabel?.text = modelItem.subtitle
    }

}
