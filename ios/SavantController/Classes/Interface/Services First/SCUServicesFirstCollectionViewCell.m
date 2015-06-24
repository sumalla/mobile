//
//  SCUServicesFirstCollectionViewCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 7/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServicesFirstCollectionViewCell.h"
#import "SCUStandardCollectionViewCellPrivate.h"
#import "SCUServicesFirstDataModel.h"
#import "SCUAnimatedLabel.h"

NSString *const SCUServicesFirstCollectionViewCellSubordinateTextKey = @"SCUServicesFirstCollectionViewCellSubordinateTextKey";
NSString *const SCUServicesFirstCollectionViewCellSubordinateTextColorKey = @"SCUServicesFirstCollectionViewCellSubordinateTextColorKey";
NSString *const SCUServicesFirstCollectionViewCellSupplimentaryTextKey = @"SCUServicesFirstCollectionViewCellSupplimentaryTextKey";
NSString *const SCUServicesFirstCollectionViewCellSupplimentaryTextColorKey = @"SCUServicesFirstCollectionViewCellSupplimentaryTextColorKey";
NSString *const SCUServicesFirstCollectionViewCellCycleValuesKey = @"SCUServicesFirstCollectionViewCellCycleValuesKey";

@interface SCUServicesFirstCollectionViewCell ()

@property (nonatomic) UIImageView *imageView;
@property (nonatomic) NSTimer *stateChangeTimer;
@property (nonatomic) SCUAnimatedLabel *subordinateLabel;
@property (nonatomic, copy) NSArray *cycleValues;
@property (nonatomic) NSMutableArray *currentCycleValues;

@end

@implementation SCUServicesFirstCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        [self.textLabel removeFromSuperview];
        [self.imageView removeFromSuperview];
        self.imageView.contentMode = UIViewContentModeCenter;
        [self.contentView addSubview:self.textLabel];
        [self.contentView addSubview:self.imageView];

        self.textLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h9];

        self.subordinateLabel = [[SCUAnimatedLabel alloc] initWithFrame:CGRectZero];
        self.subordinateLabel.transitionType = SCUAnimatedLabelTransitionTypeFadeOutFadeIn;
        self.subordinateLabel.backgroundColor = self.backgroundColor;
        self.subordinateLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h11];
        [self.contentView addSubview:self.subordinateLabel];

        CGFloat yPercentage = .21;

        if ([UIDevice isPhablet])
        {
            yPercentage = .27;
        }

        [self.contentView sav_setY:yPercentage forView:self.imageView isRelative:YES];
        [self.contentView sav_pinView:self.imageView withOptions:SAVViewPinningOptionsHorizontally];

        self.textLabel.numberOfLines = 2;
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;

        [self.contentView sav_pinView:self.textLabel
                          withOptions:SAVViewPinningOptionsToBottom
                               ofView:self.imageView
                            withSpace:13];

        [self.contentView sav_pinView:self.textLabel
                          withOptions:SAVViewPinningOptionsHorizontally
                            withSpace:SAVViewAutoLayoutStandardSpace];

        [self.contentView sav_pinView:self.subordinateLabel
                          withOptions:SAVViewPinningOptionsToBottom
                               ofView:self.textLabel
                            withSpace:4];

        [self.contentView sav_pinView:self.subordinateLabel
                          withOptions:SAVViewPinningOptionsHorizontally
                            withSpace:SAVViewAutoLayoutStandardSpace];

        self.contentView.clipsToBounds = YES;
    }

    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    [self.subordinateLabel resetText];

    if (self.stateChangeTimer.isValid)
    {
        [self.stateChangeTimer invalidate];
        self.stateChangeTimer = nil;
    }
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];
    self.textLabel.text = info[SCUDefaultCollectionViewCellKeyTitle];
    self.subordinateLabel.text = nil;

    NSString *subordinateText = info[SCUServicesFirstCollectionViewCellSubordinateTextKey];
    UIColor *subordinateColor = info[SCUServicesFirstCollectionViewCellSubordinateTextColorKey];
    NSArray *cycleValues = info[SCUServicesFirstCollectionViewCellCycleValuesKey];

    if ([cycleValues count])
    {
        self.cycleValues = cycleValues;
        self.currentCycleValues = [cycleValues mutableCopy];
        [self _cycleValues];
    }
    else if (subordinateText)
    {
        self.subordinateLabel.text = subordinateText;
        self.subordinateLabel.textColor = subordinateColor;
    }
}

- (UIColor *)imageTintColorWithInfo:(NSDictionary *)info
{
    return [[SCUColors shared] color04];
}

- (void)_cycleValues
{
    if (![self.currentCycleValues count])
    {
        self.currentCycleValues = [self.cycleValues mutableCopy];
    }

    NSDictionary *cycleValues = [self.currentCycleValues firstObject];
    [self.currentCycleValues removeObjectAtIndex:0];

    self.subordinateLabel.textColor = cycleValues[SCUServicesFirstCollectionViewCellSubordinateTextColorKey];
    self.subordinateLabel.text = cycleValues[SCUServicesFirstCollectionViewCellSubordinateTextKey];
    self.subordinateLabel.backgroundColor = self.backgroundColor;

    self.stateChangeTimer = [NSTimer timerWithTimeInterval:2 target:self selector:_cmd userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:self.stateChangeTimer forMode:NSRunLoopCommonModes];
}

@end
