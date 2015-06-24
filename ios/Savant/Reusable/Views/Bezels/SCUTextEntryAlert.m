//
//  SCUTextEntryAlert.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUTextEntryAlert.h"
#import "SCUAlertViewPrivate.h"

@interface SCUTextEntryAlert ()

@property (nonatomic) UILabel *messageLabel;

@property (nonatomic) UITextField *defaultTextField;

@property (nonatomic) UIView *separator;

@property (nonatomic) UITextField *secureTextField;

@end

@implementation SCUTextEntryAlert

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message textEntryType:(SCUTextEntryAlertFieldType)textEntryType buttonTitles:(NSArray *)buttonTitles
{
    NSParameterAssert(textEntryType);

    UIView *contentView = [[UIView alloc] initWithFrame:CGRectZero];

    self = [super initWithTitle:title contentView:contentView buttonTitles:buttonTitles];

    if (self)
    {
        if ([message length])
        {
            self.messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            self.messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
            self.messageLabel.numberOfLines = 0;
            self.messageLabel.textAlignment = NSTextAlignmentCenter;
            self.messageLabel.text = message;
            self.messageLabel.textColor = [[SCUColors shared] color03];
            self.messageLabel.font = [UIFont systemFontOfSize:14];
            [contentView addSubview:self.messageLabel];
        }

        UIView *textContainer = [[UIView alloc] initWithFrame:CGRectZero];
        textContainer.backgroundColor = [UIColor lightGrayColor];
        textContainer.clipsToBounds = YES;
        textContainer.layer.cornerRadius = 5;
        textContainer.layer.borderWidth = [UIScreen screenPixel];
        textContainer.layer.borderColor = [[SCUColors shared] color04].CGColor;
        [contentView addSubview:textContainer];

        if (textEntryType & SCUTextEntryAlertFieldTypeDefault)
        {
            self.defaultTextField = [[UITextField alloc] initWithFrame:CGRectZero];
            [self setInitialPropertiesForTextField:self.defaultTextField];
            [textContainer addSubview:self.defaultTextField];
        }

        if (textEntryType & SCUTextEntryAlertFieldTypeSecure)
        {
            self.secureTextField = [[UITextField alloc] initWithFrame:CGRectZero];
            self.secureTextField.secureTextEntry = YES;
            [self setInitialPropertiesForTextField:self.secureTextField];
            [textContainer addSubview:self.secureTextField];
        }

        if (textEntryType == SCUTextEntryAlertFieldTypeBoth)
        {
            self.separator = [[UIView alloc] initWithFrame:CGRectZero];
            self.separator.backgroundColor = [[SCUColors shared] color04];
            [textContainer addSubview:self.separator];
        }

        NSDictionary *textFieldMetrics = @{@"height": @35,
                                           @"inset": @4,
                                           @"separatorHeight": @([UIScreen screenPixel])};

        if (textEntryType == SCUTextEntryAlertFieldTypeDefault)
        {
            [textContainer addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                                 metrics:textFieldMetrics
                                                                                   views:@{@"view": self.defaultTextField}
                                                                                 formats:@[@"|-inset-[view]-inset-|",
                                                                                           @"V:|[view(height)]|"]]];
        }
        else if (textEntryType == SCUTextEntryAlertFieldTypeSecure)
        {
            [textContainer addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                                 metrics:textFieldMetrics
                                                                                   views:@{@"view": self.secureTextField}
                                                                                 formats:@[@"|-inset-[view]-inset-|",
                                                                                           @"V:|[view(height)]|"]]];
        }
        else if (textEntryType == SCUTextEntryAlertFieldTypeBoth)
        {
            NSDictionary *views = @{@"default": self.defaultTextField,
                                    @"separator": self.separator,
                                    @"secure": self.secureTextField};

            [textContainer addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                                 metrics:textFieldMetrics
                                                                                   views:views
                                                                                 formats:@[@"|-inset-[default]-inset-|",
                                                                                           @"|[separator]|",
                                                                                           @"|-inset-[secure]-inset-|",
                                                                                           @"V:|[default(height)][separator(separatorHeight)][secure(height)]|"]]];
        }

        [contentView addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                           metrics:nil
                                                                             views:@{@"message": self.messageLabel, @"text": textContainer}
                                                                           formats:@[@"|[message]|",
                                                                                     @"|[text]|",
                                                                                     @"V:|[message]-[text]|"]]];
    }

    return self;
}

#pragma mark - Overrides

- (void)show
{
    [super show];

    if (self.defaultTextField)
    {
        [self.defaultTextField becomeFirstResponder];
    }
    else if (self.secureTextField)
    {
        [self.secureTextField becomeFirstResponder];
    }
}

- (NSString *)textForFieldWithType:(SCUTextEntryAlertFieldType)fieldType
{
    NSString *text = nil;

    if (fieldType & SCUTextEntryAlertFieldTypeDefault)
    {
        text = self.defaultTextField.text;
    }
    else if (fieldType & SCUTextEntryAlertFieldTypeSecure)
    {
        text = self.secureTextField.text;
    }

    return text;
}

- (NSString *)text
{
    NSString *text = nil;

    if (self.defaultTextField && self.secureTextField)
    {
        abort();
    }
    else
    {
        text = [self textForFieldWithType:SCUTextEntryAlertFieldTypeBoth];
    }

    return text;
}

#pragma mark -

- (void)positionInView:(UIView *)containingView
{
    CGFloat space = -40;

    if ([UIDevice isPad])
    {
        space = -60;
    }

    [containingView sav_pinView:self withOptions:SAVViewPinningOptionsCenterX];
    [containingView sav_pinView:self withOptions:SAVViewPinningOptionsCenterY withSpace:space];
}

#pragma mark -

- (void)setInitialPropertiesForTextField:(UITextField *)textField
{
    textField.backgroundColor = [UIColor lightGrayColor];
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.textColor = [[SCUColors shared] color04];
}

@end
