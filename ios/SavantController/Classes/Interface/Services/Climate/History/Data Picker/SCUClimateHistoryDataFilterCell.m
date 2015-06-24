//
//  SCUClimateHistoryDataFilterCell.m
//  SavantController
//
//  Created by Nathan Trapp on 7/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUClimateHistoryDataFilterCell.h"

NSString *const SCUClimateHistoryDataFilterCellKeyState = @"SCUClimateHistoryDataFilterCellKeyState";
NSString *const SCUClimateHistoryDataFilterCellKeyStyle = @"SCUClimateHistoryDataFilterCellKeyStyle";

@interface SCUClimateHistoryDataFilterCell ()

@property UIView *lineStyle;
@property UILabel *label;
@property UISwitch *toggleSwitch;

@end

@implementation SCUClimateHistoryDataFilterCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.lineStyle = [[UIView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:self.lineStyle];

        self.label = [[UILabel alloc] initWithFrame:CGRectZero];
        self.label.textColor = [[SCUColors shared] color04];
        self.label.font = [UIFont fontWithName:@"Gotham" size:18];
        [self.contentView addSubview:self.label];

        self.toggleSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        self.accessoryView = self.toggleSwitch;

        [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:nil
                                                                                 views:@{@"label": self.label,
                                                                                         @"style": self.lineStyle}
                                                                                formats:@[@"|-[style(25)]-[label(>=0)]|",
                                                                                          @"V:|[label]|",
                                                                                          @"V:|[style]|"]]];
    }
    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    self.label.text = info[SCUDefaultTableViewCellKeyTitle];
    [self.lineStyle.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    UIView *style = info[SCUClimateHistoryDataFilterCellKeyStyle];
    [self.lineStyle addSubview:style];
    [self.lineStyle sav_addCenteredConstraintsForView:style];
    [self.lineStyle sav_setWidth:CGRectGetWidth(style.frame) forView:style isRelative:NO];
    [self.lineStyle sav_setHeight:CGRectGetHeight(style.frame) forView:style isRelative:NO];

    self.toggleSwitch.on = [info[SCUClimateHistoryDataFilterCellKeyState] boolValue];
}

@end
