//
//  SCUSchedulingEditingViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 7/14/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelExpandableTableViewController.h"
#import "SCUSchedulingEditorModel.h"
#import "SCUSchedulingEditingModel.h"

@class SAVClimateSchedule;
@protocol SCUSchedulingEditingViewControllerDelegate;

@interface SCUSchedulingEditingViewController : SCUModelExpandableTableViewController <SCUSchedulingEditingDelegate>

+ (Class)classForType:(SCUSchedulingEditorType)type;
+ (instancetype)editingViewControllerForType:(SCUSchedulingEditorType)type andSchedule:(SAVClimateSchedule *)schedule;

- (instancetype)initWithSchedule:(SAVClimateSchedule *)schedule;

@property (nonatomic, readonly) CGFloat estimatedHeight;

@property (weak) id <SCUSchedulingEditingViewControllerDelegate> delegate;

@end

@protocol SCUSchedulingEditingViewControllerDelegate <NSObject>

- (void)reloadData;

@end