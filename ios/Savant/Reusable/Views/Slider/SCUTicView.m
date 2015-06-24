//
//  SCUTicView.m
//  SavantController
//
//  Created by David Fairweather on 4/14/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUTicView.h"
@import Extensions;

@interface SCUTicView ()

//-------------------------------------------------------------------
// The normal height and width for each tic. For alternative height,
// We can just set the added length within the .m
// Default is set to 1 X 50
//-------------------------------------------------------------------
@property (nonatomic) CGFloat ticWidth;

@property (nonatomic) NSInteger scaleUnits; //2 * The number of tics that will be displayed

@property (nonatomic) NSMutableDictionary *labels;

@property (nonatomic) NSMutableArray *tics;

@property (nonatomic) CGFloat labelWidth;

@property (nonatomic) CGFloat labelHeight;

@property (nonatomic) CGFloat kConst;

@property (nonatomic) NSUInteger majorTics;

@property (nonatomic) NSUInteger minorTics;

@property (nonatomic) NSUInteger lowestValue;

@property (nonatomic) NSUInteger integerConversionFactor;

@end

@implementation SCUTicView

- (instancetype)initWithFrame:(CGRect)frame withScaleOf:(CGFloat)scale andOffsetOf:(NSInteger)offset majorTicsAt:(NSUInteger)majorTics minorTicsAt:(NSUInteger)minorTics integerConversionFactor:(NSUInteger)integerConversionFactor
{
    self = [self initWithFrame:frame withScaleOf:scale andOffsetOf:offset withOrientation:SCUSlideViewOrientationHorizontal];
    if (self)
    {
        self.majorTics = majorTics;

        if (0 == minorTics)
        {
            self.minorTics = majorTics;
        }
        else
        {
            self.minorTics = minorTics;
        }
        
        self.kConst = (offset % self.minorTics);
        self.lowestValue = offset;
        self.integerConversionFactor = integerConversionFactor;

        self.labels = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame withScaleOf:(CGFloat)scale andOffsetOf:(NSInteger)offset withOrientation:(NSInteger)orientation
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.majorTics = 10;
        self.minorTics = 2;
        self.ticWidth = 2.0f;

        // Initialization code
        self.ticHeight = [UIDevice isPad] ? 35.0f : 21.0f;
        self.edgePadding = [UIDevice isPad] ? 30.0f : 10.0f;
        
        self.labelHeight = [UIDevice isPad] ? 25.0f : 15.0f;
        self.labelWidth = [UIDevice isPad] ? 50.0f : 30.0f;
        
        //determines max number of tics for slider
        if (scale < 35)
        {
            self.scaleUnits = 2 * scale;
            self.kConst = ((offset * 2) % self.majorTics);
        }
        else
        {
            self.kConst = (offset % self.majorTics);
            self.scaleUnits = scale;
        }

        self.ticOffset = 0;
        self.integerConversionFactor = 1;
        self.orientation = orientation;
        self.tics = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    //-------------------------------------------------------------------
    //  The spacing between tics can be solved using a simplified speed equation!
    //  X = (final tic position + starting tic position) / number of tics
    //  where X is the spacing between tics
    //-------------------------------------------------------------------
    CGFloat x, y, width, height;
    CGFloat spacing;
    CGFloat largeTicModifier = 15.0f;
    NSUInteger kConst = self.kConst;
    
    //-------------------------------------------------------------------
    // Repositions the sublayers according to orientation
    //-------------------------------------------------------------------
    if (self.orientation == SCUSlideViewOrientationVertical)
    {
        self.edgePadding = [UIDevice isPad] ? 4.0f : 2.0f;

        spacing = (CGRectGetHeight(self.bounds) - (self.edgePadding * 2)) / (CGFloat)self.scaleUnits;

        x = CGRectGetMaxX(self.bounds) - self.ticHeight - self.ticOffset;
        y = CGRectGetMinY(self.bounds) + self.edgePadding; //Changes over time
        width = self.ticHeight;
        height = self.ticWidth;
    }
    else
    {
        CGFloat numberOfTics = (CGFloat)self.scaleUnits;
        CGFloat totalWidth = self.frame.size.width;
        spacing = (totalWidth - (self.edgePadding * 2)) / numberOfTics;
        x = self.edgePadding; //Changes over time
        y = CGRectGetMaxY(self.bounds) - self.ticHeight;
        self.ticWidth = 1.0f;
        width = self.ticWidth;
        height = self.ticHeight;
    }
    
    CGFloat ticX;
    CGFloat ticY;
    CGFloat ticWidth;
    if ([self.tics count] > 0)
    {
        [CATransaction begin];
        [CATransaction setAnimationDuration:[UIDevice rotationSpeed]];
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        NSArray *subViews = self.tics;
        
        for (NSInteger i = 0; i <= self.scaleUnits; ++i)
        {
            if (kConst % self.minorTics == 0)
            {
                NSUInteger arrayIndex = (i / self.minorTics);
                CALayer *layer = subViews[arrayIndex];
                if (self.orientation == SCUSlideViewOrientationVertical)
                {
                    ticY = y + (i * spacing);
                    
                    if (kConst % self.majorTics == 0)
                    {
                        ticX = x - largeTicModifier;
                    }
                    else
                    {
                        ticX = x;
                    }
                }
                else
                {
                    ticY = y;
                    ticX = x + (i * spacing);
                }
                layer.frame = CGRectMake(ticX, ticY, CGRectGetWidth(layer.bounds), CGRectGetHeight(layer.bounds));
                NSInteger labelValue = i + self.lowestValue;
                if (labelValue % self.majorTics == 0 && (self.orientation == SCUSlideViewOrientationHorizontal))
                {
                    UILabel *label = self.labels[[@(kConst) stringValue]];
                    if (label)
                    {
                        label.center = CGPointMake(CGRectGetMidX(layer.frame), CGRectGetMaxY(layer.frame) + label.frame.size.height / 2);
                    }
                }
            }
            ++kConst;
        }
        [CATransaction commit];
    }
    else
    {
        for (NSInteger i = 0; i <= self.scaleUnits; ++i)
        {
            if (kConst % self.minorTics == 0)
            {
                CALayer *newLayer = [[CALayer alloc] init];
                if (self.orientation == SCUSlideViewOrientationVertical)
                {
                    ticY = y + (i * spacing);
                    if (kConst % self.majorTics == 0)
                    {
                        ticX = x - largeTicModifier;
                        ticWidth = width + largeTicModifier;
                        kConst = self.majorTics;
                    }
                    else
                    {
                        ticX = x;
                        ticWidth = width;
                    }
                }
                else
                {
                    ticY = y;
                    ticX = x + (i * spacing);
                    ticWidth = width;
                }
                
                newLayer.frame = CGRectMake(ticX, ticY, ticWidth, height);
                
                if (self.orientation == SCUSlideViewOrientationHorizontal)
                {
                    if (kConst % (2 * self.minorTics) == 0)
                    {
                        newLayer.backgroundColor = self.ticColor.CGColor;
                    }
                    else
                    {
                        newLayer.backgroundColor = self.ticAlternateColor.CGColor;
                    }
                }
                else
                {
                    newLayer.backgroundColor = self.ticColor.CGColor;
                }
                
                [self.layer addSublayer:newLayer];
                [self.tics addObject:newLayer];
                NSInteger labelValue = i + self.lowestValue;
                if (labelValue % self.majorTics == 0 && (self.orientation == SCUSlideViewOrientationHorizontal))
                {
                    UILabel *label = [self radioScaleLabelForValue:labelValue / self.integerConversionFactor];
                    label.center = CGPointMake(CGRectGetMidX(newLayer.frame), CGRectGetMaxY(newLayer.frame) + label.frame.size.height / 2);
                    [self.labels setObject:label forKey:[@(kConst) stringValue]];
                }
            }
            ++kConst;
        }
    }
}

- (void)addNumberOfTics:(NSInteger)num
{
    self.scaleUnits = 2 * num;
}

//-------------------------------------------------------------------
// Create the lables for the slider view in radio
//-------------------------------------------------------------------
- (UILabel *)radioScaleLabelForValue:(NSInteger)value
{
    //CGRectMake(CGRectGetMidX(selected.frame) - (self.labelWidth / 2), CGRectGetHeight(self.bounds), self.labelWidth, self.labelHeight)
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    
    label.font = [UIFont fontWithName:@"Gotham" size:([UIDevice isPad] ? 15.0f : 12.0f)];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor sav_colorWithRGBValue:0xABABAB];
    label.text = [NSString stringWithFormat:@"%ld", (long)value];
    [label sizeToFit];
    [self addSubview:label];
    
    return label;
}

