//
//  UIScrollView+SAVExtensions.m
//  SavantExtensions
//
//  Created by Nathan Trapp on 7/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "UIScrollView+SAVExtensions.h"

@implementation UIScrollView (SAVExtensions)

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated completion:(void (^)(BOOL finished))completion
{
    if (animated)
    {
        [UIView animateWithDuration:0.4f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.contentOffset = contentOffset;
                         }
                         completion:completion];
    }
    else
    {
        self.contentOffset = contentOffset;
        completion(YES);
    }
}

@end
