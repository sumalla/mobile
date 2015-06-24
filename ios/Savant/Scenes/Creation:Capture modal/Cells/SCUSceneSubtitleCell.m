//
//  SCUSceneSubtitleCell.m
//  SavantController
//
//  Created by Nathan Trapp on 8/19/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneSubtitleCell.h"

@implementation SCUSceneSubtitleCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        self.detailTextLabel.minimumScaleFactor = .5;
        self.detailTextLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h10];
        self.detailTextLabel.textColor = [[SCUColors shared] color03shade07];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.detailTextLabel.text.length)
    {
        CGRect textFrame   = self.textLabel.frame;
        CGRect detailFrame = self.detailTextLabel.frame;
        
        textFrame.origin.y -= 4;
        detailFrame.origin.y += 4;
        
        self.textLabel.frame = textFrame;
        self.detailTextLabel.frame = detailFrame;
    }
}

@end
