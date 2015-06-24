//
//  SCUSecuritySensorCell.m
//  SavantController
//
//  Created by Nathan Trapp on 5/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSecuritySensorCell.h"
#import "SCUButton.h"

#import <SAVSecurityEntity.h>

NSString *const SCUSecuritySensorCellKeyIsBypassed     = @"SCUSecuritySensorCellKeyIsBypassed";
NSString *const SCUSecuritySensorCellKeyHasBypass      = @"SCUSecuritySensorCellKeyHasBypass";
NSString *const SCUSecuritySensorCellKeyStatus         = @"SCUSecuritySensorCellKeyStatus";
NSString *const SCUSecuritySensorCellKeyDetailedStatus = @"SCUSecuritySensorCellKeyDetailedStatus";
NSString *const SCUSecuritySensorCellKeyIdentifier     = @"SCUSecuritySensorCellKeyIdentifier";

#define kUnknownColor  0x9e9e9e
#define kTroubleColor  0xf9d700
#define kCriticalColor 0xff4200
#define kReadyColor    0xafcc00

@interface SCUSecuritySensorCell ()

@property UIView *statusIndicator;
@property UILabel *detailedStatus;
@property UILabel *roomLabel;
@property SCUButton *bypassButton;
@property NSArray *bypassConstraints;
@property NSArray *noBypassConstraints;

@end

@implementation SCUSecuritySensorCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        self.statusIndicator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 23, 23)];
        self.statusIndicator.layer.cornerRadius = 12;
        self.statusIndicator.clipsToBounds = YES;
        [self.contentView addSubview:self.statusIndicator];

        self.detailedStatus = [[UILabel alloc] init];
        self.detailedStatus.font = [UIFont fontWithName:@"Gotham-Light" size:14];
        self.detailedStatus.textColor = [[[SCUColors shared] color04] colorWithAlphaComponent:.7];
        [self.contentView addSubview:self.detailedStatus];

        self.roomLabel = [[UILabel alloc] init];
        self.roomLabel.font = [UIFont fontWithName:@"Gotham-Light" size:14];
        self.roomLabel.textColor = [[SCUColors shared] color04];
        self.roomLabel.numberOfLines = 2;
        [self.contentView addSubview:self.roomLabel];

        self.bypassButton = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"Bypass", nil)];
        self.bypassButton.selectedBackgroundColor = [[SCUColors shared] color01];
        self.bypassButton.selectedColor = [[SCUColors shared] color03];
        self.bypassButton.titleLabel.font = [UIFont fontWithName:@"Gotham-Light" size:14];

        [self.contentView addSubview:self.bypassButton];

        NSDictionary *metrics = nil;

        if ([UIDevice isPad])
        {
            metrics = @{@"roomWidth": @300,
                        @"spacer": @15,
                        @"bypassWidth": @70};
        }
        else
        {
            metrics = @{@"roomWidth": @138,
                        @"spacer": @10,
                        @"bypassWidth": @70};
        }

        self.bypassConstraints = [NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                          views:@{@"bypass": self.bypassButton,
                                                                                  @"room": self.roomLabel,
                                                                                  @"status": self.statusIndicator,
                                                                                  @"detail": self.detailedStatus}
                                                                        formats:@[@"|-(spacer)-[status(23)]-(spacer)-[room(roomWidth)]-(spacer)-[detail]-(>=1)-[bypass(bypassWidth)]|",
                                                                                  @"V:|[bypass]|"]];

        self.noBypassConstraints = [NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                          views:@{@"room": self.roomLabel,
                                                                                  @"status": self.statusIndicator,
                                                                                  @"detail": self.detailedStatus}
                                                                        formats:@[@"|-(spacer)-[status(23)]-(spacer)-[room(roomWidth)]-(spacer)-[detail]-|"]];

        [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                                  views:@{@"room": self.roomLabel,
                                                                                          @"status": self.statusIndicator,
                                                                                          @"detail": self.detailedStatus}
                                                                                formats:@[@"V:|[detail]|",
                                                                                          @"V:|[room]|",
                                                                                          @"status.centerY = super.centerY",
                                                                                          @"status.height = 23"]]];
    }
    return self;
}

- (void)configureWithInfo:(id)info
{
    self.detailedStatus.text = info[SCUSecuritySensorCellKeyDetailedStatus];
    self.roomLabel.text = info[SCUDefaultTableViewCellKeyTitle];

    SAVSecurityEntityStatus status = [info[SCUSecuritySensorCellKeyStatus] integerValue];

    switch (status)
    {
        case SAVSecurityEntityStatus_Ready:
            self.statusIndicator.backgroundColor = [UIColor sav_colorWithRGBValue:kReadyColor];
            break;
        case SAVSecurityEntityStatus_Trouble:
            self.statusIndicator.backgroundColor = [UIColor sav_colorWithRGBValue:kTroubleColor];
            break;
        case SAVSecurityEntityStatus_Critical:
            self.statusIndicator.backgroundColor = [UIColor sav_colorWithRGBValue:kCriticalColor];
            break;
    }

    self.bypassButton.hidden = ![info[SCUSecuritySensorCellKeyHasBypass] boolValue];
    self.bypassButton.selected = [info[SCUSecuritySensorCellKeyIsBypassed] boolValue];

    [self.contentView removeConstraints:self.bypassConstraints];
    [self.contentView removeConstraints:self.noBypassConstraints];

    if (self.bypassButton.hidden)
    {
        [self.contentView addConstraints:self.noBypassConstraints];
    }
    else
    {
        [self.contentView addConstraints:self.bypassConstraints];
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.statusIndicator.backgroundColor = [UIColor sav_colorWithRGBValue:kUnknownColor];
    self.detailedStatus.text = nil;
    self.roomLabel.text = nil;
    self.textLabel.text = nil;
    self.bypassButton.hidden = YES;
}

@end
