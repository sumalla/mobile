//
//  SCUSceneLightingExcludedTableViewCell.m
//  SavantController
//
//  Created by Stephen Silber on 10/2/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneLightingExcludedTableViewCell.h"

@implementation SCUSceneLightingExcludedTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.backgroundColor = [[SCUColors shared] color03shade02];
        self.textLabel.textColor = [[SCUColors shared] color03shade07];
        self.detailTextLabel.textColor = [[SCUColors shared] color03shade07];
        
        self.detailTextLabel.text = NSLocalizedString(@"Excluded", nil);
    }
    
    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    if (info[SCUDefaultTableViewCellKeyDetailTitle])
    {
        self.detailTextLabel.text = info[SCUDefaultTableViewCellKeyDetailTitle];
    }
    
    if (info[SCUDefaultTableViewCellKeyTitle])
    {
        self.textLabel.text = info[SCUDefaultTableViewCellKeyTitle];
    }
}

@end
