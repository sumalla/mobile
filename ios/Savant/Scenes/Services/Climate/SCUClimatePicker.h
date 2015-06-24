//
//  SCUClimatePicker.h
//  SavantController
//
//  Created by Stephen Silber on 8/13/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@class SCUClimatePicker;

typedef void (^SCUClimatePickerCallback)(SCUClimatePicker *picker, NSInteger row, NSInteger component);

@interface SCUClimatePicker : UIPickerView

/**
 *  This callback is called when the picker updates.
 */
@property (nonatomic, copy) SCUClimatePickerCallback callback;

@property (nonatomic, readonly) NSInteger minimumValue;

@property (nonatomic, readonly) NSInteger maximumValue;

@property (nonatomic) NSInteger stepValue;

- (void)setMinimumValue:(NSInteger)minimumValue;

- (void)setMaximumValue:(NSInteger)maximumValue;

@end
