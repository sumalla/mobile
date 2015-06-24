//
//  SCUToolbarButton.m
//  SavantController
//
//  Created by Nathan Trapp on 4/11/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUToolbarButton.h"
#import <SavantExtensions/SavantExtensions.h>

@implementation SCUToolbarButton

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.titleLabel.font = [UIFont fontWithName:@"Gotham-Light" size:17];
        self.backgroundColor = nil;
        self.selectedBackgroundColor = nil;
        self.selectedColor = [[SCUColors shared] color01];
        self.scaleImage = NO;
    }
    return self;
}

@end
