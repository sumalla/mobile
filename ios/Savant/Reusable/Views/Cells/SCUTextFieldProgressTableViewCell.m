//
//  SCUTextFieldTableViewCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUTextFieldProgressTableViewCell.h"

@import Extensions;

NSString *const SCUTextFieldProgressTableViewCellKeyEditableText = @"SCUTextFieldProgressTableViewCellKeyEditableText";
NSString *const SCUTextFieldProgressTableViewCellKeyPlaceholderText = @"SCUTextFieldProgressTableViewCellKeyPlaceholderText";
NSString *const SCUTextFieldProgressTableViewCellKeyIsSecure = @"SCUTextFieldProgressTableViewCellKeyIsSecure";
NSString *const SCUTextFieldProgressTableViewCellKeyKeyboardType = @"SCUTextFieldProgressTableViewCellKeyKeyboardType";
NSString *const SCUTextFieldProgressTableViewCellKeyReturnKeyType = @"SCUTextFieldProgressTableViewCellKeyReturnKeyType";
NSString *const SCUTextFieldProgressTableViewCellKeyClearType = @"SCUTextFieldProgressTableViewCellKeyClearType";
NSString *const SCUTextFieldProgressTableViewCellKeyAutocorrectionType = @"SCUTextFieldProgressTableViewCellKeyAutocorrectionType";
NSString *const SCUTextFieldProgressTableViewCellKeyAutocapitalizationType = @"SCUTextFieldProgressTableViewCellKeyAutocapitalizationType";
NSString *const SCUTextFieldProgressTableViewCellKeyErrorText = @"SCUTextFieldProgressTableViewCellKeyErrorText";

@interface SCUTextFieldProgressTableViewCell ()

@property (nonatomic) SCUErrorTextField *textField;

@property (nonatomic) NSDictionary *info; /* hacky */

@end

@implementation SCUTextFieldProgressTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.textLabel.hidden = YES;

        SCUErrorTextField *textField = [[SCUErrorTextField alloc] initWithFrame:CGRectZero];
        textField.contentInsets = UIEdgeInsetsMake(2, 16, 5, 21);
        self.textField = textField;

        [self setDefaults];
        [self.contentView addSubview:self.textField];
        [self.contentView sav_addFlushConstraintsForView:textField];
    }

    return self;
}

- (void)setDefaults
{
    self.textField.delegate = nil;
    self.textField.placeholder = nil;
    self.textField.text = nil;
    self.textField.textColor = self.textLabel.textColor;
    self.textField.returnKeyType = UIReturnKeyDefault;
    self.textField.secureTextEntry = NO;
    self.textField.spellCheckingType = UITextAutocorrectionTypeNo;
    self.tag = 0;
    self.textField.tag = 0;
    [self.textField restore];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self setDefaults];
}

- (void)configureWithInfo:(NSDictionary *)info
{
    self.info = info;

    [super configureWithInfo:info];

    if (self.isFixed)
    {
        self.textLabel.hidden = NO;
        self.detailTextLabel.hidden = NO;
        self.textField.hidden = YES;
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
        self.textLabel.text = info[SCUDefaultTableViewCellKeyTitle];
        self.detailTextLabel.text = info[SCUDefaultTableViewCellKeyDetailTitle];
        self.detailTextLabel.textColor = info[SCUDefaultTableViewCellKeyDetailTitleColor];
    }
    else
    {
        self.textLabel.hidden = YES;
        self.detailTextLabel.hidden = YES;
        self.textField.hidden = NO;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.textField.text = info[SCUTextFieldProgressTableViewCellKeyEditableText];
        [self.textField sav_setPlaceholderText:info[SCUTextFieldProgressTableViewCellKeyPlaceholderText] color:[[[SCUColors shared] color04] colorWithAlphaComponent:0.6]];
        self.textField.secureTextEntry = [info[SCUTextFieldProgressTableViewCellKeyIsSecure] boolValue];
        self.textField.keyboardType = [info[SCUTextFieldProgressTableViewCellKeyKeyboardType] integerValue];
        self.textField.returnKeyType = [info[SCUTextFieldProgressTableViewCellKeyReturnKeyType] integerValue];
        self.textField.rightViewMode = [info[SCUTextFieldProgressTableViewCellKeyClearType] integerValue];
        self.textField.autocorrectionType = [info[SCUTextFieldProgressTableViewCellKeyAutocorrectionType] integerValue];
        self.textField.autocapitalizationType = [info[SCUTextFieldProgressTableViewCellKeyAutocapitalizationType] integerValue];

        NSString *errorText = info[SCUTextFieldProgressTableViewCellKeyErrorText];

        if (errorText)
        {
            self.textField.errorMessage = errorText;
        }
    }
}

#pragma mark -

- (void)setFixed:(BOOL)fixed
{
    _fixed = fixed;
    [self configureWithInfo:self.info];
}

@end
