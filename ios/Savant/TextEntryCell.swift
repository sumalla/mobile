//
//  TextEntryCell.swift
//  Prototype
//
//  Created by Cameron Pulsford on 2/27/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import DataSource

class TextEntryItem: ModelItem {
    var placeholderText = ""
    var placeholderTextColor = SCUColors.shared().color03shade05
    var text = ""
    var textColor = Colors.color1shade1
    var autocorrectionType = UITextAutocorrectionType.No
    var autocapitalizationType = UITextAutocapitalizationType.None
    var returnKeyType = UIReturnKeyType.Done
    var keyboardType = UIKeyboardType.Default
    var secureTextEntry = false
}

class TextEntryCell: DataSourceTableViewCell {

    let textField = SCUErrorTextField()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(textField)
        contentView.sav_addFlushConstraintsForView(textField)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureWithItem(modelItem: ModelItem) {
        super.configureWithItem(modelItem)
        textLabel?.text = nil

        if let item = modelItem as? TextEntryItem {
            textField.autocorrectionType = item.autocorrectionType
            textField.autocapitalizationType = item.autocapitalizationType
            textField.returnKeyType = item.returnKeyType
            textField.keyboardType = item.keyboardType
            textField.secureTextEntry = item.secureTextEntry
            textField.textColor = item.textColor
            textField.attributedPlaceholder = NSAttributedString(string: item.placeholderText, attributes: [NSForegroundColorAttributeName: item.placeholderTextColor])
        }
    }

}
