//
//  SCUProgressBezel.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUProgressBezel.h"
#import "SCUAlertViewPrivate.h"

@interface SCUProgressBezel ()

@property (nonatomic) UILabel *stageLabel;
@property (nonatomic) UIView *progressContentView;
@property (nonatomic) SCUProgressBezelStyle progressStyle;
@property (nonatomic) UIActivityIndicatorView *spinner;
@property (nonatomic) UIProgressView *progressBar;
@property (nonatomic) UIImageView *completeCheckmark;

@end

@implementation SCUProgressBezel

- (instancetype)initWithTitle:(NSString *)title progressStyle:(SCUProgressBezelStyle)progressStyle cancelButtonTitle:(NSString *)cancelButtonTitle
{
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectZero];

    self = [super initWithTitle:title contentView:contentView buttonTitles:cancelButtonTitle ? @[cancelButtonTitle] : nil];

    if (self)
    {
        //-------------------------------------------------------------------
        // Setup stage label.
        //-------------------------------------------------------------------
        self.stageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.stageLabel.textAlignment = NSTextAlignmentCenter;
        self.stageLabel.textColor = [[SCUColors shared] color03];
        self.stageLabel.font = [UIFont systemFontOfSize:14];
        [contentView addSubview:self.stageLabel];

        //-------------------------------------------------------------------
        // Setup progress content view.
        //-------------------------------------------------------------------
        self.progressContentView = [[UIView alloc] initWithFrame:CGRectZero];
        [contentView addSubview:self.progressContentView];

        {
            NSDictionary *views = @{@"stage": self.stageLabel,
                                    @"content": self.progressContentView};

            [contentView addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                               metrics:nil
                                                                                 views:views
                                                                               formats:@[@"|[stage]|",
                                                                                         @"|[content]|",
                                                                                         @"V:|[stage]-[content]|"]]];
        }

        UIView *progressView = nil;

        //-------------------------------------------------------------------
        // Setup progress indicator.
        //-------------------------------------------------------------------
        if (progressStyle == SCUProgressBezelStyleIndeterminate)
        {
            self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            [self.spinner startAnimating];
            self.spinner.tintColor = [[SCUColors shared] color01];
            progressView = self.spinner;
        }
        else if (progressStyle == SCUProgressBezelStyleBar)
        {
            self.progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
            self.progressBar.progressTintColor = [[SCUColors shared] color01];
            self.progressBar.trackTintColor = [[SCUColors shared] color02];
            progressView = self.progressBar;
        }

        if (progressView)
        {
            [self.progressContentView addSubview:progressView];

            NSDictionary *views = @{@"view": progressView};

            [self.progressContentView addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                                            metrics:nil
                                                                                              views:views
                                                                                            formats:@[@"|[view]|",
                                                                                                      @"V:|[view]|"]]];
        }

        self.completeCheckmark = [[UIImageView alloc] initWithImage:[UIImage sav_imageNamed:@"TableCheckmark" tintColor:[[SCUColors shared] color01]]];
        self.completeCheckmark.hidden = YES;
        self.completeCheckmark.contentMode = UIViewContentModeCenter;
        self.completeCheckmark.clipsToBounds = YES;
        [self addSubview:self.completeCheckmark];
        [self sav_pinView:self.completeCheckmark withOptions:SAVViewPinningOptionsToBottom withSpace:12];
        [self sav_pinView:self.completeCheckmark withOptions:SAVViewPinningOptionsHorizontally];
        [self sav_setHeight:40 forView:self.completeCheckmark isRelative:NO];
    }

    return self;
}

- (void)completeWithMessage:(NSString *)message
{
    self.completeCheckmark.hidden = NO;
    self.stage = message;
    self.progressBar.hidden = YES;
    self.spinner.hidden = YES;
    [self setButtonViewHidden:YES];
}

#pragma mark -

- (CGFloat)contentPadding
{
    return 8;
}

- (void)setStage:(NSString *)stage
{
    _stage = stage;
    self.stageLabel.text = stage;
}

- (void)setProgress:(CGFloat)progress
{
    BOOL shrink = progress < _progress ? YES : NO;
    _progress = progress;

    if (shrink)
    {
        self.progressBar.progress = progress;
    }
    else
    {
        [self.progressBar setProgress:progress animated:YES];
    }
}

@end
