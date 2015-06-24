//
//  TipsViewModel.swift
//  Savant
//
//  Created by Stephen Silber on 4/29/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import DataSource

class TipModelItem: ModelItem {
    var tipText = String()
    var tipNumberText = String()
}

class TipViewModel: DataSource {
    
    var dataSource = [TipModelItem]()
    
    init(tipItems: [String]) {
        super.init()
        
        updateDataSource(tipItems)
        setItems(dataSource)
        reloader?.reloadData()
    }
    
    func updateDataSource(items: [String]) {
        dataSource = [TipModelItem]()
        
        for (index, text) in enumerate(items) {
            var modelItem = TipModelItem()
            modelItem.tipText = text
            modelItem.tipNumberText = String("Tip \(index + 1): ")
            dataSource.append(modelItem)
        }
    }
    
    override func itemForIndexPath(indexPath: NSIndexPath) -> T? {
        return dataSource[indexPath.row]
    }

}
