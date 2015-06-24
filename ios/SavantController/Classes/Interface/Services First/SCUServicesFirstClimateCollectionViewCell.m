//
//  SCUServicesFirstClimateCollectionViewCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 9/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServicesFirstClimateCollectionViewCell.h"
#import "SCUAnimatedLabel.h"

@interface SCUServicesFirstClimateCollectionViewCell ()

@property (nonatomic) UIView *container;
@property (nonatomic) NSTimer *stateChangeTimer;
@property (nonatomic, copy) NSArray *climateValues;
@property (nonatomic) NSMutableArray *currentClimateValues;

@property (nonatomic) SCUAnimatedLabel *animatedSupplementaryLabel;
@property (nonatomic) SCUAnimatedLabel *animatedSubordinatelabel;

@end

@implementation SCUServicesFirstClimateCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        [self.subordinateLabel removeFromSuperview];
        [self.textLabel removeFromSuperview];
        [self.imageView removeFromSuperview];
        self.imageView.contentMode = UIViewContentModeLeft;

        self.animatedSupplementaryLabel = [[SCUAnimatedLabel alloc] initWithFrame:CGRectZero];
        self.animatedSupplementaryLabel.transitionType = SCUAnimatedLabelTransitionTypeFadeOutFadeIn;

        self.animatedSubordinatelabel = [[SCUAnimatedLabel alloc] initWithFrame:CGRectZero];
        self.animatedSubordinatelabel.transitionType = SCUAnimatedLabelTransitionTypeFadeOutFadeIn;
        self.animatedSubordinatelabel.backgroundColor = self.backgroundColor;

        self.container = [UIView sav_viewWithColor:[UIColor clearColor]];
        [self.contentView addSubview:self.container];
        [self.contentView addSubview:self.textLabel];
        [self.contentView addSubview:self.animatedSubordinatelabel];

        self.textLabel.numberOfLines = 2;
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        
        [UIDevice isPad] ? [self applyPadLayout] : [self applyPhoneLayout];

        self.contentView.clipsToBounds = YES;
    }

    return self;
}

- (void)applyPadLayout
{
    self.animatedSupplementaryLabel.font = [UIFont fontWithName:@"Gotham-Light" size:[[SCUDimens dimens] regular].h1];
    self.animatedSubordinatelabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h9];
    self.textLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h7];
    
    [self.contentView sav_setY:.27 forView:self.container isRelative:YES];
    [self.contentView sav_pinView:self.container withOptions:SAVViewPinningOptionsCenterX];
    [self.contentView sav_setWidth:225 forView:self.container isRelative:NO];
    [self.contentView sav_setHeight:100 forView:self.container isRelative:NO];
    
    [self.contentView sav_pinView:self.textLabel
                      withOptions:SAVViewPinningOptionsToBottom
                           ofView:self.container
                        withSpace:15];
    
    [self.contentView sav_pinView:self.textLabel
                      withOptions:SAVViewPinningOptionsHorizontally
                        withSpace:SAVViewAutoLayoutStandardSpace];
    
    [self.contentView sav_pinView:self.animatedSubordinatelabel
                      withOptions:SAVViewPinningOptionsToBottom
                           ofView:self.textLabel
                        withSpace:7];
    
    [self.contentView sav_pinView:self.animatedSubordinatelabel
                      withOptions:SAVViewPinningOptionsHorizontally
                        withSpace:SAVViewAutoLayoutStandardSpace];
}

