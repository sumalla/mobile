//
//  SCUHomeGridCell.m
//  SavantController
//
//  Created by Nathan Trapp on 4/29/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUHomeGridCell.h"
#import "SCUHomeCellPrivate.h"

#import <SavantExtensions/SavantExtensions.h>

@implementation SCUHomeGridCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.gradient.colors = @[[[[SCUColors shared] color03] colorWithAlphaComponent:.2], [[[SCUColors shared] color03] colorWithAlphaComponent:.2], [[[SCUColors shared] color03] colorWithAlphaComponent:.98]];
        self.gradient.locations = @[@(0), @(.65), @(1)];
        self.gradient.alpha = 0.80;
        
        self.textLabel.textColor = [[SCUColors shared] color04];
        self.textLabel.font = [UIFont fontWithName:@"Gotham-Light" size:[[SCUDimens dimens] regular].h7];

        self.temperatureButton.color = [[SCUColors shared] color04];
        self.temperatureButton.titleLabel.font = [UIFont fontWithName:@"Gotham-Light" size:[[SCUDimens dimens] regular].h7];

        self.textLabel.adjustsFontSizeToFitWidth = YES;
        self.textLabel.minimumScaleFactor = .75;

        self.temperatureButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.temperatureButton.titleLabel.minimumScaleFactor = .75;
    }
    return self;
}

@end
