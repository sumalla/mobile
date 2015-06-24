//
//  SCUDefaultEditableCollectionViewCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 9/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultEditableCollectionViewCell.h"
#import "SCUStandardCollectionViewCellPrivate.h"
#import "SCUGradientView.h"

NSString *const SCUDefaultEditableCollectionViewCellIsInEditModeKey = @"SCUDefaultEditableCollectionViewCellIsInEditModeKey";
NSString *const SCUDefaultEditableCollectionViewCellIsMovingKey = @"SCUDefaultEditableCollectionViewCellIsMovingKey";

@interface SCUDefaultEditableCollectionViewCell ()

@property (nonatomic) SCUGradientView *editMask;
@property (nonatomic) UIView *movingMask;
@property (nonatomic) NSString *lastImageName;
@property (nonatomic) SAVViewPositioningConfiguration *fullPosition;

@end

@implementation SCUDefaultEditableCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        [self.textLabel removeFromSuperview];
        [self.imageView removeFromSuperview];

        [self.contentView addSubview:self.textLabel];
        [self.contentView sav_pinView:self.textLabel withOptions:SAVViewPinningOptionsHorizontally | SAVViewPinningOptionsCenterY];

        [self.contentView addSubview:self.imageView];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.clipsToBounds = YES;
        [self.contentView sav_addFlushConstraintsForView:self.imageView];

        self.movingMask = [UIView sav_viewWithColor:[[SCUColors shared] color03shade01]];
        self.movingMask.borderColor = [[SCUColors shared] color03shade05];
        self.movingMask.borderWidth = [UIScreen screenPixel] * 2;
        self.movingMask.hidden = YES;
        [self.contentView addSubview:self.movingMask];

        self.editMask = [[SCUGradientView alloc] initWithFrame:CGRectZero
                                                     andColors:@[[UIColor clearColor], [[SCUColors shared] color03]]];
        self.editMask.radial = YES;
        self.editMask.hidden = YES;
        self.editMask.startRadius = .1;
        self.editMask.endRadius = 1;
        [self.contentView addSubview:self.editMask];
        
        [self.contentView sav_addFlushConstraintsForView:self.editMask];
        [self.contentView sav_addFlushConstraintsForView:self.movingMask];

        self.fullPosition = [[SAVViewPositioningConfiguration alloc] init];
        self.fullPosition.position = CGRectMake(0, 0, 1, 1);
        self.fullPosition.relativePositions = SAVViewRelativePositionsHeight | SAVViewRelativePositionsWidth;
    }

    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.movingMask.hidden = YES;
    self.editMask.hidden = YES;
    self.textLabel.text = nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

//    [self.movingMask sav_setPositionWithConfiguration:self.fullPosition];
//    [self.editMask sav_setPositionWithConfiguration:self.fullPosition];
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];

    if ([info[SCUDefaultEditableCollectionViewCellIsMovingKey] boolValue])
    {
        self.movingMask.hidden = NO;
        [self.contentView bringSubviewToFront:self.movingMask];
        return;
    }
    else
    {
        self.movingMask.hidden = YES;
    }

    if ([info[SCUDefaultEditableCollectionViewCellIsInEditModeKey] boolValue])
    {
        self.editMask.hidden = NO;
        self.movingMask.hidden = YES;
    }
    else
    {
        self.editMask.hidden = YES;
    }

    if (self.imageView.image)
    {
        //-------------------------------------------------------------------
        // Hide the text if there is an image.
        //-------------------------------------------------------------------
        self.textLabel.text = nil;
    }
}

@end
