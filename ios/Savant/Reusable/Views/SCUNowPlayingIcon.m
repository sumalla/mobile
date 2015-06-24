//
//  SCUNowPlayingIcon.m
//  SavantController
//
//  Created by Nathan Trapp on 8/25/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUNowPlayingIcon.h"

@import Extensions;

@interface SCUNowPlayingIcon ()

@property NSMutableArray *lineViews;
@property NSUInteger firstIndex;
@property (nonatomic, getter = isAnimating) BOOL animating;
@property NSArray *lineHeights;
@property BOOL hasInitialFrames;

@end

@implementation SCUNowPlayingIcon

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.lineViews = [NSMutableArray array];
        self.numberOfLines = 4;
        self.animationDuration = .6;

        [self startAnimating];
    }
    return self;
}

- (void)startAnimating
{
    if (!self.animating)
    {
        self.animating = YES;
        [self repeatingAnimation];
    }
}

- (void)repeatingAnimation
{
    [self.layer removeAllAnimations];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];

    CGFloat duration = self.animationDuration / self.numberOfLines;

    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self updateLinesHeights];
                         [self setNeedsLayout];
                         [self layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         if (self.animating)
                         {
                             if (finished)
                             {
                                 [self performSelector:_cmd withObject:nil afterDelay:0 inModes:@[NSRunLoopCommonModes]];
                             }
                             else
                             {
                                 [self performSelector:_cmd withObject:nil afterDelay:0.1 inModes:@[NSRunLoopCommonModes]];
                             }
                         }
                     }];
}

- (void)stopAnimating
{
    self.animating = NO;
    [self.layer removeAllAnimations];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];
}

- (void)setAnimationDuration:(CGFloat)animationDuration
{
    _animationDuration = animationDuration;
}

- (void)setNumberOfLines:(NSUInteger)numberOfLines
{
    _numberOfLines = numberOfLines;

    [self prepareLines];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat width = floorf(1.0 / self.numberOfLines * (CGRectGetWidth(self.bounds) - (self.numberOfLines * 2)));
    CGFloat halfHeight = CGRectGetHeight(self.bounds) / 2;

    for (UIView *lineView in self.lineViews)
    {
        NSDictionary *heightDict = self.lineHeights[[self.lineViews indexOfObject:lineView]];
        CGFloat lineHeightScale = [heightDict[@"height"] floatValue];

        CGRect frame = lineView.frame;
        frame.origin.x = (width + 2) * [self.lineViews indexOfObject:lineView];
        frame.size.width = width;
        CGFloat height = floorf(CGRectGetHeight(self.bounds) * lineHeightScale);
        frame.size.height = height;
        frame.origin.y = halfHeight - (height / 2);
        lineView.frame = frame;
    }
}

- (void)updateLinesHeights
{
    NSMutableArray *lineHeights = [NSMutableArray array];

    CGFloat heightUnit = 1 / (CGFloat)self.numberOfLines;

    for (NSDictionary *heightDict in self.lineHeights)
    {
        BOOL increasing = [heightDict[@"increasing"] boolValue];
        CGFloat lineHeight = [heightDict[@"height"] floatValue];

        if (lineHeight == 1)
        {
            lineHeight = lineHeight - heightUnit;
        }
        else if (lineHeight == heightUnit)
        {
            lineHeight = lineHeight + heightUnit;
        }
        else
        {
            BOOL increase = arc4random_uniform(2);
            lineHeight = lineHeight + (heightUnit * (increase ? 1 : -1));
        }

        //-------------------------------------------------------------------
        // Use this for not random values..
        //-------------------------------------------------------------------
//        if (increasing)
//        {
//            lineHeight += heightUnit;
//
//            if (lineHeight >= 1)
//            {
//                increasing = NO;
//            }
//        }
//        else
//        {
//            lineHeight -= heightUnit;
//
//            if (lineHeight <= heightUnit)
//            {
//                increasing = YES;
//            }
//        }

        [lineHeights addObject:@{@"increasing": @(increasing),
                                 @"height": @(lineHeight)}];
    }

    self.lineHeights = lineHeights;
}

- (void)prepareLines
{
    [self.lineViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.lineViews removeAllObjects];

    NSMutableArray *lineHeights = [NSMutableArray array];

    for (NSUInteger i = 0; i < self.numberOfLines; i++)
    {
        CGFloat height = (i + 1) / (CGFloat)self.numberOfLines;
        [lineHeights addObject:@{@"increasing": height == 1 ? @NO : @YES,
                                 @"height": @(height)}];

        UIView *lineView = [[UIView alloc] init];
        lineView.backgroundColor = [[SCUColors shared] color01];

        [self addSubview:lineView];

        [self.lineViews addObject:lineView];
    }

    self.lineHeights = lineHeights;

    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end