- (void)changeScale:(CGFloat)scale andOffsetOf:(NSInteger)offset majorTicsAt:(NSUInteger)majorTics minorTicsAt:(NSUInteger)minorTics integerConversionFactor:(NSUInteger)integerConversionFactor
{
    self.majorTics = majorTics;
    if (0 == minorTics)
    {
        self.minorTics = majorTics;
    }
    else
    {
        self.minorTics = minorTics;
    }
    self.kConst = (offset % self.minorTics);
    self.lowestValue = offset;
    self.integerConversionFactor = integerConversionFactor;
    self.scaleUnits = scale;
    
    if (self.labels)
    {
        for (UILabel *label in [self.labels allValues])
        {
            [label removeFromSuperview];
        }
        [self.labels removeAllObjects];
    }
    self.labels = [[NSMutableDictionary alloc] init];
    
    if (self.tics)
    {
        for (CALayer *tic in self.tics)
        {
            [tic removeFromSuperlayer];
        }
        [self.tics removeAllObjects];
    }
    self.tics = [[NSMutableArray alloc] init];
    [self layoutSubviews];
}

- (void)changeScaleWithLowestValue:(NSInteger)lowValue andHighValue:(NSInteger)highValue
{
    self.lowestValue = lowValue;
    self.scaleUnits = highValue - lowValue;
    
    if (self.scaleUnits < 35)
    {
        self.scaleUnits *= 2;
        self.lowestValue *= 2;
    }
    self.kConst = (self.lowestValue % self.majorTics);

    if (self.tics)
    {
        for (CALayer *tic in self.tics)
        {
            [tic removeFromSuperlayer];
        }
        [self.tics removeAllObjects];
    }
    self.tics = [[NSMutableArray alloc] init];
    [self layoutSubviews];
}

- (void)setOrientation:(NSInteger)orientation
{
    _orientation = orientation;
    if (self.orientation == SCUSlideViewOrientationVertical)
    {
        self.ticOffset = ([UIDevice isPad] ? (self.ticHeight * 2): 50);
        self.ticColor = self.ticAlternateColor = [UIColor colorWithWhite:1 alpha:0.3];
    }
    else
    {
        self.ticOffset = 0;
        self.ticAlternateColor = [UIColor sav_colorWithRGBValue:0x4b4b4b];
        self.ticColor = [UIColor sav_colorWithRGBValue:0x6b6b6b];
    }
}

@end
