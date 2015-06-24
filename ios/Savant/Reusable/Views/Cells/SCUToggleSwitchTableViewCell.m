//
//  SCUSignInSwitchTableViewCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUToggleSwitchTableViewCell.h"
#import "SCUSwipeCellPrivate.h"
@import Extensions;

NSString *const SCUToggleSwitchTableViewCellKeyValue   = @"SCUToggleSwitchTableViewCellKeyValue";
NSString *const SCUToggleSwitchTableViewCellKeyAnimate = @"SCUToggleSwitchTableViewCellKeyAnimate";
NSString *const SCUToggleSwitchTableViewCellKeyImage = @"SCUToggleSwitchTableViewCellKeyImage";

@interface SCUToggleSwitchTableViewCell ()

@property (nonatomic) UISwitch *toggleSwitch;
@property (nonatomic) UIImageView *toggleImageView;

@end

@implementation SCUToggleSwitchTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.toggleSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        self.accessoryView = self.toggleSwitch;

        self.toggleImageView = [[UIImageView alloc] init];
        self.toggleImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.toggleImageView.hidden = YES;
        [self.contentView addSubview:self.toggleImageView];

        [self.contentView sav_pinView:self.toggleImageView withOptions:SAVViewPinningOptionsToRight withSpace:25];
        [self.contentView sav_pinView:self.toggleImageView withOptions:SAVViewPinningOptionsVertically withSpace:5];
    }

    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.toggleSwitch.sav_didChangeHandler = nil;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];

    BOOL value = [info[SCUToggleSwitchTableViewCellKeyValue] boolValue];
    BOOL animate = [info[SCUToggleSwitchTableViewCellKeyAnimate] boolValue];

    if (self.toggleSwitch.on != value)
    {
        [self.toggleSwitch setOn:value animated:animate];
    }

    if (info[SCUToggleSwitchTableViewCellKeyImage])
    {
        self.toggleImageView.hidden = NO;
        self.toggleImageView.image = info[SCUToggleSwitchTableViewCellKeyImage];
    }
    else
    {
        self.toggleImageView.hidden = YES;
    }
}

@end
