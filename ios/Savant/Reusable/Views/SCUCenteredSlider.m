//
//  SCUBiDirectionalSlider.m
//  SavantController
//
//  Created by Cameron Pulsford on 5/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUCenteredSlider.h"
#import "SCUSliderPrivate.h"

@interface SCUCenteredSlider ()

@end

@implementation SCUCenteredSlider

#pragma mark - Private

- (void)updateFillWithPercentage:(CGFloat)percentage
{
    CGRect fillFrame = self.trackView.frame;
    CGFloat fillFrameWidth = CGRectGetWidth(fillFrame);
    CGFloat fillFrameHalfWidth = fillFrameWidth / 2;

    BOOL hidden = NO;

    if (percentage < .5)
    {
        fillFrame.origin.x = fillFrameWidth * percentage;
        fillFrame.size.width = fillFrameHalfWidth - CGRectGetMinX(fillFrame);
    }
    else if (percentage > .5)
    {
        fillFrame.origin.x = fillFrameHalfWidth;
        fillFrame.size.width = fillFrameWidth * (percentage - .5);
    }
    else
    {
        hidden = YES;
        fillFrame.origin.x = fillFrameHalfWidth;
        fillFrame.size.width = 0;
    }

    self.fillView.frame = CGRectIntegral(fillFrame);
    self.fillView.hidden = hidden;
}

- (CGPoint)normalizedPointFromPoint:(CGPoint)point isTap:(BOOL)isTap
{
    CGPoint normalizedPoint = point;

    if (isTap)
    {
        CGFloat midX = CGRectGetMidX(self.trackView.bounds);

        if (point.x > midX - self.centerTapThreshold && point.x < midX + self.centerTapThreshold)
        {
            normalizedPoint.x = midX;
        }
    }

    return normalizedPoint;
}

#pragma mark - Callbacks

- (void)callCallback
{
    if (self.callback)
    {
        self.callback(self);
    }
}

@end
