//
//  SCUTicView.h
//  SavantController
//
//  Created by David Fairweather on 4/14/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSInteger, SCUSlideViewOrientation)
{
    SCUSlideViewOrientationVertical = 1,
    SCUSlideViewOrientationHorizontal = 2,
};

@interface SCUTicView : UIView

@property (nonatomic) CGFloat edgePadding;

@property (nonatomic) CGFloat ticOffset;

@property (nonatomic) CGFloat ticHeight; //normal height for each tic

@property (nonatomic) BOOL isRadioFM;

@property (nonatomic) UIColor *ticColor;
@property (nonatomic) UIColor *ticAlternateColor;

//-------------------------------------------------------------------
// Maybe better to add Horiz/Vert config to determine tic direction?
//-------------------------------------------------------------------
@property (nonatomic) NSInteger orientation;

- (instancetype)initWithFrame:(CGRect)frame withScaleOf:(CGFloat)scale andOffsetOf:(NSInteger)offset majorTicsAt:(NSUInteger)majorTics minorTicsAt:(NSUInteger)minorTics integerConversionFactor:(NSUInteger)integerConversionFactor;

- (instancetype)initWithFrame:(CGRect)frame withScaleOf:(CGFloat)scale andOffsetOf:(NSInteger)offset withOrientation:(NSInteger)orientation;

- (void)addNumberOfTics:(NSInteger)num;

- (void)changeScale:(CGFloat)scale andOffsetOf:(NSInteger)offset majorTicsAt:(NSUInteger)majorTics minorTicsAt:(NSUInteger)minorTics integerConversionFactor:(NSUInteger)integerConversionFactor;

- (void)changeScaleWithLowestValue:(NSInteger)lowValue andHighValue:(NSInteger)highValue;

@end
