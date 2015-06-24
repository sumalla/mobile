//
//  SCUFavoritesEditableCollectionViewCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 9/19/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUFavoritesEditableCollectionViewCell.h"
#import "SCUStandardCollectionViewCellPrivate.h"
@import SDK;

@implementation SCUFavoritesEditableCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.noGradientView = YES;

        self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.backgroundImageView removeFromSuperview];

        [self.contentView addSubview:self.backgroundImageView];
        [self.contentView sav_addFlushConstraintsForView:self.backgroundImageView withPadding:35.0f];

        [self.contentView sendSubviewToBack:self.backgroundImageView];
    }
    
    return self;
}

@end
