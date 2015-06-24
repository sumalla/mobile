//
//  ModelCollectionViewController.swift
//  Prototype
//
//  Created by Cameron Pulsford on 2/26/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation

public protocol ViewModelProtocol {

    func willAppear()

    func didAppear()

    func willDisappear()

    func didDisappear()
}

public protocol DataSourceProtocol: ViewModelProtocol {

    typealias T: ModelItem

    weak var reloader: Reloader? { get set }

    var sections: [Section] { get set }

    func numberOfSections() -> Int

    func numberOfItemsInSection(section: Int) -> Int?

    func itemForIndexPath(indexPath: NSIndexPath) -> T?

    func modelTypeForIndexPath(indexPath: NSIndexPath) -> Int?

    func headerTitleForSection(section: Int) -> String?

    func footerTitleForSection(section: Int) -> String?

    func selectItemAtIndexPath(indexPath: NSIndexPath, modelItem: T)

    func deselectItemAtIndexPath(indexPath: NSIndexPath) -> Bool

}


public class DataSource: NSObject, DataSourceProtocol {

    public typealias T = ModelItem

    public weak var reloader: Reloader?

    public var sections = [Section]()

    /**
    If you are using a flat data source, you can use this convenience method to feed the data source.

    :param: items Your ModelItems.
    */
    public func setItems(items: [T]) {
        sections = [Section(modelItems: items)]
    }

    /**
    Returns the Section object, or nil, for the given section.

    :param: section The section whose Section object you would like.

    :returns: The Section object, or nil, for the given section.
    */
    public func sectionForSection(section: Int) -> Section? {
        if section < numberOfSections() {
            return sections[section]
        }

        return nil
    }
    
    public func enumerateItems(enumerate: (indexPath: NSIndexPath) -> Void) {
        if numberOfSections() == 1 {
            let items = numberOfItemsInSection(0)
            for index in 0...items! {
                enumerate(indexPath: NSIndexPath(forRow: index, inSection: 0))
            }
        } else {
            let sections = numberOfSections()
            
            for section in 0...sections {
                let items = numberOfItemsInSection(sections)
                for index in 0...items! {
                    enumerate(indexPath: NSIndexPath(forRow: index, inSection: section))
                }
            }
        }
    }

}

extension DataSource {

    public func willAppear() {

    }

    public func didAppear() {

    }

    public func willDisappear() {

    }

    public func didDisappear() {
        
    }

}

extension DataSource {

    public func numberOfSections() -> Int {
        return sections.count
    }

    public func numberOfItemsInSection(section: Int) -> Int? {
        if let modelSection = sectionForSection(section) {
            return modelSection.items.count
        } else {
            return nil
        }
    }

    public func itemForIndexPath(indexPath: NSIndexPath) -> T? {
        if let section = sectionForSection(indexPath.section) {
            if indexPath.row < section.items.count {
                return section.items[indexPath.row]
            }
        }

        return nil
    }

    public func modelTypeForIndexPath(indexPath: NSIndexPath) -> Int? {
        if let item = itemForIndexPath(indexPath) {
            return item.type
        }

        return nil
    }

    public func headerTitleForSection(section: Int) -> String? {
        if let modelSection = sectionForSection(section) {
            return modelSection.headerTitle
        }

        return nil
    }

    public func footerTitleForSection(section: Int) -> String? {
        if let modelSection = sectionForSection(section) {
            return modelSection.footerTitle
        }

        return nil
    }

    public func selectItemAtIndexPath(indexPath: NSIndexPath, modelItem: T) {

    }

    public func deselectItemAtIndexPath(indexPath: NSIndexPath) -> Bool {
        return true
    }

}
