//
//  SCUSchedulingPickerCell.h
//  SavantController
//
//  Created by Nathan Trapp on 7/17/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"

extern NSString *const SCUSchedulingPickerCellKeyTime;
extern NSString *const SCUSchedulingPickerCellKeySetPoint1;
extern NSString *const SCUSchedulingPickerCellKeySetPoint2;
extern NSString *const SCUSchedulingPickerCellKeyMaxTitle;
extern NSString *const SCUSchedulingPickerCellKeyMinTitle;
extern NSString *const SCUSchedulingPickerCellKeyMaxColor;
extern NSString *const SCUSchedulingPickerCellKeyMinColor;
extern NSString *const SCUSchedulingPickerCellKeyUnitsString;
extern NSString *const SCUSchedulingPickerCellKeyCellType;
extern NSString *const SCUSchedulingPickerCellKeyCellModeTitle;
extern NSString *const SCUSchedulingPickerCellKeyMode;
extern NSString *const SCUSchedulingPickerCellKeyModeEnabled;

typedef NS_ENUM(NSUInteger, SCUSchedulingPickerCellType) {
    SCUSchedulingPickerCellTypeTemp,
    SCUSchedulingPickerCellTypeHumidity,
    SCUSchedulingPickerCellTypeMode,
    SCUSchedulingPickerCellTypeAdd
};

@class SCUPickerView, SCUButton;

@interface SCUSchedulingPickerCell : SCUDefaultTableViewCell

@property (readonly) SCUPickerView *minPickerView, *maxPickerView;
@property (readonly) SCUButton *addButton, *deleteButton;
@property (readonly) SCUButton *timeButton, *modeButton;

- (void)setMinSetPoint:(NSInteger)value;
- (void)setMaxSetPoint:(NSInteger)value;

@end
