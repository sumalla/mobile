//
//  SCUSceneScheduleDataSource.h
//  SavantController
//
//  Created by Nathan Trapp on 8/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneCreationDataSource.h"

@class SCUDayPickerCell, PMEDatePicker;
@protocol SCUSceneScheduleDelegate;

typedef NS_ENUM(NSInteger, SCUSceneScheduleCellTypes)
{
    SCUSceneScheduleCellTypeDefault = 0,
    SCUSceneScheduleCellTypeChild,
    SCUSceneScheduleCellTypeDate,
    SCUSceneScheduleCellTypeDatePicker,
    SCUSceneScheduleCellTypeDayPicker,
    SCUSceneScheduleCellTypeNumericPicker,
    SCUSceneScheduleCellTypeToggle
};

@interface SCUSceneScheduleDataSource : SCUSceneCreationDataSource

@property (weak) id <SCUSceneScheduleDelegate> delegate;

- (void)listenToDatePicker:(PMEDatePicker *)picker withParent:(NSIndexPath *)indexPath;
- (void)listenToDayPicker:(SCUDayPickerCell *)picker withParent:(NSIndexPath *)indexPath;
- (void)prepareData;

@end

@protocol SCUSceneScheduleDelegate <NSObject>

- (void)reloadIndexPath:(NSIndexPath *)indexPath;
- (void)toggleIndex:(NSIndexPath *)indexPath;
- (void)reloadChildrenBelowIndexPath:(NSIndexPath *)indexPath;
- (void)reloadData;

@end
