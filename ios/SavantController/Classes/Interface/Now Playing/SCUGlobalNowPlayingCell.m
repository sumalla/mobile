//
//  SCUGlobalNowPlayingCell.m
//  SavantController
//
//  Created by Nathan Trapp on 8/27/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUGlobalNowPlayingCell.h"
#import "SCUButton.h"
#import "SCUButtonContentView.h"
#import "SCUVolumeViewController.h"
#import "SCUMarqueeLabel.h"
#import "SCUInterface.h"
#import "SCUGlobalNowPlayingNowPlayingViewController.h"

#import <SavantControl/SavantControl.h>

NSString *const SCUGlobalNowPlayingCellKeyRooms = @"SCUGlobalNowPlayingCellKeyRooms";
NSString *const SCUGlobalNowPlayingCellKeyServiceGroup = @"SCUGlobalNowPlayingCellKeyServiceGroup";
NSString *const SCUGlobalNowPlayingCellKeyStatus = @"SCUGlobalNowPlayingCellKeyStatus";
NSString *const SCUGlobalNowPlayingCellKeyArtwork = @"SCUGlobalNowPlayingCellKeyArtwork";

@interface SCUGlobalNowPlayingCell ()

@property (weak) UIImageView *backgroundImage;
@property (weak) UIImageView *iconImage;
@property (weak) UIView *iconContainer;
@property (weak) UILabel *serviceLabel;
@property (weak) SCUMarqueeLabel *statusLabel;
@property (readonly, nonatomic) UILabel *roomsLabel;
@property (nonatomic) SCUButton *serviceButton;
@property SCUVolumeViewController *volumeVC;
@property UILabel *largeRoomsLabel;
@property UILabel *smallRoomsLabel;
@property SCUButtonContentView *largeRoomsButtonContent;
@property (weak) UIView *midDivider;
@property SCUGlobalNowPlayingNowPlayingViewController *nowPlayingVC;
@property UIView *transportRow;
@property (nonatomic) SCUButton *powerButton;
@property SCUButton *roomsButton;
@property SAVServiceGroup *currentServiceGroup;
@property (weak) UIView *labelContainer;
@property NSArray *labelConstraints;

@end

@implementation SCUGlobalNowPlayingCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        CGFloat padding = [UIDevice isPad] ? 22 : 11;

        self.clipsToBounds = YES;
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        UIImageView *backgroundImage = [[UIImageView alloc] init];
        backgroundImage.alpha = .2;
        backgroundImage.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:backgroundImage];
        self.backgroundImage = backgroundImage;

        SCUButton *serviceButton = [[SCUButton alloc] init];
        serviceButton.backgroundColor = nil;
        serviceButton.selectedBackgroundColor = [[[SCUColors shared] color03shade04] colorWithAlphaComponent:.9];
        [self.contentView addSubview:serviceButton];
        self.serviceButton = serviceButton;

        UIView *iconContainer = [[UIImageView alloc] init];
        iconContainer.userInteractionEnabled = NO;
        iconContainer.layer.borderColor = [[[SCUColors shared] color04] colorWithAlphaComponent:0.15].CGColor;
        iconContainer.layer.borderWidth = [UIScreen screenPixel];
        [self.contentView addSubview:iconContainer];
        self.iconContainer = iconContainer;

        UIImageView *iconImage = [[UIImageView alloc] init];
        iconImage.contentMode = UIViewContentModeScaleAspectFit;
        [iconContainer addSubview:iconImage];
        self.iconImage = iconImage;

        [iconContainer sav_addConstraintsForView:iconImage withEdgeInsets:UIEdgeInsetsMake(15, 15, 15, 15)];

        SCUButtonContentView *roomsView = [[SCUButtonContentView alloc] init];
        roomsView.ignoreImageColor = YES;

        UILabel *roomsLabel = [[UILabel alloc] init];
        roomsLabel.textColor = [[SCUColors shared] color04];
        [roomsView addSubview:roomsLabel];
        self.largeRoomsLabel = roomsLabel;

        UIImageView *roomsImage = [[UIImageView alloc] initWithImage:[UIImage sav_imageNamed:@"distribute" tintColor:[[SCUColors shared] color01]]];
        roomsImage.contentMode = UIViewContentModeScaleAspectFit;
        [roomsView addSubview:roomsImage];

        UIImageView *roomsDisclosure = [[UIImageView alloc] initWithImage:[UIImage sav_imageNamed:@"TableDisclosureIndicator" tintColor:[[SCUColors shared] color03shade07]]];
        roomsDisclosure.contentMode = UIViewContentModeScaleAspectFit;
        [roomsView addSubview:roomsDisclosure];

        [roomsView sav_pinView:roomsImage withOptions:SAVViewPinningOptionsVertically withSpace:10];
        [roomsView sav_pinView:roomsImage withOptions:SAVViewPinningOptionsToLeft withSpace:15];
        [roomsView sav_setWidth:34 forView:roomsImage isRelative:NO];
        [roomsView sav_pinView:roomsLabel withOptions:SAVViewPinningOptionsVertically];
        [roomsView sav_pinView:roomsLabel withOptions:SAVViewPinningOptionsToRight ofView:roomsImage withSpace:8];
        [roomsView sav_pinView:roomsLabel withOptions:SAVViewPinningOptionsToLeft ofView:roomsDisclosure withSpace:15];
        [roomsView sav_pinView:roomsDisclosure withOptions:SAVViewPinningOptionsVertically withSpace:10];
        [roomsView sav_pinView:roomsDisclosure withOptions:SAVViewPinningOptionsToRight withSpace:2];
        [roomsView sav_setWidth:34 forView:roomsDisclosure isRelative:NO];

        self.roomsButton = [[SCUButton alloc] init];

        self.largeRoomsButtonContent = roomsView;

        SCUVolumeViewController *volumeViewController = [[SCUVolumeViewController alloc] init];
        volumeViewController.fullWidth = YES;
        volumeViewController.globalVolume = YES;
        [volumeViewController viewWillAppear:NO];
        [self.contentView addSubview:volumeViewController.view];
        volumeViewController.view.backgroundColor = [[[SCUColors shared] color03shade03] colorWithAlphaComponent:.9];
        self.volumeVC = volumeViewController;

        UIView *labelContainer = [[UIView alloc] init];
        labelContainer.userInteractionEnabled = NO;
        [self.contentView addSubview:labelContainer];
        self.labelContainer = labelContainer;

        UILabel *serviceLabel = [[UILabel alloc] init];
        serviceLabel.font = [UIFont fontWithName:@"Gotham-Light" size:[UIDevice isPad] ? 14 : 12];
        serviceLabel.textColor = [[[SCUColors shared] color03shade07] colorWithAlphaComponent:.8];
        [labelContainer addSubview:serviceLabel];
        self.serviceLabel = serviceLabel;

        SCUMarqueeLabel *statusLabel = [[SCUMarqueeLabel alloc] initWithFrame:CGRectZero];
        statusLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[UIDevice isPad] ? 22 : 17];
        statusLabel.textColor = [[SCUColors shared] color04];
        statusLabel.fadeInset = [UIDevice isPad] ? 15 : 5;
        [labelContainer addSubview:statusLabel];
        self.statusLabel = statusLabel;

        SCUButton *powerButton = [[SCUButton alloc] initWithImage:[UIImage imageNamed:@"Power"]];
        powerButton.backgroundColor = nil;
        powerButton.selectedBackgroundColor = nil;
        powerButton.titleLabel.font = [UIFont systemFontOfSize:20];
        powerButton.scaleImage = YES;
        [self.contentView addSubview:powerButton];
        self.powerButton = powerButton;

        UIView *topDivider = [[UIView alloc] init];
        topDivider.backgroundColor = [[[SCUColors shared] color03shade04] colorWithAlphaComponent:.9];
        [self.contentView addSubview:topDivider];

        UIView *midDivider = [[UIView alloc] init];
        midDivider.backgroundColor = [[[SCUColors shared] color03shade04] colorWithAlphaComponent:.9];
        [self.contentView addSubview:midDivider];
        self.midDivider = midDivider;

        [labelContainer sav_pinView:self.statusLabel withOptions:SAVViewPinningOptionsHorizontally];
        [labelContainer sav_pinView:self.serviceLabel withOptions:SAVViewPinningOptionsHorizontally];
        [labelContainer sav_pinView:self.statusLabel withOptions:SAVViewPinningOptionsToTop];
        [labelContainer sav_pinView:self.serviceLabel withOptions:SAVViewPinningOptionsToBottom ofView:self.statusLabel withSpace:5];

        [self.contentView sav_pinView:powerButton withOptions:SAVViewPinningOptionsToRight withSpace:4];
        [self.contentView sav_pinView:powerButton withOptions:SAVViewPinningOptionsToTop withSpace:[UIDevice isPad] ? 63 : 33];

        [self.contentView sav_addFlushConstraintsForView:self.backgroundImage];

        [self.contentView sav_pinView:self.volumeVC.view withOptions:SAVViewPinningOptionsHorizontally];
        [self.contentView sav_pinView:self.volumeVC.view withOptions:SAVViewPinningOptionsToBottom ofView:self.serviceButton withSpace:0];
        [self.contentView sav_setHeight:44 forView:self.volumeVC.view isRelative:NO];

        [self.contentView sav_setSize:[UIDevice isPad] ? CGSizeMake(108, 108) : CGSizeMake(72, 72) forView:self.iconContainer isRelative:NO];
        [self.contentView sav_pinView:self.iconContainer withOptions:SAVViewPinningOptionsToTop|SAVViewPinningOptionsToLeft withSpace:padding];

        [self.contentView sav_pinView:labelContainer withOptions:SAVViewPinningOptionsToLeft ofView:powerButton withSpace:4];
        [self.contentView sav_pinView:labelContainer withOptions:SAVViewPinningOptionsToRight|SAVViewPinningOptionsCenterY ofView:self.iconContainer withSpace:padding];

        [self.contentView sav_pinView:midDivider withOptions:SAVViewPinningOptionsToBottom|SAVViewPinningOptionsCenterX ofView:self.volumeVC.view withSpace:0];
        [self.contentView sav_setHeight:1 forView:midDivider isRelative:NO];
        [self.contentView sav_pinView:midDivider withOptions:SAVViewPinningOptionsToLeft|SAVViewPinningOptionsToRight withSpace:15];

        [self.contentView sav_pinView:topDivider withOptions:SAVViewPinningOptionsToBottom ofView:self.serviceButton withSpace:0];
        [self.contentView sav_pinView:topDivider withOptions:SAVViewPinningOptionsHorizontally];
        [self.contentView sav_setHeight:1 forView:topDivider isRelative:NO];

        [self.contentView sav_pinView:self.serviceButton withOptions:SAVViewPinningOptionsHorizontally|SAVViewPinningOptionsToTop];
        [self.contentView sav_pinView:self.serviceButton withOptions:SAVViewPinningOptionsToBottom withSpace:88];
    }
    return self;
}

