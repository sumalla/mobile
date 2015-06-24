//
//  SCUMoreActionsCell.m
//  SavantController
//
//  Created by Nathan Trapp on 6/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMoreActionsCell.h"
#import "SCUSwipeCellPrivate.h"

@interface SCUMoreActionsCell ()

@property (weak) UILabel *label;

@end

@implementation SCUMoreActionsCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
    {
        self.bottomLineType = SCUDefaultTableViewCellBottomLineTypeNone;
        self.textLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h10];
        self.backgroundColor = [UIColor clearColor];
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        self.selectedBackgroundView.backgroundColor = [UIColor sav_colorWithRGBValue:0x636363];
    }

    return self;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];

    self.textLabel.textColor = selected ? [[SCUColors shared] color04] : [UIColor sav_colorWithRGBValue:0x989898];
}

- (CGFloat)leftContentOffset
{
    return 14;
}

@end
