//
//  SCUSlider.h
//  SavantController
//
//  Created by Cameron Pulsford on 7/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSUInteger, SCUSliderStyle)
{
    SCUSliderStylePlain,
    SCUSliderStyleiTunes,
    SCUSliderStyleVolumePopup
};

@class SCUSlider;

@protocol SCUSliderDelegate;

typedef void (^SCUSliderCallback)(SCUSlider *slider);

@interface SCUSlider : UIView

- (instancetype)initWithStyle:(SCUSliderStyle)style frame:(CGRect)frame NS_DESIGNATED_INITIALIZER;

/**
 *  Returns the current style of the slider.
 */
@property (nonatomic, readonly) SCUSliderStyle style;

/**
 *  This callback is called when the slider updates.
 */
@property (nonatomic, copy) SCUSliderCallback callback;

/**
 *  Specifies the minimum interval between callbacks.
 */
@property (nonatomic) NSTimeInterval callbackTimeInterval;

/**
 *  Set the track color.
 */
@property (nonatomic) UIColor *trackColor UI_APPEARANCE_SELECTOR;

/**
 *  Set the fill/value/progress color.
 */
@property (nonatomic) UIColor *fillColor UI_APPEARANCE_SELECTOR;

/**
 *  Set the thumb color.
 */
@property (nonatomic) UIColor *thumbColor UI_APPEARANCE_SELECTOR;

/**
 *  YES if the slider is tracking; otherwise NO.
 */
@property (nonatomic, readonly, getter = isTracking) BOOL tracking;

/**
 *  Set the minimum value the slider should represent. This can be negative. The default is 0.
 */
@property (nonatomic) CGFloat minimumValue;

/**
 *  Set the maximum value the slider should represent. This can be negative but must be higher than the minimumValue. The default is 100.
 */
@property (nonatomic) CGFloat maximumValue;

/**
 *  Set the minimum interval between slider points. The default is 0, which means use the maximum delta.
 */
@property (nonatomic) CGFloat delta;

/**
 *  Set and get the current value. To set the value with an animation, use the @p -setValue:animated: method.
 */
@property (nonatomic) CGFloat value;

/**
 *  Set to YES to generate value updates as the slider moves, otherwise the slider will only generate an update event when the slider has stopped moving. The defaults is YES.
 */
@property (nonatomic, getter = isContinuous) BOOL continuous;

/**
 *  Set to YES to generate value updates as the slider moves, otherwise the slider will only generate an update event when the slider has stopped moving. The defaults is YES.
 */
@property (nonatomic) BOOL showsIndicator;

/**
 *  The pan gesture recognizer used internally to the slider.
 */
@property (nonatomic, readonly) UIPanGestureRecognizer *panGestureRecognizer;

/**
 *  Returns the thumbView.
 */
@property (nonatomic, readonly) UIView *thumb;

/**
 *  Set the value of the slider.
 *
 *  @param value    The new slider value.
 *  @param animated YES to animate the transition; otherwise, NO.
 */
- (void)setValue:(CGFloat)value animated:(BOOL)animated;

@end
