//
//  SCURangeViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 7/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelTableViewController.h"
#import "SCUMainToolbarManager.h"

@interface SCURangeViewController : SCUModelTableViewController <SCUMainToolbarManager>

@property (nonatomic) NSDate *startDate, *endDate, *minDate;
@property (nonatomic) BOOL endOnly;
@property (nonatomic) NSString *datePickerFormat;
@property (nonatomic) NSString *dateFormat;

@end
