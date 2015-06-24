        //
//  SCUErrorTextField.m
//  SavantController
//
//  Created by Cameron Pulsford on 8/18/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUErrorTextField.h"
@import Extensions;

@interface SCUErrorTextField ()

@property (nonatomic, getter = isInErrorState) BOOL inErrorState;
@property (nonatomic) UIView *errorView;
@property (nonatomic) UILabel *errorLabel;
@property (nonatomic) NSString *previousText;
@property (nonatomic) NSAttributedString *previousAttribuedPlaceholder;

@end

@implementation SCUErrorTextField

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        self.errorView = [UIView sav_viewWithColor:[[SCUColors shared] color01]];
        self.errorView.userInteractionEnabled = NO;
        [self addSubview:self.errorView];
        self.errorView.hidden = YES;

        self.errorLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.errorLabel.userInteractionEnabled = NO;
        self.errorLabel.textColor = [[SCUColors shared] color04];
        self.errorLabel.adjustsFontSizeToFitWidth = YES;
        self.errorLabel.minimumScaleFactor = .7;
        [self.errorView addSubview:self.errorLabel];
    }

    return self;
}

- (void)setErrorMessage:(NSString *)errorMessage
{
    _errorMessage = errorMessage;

    if (errorMessage)
    {
        self.previousText = self.text;
        self.previousAttribuedPlaceholder = self.attributedPlaceholder;
        self.text = nil;
        self.attributedPlaceholder = nil;
        self.errorLabel.text = errorMessage;
        self.errorView.hidden = NO;
    }
}

- (void)restore
{
    self.errorMessage = nil;
    self.errorLabel.text = nil;
    self.errorView.hidden = YES;

    if (self.previousText)
    {
        self.text = self.previousText;
    }

    if (self.previousAttribuedPlaceholder)
    {
        self.attributedPlaceholder = self.previousAttribuedPlaceholder;
    }

    self.previousText = nil;
    self.previousAttribuedPlaceholder = nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.errorView.frame = self.bounds;
    CGRect errorLabel = self.bounds;
    errorLabel.origin.x += self.contentInsets.left;
    errorLabel.size.width -= self.contentInsets.right;
    self.errorLabel.frame = errorLabel;
}

@end
