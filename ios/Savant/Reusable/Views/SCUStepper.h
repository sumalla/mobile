//
//  SCUStepper.h
//  SavantController
//
//  Created by Stephen Silber on 7/9/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

#import "SCUButton.h"

@class SCUStepper;

@protocol SCUStepperDelegate <NSObject>

@optional

- (void)stepperValueDidChange:(SCUStepper *)stepper;

@end

typedef void (^SCUStepperCallback)(SCUStepper *slider);

@interface SCUStepper : UIControl

@property (nonatomic, weak) id <SCUStepperDelegate> delegate;

@property (nonatomic, copy) SCUStepperCallback callback;

@property (nonatomic) NSTimeInterval callbackTimeInterval;

//- (instancetype)initWithImages:(NSArray *)images;
- (instancetype)initWithTextArray:(NSArray *)textArray;
- (void)setTitlesFromArray:(NSArray *)titleArray;
- (void)setLeftTitle:(NSString *)title;
- (void)setRightTitle:(NSString *)title;
- (void)updateButtonLabelSize:(NSString *)fontSize;

/**
 * Min, Max, Current, and step size values
 */
@property (nonatomic) float minimumValue;
@property (nonatomic) float maximumValue;
@property (nonatomic) float value;
@property (nonatomic) float stepValue;

/**
 *  Left button object
 */
@property (nonatomic) SCUButton *leftButton;

/**
 *  Right button object
 */
@property (nonatomic) SCUButton *rightButton;

/**
 *  Text or image color for the normal state.
 */
@property (nonatomic) UIColor *color;

/**
 *  Background color for the normal state.
 */
@property (nonatomic) UIColor *backgroundColor;

/**
 *  Text or image color for the selected state.
 */
@property (nonatomic) UIColor *selectedColor;

/**
 *  Background color for the selected state.
 */
@property (nonatomic) UIColor *selectedBackgroundColor;

/**
 *  This color is used when userInteractionEnabled is set to NO.
 */
@property (nonatomic) UIColor *disabledColor;

@property (nonatomic, weak) id target;
@property (nonatomic) SEL action;

@end
