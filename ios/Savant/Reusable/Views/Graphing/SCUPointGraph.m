//
//  SCUPointGraph.m
//  SavantController
//
//  Created by Nathan Trapp on 7/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUPointGraph.h"
#import "SCUGraphSubclass.h"

@import Extensions;

@interface SCUPointGraph ()

@property NSArray *pointViews;

@end

@implementation SCUPointGraph

- (void)drawPointsData:(BOOL)animated
{
    [super drawPointsData:animated];

    [self.pointViews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    NSMutableArray *pointViews = [NSMutableArray array];

    SCUGraphPoint *previousPoint = nil;

    for (SCUGraphPoint *point in self.points)
    {
        if (previousPoint.y != point.y || !previousPoint)
        {
            UIView *pointView = [self pointViewWithValue:point.value];

            if ((point.x / 2) <= CGRectGetWidth(pointView.frame))
            {
                CGRect frame = pointView.frame;
                frame.origin = point.point;
                pointView.frame = frame;
            }
            else
            {
                pointView.center = point.point;
            }

            [self addSubview:pointView];
            [pointViews addObject:pointView];
        }

        previousPoint = point;
    }

    if (animated)
    {
        CGFloat duration = 1.0 / [pointViews count];
        CGFloat delay = 0;

        for (UIView *pointView in pointViews)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:duration animations:^{
                    pointView.alpha = 1;
                }];
            });

            delay += duration;
        }
    }
    else
    {
        [UIView animateWithDuration:animated animations:^{
            for (UIView *pointView in pointViews)
            {
                pointView.alpha = 1;
            }
        }];
    }
    
    self.pointViews = pointViews;
}

- (UIView *)pointViewWithValue:(CGFloat)value
{
    UIView *pointView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.pointSize.width, self.pointSize.height)];
    pointView.backgroundColor = self.pointColor;
    pointView.alpha = 0;

    if (self.pointRadius)
    {
        pointView.layer.cornerRadius = self.pointRadius;
        pointView.clipsToBounds = YES;
    }

    if (self.displayLabel)
    {
        UILabel *pointLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        pointLabel.text = [NSString stringWithFormat:@"%ld", (unsigned long)value];
        pointLabel.font = self.labelFont;
        pointLabel.textColor = self.labelColor;

        [pointView addSubview:pointLabel];
        [pointView sav_addCenteredConstraintsForView:pointLabel];
    }

    return pointView;
}

@end
