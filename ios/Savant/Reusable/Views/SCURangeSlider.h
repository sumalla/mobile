//
//  SCURangeSlider.h
//  SavantController
//
//  Created by Stephen Silber on 1/14/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSUInteger, SCURangeSliderStyle)
{
    SCURangeSliderStyleNone,
    SCURangeSliderStyleClimate,
    SCURangeSliderStyleHumidity
};

@class SCURangeSlider;

typedef void (^SCURangeSliderCallback)(SCURangeSlider *slider);

@interface SCURangeSlider : UIView

- (instancetype)initWithStyle:(SCURangeSliderStyle)style frame:(CGRect)frame;

- (instancetype)initWithStyle:(SCURangeSliderStyle)style withOffsetPercentage:(CGFloat)offset andFrame:(CGRect)frame;

- (void)setLeftValue:(CGFloat)value animated:(BOOL)animated;

- (void)setRightValue:(CGFloat)value animated:(BOOL)animated;

/**
 *  Sets the gradient of the fill color
 *
 *  @param colors - an array of 2 UIColor objects for the startColor and endColor
 */
- (void)setGradientColors:(NSArray *)colors;

/**
 *  Callback is called every time a value updates
 */
@property (nonatomic, copy) SCURangeSliderCallback callback;

/**
 *  Access the left handle's value
 */
@property (nonatomic, readonly) CGFloat leftValue;

/**
 *  Access the right handle's value
 */
@property (nonatomic, readonly) CGFloat rightValue;

/**
 *  Access the minimum value
 */
@property (nonatomic, readonly) CGFloat minimumValue;

/**
 *  Access the minimum value
 */
@property (nonatomic, readonly) CGFloat maximumValue;

/**
 *  Sets the color of the track that is 'inactive'
 */
@property (nonatomic) UIColor *trackColor;

/**
 *  Sets the color of the thumb handles (both left and right)
 */
@property (nonatomic) UIColor *thumbColor;

/**
 *  Returns the modifier character (% or º)
 */
@property (nonatomic, readonly) NSString *modifierCharacter;

/**
 *  Tells the view if it's contained in a subview to handle vertical scrolling
 */
@property (nonatomic, getter=isInScrollview) BOOL inScrollview;

@end
