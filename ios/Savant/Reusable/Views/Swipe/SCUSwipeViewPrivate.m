//
//  SCUSwipeViewPrivate.m
//  SavantController
//
//  Created by Cameron Pulsford on 8/21/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSwipeViewPrivate.h"
@import Extensions;

@interface SCUSwipeView (VeryPrivate)

@property (nonatomic, copy) NSArray *code;
@property (nonatomic) NSMutableArray *currentCode;

@end

@implementation SCUSwipeView (Private)

SAVSynthesizeCategoryProperty(code, setCode, NSArray *, OBJC_ASSOCIATION_COPY_NONATOMIC)
SAVSynthesizeCategoryProperty(currentCode, setCurrentCode, NSMutableArray *, OBJC_ASSOCIATION_RETAIN_NONATOMIC)

- (void)didSwipeWithDirection:(SCUSwipeViewDirection)direction
{
    if (!self.code)
    {
        self.code = @[@(SCUSwipeViewDirectionUp),
                      @(SCUSwipeViewDirectionUp),
                      @(SCUSwipeViewDirectionDown),
                      @(SCUSwipeViewDirectionDown),
                      @(SCUSwipeViewDirectionLeft),
                      @(SCUSwipeViewDirectionRight),
                      @(SCUSwipeViewDirectionLeft),
                      @(SCUSwipeViewDirectionRight)];

        self.currentCode = [self.code mutableCopy];
    }

    if ([[self.currentCode firstObject] unsignedIntegerValue] == direction)
    {
        [self.currentCode removeObjectAtIndex:0];

        if (![self.currentCode count])
        {
            UIView *app = self;
            CGAffineTransform transform = app.transform;

            [UIView animateWithDuration:.4 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                app.transform = CGAffineTransformMakeRotation(-M_PI);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:.4 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    app.transform = CGAffineTransformConcat(app.transform, CGAffineTransformMakeRotation(-M_PI));
                } completion:^(BOOL finished) {
                    app.transform = transform;

                    //-------------------------------------------------------------------
                    // TODO: find a better way to do this that doesn't require crashing
                    //-------------------------------------------------------------------
//                    [NSUserDefaults sav_modifyDefaults:^(NSUserDefaults *defaults) {
//                        [defaults setBool:YES forKey:@"invert"];
//                    }];
//
//                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                        exit(0);
//                    });

                }];
            }];

            self.currentCode = [self.code mutableCopy];
        }
    }
    else
    {
        self.currentCode = [self.code mutableCopy];
    }
}

@end
