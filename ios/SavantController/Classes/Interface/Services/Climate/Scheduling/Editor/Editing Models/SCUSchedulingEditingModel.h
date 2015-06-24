//
//  SCUSchedulingEditingModel.h
//  SavantController
//
//  Created by Nathan Trapp on 7/14/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUExpandableDataSourceModel.h"

@class SAVClimateSchedule;
@protocol SCUSchedulingEditingDelegate;

@interface SCUSchedulingEditingModel : SCUExpandableDataSourceModel

- (instancetype)initWithSchedule:(SAVClimateSchedule *)schedule;

@property (readonly) SAVClimateSchedule *schedule;
@property (weak) id <SCUSchedulingEditingDelegate> delegate;

@end

@protocol SCUSchedulingEditingDelegate <NSObject>

- (void)reloadData;
- (void)insertRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)deleteRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)reloadRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)reloadRowAtIndexPath:(NSIndexPath *)indexPath withRowAnimation:(UITableViewRowAnimation)animation;
- (UITableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath;

@optional
- (void)reconfigureIndexPath:(NSIndexPath *)indexPath;
- (void)setImages:(NSArray *)images forIndexPath:(NSIndexPath *)indexPath;
- (void)reorderIndexPathsWithData:(NSArray *)newData;
- (NSIndexPath *)indexPathForCell:(UITableViewCell *)cell;

@end
