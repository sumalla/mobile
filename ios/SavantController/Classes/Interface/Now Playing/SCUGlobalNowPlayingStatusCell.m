//
//  SCUGlobalNowPlayingStatusCell.m
//  SavantController
//
//  Created by Nathan Trapp on 10/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUGlobalNowPlayingStatusCell.h"
#import "SCUButton.h"
#import "SCUMarqueeLabel.h"
#import "SCUInterface.h"
#import "SCUGlobalNowPlayingNowPlayingViewController.h"

#import <SavantControl/SavantControl.h>

NSString *const SCUGlobalNowPlayingStatusCellKeyServiceGroup = @"SCUGlobalNowPlayingCellKeyServiceGroup";
NSString *const SCUGlobalNowPlayingStatusCellKeyStatus = @"SCUGlobalNowPlayingCellKeyStatus";
NSString *const SCUGlobalNowPlayingDistributeCellKeyArtworkPresent  = @"SCUGlobalNowPlayingDistributeCellKeyArtworkPresent";

@interface SCUGlobalNowPlayingStatusCell ()

@property (weak) UIImageView *iconImage;
@property (weak) UIView *iconContainer;
@property (weak) UILabel *serviceLabel;
@property (weak) SCUMarqueeLabel *statusLabel;
@property (nonatomic) SCUButton2 *powerButton;
@property (weak) UIView *labelContainer;
@property NSArray *labelConstraints;

@end

@implementation SCUGlobalNowPlayingStatusCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        CGFloat padding = [UIDevice isPad] ? 22 : 15;

        UIView *iconContainer = [[UIImageView alloc] init];
        iconContainer.userInteractionEnabled = NO;
        iconContainer.layer.borderColor = [[[SCUColors shared] color04] colorWithAlphaComponent:0.15].CGColor;
        iconContainer.layer.borderWidth = [UIScreen screenPixel];
        [self.contentView addSubview:iconContainer];
        iconContainer.alpha = .9;
        self.iconContainer = iconContainer;

        UIImageView *iconImage = [[UIImageView alloc] init];
        iconImage.contentMode = UIViewContentModeScaleAspectFit;
        [iconContainer addSubview:iconImage];
        self.iconImage = iconImage;

        [iconContainer sav_addConstraintsForView:iconImage withEdgeInsets:UIEdgeInsetsMake(15, 15, 15, 15)];

        UIView *labelContainer = [[UIView alloc] init];
        labelContainer.userInteractionEnabled = NO;
        [self.contentView addSubview:labelContainer];
        self.labelContainer = labelContainer;

        UILabel *serviceLabel = [[UILabel alloc] init];
        serviceLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[UIDevice isPad] ? [[SCUDimens dimens] regular].h10: [[SCUDimens dimens] regular].h10];
        serviceLabel.textColor = [[[SCUColors shared] color04] colorWithAlphaComponent:.8];
        [labelContainer addSubview:serviceLabel];
        self.serviceLabel = serviceLabel;

        SCUMarqueeLabel *statusLabel = [[SCUMarqueeLabel alloc] initWithFrame:CGRectZero];
        statusLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[UIDevice isPad] ? [[SCUDimens dimens] regular].h9 : [[SCUDimens dimens] regular].h9];
        statusLabel.textColor = [[SCUColors shared] color04];
        statusLabel.fadeInset = [UIDevice isPad] ? 15 : 5;
        [labelContainer addSubview:statusLabel];
        self.statusLabel = statusLabel;

        SCUButton2 *powerButton = [[SCUButton2 alloc] initWithStyle:SCUButtonStyle3 image:[UIImage sav_imageNamed:@"Power" tintColor:[[SCUColors shared] color01]]];
        powerButton.tintImage = NO;
        powerButton.scaleImageToFont = YES;
        powerButton.titleLabel.font = [UIFont systemFontOfSize:20];
        [self.contentView addSubview:powerButton];
        self.powerButton = powerButton;

        [labelContainer sav_pinView:self.statusLabel withOptions:SAVViewPinningOptionsHorizontally];
        [labelContainer sav_pinView:self.serviceLabel withOptions:SAVViewPinningOptionsHorizontally];
        [labelContainer sav_pinView:self.statusLabel withOptions:SAVViewPinningOptionsToTop];
        [labelContainer sav_pinView:self.serviceLabel withOptions:SAVViewPinningOptionsToBottom ofView:self.statusLabel withSpace:5];

        [self.contentView sav_pinView:powerButton withOptions:SAVViewPinningOptionsToRight|SAVViewPinningOptionsVertically];

        [self.contentView sav_setHeight:.7 forView:self.iconContainer isRelative:YES];
        [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:nil views:@{@"iconContainer": iconContainer} formats:@[@"iconContainer.width = iconContainer.height",
                                                                                                                                               @"iconContainer.centerY = super.centerY"]]];
        [self.contentView sav_pinView:self.iconContainer withOptions:SAVViewPinningOptionsToLeft withSpace:padding];

        [self.contentView sav_pinView:labelContainer withOptions:SAVViewPinningOptionsToLeft ofView:powerButton withSpace:4];
        [self.contentView sav_pinView:labelContainer withOptions:SAVViewPinningOptionsCenterY];
        [self.contentView sav_pinView:labelContainer withOptions:SAVViewPinningOptionsToRight ofView:self.iconContainer withSpace:padding];
    }
    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    SAVServiceGroup *serviceGroup = info[SCUGlobalNowPlayingStatusCellKeyServiceGroup];

    self.iconContainer.backgroundColor = [[[SCUInterface sharedInstance] colorForServiceId:serviceGroup.serviceId] colorWithAlphaComponent:0.9];

    NSString *statusText = nil;

    if (self.labelConstraints)
    {
        [self.labelContainer removeConstraints:self.labelConstraints];
        self.labelConstraints = nil;
    }
    
    if ([info[SCUGlobalNowPlayingDistributeCellKeyArtworkPresent] boolValue])
    {
        self.backgroundColor = [[[SCUColors shared] color03shade03] colorWithAlphaComponent:0.4];
    }
    else
    {
        self.backgroundColor = [[[SCUColors shared] color03shade03] colorWithAlphaComponent:0.9];
    }

    if ([info[SCUGlobalNowPlayingStatusCellKeyStatus] length])
    {
        self.labelConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[view(height)]"
                                                                        options:0
                                                                        metrics:@{@"height": @48}
                                                                          views:@{@"view": self.labelContainer}];
        statusText = info[SCUGlobalNowPlayingStatusCellKeyStatus];
        self.serviceLabel.text = [serviceGroup.alias uppercaseString];
    }
    else
    {
        self.labelConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[view(height)]"
                                                                        options:0
                                                                        metrics:@{@"height": @25}
                                                                          views:@{@"view": self.labelContainer}];

        statusText = serviceGroup.alias;
        self.serviceLabel.text = nil;
    }

    if (self.labelConstraints)
    {
        [self.labelContainer addConstraints:self.labelConstraints];
    }

    if (![self.statusLabel.text isEqualToString:statusText])
    {
        self.statusLabel.text = statusText;
    }

    self.iconImage.image = [UIImage sav_imageNamed:serviceGroup.iconName tintColor:[[SCUColors shared] color04]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    UIColor *backgroundColor = self.iconContainer.backgroundColor;
    [super setSelected:selected animated:animated];
    self.iconContainer.backgroundColor = backgroundColor;
}

- (void)setHighlighted:(BOOL)selected animated:(BOOL)animated
{
    UIColor *backgroundColor = self.iconContainer.backgroundColor;
    [super setHighlighted:selected animated:animated];
    self.iconContainer.backgroundColor = backgroundColor;
}

@end
