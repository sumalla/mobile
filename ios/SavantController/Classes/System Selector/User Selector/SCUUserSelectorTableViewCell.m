//
//  SCUUserSelectorTableViewCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUUserSelectorTableViewCell.h"
#import "SCUUserSelectorViewModel.h"
#import <SavantControl/SavantControl.h>

@implementation SCUUserSelectorTableViewCell

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];
    
    SAVLocalUser *user = info[SCUDefaultTableViewCellKeyModelObject];

    self.textLabel.text = user.accountName;

    if (user.requiresAuthentication)
    {
        self.accessoryType = SCUTableViewCellAccessoryLock;
    }
}

@end
