//
//  SCUMediaCollectionViewCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 7/27/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMediaCollectionViewCell.h"
#import "SCUMediaDataModel.h"
#import "SCUGradientView.h"

@interface SCUMediaCollectionViewCell ()

@property (nonatomic) UIImageView *artwork;
@property (nonatomic) SCUGradientView *textLabelMask;

@end

@implementation SCUMediaCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        self.artwork = [[UIImageView alloc] init];
        self.artwork.contentMode = UIViewContentModeScaleAspectFill;
        self.artwork.clipsToBounds = YES;
        [self.contentView addSubview:self.artwork];
        [self.contentView sav_addFlushConstraintsForView:self.artwork];

        self.textLabelMask = [[SCUGradientView alloc] initWithFrame:CGRectZero andColors:@[[UIColor clearColor], [[[SCUColors shared] color03] colorWithAlphaComponent:.7]]];
        [self.contentView addSubview:self.textLabelMask];
        [self.contentView sav_addFlushConstraintsForView:self.textLabelMask];

        [self.textLabel removeFromSuperview];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.numberOfLines = 0;
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.textLabelMask addSubview:self.textLabel];
        [self.textLabelMask sav_pinView:self.textLabel withOptions:SAVViewPinningOptionsHorizontally];
        [self.textLabelMask sav_pinView:self.textLabel withOptions:SAVViewPinningOptionsToBottom withSpace:SAVViewAutoLayoutStandardSpace];
        [self.textLabelMask sav_setHeight:.3 forView:self.textLabel isRelative:YES];
        self.textLabelMask.locations = @[@0, @.9];
    }

    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.artwork.image = nil;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    self.textLabel.text = info[SCUMediaModelKeyTitle];
}

@end
