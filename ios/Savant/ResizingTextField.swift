//
//  ResizingTextField.swift
//  Savant
//
//  Created by Stephen Silber on 5/21/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

class ResizingTextField: UIView, UITextFieldDelegate {
    let textField = UITextField(frame: CGRectZero)
    let editButton = SCUButton(image: UIImage(named: "pencil"))
    let maxWidth: CGFloat
    var textFieldUpdate: ((String, finishedEditing:Bool) -> Void)?
    var size = CGSizeZero
    let tap = UITapGestureRecognizer()
    let underline = UIView(frame: CGRectZero)
    
    var text: String? {
        get {
            return textField.text
        }
        
        set(newText) {
            textField.text = newText
            if let sv = superview, recognizers = sv.gestureRecognizers as? [UIGestureRecognizer] {
                if find(recognizers, tap) == nil {
                    sv.addGestureRecognizer(tap)
                }
            }
            textFieldDidChange(textField)
        }
    }
    
    init(frame: CGRect, maxWidth: CGFloat) {
        self.maxWidth = maxWidth
        super.init(frame: CGRectZero)

        addSubview(textField)
        addSubview(editButton)
        addSubview(underline)
        
        underline.backgroundColor = Colors.color1shade1
        underline.hidden = true

        sav_pinView(underline, withOptions: .ToBottom | .CenterX)
        sav_setHeight(UIScreen.screenPixel() * 2, forView: underline, isRelative: false)
        
        textField.font = Fonts.body
        textField.textColor = Colors.color1shade1
        textField.textAlignment = .Center
        textField.returnKeyType = .Done
        
        textField.delegate = self
        
        editButton.color = Colors.color1shade1
        
        editButton.releaseCallback = { [unowned self] in
            if self.textField.isFirstResponder() {
                self.textField.resignFirstResponder()
                if let update = self.textFieldUpdate {
                    update(self.textField.text, finishedEditing:true)
                }
            } else {
                self.textField.becomeFirstResponder()
            }
        }
        
        textField.frame.size.width = intrinsicContentSize().width - 80
        textField.frame.size.height = intrinsicContentSize().height
        textField.frame.origin.x = 40
        
        tap.numberOfTapsRequired = 1
        tap.sav_handler = { [unowned self] (state, point) in
            self.textField.resignFirstResponder()
            self.textFieldUpdate?(self.textField.text, finishedEditing:true)
        }
        
        self.superview?.addGestureRecognizer(tap)
        
        sav_pinView(editButton, withOptions: .CenterY)
        
        textField.addTarget(self, action: "textFieldDidChange:", forControlEvents: .EditingChanged)
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        updateButtonPosition()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textFieldDidChange(textField: UITextField) {
        let text = textField.text as NSString
        size = text.sizeWithAttributes([NSFontAttributeName: textField.font]) as CGSize
        
        if maxWidth >= size.width + CGRectGetWidth(editButton.frame) {
            UIView.animateWithDuration(0.1) { [unowned self] in
                self.updateButtonPosition()
            }
        }
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        underline.hidden = false
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        underline.hidden = true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.textField.resignFirstResponder()
        self.textFieldUpdate?(self.textField.text, finishedEditing:true)
        return true
    }
    
    func updateButtonPosition() {
        if (CGRectGetMidX(textField.frame) + self.size.width / 2) < CGRectGetMaxX(textField.frame) {
            self.editButton.frame.origin.x = CGRectGetMidX(textField.frame) + self.size.width / 2 - Sizes.columnForOrientation(UIDevice.interfaceOrientation())
            underline.frame.size.width = size.width + 10
            underline.frame.origin.x = CGRectGetMidX(textField.frame) - self.size.width / 2 - 5
        }
    }
    
    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: self.maxWidth, height: Sizes.row * 4);
    }
}
