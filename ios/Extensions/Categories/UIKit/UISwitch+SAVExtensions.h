//
//  UISwitch+SAVExtensions.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

typedef void (^SAVUISwitchDidChangeHandler)(BOOL isOn);

@interface UISwitch (SAVExtensions)

@property (nonatomic, copy) SAVUISwitchDidChangeHandler sav_didChangeHandler;

@end
