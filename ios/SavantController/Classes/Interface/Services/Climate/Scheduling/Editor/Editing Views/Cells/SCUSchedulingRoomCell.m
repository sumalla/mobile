//
//  SCUSchedulingRoomCell.m
//  SavantController
//
//  Created by Nathan Trapp on 7/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSchedulingRoomCell.h"

@interface SCUSchedulingRoomCell ()

@end

@implementation SCUSchedulingRoomCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.imageButtonEnabled = NO;
    }
    
    return self;
}

@end
