//
//  SCUNotificationCreationWhenViewModel.h
//  SavantController
//
//  Created by Stephen Silber on 1/23/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationCreationDataSource.h"

@class SCUDayPickerCell, PMEDatePicker;

@protocol SCUNotificationWhenViewDelegate <NSObject>

- (void)reloadIndexPath:(NSIndexPath *)indexPath;
- (void)toggleIndex:(NSIndexPath *)indexPath;
- (void)reloadChildrenBelowIndexPath:(NSIndexPath *)indexPath;
- (void)reloadData;

@end

typedef NS_ENUM(NSUInteger, SCUNotificationWhenCellType)
{
        SCUNotificationWhenCellTypeDefault = 0,
        SCUNotificationWhenCellTypeChild,
        SCUNotificationWhenCellTypeDate,
        SCUNotificationWhenCellTypeDatePicker,
        SCUNotificationWhenCellTypeDayPicker,
        SCUNotificationWhenCellTypeNumericPicker,
        SCUNotificationWhenCellTypeToggle
};

typedef NS_ENUM(NSUInteger, SCUNotificationWhenCellProperty)
{
    SCUNotificationWhenCellPropertyType = 0,
    SCUNotificationWhenCellPropertyAllDay,
    SCUNotificationWhenCellPropertyStartTime,
    SCUNotificationWhenCellPropertyEndTime,
    SCUNotificationWhenCellPropertyAllYear,
    SCUNotificationWhenCellPropertyStartDate,
    SCUNotificationWhenCellPropertyEndDate,
    SCUNotificationWhenCellPropertyDays,
    SCUNotificationWhenCellPropertyCelestialStart,
    SCUNotificationWhenCellPropertyCelestialStartOffset,
    SCUNotificationWhenCellPropertyCelestialEnd,
    SCUNotificationWhenCellPropertyCelestialEndOffset
};

@interface SCUNotificationCreationWhenViewModel : SCUNotificationCreationDataSource

@property (weak) id <SCUNotificationWhenViewDelegate> delegate;

- (void)listenToDatePicker:(PMEDatePicker *)picker withParent:(NSIndexPath *)indexPath;
- (void)listenToDayPicker:(SCUDayPickerCell *)picker withParent:(NSIndexPath *)indexPath;
- (SCUNotificationWhenCellProperty)cellPropertyForIndexPath:(NSIndexPath *)indexPath;
- (void)prepareData;

@end
