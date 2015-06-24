//
//  SCUDateCell.m
//  SavantController
//
//  Created by Nathan Trapp on 7/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDateCell.h"

NSString *const SCUDateCellKeyDate       = @"SCUClimateHistoryRangeCellKeyDate";
NSString *const SCUDateCellKeyDateFormat = @"SCUClimateHistoryRangeCellKeyDateFormat";

@implementation SCUDateCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.detailTextLabel.textColor = [[SCUColors shared] color03shade07];
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        self.selectedBackgroundView.backgroundColor = [[[SCUColors shared] color04] colorWithAlphaComponent:.2];

        UIView *topLine = [[UIView alloc] initWithFrame:CGRectZero];
        topLine.backgroundColor = [[[SCUColors shared] color03] colorWithAlphaComponent:.4];
        [self.selectedBackgroundView addSubview:topLine];

        UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectZero];
        bottomLine.backgroundColor = [[[SCUColors shared] color03] colorWithAlphaComponent:.4];
        [self.selectedBackgroundView addSubview:bottomLine];

        [self.selectedBackgroundView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:@{@"spacer": @10,
                                                                                                     @"width": @5}
                                                                                             views:@{@"topLine": topLine,
                                                                                                     @"bottomLine": bottomLine}
                                                                                           formats:@[@"|[topLine]|",
                                                                                                     @"|[bottomLine]|",
                                                                                                     @"V:|[topLine(0.5)]",
                                                                                                     @"V:[bottomLine(0.5)]|"]]];
    }
    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];

    if (info[SCUDateCellKeyDateFormat])
    {
        df.dateFormat = info[SCUDateCellKeyDateFormat];
    }
    else
    {
        df.dateStyle = NSDateFormatterLongStyle;
    }

    if (info[SCUDefaultTableViewCellKeyTitle])
    {
        [super configureWithInfo:info];

        self.detailTextLabel.text = [df stringFromDate:info[SCUDateCellKeyDate]];
    }
    else
    {
        self.textLabel.text = [df stringFromDate:info[SCUDateCellKeyDate]];
    }
}

@end
