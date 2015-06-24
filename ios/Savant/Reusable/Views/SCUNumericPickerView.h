//
//  SCUNumericPickerView.h
//  SavantController
//
//  Created by Nathan Trapp on 8/18/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

typedef void (^SCUNumericPickerViewCallback)(CGFloat value);

@interface SCUNumericPickerView : UIPickerView

/**
 *  The min and max allowed values.
 */
@property (nonatomic) CGFloat maxValue, minValue;
/**
 *  The range between values.
 */
@property (nonatomic) CGFloat delta;
/**
 *  The current selected value.
 */
@property (readonly, nonatomic) CGFloat value;
/**
 *  A predefined list of values, if this is defined delta, min, and max are ignored.
 */
@property (nonatomic) NSArray *values;

@property (nonatomic) UIColor *textColor;
@property (nonatomic) UIFont *textFont;

- (void)setValue:(CGFloat)value animated:(BOOL)animated;

@property (copy) SCUNumericPickerViewCallback handler;

- (NSUInteger)rowForValue:(CGFloat)value;
- (CGFloat)valueForRow:(NSUInteger)row;

- (void)reloadData;

@end
