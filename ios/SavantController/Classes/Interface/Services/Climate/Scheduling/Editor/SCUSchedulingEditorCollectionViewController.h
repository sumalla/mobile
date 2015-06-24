//
//  SCUSchedulingEditor.h
//  SavantController
//
//  Created by Nathan Trapp on 7/14/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelCollectionViewController.h"

@class SAVClimateSchedule, SCUSchedulingEditorModel, SCUSchedulingEditingViewController;

@interface SCUSchedulingEditorCollectionViewController : SCUModelCollectionViewController

- (instancetype)initWithSchedule:(SAVClimateSchedule *)schedule;

@property (readonly) SCUSchedulingEditorModel *model;

@property (readonly) NSIndexPath *selectedIndex;

- (SCUSchedulingEditingViewController *)editingViewControllerForIndexPath:(NSIndexPath *)indexPath;

@end


