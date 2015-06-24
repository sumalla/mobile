//
//  UISwitch+SAVExtensions.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "UISwitch+SAVExtensions.h"
@import ObjectiveC.runtime;

@interface UISwitch ()

@property (nonatomic) BOOL lastIsOnValue;

@end

@implementation UISwitch (SAVExtensions)

@dynamic sav_didChangeHandler;

- (void)setSav_didChangeHandler:(SAVUISwitchDidChangeHandler)sav_didChangeHandler
{
    if (sav_didChangeHandler)
    {
        [self addTarget:self action:@selector(sav_didChange) forControlEvents:UIControlEventValueChanged];
    }
    else
    {
        [self removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
    }
    
    objc_setAssociatedObject(self, @selector(sav_didChangeHandler), sav_didChangeHandler, OBJC_ASSOCIATION_COPY_NONATOMIC);
    self.lastIsOnValue = self.isOn;
}

- (SAVUISwitchDidChangeHandler)sav_didChangeHandler
{
    return objc_getAssociatedObject(self, @selector(sav_didChangeHandler));
}

- (void)setLastIsOnValue:(BOOL)lastIsOnValue
{
    objc_setAssociatedObject(self, @selector(lastIsOnValue), @(lastIsOnValue), OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)lastIsOnValue
{
    return [objc_getAssociatedObject(self, @selector(lastIsOnValue)) boolValue];
}

- (void)sav_didChange
{
    if (self.isOn != self.lastIsOnValue)
    {
        self.lastIsOnValue = self.isOn;
        self.sav_didChangeHandler(self.isOn);
    }
}

@end
