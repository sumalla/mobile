//
//  SCUNotificationToggleTableViewCell.m
//  SavantController
//
//  Created by Julian Locke on 1/15/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationToggleTableViewCell.h"
#import "SCUSwipeCellPrivate.h"
#import "SCUSignInViewModel.h"
#import <SavantExtensions/SavantExtensions.h>

NSString *const SCUNotificationToggleTableViewCellKeyValue   = @"SCUNotificationToggleTableViewCellKeyValue";
NSString *const SCUNotificationToggleTableViewCellKeyAnimate = @"SCUNotificationToggleTableViewCellKeyAnimate";

@interface SCUNotificationToggleTableViewCell ()

@property (nonatomic) UISwitch *toggleSwitch;

@end

@implementation SCUNotificationToggleTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.toggleSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:self.toggleSwitch];
        [self.contentView sav_pinView:self.toggleSwitch withOptions:SAVViewPinningOptionsToRight withSpace:[[SCUDimens dimens] regular].globalMargin1];
        [self.contentView sav_pinView:self.toggleSwitch withOptions:SAVViewPinningOptionsToTop withSpace:20];
        
        self.textLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h10];
        self.textLabel.textColor = [[SCUColors shared] color03shade07];
        [self.contentView sav_pinView:self.textLabel withOptions:SAVViewPinningOptionsToLeft withSpace:[[SCUDimens dimens] regular].globalMargin1];
        [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:nil views:@{@"switch": self.toggleSwitch, @"title": self.textLabel} formats:@[@"title.centerY = switch.centerY"]]];
        
        self.detailTextLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h9];
        self.detailTextLabel.textColor = [[SCUColors shared] color04];
        self.detailTextLabel.textAlignment = NSTextAlignmentLeft;
        self.detailTextLabel.numberOfLines = 0;
        self.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        [self.contentView sav_pinView:self.detailTextLabel withOptions:SAVViewPinningOptionsHorizontally withSpace:[[SCUDimens dimens] regular].globalMargin1];
        [self.contentView sav_pinView:self.detailTextLabel withOptions:SAVViewPinningOptionsToTop withSpace:125 / 2];
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
    
    BOOL value = [info[SCUNotificationToggleTableViewCellKeyValue] boolValue];
    BOOL animate = [info[SCUNotificationToggleTableViewCellKeyAnimate] boolValue];
    
    if (self.toggleSwitch.on != value)
    {
        [self.toggleSwitch setOn:value animated:animate];
    }
}

@end
