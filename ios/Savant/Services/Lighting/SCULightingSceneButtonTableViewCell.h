//
//  SCULightingSceneButtonTableViewCell.h
//  SavantController
//
//  Created by Cameron Pulsford on 9/15/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"
#import "SCUButton.h"

extern NSString *const SCULightingSceneButtonTableViewCellKeyEnabled;

@interface SCULightingSceneButtonTableViewCell : SCUDefaultTableViewCell

@property (nonatomic, readonly) UILongPressGestureRecognizer *holdGesture;

@end
