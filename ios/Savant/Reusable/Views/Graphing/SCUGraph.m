//
//  SCUGraph.m
//  SavantController
//
//  Created by Nathan Trapp on 7/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUGraphSubclass.h"
#import "SCUOnOffGraph.h"
#import "SCUPointGraph.h"

@import Extensions;

@interface SCUGraph ()

@property id observer;

@end

@implementation SCUGraph

+ (Class)layerClass
{
    return [CAShapeLayer class];
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.clipsToBounds = YES;

        SAVWeakSelf;
        self.observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillChangeStatusBarOrientationNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [wSelf reloadData:NO];
            });
        }];
    }
    return self;
}

- (void)dealloc
{
    if (self.observer)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self.observer];
    }
}

- (BOOL)allowZeroValues
{
    return NO;
}

- (void)buildPointsData:(dispatch_block_t)completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSUInteger numberOfPoints = [self.dataSource numberOfVerticalValuesInGraph:self];

        CGFloat horizontalScaleFactor = CGRectGetWidth(self.bounds) / numberOfPoints;

        NSMutableArray *points = [NSMutableArray array];

        for (NSUInteger i = 0; i < numberOfPoints; i++)
        {
            CGFloat y = [self.dataSource graph:self verticalValueForHorizontalIndex:i];

            if (y > 0 || [self allowZeroValues])
            {
                SCUGraphPoint *point = [[SCUGraphPoint alloc] init];
                point.value = y;
                
                y = [self normalizedHeightForRawHeight:y];
                CGFloat x = horizontalScaleFactor * i;

                point.x = x;
                point.y = y;

                [points addObject:point];
            }
        }

        self.points = points;

        if (self.smoothing)
        {
            for (SCUGraphPoint *point in self.points)
            {
                point.y = [self movingVerticalAverage:point pointsBefore:5 pointsAfter:5];
            }
        }

        completion();
    });
}

- (CGFloat)normalizedHeightForRawHeight:(CGFloat)rawHeight
{
    if ((self.maximumValue - self.minimumValue) <= 0)
    {
        return 0;
    }

    return CGRectGetHeight(self.bounds) - ((rawHeight - self.minimumValue) / (self.maximumValue - self.minimumValue)) * CGRectGetHeight(self.bounds);
}

- (CGFloat)movingVerticalAverage:(SCUGraphPoint *)point pointsBefore:(NSInteger)before pointsAfter:(NSInteger)after
{
    CGFloat average = 0;
    CGFloat sum = 0;
    NSInteger count = 0;

    NSInteger position = [self.points indexOfObject:point];

    for (NSInteger i = (position + after); i > (position - before); i--)
    {
        if (i > 0 && i < ((NSInteger)[self.points count] - 1))
        {
            SCUGraphPoint *p = self.points[i];
            sum += p.y;
            count++;
        }
    }

    if (count)
    {
        average = sum / count;
    }
    else
    {
        average = point.y;
    }

    return average;
}

- (void)reloadData:(BOOL)animated
{
    self.layer.path = nil;

    [self buildPointsData:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self drawPointsData:animated];
        });
    }];
}

- (void)drawPointsData:(BOOL)animated
{
    if (self.lineWidth && self.lineColor)
    {
        UIBezierPath *path = nil;

        for (SCUGraphPoint *point in self.points)
        {
            if (!path)
            {
                path = [UIBezierPath bezierPath];
                [path moveToPoint:point.point];
            }
            else
            {
                [path addLineToPoint:point.point];
            }
        }

        [self styleLayer];

        self.layer.path = path.CGPath;

        if (animated)
        {
            [self animatePath];
        }
    }
}

- (void)animatePath
{
    CABasicAnimation *drawPath = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    drawPath.delegate = self;
    drawPath.fromValue = @0;
    drawPath.toValue = @1;
    drawPath.duration = 1;
    drawPath.fillMode = kCAFillModeForwards;
    drawPath.removedOnCompletion = YES;
    [self.layer addAnimation:drawPath forKey:nil];
}

- (void)styleLayer
{
    self.layer.lineWidth = self.lineWidth;
    self.layer.strokeColor = self.lineColor.CGColor;
    self.layer.fillColor = [UIColor clearColor].CGColor;

    if (self.smoothing)
    {
        self.layer.lineCap = kCALineCapRound;
        self.layer.lineJoin = kCALineJoinRound;
    }
    else
    {
        self.layer.lineCap = kCALineCapButt;
        self.layer.lineJoin = kCALineJoinMiter;
    }

    switch (self.lineStyle)
    {
        case SCUGraphStyle_Standard:
            break;
        case SCUGraphStyle_Dashed:
            self.layer.lineDashPattern = @[@4, @4];
            break;
        case SCUGraphStyle_Dotted:
            self.layer.lineDashPattern = @[@2, @6];
            self.layer.lineCap = kCALineCapRound;
            self.layer.lineJoin = kCALineJoinRound;
            break;
    }
}

@end

@implementation SCUGraphPoint

- (CGPoint)point
{
    return CGPointMake(self.x, self.y);
}

- (NSString *)description
{
    return NSStringFromCGPoint(self.point);
}

@end