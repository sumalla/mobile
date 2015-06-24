//
//  HodgePodge.swift
//  Prototype
//
//  Created by Cameron Pulsford on 3/10/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

extension NSIndexPath: Equatable, Comparable {}

public func ==(lhs: NSIndexPath, rhs: NSIndexPath) -> Bool {
    return lhs.section == rhs.section && lhs.row == rhs.row
}

public func <(x: NSIndexPath, y: NSIndexPath) -> Bool {
    if x.section < y.section {
        return true
    } else if x.section > y.section {
        return false
    } else {
        if x.row < y.row {
            return true
        } else {
            return false
        }
    }
}

public func stringSort(options: NSStringCompareOptions = .CaseInsensitiveSearch | .NumericSearch, ascending: Bool = true) -> ((s1: String, s2: String) -> Bool) {
    return { (s1: String, s2: String) -> Bool in
        let cr = s1.compare(s2, options: options)
        
        if ascending {
            return cr == .OrderedAscending
        } else {
            return cr == .OrderedDescending
        }
    }
}
