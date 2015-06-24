//
//  SCUAddTrashcanCollectionViewCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 9/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAddTrashcanCollectionViewCell.h"

NSString *const SCUAddTrashcanCollectionViewCellShowsAdd = @"SCUAddTrashcanCollectionViewCellShowsAdd";
NSString *const SCUAddTrashcanCollectionViewCellIsEnabledKey = @"SCUAddTrashcanCollectionViewCellIsEnabledKey";

@interface SCUAddTrashcanCollectionViewCell ()

@property (nonatomic) UIView *disabledMask;

@end

@implementation SCUAddTrashcanCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        self.backgroundImageView.contentMode = UIViewContentModeCenter;
    }

    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];

    if ([info[SCUAddTrashcanCollectionViewCellShowsAdd] boolValue])
    {
        self.backgroundImageView.image = [UIImage sav_imageNamed:@"VolumePlus" tintColor:[[SCUColors shared] color04]];
    }
    else
    {
        self.backgroundImageView.image = [UIImage sav_imageNamed:@"trash" tintColor:[[SCUColors shared] color04]];
    }

    if ([info[SCUAddTrashcanCollectionViewCellIsEnabledKey] boolValue])
    {
        self.userInteractionEnabled = YES;

        if (self.disabledMask)
        {
            [self.disabledMask removeFromSuperview];
            self.disabledMask = nil;
        }
    }
    else
    {
        self.userInteractionEnabled = NO;

        if (!self.disabledMask)
        {
            self.disabledMask = [UIView sav_viewWithColor:[[[SCUColors shared] color03] colorWithAlphaComponent:.5]];
            [self.contentView addSubview:self.disabledMask];
            [self.contentView sav_addFlushConstraintsForView:self.disabledMask];
            [self.contentView bringSubviewToFront:self.disabledMask];
        }
    }
}

@end
