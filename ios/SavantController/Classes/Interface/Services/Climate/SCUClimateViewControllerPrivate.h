//
//  SCUClimateViewControllerPrivate.h
//  SavantController
//
//  Created by David Fairweather on 5/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSliderView.h"
#import "SCUButton.h"
#import "SCUClimateModeTableViewController.h"
#import "SCUPopoverController.h"
#import "SCUClimateServiceModel.h"
#import "SCUGradientView.h"
#import "SCUSetChangePickerView.h"
#import "SCUPickerView.h"
#import "SCUClimateViewController.h"

@interface SCUClimateViewController ()

@property (nonatomic) SCUSliderView *sliderView;

@property (nonatomic) UILabel *desiredSetPointLabel;
@property (nonatomic) UILabel *doAtSetPointLabel;
@property (nonatomic) UILabel *highSetPointValueLabel;
@property (nonatomic) UILabel *lowSetPointValueLabel;

@property (nonatomic) UILabel *rangeSetPointTitleLabel;
@property (nonatomic) UILabel *dashLabel;

@property (nonatomic) CGFloat desiredSetPointLabelHeight;

@property (nonatomic) UILabel *currentClimatePointLabel;
@property (nonatomic) CGFloat cornerLabelHeight;

@property (nonatomic) CGFloat centerButtonAndTimePickerWidth;
@property (nonatomic) CGFloat centerButtonAndTimePickerHeight;
@property (nonatomic) CGFloat offsetFromCenter;

@property (nonatomic) UILabel *desiredTitleLabel;
@property (nonatomic) UILabel *doAtTitleLabel;
@property (nonatomic) UILabel *currentTitleLabel;
@property (nonatomic) CGFloat titleLabelWidth;
@property (nonatomic) CGFloat titleLabelHeight;
@property (nonatomic) CGFloat titleOffsetFromCorrnerLabel;

@property (nonatomic) NSTimer *feedbackWaitTimer;

@property (nonatomic) NSArray *normalGradientBackground;
@property (nonatomic) NSArray *greaterGradientBackground;
@property (nonatomic) NSArray *lesserGradientBackground;

@property (nonatomic) UIColor *inCornerLabelColor;

@property (nonatomic) CGFloat centerLabelFontSize;
@property (nonatomic) CGFloat cornerLabelFontSize;
@property (nonatomic) CGFloat cornerValueFontSize;

@property (nonatomic) CGFloat rangeValueFontSize;

@property (nonatomic) CGFloat setPointPopoverFontSize;

@property (nonatomic) CGFloat centerLabelSuperScriptFontSize;
@property (nonatomic) CGFloat cornerLabelSuperScriptFontSize;
@property (nonatomic) CGFloat setPointPopoverSuperScriptFontSize;

@property (nonatomic) CGFloat titleLabelFontSize;

@property (nonatomic) NSInteger sliderMaxValue;
@property (nonatomic) NSInteger sliderMinValue;

@property (nonatomic) SCUClimateServiceModel *model;

@property (nonatomic) SCUSetChangePickerView *timePicker;
@property (nonatomic) UIView *timePickerBackgroundView;
@property (nonatomic) CGFloat timePickerWidth;
@property (nonatomic) CGFloat timePickerHeight;

@property (nonatomic) NSString *setToChangeUpText;
@property (nonatomic) NSString *setToChangeDownText;
@property (nonatomic) NSString *notificationChangingUpText;
@property (nonatomic) NSString *notificationChangingDownText;

@property (nonatomic) NSString *atClimateChangeUpText;
@property (nonatomic) NSString *atClimateChangeDownText;

@property (nonatomic) UIView *setPointPickerBackgroundView;
@property (nonatomic) UIView *lineView;

@property (nonatomic) SCUClimateAdjustmentType upDownArrowsType;

@property (nonatomic) SCUPickerView *upDownArrows;
@property (nonatomic) SCUPickerView *upDownArrowsForOverLay;

@property (nonatomic) NSTimer *visibilityTimer;

@property (nonatomic) BOOL isChangingUp;
@property (nonatomic) BOOL isChangingDown;

@property (nonatomic) NSArray *cornerConstraint;
@property (nonatomic) NSArray *centeredConstraint;

- (void)forceToCenter;

- (NSArray *)centerConstraintFormatsForView;
- (NSArray *)cornerConstraintFormatsForView;
- (void)animateLabelToCorner:(BOOL)inCorner withTimer:(BOOL)isTimed;
- (SCUSliderViewConfiguration)sliderConfiguration;
- (NSDictionary *)getCurrentSetPoints;

- (void)scaleCurrentValueLable;
- (void)layoutSubviews;

- (void)startSliderSetPointAddjustment;
- (void)endSliderSetPointAddjustment;

@end
