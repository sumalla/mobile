//
//  SCUSliderView.h
//  SavantController
//
//  Created by David Fairweather on 4/14/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

//-------------------------------------------------------------------
// Slider View
//-------------------------------------------------------------------

@import UIKit;

#import "SCUTicView.h"
#import "SCUGradientView.h"

extern NSString *const SCUSliderCurrentValue;
extern NSString *const SCUSliderHighSetPoint;
extern NSString *const SCUSliderLowSetPoint;
extern NSString *const SCUSliderMiddleSetPoint;

//configuration settings
typedef NS_OPTIONS(NSInteger, SCUSliderViewConfiguration)
{
    SCUSliderViewConfigurationVertical   = 1 << 0,
    SCUSliderViewConfigurationHorizontal = 1 << 1, //Radio will have different settings
    SCUSliderViewConfigurationMultipleHandles = 1 << 2, //will include two handles, with desired handle between the two
    SCUSliderViewConfigurationTapOnly = 1 << 3, //slider can only be tappable, not drag
    SCUSliderViewConfigurationPool = 1 << 4 //slider doesn't change color
};

typedef NS_ENUM(NSInteger, SCUSliderSetPointMode)
{
    SCUSliderSetPointModeLowPointOnly,
    SCUSliderSetPointModeHighPointOnly,
    SCUSliderSetPointModeDualSetPointAuto,
    SCUSliderSetPointModeSingleSetPointAuto,
    SCUSliderSetPointModeOff
};

typedef NS_ENUM(NSInteger, SCUHandleType)
{
    SCUHandleHighSetPoint,
    SCUHandleLowSetPoint,
    SCUHandleCenterSetPoint
};

@protocol SCUSliderViewDelegate;

@interface SCUSliderView : UIView

@property (weak, nonatomic) id<SCUSliderViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame andConfiguration:(SCUSliderViewConfiguration)config;

//-------------------------------------------------------------------
// View Controller sets the scale before this view configures everything
//-------------------------------------------------------------------
- (void)setScaleOfSliderFrom:(CGFloat)lowest To:(CGFloat)highest;

- (void)setColorOfMainHandle:(UIColor *)color;

- (void)setColorOfMaxPoint:(UIColor *)maxColor andMinPoint:(UIColor *)minColor;

- (void)changeValueOfHandleToValue:(CGFloat)value;

- (void)changeValueOfMaxPointToValue:(CGFloat)value;

- (void)changeValueOfMinPointToValue:(CGFloat)value;

- (void)setMultipleHandlesWithRange:(NSInteger)range;

- (void)changeConfigurationToMode:(SCUSliderSetPointMode)mode;

- (void)changeCurrentHandleToValue:(CGFloat)value;

- (void)setSliderVisibility:(BOOL)visible;

- (BOOL)canReciveOutSideSetPoints;

@property (nonatomic, readonly) CGRect setLayoutOfGradientView;

/**
 *  Change the delay before a hold command is recognized. The default is .4 seconds.
 */
@property (nonatomic) NSTimeInterval holdDelay;

//-------------------------------------------------------------------
// current status of the room constantly checked/updated by the system
//-------------------------------------------------------------------
@property (nonatomic) NSInteger currentValue;

@property (nonatomic) CGFloat desiredValue;

@property (nonatomic) CGFloat highSliderValue;

@property (nonatomic) CGFloat lowSliderValue;

@property (nonatomic) CGFloat lowestValue;

@property (nonatomic) CGFloat highestValue;

//-------------------------------------------------------------------
// Notes the current temperature/humidity level. Changes overtime
// to match the "desired" level.
//-------------------------------------------------------------------
@property (nonatomic) UIView *currentStatusSliderHandle;

@property (nonatomic) SCUTicView *ticsView;

@property (nonatomic) UITapGestureRecognizer *tap;

@property (nonatomic) UILongPressGestureRecognizer *longPress;

@property (nonatomic) CGFloat longPressControlRange;

@property (nonatomic) NSInteger minDeadband;

@property (nonatomic) UIColor *maxPointColor;
@property (nonatomic) UIColor *minPointColor;

@property (nonatomic) float scaleGranularity;

@property (nonatomic) CGFloat minimumWidth;

@property (nonatomic) BOOL setPointPopUp;

@end

@protocol SCUSliderViewDelegate <NSObject>

@optional

- (void)sliderView:(SCUSliderView *)sliderView didChangeValueWithDesiredValue:(CGFloat)value andHeldDown:(BOOL)hold;

- (void)sliderView:(SCUSliderView *)sliderView didChangeMultipleValuesWithHighestValue:(NSInteger)high andLowestValue:(NSInteger)low andDesiredValue:(NSInteger)value andHeldDown:(BOOL)hold;

- (void)sliderView:(SCUSliderView *)sliderView didChangeSingleSetPointWithDesiredValue:(NSInteger)value withSetPointValue:(NSInteger)pointValue andHeldDown:(BOOL)hold;

- (void)sliderView:(SCUSliderView *)slider didEndHoldAtValue:(CGFloat)value;

- (void)sliderView:(SCUSliderView *)slider didSelectSetPointHandle:(SCUHandleType)handleType;

- (NSString *)interpretedDisplayValue:(NSInteger)value;// this can be used to convert units or add suffixes like %

- (NSDictionary *)getCurrentSetPoints;

- (void)didTouchNonHandlePartOfSlider;

@end