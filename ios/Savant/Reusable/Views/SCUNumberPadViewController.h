//
//  SCUNumberPadViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 5/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUButtonViewController.h"

#define kClearNumbersInternalAppCommand (@"ClearNumbersInternalAppCommand")

@interface SCUNumberPadViewController : SCUButtonViewController

@property NSTimeInterval inputBoxTimeout;
@property (nonatomic, readonly) NSString *labelText;

@property (nonatomic) BOOL letterMapping;
@property (nonatomic) BOOL isPresetOnly;
@property (nonatomic) BOOL flushConstraints;
@property (nonatomic) BOOL hideInfoBox;
@property (nonatomic) BOOL alwaysShowClearButton;

@end
