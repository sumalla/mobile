//
//  SCUAVSettingsButtonCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 5/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVSettingsButtonCell.h"

@interface SCUAVSettingsButtonCell ()

@property (nonatomic) UILabel *rightLabel;
@property (nonatomic) SCUButton *rightButton;

@end

NSString *const SCUAVSettingsCellValueLabel = @"SCUAVSettingsCellValueLabel";

@implementation SCUAVSettingsButtonCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.rightButton = [[SCUButton alloc] initWithFrame:CGRectZero];
        [self.rightButton setTitle:@"Default" forState:UIControlStateNormal];
        self.rightButton.titleLabel.textColor = [[SCUColors shared] color01];
        self.rightButton.selectedColor = [[SCUColors shared] color04];
        self.rightButton.color = [[SCUColors shared] color01];
        
        self.rightLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.rightLabel.text = @"None";
        self.rightLabel.textColor = [[SCUColors shared] color03shade07];
        
        [self.contentView addSubview:self.rightLabel];
        [self.contentView addSubview:self.rightButton];
        
        self.detailTextLabel.textColor = [[SCUColors shared] color03shade07];

        NSDictionary *metrics = @{@"rightPadding": @15,
                                  @"middlePadding": @20};
        NSDictionary *views = @{@"rightButton": self.rightButton,
                                @"rightLabel" : self.rightLabel};
        
        [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                              metrics:metrics
                                                                                views:views
                                                                              formats:@[@"[rightLabel]-middlePadding-[rightButton]-rightPadding-|",
                                                                                        @"rightLabel.centerY = super.centerY",
                                                                                        @"rightButton.centerY = super.centerY"
                                                                                        ]]];

    }
    
    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];
    if ([info[SCUAVSettingsCellValueLabel] length])
    {
        self.textLabel.text = [NSString stringWithFormat:@"Effect: %@", info[SCUAVSettingsCellValueLabel]];
    }
    else
    {
        // TODO: bad!
        self.textLabel.text = @"Effect: Default";
    }

    self.rightButton.titleLabel.text = @"Default";
    self.detailTextLabel.text = info[SCUAVSettingsCellValueLabel];
}

@end
