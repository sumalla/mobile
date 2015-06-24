//
//  UIGestureRecognizer+SAVExtensions.m
//  SavantController
//
//  Created by Nathan Trapp on 6/27/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "UIGestureRecognizer+SAVExtensions.h"
@import ObjectiveC.runtime;

@implementation UIGestureRecognizer (SAVExtensions)

- (void)setSav_handler:(SAVGestureRecognizerHandler)handler
{
    [self removeTarget:self action:@selector(sav_gestureFired)];
    
    if (handler)
    {
        [self addTarget:self action:@selector(sav_gestureFired)];
    }
    
    objc_setAssociatedObject(self, @selector(sav_handler), handler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (SAVGestureRecognizerHandler)sav_handler
{
    return objc_getAssociatedObject(self, @selector(sav_handler));
}

- (void)sav_gestureFired
{
    self.sav_handler(self.state, [self locationInView:self.view.superview]);
}

@end
