//
//  SCUGradientView.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/17/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUGradientLayer.h"
@import Extensions;

@interface SCUGradientLayer ()

@property NSArray *cgColors;

@end

@implementation SCUGradientLayer

- (instancetype)initWithFrame:(CGRect)frame andColors:(NSArray *)colors
{
    self = [super init];

    if (self)
    {
        self.frame = frame;
        self.startPoint = CGPointMake(.5, 0);
        self.endPoint = CGPointMake(.5, 1);
        self.colors = colors;
    }

    return self;
}

- (void)drawInContext:(CGContextRef)ctx
{
    if (self.hidden)
    {
        return;
    }
    
    if ([self.colors count] >= 2)
    {
        CGFloat *locations = NULL;

        if ([self.locations count])
        {
            NSAssert(self.colors.count == self.locations.count, @"The number of locations must be equal to the number of colors, or nil");

            locations = malloc(sizeof(CGFloat) * self.locations.count);

            for (NSUInteger i = 0; i < self.locations.count; i++)
            {
                locations[i] = [self.locations[i] floatValue];
            }
        }

        CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();
        CGGradientRef gradient = CGGradientCreateWithColors(baseSpace, (CFArrayRef)self.cgColors, locations);

        if (self.radial)
        {
            CGFloat endRadius = CGRectGetHeight(self.bounds) + self.endRadius;
            CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
            CGContextDrawRadialGradient(ctx, gradient, center, self.startRadius, center, endRadius, kCGGradientDrawsAfterEndLocation);
        }
        else
        {
            CGPoint startPoint = CGPointMake(self.startPoint.x * CGRectGetWidth(self.bounds), self.startPoint.y * CGRectGetHeight(self.bounds));
            CGPoint endPoint = CGPointMake(self.endPoint.x * CGRectGetWidth(self.bounds), self.endPoint.y * CGRectGetHeight(self.bounds));
            CGContextDrawLinearGradient(ctx, gradient, startPoint, endPoint, kCGGradientDrawsAfterEndLocation);
        }

        CGColorSpaceRelease(baseSpace);
        CGGradientRelease(gradient);

        if (locations)
        {
            free(locations);
        }
    }
}

#pragma mark - Properties

- (void)setColors:(NSArray *)colors
{
    _colors = colors;

    self.cgColors = [colors arrayByMappingBlock:^id(UIColor *color) {
        return (id)color.CGColor;
    }];

    [self setNeedsDisplay];
}

- (void)setLocations:(NSArray *)locations
{
    _locations = locations;
    [self setNeedsDisplay];
}

- (void)setRadial:(BOOL)radial
{
    if (radial == _radial)
    {
        return;
    }

    _radial = radial;
    [self setNeedsDisplay];
}

- (void)setStartPoint:(CGPoint)startPoint
{
    _startPoint = startPoint;
    [self setNeedsDisplay];
}

- (void)setEndPoint:(CGPoint)endPoint
{
    _endPoint = endPoint;
    [self setNeedsDisplay];
}

- (void)setStartRadius:(CGFloat)startRadius
{
    _startRadius = startRadius;
    [self setNeedsDisplay];
}

- (void)setEndRadius:(CGFloat)endRadius
{
    _endRadius = endRadius;
    [self setNeedsDisplay];
}

- (void)setHidden:(BOOL)hidden
{
    if (!hidden && hidden != self.hidden)
    {
        [self setNeedsDisplay];
    }

    [super setHidden:hidden];
}

@end
