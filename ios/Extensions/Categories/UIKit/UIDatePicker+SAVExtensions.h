//
//  UIDatePicker+SAVExtensions.h
//  SavantController
//
//  Created by Nathan Trapp on 7/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

typedef void (^SAVDatePickerHandler)(NSDate *date);

@interface UIDatePicker (SAVExtensions)

@property SAVDatePickerHandler sav_handler;

@end
