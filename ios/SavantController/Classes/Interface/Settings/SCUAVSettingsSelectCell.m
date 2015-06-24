//
//  SCUAVSettingsSelectCell.m
//  SavantController
//
//  Created by Stephen Silber on 7/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVSettingsSelectCell.h"
#import <SavantExtensions/SavantExtensions.h>

@interface SCUAVSettingsSelectCell ()

@property (nonatomic) UILabel *valueLabel;

@end

NSString *const SCUAVSettingsCellLeftValueLabel = @"SCUAVSettingsCellLeftValueLabel";

@implementation SCUAVSettingsSelectCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
    {
//        UIColor *blueTint = [UIColor colorWithRed:0.0824 green:0.4902 blue:0.9608 alpha:1.0];
        
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        self.textLabel.text = @"Aspect Ratio";
        
        self.valueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.valueLabel.textColor = [UIColor colorWithRed:0.5451 green:0.5490 blue:0.5686 alpha:1.0];
        self.valueLabel.textAlignment = NSTextAlignmentRight;
        
        [self.contentView addSubview:self.valueLabel];

        NSDictionary *metrics = @{@"rightPadding": @40};
        NSDictionary *views = @{@"valueLabel"  : self.valueLabel};
        
        [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:NSLayoutFormatAlignAllLeft
                                                                                metrics:metrics
                                                                                views:views
                                                                                formats:@[@"[valueLabel]-rightPadding-|",
                                                                                          @"valueLabel.centerY = super.centerY"]]];
    }
    
    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];

    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.valueLabel.text = info[SCUAVSettingsCellLeftValueLabel];

}

@end
