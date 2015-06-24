//
//  UIGestureRecognizer+SAVExtensions.h
//  SavantController
//
//  Created by Nathan Trapp on 6/27/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

typedef void (^SAVGestureRecognizerHandler)(UIGestureRecognizerState state, CGPoint location);

@interface UIGestureRecognizer (SAVExtensions)

@property SAVGestureRecognizerHandler sav_handler;

@end
