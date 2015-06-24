//
//  ErrorField.swift
//  Savant
//
//  Created by Cameron Pulsford on 3/25/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

enum ErrorTextFieldStyle {
    case Light
    case Dark
    case Plain
}

class ErrorTextField: UIView {

    private let style: ErrorTextFieldStyle
    private let textColor: UIColor
    private let placeholderTextColor: UIColor
    private let errorBoxColor: UIColor
    private let errorTextColor: UIColor
    private let activeLineColor: UIColor
    private let inactiveLineColor: UIColor
    private let textFieldErrorBox: UIView
    private let separator: UIView
    private let errorLabel = UILabel()
    private var hasEdited = false
    let textField = UITextField()
    var beginHandler: (() -> ())?
    var returnHandler: (() -> ())?
    var validationHandler: ((text: String) -> String?)?
    var clearErrorOnTextEditingStart = true

    var text: String? {
        get {
            return textField.text
        }
        set {
            textField.text = newValue
        }
    }

    var placeholder: String? {
        get {
            return textField.attributedPlaceholder?.string
        }
        set {
            if let v = newValue {
                textField.attributedPlaceholder = NSAttributedString(string: v, attributes: [NSForegroundColorAttributeName: placeholderTextColor, NSFontAttributeName: Fonts.body])
            } else {
                textField.attributedPlaceholder = nil
            }
        }
    }

    var errorText: String? {
        get {
            return errorLabel.text ?? ""
        }
        set {
            errorLabel.text = newValue
            layoutIfNeeded()

            UIView.animateWithDuration(0.2) {
                self.invalidateIntrinsicContentSize()
                self.layoutIfNeeded()

                if newValue == nil {
                    self.textFieldErrorBox.alpha = 0
                } else {
                    self.textFieldErrorBox.alpha = 1
                }
            }
        }
    }

    var valid: Bool {
        return errorText == nil
    }

    init(frame: CGRect, style s: ErrorTextFieldStyle) {
        style = s

        switch style {
        case .Light:
            textColor = Colors.color1shade1
            placeholderTextColor = Colors.color1shade3
            errorBoxColor = Colors.color1shade4
            errorTextColor = Colors.color1shade1
            activeLineColor = Colors.color1shade1
            inactiveLineColor = Colors.color1shade1
        case .Dark:
            textColor = Colors.color3shade1
            placeholderTextColor = Colors.color3shade2
            errorBoxColor = Colors.color3shade4
            errorTextColor = Colors.color3shade1
            activeLineColor = Colors.color3shade1
            inactiveLineColor = Colors.color3shade2
        case .Plain:
            textColor = Colors.color1shade1
            placeholderTextColor = Colors.color3shade2
            errorBoxColor = Colors.color3shade4
            errorTextColor = Colors.color1shade1
            activeLineColor = UIColor.clearColor()
            inactiveLineColor = UIColor.clearColor()
        }

        textFieldErrorBox = UIView.sav_viewWithColor(errorBoxColor)
        separator = UIView.sav_viewWithColor(inactiveLineColor)

        super.init(frame: frame)
        addSubview(textFieldErrorBox)
        addSubview(textField)
        addSubview(separator)
        addSubview(errorLabel)

        textField.tintColor = textColor
        errorLabel.textAlignment = .Center
        textField.font = Fonts.body
        textField.delegate = self
        errorLabel.font = Fonts.caption1
        textField.textColor = textColor
        errorLabel.textColor = errorTextColor
        errorLabel.numberOfLines = 0

        sav_pinView(textFieldErrorBox, withOptions: .ToTop | .Horizontally)
        sav_setHeight(Sizes.row * 6, forView: textFieldErrorBox, isRelative: false)
        
        sav_pinView(textField, withOptions: .ToTop, withSpace: Sizes.row * 1.5)
        
        if style == .Plain {
            sav_pinView(textField, withOptions: .ToLeft)
        } else {
            sav_pinView(textField, withOptions: .ToLeft, withSpace: Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 2)
        }
        
        sav_pinView(textField, withOptions: .ToRight)
        sav_setHeight(Sizes.row * 3, forView: textField, isRelative: false)

        sav_pinView(separator, withOptions: .Horizontally)
        sav_pinView(separator, withOptions: .ToBottom, ofView: textFieldErrorBox, withSpace: 0)
        sav_setHeight(Sizes.pixel * 2, forView: separator, isRelative: false)

        sav_pinView(errorLabel, withOptions: .ToBottom, ofView: separator, withSpace: Sizes.row / 2)
        sav_pinView(errorLabel, withOptions: .Horizontally)

        textFieldErrorBox.alpha = 0
    }

    convenience init(style: ErrorTextFieldStyle) {
        self.init(frame: CGRectZero, style: style)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func validate() -> Bool {
        var valid = true

        if let vh = validationHandler {
            if let error = vh(text: textField.text) {
                errorText = error
                valid = false
            } else {
                errorText = nil
            }
        }

        return valid
    }

    override func intrinsicContentSize() -> CGSize {
        var height = Sizes.row * 6.5

        let minErrorSpacing = Sizes.row * 2.5

        if let t = errorLabel.text {
            if count(t) > 0 {
                var h = errorLabel.intrinsicContentSize().height

                if h < minErrorSpacing {
                    h = minErrorSpacing
                } else {
                    h += Sizes.row * 1.5
                }

                height += h
            } else {
                height += minErrorSpacing
            }
        } else {
            height += minErrorSpacing
        }

        return CGSize(width: UIViewNoIntrinsicMetric, height: height)
    }

    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        beginEditing()
    }

    func beginEditing() {
        textField.becomeFirstResponder()

        if clearErrorOnTextEditingStart {
            errorText = nil
        }
    }

}

extension ErrorTextField: UITextFieldDelegate {

    func textFieldDidBeginEditing(textField: UITextField) {
        separator.backgroundColor = activeLineColor
        if let bh = beginHandler {
            bh()
        }
        beginEditing()
    }

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        hasEdited = true
        beginEditing()
        return true
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let rh = returnHandler {
            rh()
        }

        return true
    }

    func textFieldDidEndEditing(textField: UITextField) {
        separator.backgroundColor = inactiveLineColor

        if hasEdited {
            validate()
        }
    }

}
