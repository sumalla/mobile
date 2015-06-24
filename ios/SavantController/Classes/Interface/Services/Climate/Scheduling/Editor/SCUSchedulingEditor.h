//
//  SCUSchedulingEditor.h
//  SavantController
//
//  Created by Nathan Trapp on 7/21/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelViewController.h"

@class SAVClimateSchedule;
@protocol SCUSchedulingEditorDelegate;

@interface SCUSchedulingEditor : SCUModelViewController

- (instancetype)initWithSchedule:(SAVClimateSchedule *)schedule;

@property (weak, nonatomic) id <SCUSchedulingEditorDelegate> delegate;
@property BOOL newSchedule;

@end

@protocol SCUSchedulingEditorDelegate <NSObject>

- (void)willDismissEditor:(SAVClimateSchedule *)schedule;
- (NSDictionary *)schedulerSettings;

@end