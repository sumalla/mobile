//
//  SCUClimateScheduleSwitchCell.m
//  SavantController
//
//  Created by Nathan Trapp on 7/11/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUClimateScheduleSwitchCell.h"

#import <SavantControl/SAVClimateSchedule.h>

@implementation SCUClimateScheduleSwitchCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.detailTextLabel.textColor = [[SCUColors shared] color03shade07];
    }
    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];

    SAVClimateSchedule *schedule = info[SCUDefaultTableViewCellKeyModelObject];

    if (schedule)
    {
        self.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", [schedule shortDateString], [schedule dayString]];
    }
}

@end
