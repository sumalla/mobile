//
//  ModelCollectionViewController.swift
//  Prototype
//
//  Created by Cameron Pulsford on 2/26/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

public protocol Reloader: class {

    func performUpdates(updates: ((reloader: Reloader) -> ()))

    func reloadData()

    func reloadIndexPaths(indexPaths: [NSIndexPath], animation: UITableViewRowAnimation)

    func reloadSections(sections: NSIndexSet, animation: UITableViewRowAnimation)

    func insertRowsAtIndexPaths(indexPaths: [NSIndexPath], animation: UITableViewRowAnimation)

    func deleteRowsAtIndexPaths(indexPaths: [NSIndexPath], animation: UITableViewRowAnimation)
    
    func insertSections(sections: NSIndexSet, animation: UITableViewRowAnimation)
    
    func deleteSections(sections: NSIndexSet, animation: UITableViewRowAnimation)

}
