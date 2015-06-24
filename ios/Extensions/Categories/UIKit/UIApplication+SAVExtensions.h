//
//  UIApplication+SAVExtensions.h
//  SavantController
//
//  Created by Nathan Trapp on 4/3/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@interface UIApplication (SAVExtensions)

+ (CGFloat)sav_statusBarHeight;

+ (UIApplication *)sav_sharedApplicationOrException;

@end
