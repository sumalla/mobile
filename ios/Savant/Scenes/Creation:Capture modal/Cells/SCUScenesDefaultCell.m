//
//  SCUScenesDefaultCell.m
//  SavantController
//
//  Created by Nathan Trapp on 7/29/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUScenesDefaultCell.h"

@implementation SCUScenesDefaultCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.layer.borderWidth = [UIScreen screenPixel];
        self.layer.borderColor = [[SCUColors shared] color03shade04].CGColor;
    }
    return self;
}

@end
