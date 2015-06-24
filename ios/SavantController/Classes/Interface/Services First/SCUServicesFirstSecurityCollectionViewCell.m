//
//  SCUServicesFirstClimateCollectionViewCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 9/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServicesFirstSecurityCollectionViewCell.h"
#import "SCUAnimatedLabel.h"

NSString *const SCUServicesFirstSecurityCollectionViewCellArmedKey = @"SCUServicesFirstSecurityCollectionViewCellArmedKey";
NSString *const SCUServicesFirstSecurityCollectionViewCellCountKey = @"SCUServicesFirstSecurityCollectionViewCellCountKey";
NSString *const SCUServicesFirstSecurityCollectionViewCellErrorKey = @"SCUServicesFirstSecurityCollectionViewCellErrorKey";

@interface SCUServicesFirstSecurityCollectionViewCell ()

@property (nonatomic) UIView *container;
@property (nonatomic) UILabel *supplimentaryLabel;

@end

@implementation SCUServicesFirstSecurityCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        [self.subordinateLabel removeFromSuperview];
        [self.textLabel removeFromSuperview];
        [self.imageView removeFromSuperview];
        self.imageView.contentMode = UIViewContentModeLeft;

        self.supplimentaryLabel = [[UILabel alloc] init];

        self.container = [UIView sav_viewWithColor:[UIColor clearColor]];
        [self.contentView addSubview:self.container];
        [self.contentView addSubview:self.textLabel];
        [self.contentView addSubview:self.subordinateLabel];

        self.textLabel.numberOfLines = 2;
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;

        [UIDevice isPad] ? [self applyPadLayout] : [self applyPhoneLayout];

        self.contentView.clipsToBounds = YES;
    }

    return self;
}

- (void)applyPadLayout
{
    self.supplimentaryLabel.font = [UIFont fontWithName:@"Gotham-Light" size:[[SCUDimens dimens] regular].h1];
    self.subordinateLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h9];
    self.textLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h7];

    [self.contentView sav_setY:.27 forView:self.container isRelative:YES];
    [self.contentView sav_pinView:self.container withOptions:SAVViewPinningOptionsCenterX];
    [self.contentView sav_setHeight:100 forView:self.container isRelative:NO];

    [self.contentView sav_pinView:self.textLabel
                      withOptions:SAVViewPinningOptionsToBottom
                           ofView:self.container
                        withSpace:15];

    [self.contentView sav_pinView:self.textLabel
                      withOptions:SAVViewPinningOptionsHorizontally
                        withSpace:SAVViewAutoLayoutStandardSpace];

    [self.contentView sav_pinView:self.subordinateLabel
                      withOptions:SAVViewPinningOptionsToBottom
                           ofView:self.textLabel
                        withSpace:8];

    [self.contentView sav_pinView:self.subordinateLabel
                      withOptions:SAVViewPinningOptionsHorizontally
                        withSpace:SAVViewAutoLayoutStandardSpace];
}

- (void)applyPhoneLayout
{
    self.supplimentaryLabel.font = [UIFont fontWithName:@"Gotham-Light" size:[[SCUDimens dimens] regular].h6];
    self.subordinateLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h11];

    CGFloat yPercentage = .21;

    if ([UIDevice isPhablet])
    {
        yPercentage = .27;
    }

    [self.contentView sav_setY:yPercentage forView:self.container isRelative:YES];
    [self.contentView sav_pinView:self.container withOptions:SAVViewPinningOptionsCenterX];
    [self.contentView sav_setHeight:48 forView:self.container isRelative:NO];

    [self.contentView sav_pinView:self.textLabel
                      withOptions:SAVViewPinningOptionsToBottom
                           ofView:self.container
                        withSpace:13];

    [self.contentView sav_pinView:self.textLabel
                      withOptions:SAVViewPinningOptionsHorizontally
                        withSpace:SAVViewAutoLayoutStandardSpace];

    [self.contentView sav_pinView:self.subordinateLabel
                      withOptions:SAVViewPinningOptionsToBottom
                           ofView:self.textLabel
                        withSpace:4];

    [self.contentView sav_pinView:self.subordinateLabel
                      withOptions:SAVViewPinningOptionsHorizontally
                        withSpace:SAVViewAutoLayoutStandardSpace];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.subordinateLabel.text = nil;
    self.supplimentaryLabel.text = nil;
    self.textLabel.text = nil;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];

    NSString *supplimentaryText = info[SCUServicesFirstCollectionViewCellSupplimentaryTextKey];
    UIColor *supplimentaryTextColor = info[SCUServicesFirstCollectionViewCellSupplimentaryTextColorKey];

    self.supplimentaryLabel.text = supplimentaryText;
    self.supplimentaryLabel.textColor = supplimentaryTextColor;

    [self.imageView removeFromSuperview];
    [self.supplimentaryLabel removeFromSuperview];

    if ([supplimentaryText integerValue])
    {
        [self.container addSubview:self.supplimentaryLabel];
        [self.container addSubview:self.imageView];
        [self.container addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:nil
                                                                                views:@{@"imageView": self.imageView,
                                                                                        @"label": self.supplimentaryLabel}
                                                                              formats:@[@"imageView.right = super.centerX + 10",
                                                                                        @"label.left = super.centerX + 10",
                                                                                        @"V:|[imageView]|",
                                                                                        @"V:|[label]|"]]];
    }
    else
    {
        [self.container addSubview:self.imageView];
        [self.container sav_addCenteredConstraintsForView:self.imageView];
    }
}

@end
