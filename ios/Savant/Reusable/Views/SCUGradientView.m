//
//  SCUGradientView.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/17/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUGradientView.h"
#import "SCUGradientLayer.h"
@import Extensions;
@import QuartzCore;

@interface SCUGradientView ()

@property (nonatomic) SCUGradientLayer *gradientLayer;

@end

@implementation SCUGradientView

+ (NSArray *)standardGradient
{
    return @[[UIColor sav_colorWithRGBValue:0x131314], [UIColor sav_colorWithRGBValue:0x2d2b2c]];
}

+ (NSArray *)standardInnerGradient
{
    return @[[UIColor sav_colorWithRGBValue:0x343434], [UIColor sav_colorWithRGBValue:0x373737]];
}

+ (NSArray *)standardRadialGradient
{
    return @[[UIColor sav_colorWithRGBValue:0x4e4e4e], [UIColor sav_colorWithRGBValue:0x202020]];
}

- (instancetype)initWithFrame:(CGRect)frame andColors:(NSArray *)colors
{
    self = [super initWithFrame:frame];

    if (self)
    {
        self.startPoint = CGPointMake(.5, 0);
        self.endPoint = CGPointMake(.5, 1);
        self.colors = colors;
        self.gradientLayer = [[SCUGradientLayer alloc] initWithFrame:frame andColors:colors];
        [self.layer addSublayer:self.gradientLayer];
    }

    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.gradientLayer.frame = self.bounds;
}

#pragma mark - Properties

- (void)setColors:(NSArray *)colors
{
    _colors = colors;
    self.gradientLayer.colors = colors;
}

- (void)setLocations:(NSArray *)locations
{
    _locations = locations;
    self.gradientLayer.locations = locations;
}

- (void)setRadial:(BOOL)radial
{
    if (radial == _radial)
    {
        return;
    }

    _radial = radial;
    self.gradientLayer.radial = radial;
}

- (void)setStartPoint:(CGPoint)startPoint
{
    _startPoint = startPoint;
    self.gradientLayer.startPoint = startPoint;
}

- (void)setEndPoint:(CGPoint)endPoint
{
    _endPoint = endPoint;
    self.gradientLayer.endPoint = endPoint;
}

- (void)setStartRadius:(CGFloat)startRadius
{
    _startRadius = startRadius;
    self.gradientLayer.startRadius = startRadius;
}

- (void)setEndRadius:(CGFloat)endRadius
{
    _endRadius = endRadius;
    self.gradientLayer.endRadius = endRadius;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if ([self.touchDelegate respondsToSelector:@selector(hitTest:withEvent:)])
    {
        return [self.touchDelegate hitTest:point withEvent:event];
    }
    else
    {
        return [super hitTest:point withEvent:event];
    }
}

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    self.gradientLayer.hidden = hidden;
}

@end
