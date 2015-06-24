//
//  SCUOnOffGraph.m
//  SavantController
//
//  Created by Nathan Trapp on 7/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUOnOffGraph.h"
#import "SCUGraphSubclass.h"

@implementation SCUOnOffGraph

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.maximumValue = 1;
        self.minimumValue = 0;
    }
    return self;
}

- (BOOL)allowZeroValues
{
    return YES;
}

- (void)drawPointsData:(BOOL)animated
{
    if (self.lineWidth && self.lineColor)
    {
        UIBezierPath *path = [UIBezierPath bezierPath];

        CGFloat previousValue = 0;

        for (SCUGraphPoint *point in self.points)
        {
            if (point.y)
            {
                if (previousValue)
                {
                    [path addLineToPoint:point.point];
                }
                else
                {
                    [path moveToPoint:point.point];
                }
            }

            previousValue = point.y;
        }

        [self styleLayer];

        self.layer.path = path.CGPath;

        if (animated)
        {
            [self animatePath];
        }
    }
}

- (CGFloat)normalizedHeightForRawHeight:(CGFloat)rawHeight
{
    return rawHeight;
}

@end