- (UIView *)transportRowForServiceGroup:(SAVServiceGroup *)serviceGroup
{
    UIView *transportRow = nil;

    if (self.transportRow)
    {
        if ([self.currentServiceGroup isEqualToServiceGroup:serviceGroup])
        {
            transportRow = self.transportRow;
        }
        else
        {
            [self.transportRow removeFromSuperview];
            self.transportRow = transportRow;
        }
    }

    if (!transportRow)
    {
        self.currentServiceGroup = serviceGroup;

        SCUGlobalNowPlayingNowPlayingViewController *nowPlayingVC = nil;

        BOOL willAppear = NO;
        if (![self.nowPlayingVC.serviceGroup isEqualToServiceGroup:serviceGroup])
        {
            [self.nowPlayingVC viewWillDisappear:NO];
            self.nowPlayingVC = nil;

            nowPlayingVC = [[SCUGlobalNowPlayingNowPlayingViewController alloc] initWithServiceGroup:serviceGroup];

            willAppear = YES;
        }
        else
        {
            nowPlayingVC = self.nowPlayingVC;
        }


        if ([nowPlayingVC.transportButtons count])
        {
            transportRow = [[UIView alloc] init];
            transportRow.backgroundColor = [[[SCUColors shared] color03shade03] colorWithAlphaComponent:.9];

            SCUButtonContentView *roomsView = [[SCUButtonContentView alloc] init];
            roomsView.ignoreImageColor = YES;

            UILabel *roomsLabel = [[UILabel alloc] init];
            roomsLabel.textColor = [[SCUColors shared] color04];
            [roomsView addSubview:roomsLabel];
            self.smallRoomsLabel = roomsLabel;

            UIImageView *roomsImage = [[UIImageView alloc] initWithImage:[UIImage sav_imageNamed:@"distribute" tintColor:[[SCUColors shared] color01]]];
            roomsImage.contentMode = UIViewContentModeScaleAspectFit;
            [roomsView addSubview:roomsImage];

            [roomsView sav_pinView:roomsImage withOptions:SAVViewPinningOptionsVertically withSpace:10];
            [roomsView sav_pinView:roomsImage withOptions:SAVViewPinningOptionsToLeft withSpace:15];
            [roomsView sav_setWidth:34 forView:roomsImage isRelative:NO];
            [roomsView sav_pinView:roomsLabel withOptions:SAVViewPinningOptionsVertically];
            [roomsView sav_pinView:roomsLabel withOptions:SAVViewPinningOptionsToRight ofView:roomsImage withSpace:[UIDevice isPad] ? 8 : 2];
            [roomsView sav_pinView:roomsLabel withOptions:SAVViewPinningOptionsToRight withSpace:15];

            [transportRow addSubview:self.roomsButton];
            [transportRow addSubview:nowPlayingVC.view];

            [transportRow sav_pinView:nowPlayingVC.view withOptions:SAVViewPinningOptionsVertically];
            [transportRow sav_pinView:nowPlayingVC.view withOptions:SAVViewPinningOptionsToRight withSpace:15];
            [transportRow sav_setWidth:200 forView:nowPlayingVC.view isRelative:NO];

            [transportRow sav_pinView:self.roomsButton withOptions:SAVViewPinningOptionsVertically|SAVViewPinningOptionsToLeft];

            self.roomsButton.backgroundColor = nil;
            self.roomsButton.selectedBackgroundColor = nil;
            self.roomsButton.customView = roomsView;

            self.nowPlayingVC = nowPlayingVC;
        }
        else
        {
            self.roomsButton.backgroundColor = [[[SCUColors shared] color03shade03] colorWithAlphaComponent:.9];
            self.roomsButton.selectedBackgroundColor = [[[SCUColors shared] color03shade04] colorWithAlphaComponent:.9];
            self.roomsButton.customView = self.largeRoomsButtonContent;
            
            transportRow = self.roomsButton;
        }
        
        self.transportRow = transportRow;
        
        [self.contentView addSubview:transportRow];
        [self.contentView bringSubviewToFront:self.midDivider];
        if (willAppear)
        {
            [self.nowPlayingVC viewWillAppear:NO];
        }
    }

    return transportRow;
}

