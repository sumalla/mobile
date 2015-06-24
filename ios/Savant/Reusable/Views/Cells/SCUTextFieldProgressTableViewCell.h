//
//  SCUTextFieldTableViewCell.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUProgressTableViewCell.h"
#import "SCUErrorTextField.h"

extern NSString *const SCUTextFieldProgressTableViewCellKeyEditableText;
extern NSString *const SCUTextFieldProgressTableViewCellKeyPlaceholderText;
extern NSString *const SCUTextFieldProgressTableViewCellKeyIsSecure;
extern NSString *const SCUTextFieldProgressTableViewCellKeyKeyboardType;
extern NSString *const SCUTextFieldProgressTableViewCellKeyReturnKeyType;
extern NSString *const SCUTextFieldProgressTableViewCellKeyClearType;
extern NSString *const SCUTextFieldProgressTableViewCellKeyAutocorrectionType;
extern NSString *const SCUTextFieldProgressTableViewCellKeyAutocapitalizationType;
extern NSString *const SCUTextFieldProgressTableViewCellKeyErrorText;

@interface SCUTextFieldProgressTableViewCell : SCUProgressTableViewCell

@property (nonatomic, readonly) SCUErrorTextField *textField;

@property (nonatomic, getter = isFixed) BOOL fixed;

@end
