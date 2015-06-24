//
//  SCUMainNavCell.m
//  SavantController
//
//  Created by Nathan Trapp on 6/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMainNavCell.h"

@implementation SCUMainNavCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        self.bottomLineType = SCUDefaultTableViewCellBottomLineTypeNone;
        self.textLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[UIDevice isShortPhone] ? 20 : 24];
        self.textLabel.textColor = [[SCUColors shared] color03shade07];
        self.textLabel.highlightedTextColor = [[SCUColors shared] color04];

        self.selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        self.selectedBackgroundView.backgroundColor = [UIColor clearColor];

        UIView *selectedIndicator = [[UIView alloc] initWithFrame:CGRectZero];
        selectedIndicator.backgroundColor = [[SCUColors shared] color01];
        [self.selectedBackgroundView addSubview:selectedIndicator];

        [self.selectedBackgroundView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:@{@"spacer": @16,
                                                                                                     @"width": @2}
                                                                                            views:@{@"indicator": selectedIndicator}
                                                                                           formats:@[@"|[indicator(width)]",
                                                                                                     @"V:|-(<=spacer)-[indicator]-(<=spacer)-|"]]];
    }
    return self;
}

@end
