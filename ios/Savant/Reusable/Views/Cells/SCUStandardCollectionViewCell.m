//
//  SCUStandardCollectionViewCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 7/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUStandardCollectionViewCell.h"
#import "SCUStandardCollectionViewCellPrivate.h"

NSString *const SCUDefaultCollectionViewCellKeyImage = @"SCUDefaultCollectionViewCellKeyImage";

@interface SCUStandardCollectionViewCell ()

@property (nonatomic) UIImageView *backgroundImageView;

@end

@implementation SCUStandardCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        self.textLabel.adjustsFontSizeToFitWidth = YES;
        self.textLabel.minimumScaleFactor = 0.7;
        self.textLabel.font = [UIFont fontWithName:@"Gotham-Book" size:17];

        self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:self.imageView];
        [self.contentView sav_addCenteredConstraintsForView:self.imageView];

        self.textLabel.numberOfLines = 0;
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView sav_pinView:self.textLabel
                          withOptions:SAVViewPinningOptionsToBottom
                            withSpace:30];
        [self.contentView sav_pinView:self.textLabel
                          withOptions:SAVViewPinningOptionsHorizontally
                            withSpace:SAVViewAutoLayoutStandardSpace];

        self.backgroundImageView = [[UIImageView alloc] init];
        self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:self.backgroundImageView];
        [self.contentView sav_addFlushConstraintsForView:self.backgroundImageView];
        [self.contentView sendSubviewToBack:self.backgroundImageView];
        self.contentView.clipsToBounds = YES;

    }

    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];

    NSString *imageName = info[SCUDefaultCollectionViewCellKeyImage];

    if ([imageName length])
    {
        self.imageView.image = [UIImage sav_imageNamed:imageName tintColor:[self imageTintColorWithInfo:info]];
    }
    else
    {
        self.imageView.image = nil;
    }
}

#pragma mark - Private

- (UIColor *)imageTintColorWithInfo:(NSDictionary *)info
{
    return [[SCUColors shared] color04];
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];

    self.alpha = highlighted ? .4 : 1;
}

@end
