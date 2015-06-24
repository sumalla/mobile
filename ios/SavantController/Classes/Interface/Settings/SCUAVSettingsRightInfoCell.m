//
//  SCUAVSettingsRightInfoCell.m
//  SavantController
//
//  Created by Stephen Silber on 7/9/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVSettingsRightInfoCell.h"

@interface SCUAVSettingsRightInfoCell ()

@property (nonatomic) UILabel *rightLabel;

@end

NSString *const SCUAVSettingsRightInfoCellRightTitle = @"SCUAVSettingsRightInfoCellRightTitle";

@implementation SCUAVSettingsRightInfoCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];

    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];
    
    self.textLabel.text = info[SCUDefaultTableViewCellKeyTitle];
    self.detailTextLabel.text = info[SCUAVSettingsRightInfoCellRightTitle];
}

@end