- (void)applyPhoneLayout
{
    self.animatedSupplementaryLabel.font = [UIFont fontWithName:@"Gotham-Light" size:[[SCUDimens dimens] regular].h6];
    self.animatedSubordinatelabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h11];

    CGFloat yPercentage = .21;

    if ([UIDevice isPhablet])
    {
        yPercentage = .27;
    }

    [self.contentView sav_setY:yPercentage forView:self.container isRelative:YES];
    [self.contentView sav_pinView:self.container withOptions:SAVViewPinningOptionsCenterX];
    [self.contentView sav_setWidth:120 forView:self.container isRelative:NO];
    [self.contentView sav_setHeight:48 forView:self.container isRelative:NO];
    
    [self.contentView sav_pinView:self.textLabel
                      withOptions:SAVViewPinningOptionsToBottom
                           ofView:self.container
                        withSpace:13];
    
    [self.contentView sav_pinView:self.textLabel
                      withOptions:SAVViewPinningOptionsHorizontally
                        withSpace:SAVViewAutoLayoutStandardSpace];
    
    [self.contentView sav_pinView:self.animatedSubordinatelabel
                      withOptions:SAVViewPinningOptionsToBottom
                           ofView:self.textLabel
                        withSpace:0];
    
    [self.contentView sav_pinView:self.animatedSubordinatelabel
                      withOptions:SAVViewPinningOptionsHorizontally
                        withSpace:SAVViewAutoLayoutStandardSpace];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.subordinateLabel.text = nil;
    [self.subordinateLabel.layer removeAllAnimations];
    [self.animatedSupplementaryLabel resetText];
    [self.animatedSubordinatelabel resetText];

    if (self.stateChangeTimer.isValid)
    {
        [self.stateChangeTimer invalidate];
        self.stateChangeTimer = nil;
    }
}

- (void)configureWithInfo:(NSDictionary *)info
{
    NSMutableDictionary *mInfo = [info mutableCopy];
    [mInfo removeObjectForKey:SCUServicesFirstCollectionViewCellCycleValuesKey];

    [super configureWithInfo:mInfo];

    NSArray *climateValues = info[SCUServicesFirstCollectionViewCellCycleValuesKey];

    [self.imageView removeFromSuperview];
    [self.animatedSupplementaryLabel removeFromSuperview];

    if ([climateValues count])
    {
        self.climateValues = climateValues;
        self.currentClimateValues = [climateValues mutableCopy];
        [self.container addSubview:self.animatedSupplementaryLabel];
        [self.container addSubview:self.imageView];
        [self.container sav_pinView:self.imageView withOptions:SAVViewPinningOptionsVertically | SAVViewPinningOptionsToLeft];
        [self.container sav_setWidth:.30 forView:self.imageView isRelative:YES];
        [self.container sav_pinView:self.animatedSupplementaryLabel withOptions:SAVViewPinningOptionsVertically];
        [self.container sav_pinView:self.animatedSupplementaryLabel withOptions:SAVViewPinningOptionsToRight ofView:self.imageView withSpace:0];
        [self.container sav_setWidth:.70 forView:self.animatedSupplementaryLabel isRelative:YES];

        [self cycleValues];
    }
    else
    {
        [self.container addSubview:self.imageView];
        [self.container sav_addCenteredConstraintsForView:self.imageView];
    }
}

- (void)cycleValues
{
    if (![self.currentClimateValues count])
    {
        self.currentClimateValues = [self.climateValues mutableCopy];
    }

    NSDictionary *climateValue = [self.currentClimateValues firstObject];
    [self.currentClimateValues removeObjectAtIndex:0];

    self.animatedSupplementaryLabel.textColor = climateValue[SCUServicesFirstCollectionViewCellSupplimentaryTextColorKey];
    self.animatedSupplementaryLabel.text = climateValue[SCUServicesFirstCollectionViewCellSupplimentaryTextKey];
    self.animatedSubordinatelabel.textColor = climateValue[SCUServicesFirstCollectionViewCellSubordinateTextColorKey];
    self.animatedSubordinatelabel.text = climateValue[SCUServicesFirstCollectionViewCellSubordinateTextKey];
    
    self.stateChangeTimer = [NSTimer timerWithTimeInterval:4 target:self selector:@selector(cycleValues) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:self.stateChangeTimer forMode:NSRunLoopCommonModes];
}

@end