- (UILabel *)roomsLabel
{
    return self.roomsButton.customView == self.largeRoomsButtonContent ? self.largeRoomsLabel : self.smallRoomsLabel;
}

- (void)dealloc
{
    [self.volumeVC viewDidDisappear:NO];
}

- (void)configureWithInfo:(NSDictionary *)info
{
    SAVServiceGroup *serviceGroup = info[SCUGlobalNowPlayingCellKeyServiceGroup];
    
    self.iconContainer.backgroundColor = [[[SCUInterface sharedInstance] colorForServiceId:serviceGroup.serviceId] colorWithAlphaComponent:0.9];

    NSString *statusText = nil;

    if (self.labelConstraints)
    {
        [self.labelContainer removeConstraints:self.labelConstraints];
        self.labelConstraints = nil;
    }

    if ([info[SCUGlobalNowPlayingCellKeyStatus] length])
    {
        self.labelConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[view(height)]"
                                                                       options:0
                                                                       metrics:@{@"height": @48}
                                                                         views:@{@"view": self.labelContainer}];
        statusText = info[SCUGlobalNowPlayingCellKeyStatus];
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

    self.volumeVC.serviceGroup = serviceGroup;
    self.backgroundImage.image = info[SCUGlobalNowPlayingCellKeyArtwork];

    [self.volumeVC viewWillAppear:NO];

    UIView *transports = [self transportRowForServiceGroup:serviceGroup];
    [self.contentView sav_pinView:transports withOptions:SAVViewPinningOptionsHorizontally|SAVViewPinningOptionsToBottom|SAVViewPinningOptionsHorizontally];
    [self.contentView sav_setHeight:44 forView:transports isRelative:NO];

    NSString *roomsLabel = [info[SCUGlobalNowPlayingCellKeyRooms] count] > 1 ? [NSString stringWithFormat:@"%ld %@", (long)[info[SCUGlobalNowPlayingCellKeyRooms] count], NSLocalizedString(@"Rooms", nil)] : [info[SCUGlobalNowPlayingCellKeyRooms] firstObject];

    if ([UIDevice isPad] || !self.nowPlayingVC)
    {
        self.roomsLabel.text = roomsLabel;
    }
    else
    {
        self.roomsLabel.text = [NSString stringWithFormat:@"%ld", (long)[info[SCUGlobalNowPlayingCellKeyRooms] count]];
    }
}

@end
