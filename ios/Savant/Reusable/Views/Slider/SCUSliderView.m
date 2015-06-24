//
//  SCUSliderView.m
//  SavantController
//
//  Created by David Fairweather on 4/14/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSliderView.h"
@import Extensions;

//#define VISIBLE_BOUNDS  15
#define sentinelValue -1000000
#define isValaidValue(value) (fabs((float)value - sentinelValue) > 0.0001 && fabs((float)value - NSNotFound) > 0.001)

NSString *const SCUSliderCurrentValue = @"SCUSliderCurrentValue";
NSString *const SCUSliderHighSetPoint = @"SCUSliderHighSetPoint";
NSString *const SCUSliderLowSetPoint = @"SCUSliderLowSetPoint";
NSString *const SCUSliderMiddleSetPoint = @"SCUSliderMiddleSetPoint";

@interface SCUSliderView () <UIGestureRecognizerDelegate>

//-------------------------------------------------------------------
// stores the scaling and values for the slider when given by the
// view controller
//-------------------------------------------------------------------
@property (nonatomic) CGFloat scaleValue;

//@property (nonatomic) CGFloat highestVisibleValue;
//@property (nonatomic) CGFloat lowestVisibleValue;

@property (nonatomic) SCUSliderViewConfiguration configuration;

@property (nonatomic) UIView *desiredSliderHandle;
@property (nonatomic) UIView *lowSliderHandle;
@property (nonatomic) UIView *highSliderHandle;


@property (nonatomic) UILabel *visibleHighLabel;
@property (nonatomic) UILabel *visibleLowLabel;
@property (nonatomic) NSString *visibleHighLabelText;
@property (nonatomic) NSString *visibleLowLabelText;

@property (nonatomic) UIView *controlledHandle;

@property (nonatomic) BOOL isHeld;
@property (nonatomic) BOOL canReciveOutSideSetPoints;

@property (nonatomic) UIGestureRecognizerState lastTouch;


@property (nonatomic) CGFloat desiredAlpha;
@property (nonatomic) CGFloat currentAlpha;

@property (nonatomic) SCUSliderSetPointMode mode;

@property (nonatomic) NSArray *desiredHandleConstraintsForSingleSetPoint;
@property (nonatomic) NSArray *desiredHandleConstraintsForDualSetPoint;

@property (nonatomic, weak) NSTimer *setPointTimer;

@property (nonatomic) CGFloat labelHeight;

@property (nonatomic) CGPoint lastTocuhLocation;

@property (nonatomic) CGFloat animationDuration;

@end

@implementation SCUSliderView

- (instancetype)initWithFrame:(CGRect)frame andConfiguration:(SCUSliderViewConfiguration)config
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        self.holdDelay = .02f;
        self.configuration = config;
        _desiredValue = sentinelValue;
        _highSliderValue = sentinelValue;
        _lowSliderValue = sentinelValue;
        _currentValue = sentinelValue;
        self.minDeadband = 3;
        self.animationDuration = 0;
        self.mode = SCUSliderSetPointModeOff;
        self.isHeld = NO;
        self.canReciveOutSideSetPoints = YES;
        self.setPointPopUp = NO;
        
        self.longPressControlRange = 20.0f;
        
        self.scaleValue = 1;

        if ([self isVertical])
        {
            self.labelHeight = [UIDevice isPad] ? 35.0f : 28.0f;
            self.scaleGranularity = 1;
        }
        else
        {
            self.desiredAlpha = 1.0;
            self.scaleGranularity = 0;
            self.labelHeight = 0;//may not be zero just don't want to interfer with the raido slider
        }
        if ([self isVertical])
        {
            // self.minimumWidth = desiredHandleHeight + self.ticsView.ticOffset + fudge factor for fat fingers;
            self.minimumWidth = ([UIDevice isPad] ? 100.0f : 50.0f) + ([UIDevice isPad] ? 70: 50) + ([UIDevice isPad] ? 20: 10);
        }
        else
        {
            // self.minimumWidth = desiredHandleHeight + self.ticsView.labelHeight + fudge factor for fat fingers;
            self.minimumWidth = ([UIDevice isPad] ? 100.0f : (45.0f / 1.4f)) + ([UIDevice isPad] ? 25.0f : 15.0f) + ([UIDevice isPad] ? 20: 10);
        }
    }
    return self;
}

//-------------------------------------------------------------------
// This method creates the view based on the initial configuration
// defined by the view controller
//-------------------------------------------------------------------
- (void)configureViewsAndGestures
{
    //-------------------------------------------------------------------
    // Constants that are only needed for this method
    //-------------------------------------------------------------------
    CGFloat desiredHandleWidth = [UIDevice isPad] ? 12.0f : 8.0f;
    CGFloat desiredHandleHeight = [UIDevice isPad] ? 140.0f : ([self isHorizontal] ? 45.0f : 70.0f);
    CGFloat handleSize = [UIDevice isPad] ? 20.0f : 20.0f;
    CGFloat cornerRadius = handleSize / 2.0f;
    
    //-------------------------------------------------------------------
    // The desired slider. Their position should be
    // adjusted by the system each time the view is revealed or rotated
    // (probably through layoutSubviews)
    //-------------------------------------------------------------------
    self.desiredSliderHandle = [[UIView alloc] initWithFrame:CGRectZero];
    self.desiredSliderHandle.backgroundColor = [[SCUColors shared] color02];
    if ([self isHorizontal] && isValaidValue(self.desiredValue) &&
        self.lowestValue < self.desiredValue && self.highestValue > self.desiredValue)
    {
        self.desiredSliderHandle.alpha = 1;
    }
    else
    {
        self.desiredSliderHandle.alpha = 0;
    }
    [self addSubview:self.desiredSliderHandle];
    
    //-------------------------------------------------------------------
    // Create Tics and Handles with constraints
    //-------------------------------------------------------------------
    if ([self isHorizontal])
    {
        [self setTicsViewScaleForRadio];
        desiredHandleWidth = [UIDevice isPad] ? 4.0f : 2.0f;

        [self addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                    metrics:@{@"height": @(desiredHandleHeight),
                                                                              @"width": @(desiredHandleWidth)
                                                                              }
                                                                      views:@{@"desiredHandle": self.desiredSliderHandle}
                                                                    formats:@[@"desiredHandle.width = width",
                                                                              @"desiredHandle.height = height",
                                                                              @"V:[desiredHandle]|"]]];
        
        [self bringSubviewToFront:self.desiredSliderHandle];
    }

    if ([self isVertical])
    {
        self.highSliderHandle = [[UIView alloc] initWithFrame:CGRectZero];
        self.lowSliderHandle = [[UIView alloc] initWithFrame:CGRectZero];
        self.highSliderHandle.alpha = 0;
        self.lowSliderHandle.alpha = 0;
        if ([self isPool])
        {
            self.currentAlpha = 0.3;
        }
        else
        {
            self.currentAlpha = 1;
        }
        self.highSliderHandle.layer.cornerRadius = cornerRadius;
        self.lowSliderHandle.layer.cornerRadius = cornerRadius;
        
        [self addSubview:self.highSliderHandle];
        [self addSubview:self.lowSliderHandle];
        
        self.currentStatusSliderHandle = [[UIView alloc] initWithFrame:CGRectZero];
        self.currentStatusSliderHandle.backgroundColor = [[SCUColors shared] color04];
        
        [self addSubview:self.currentStatusSliderHandle];
        
        self.ticsView = [[SCUTicView alloc] initWithFrame:CGRectZero
                                              withScaleOf:self.scaleValue
                                              andOffsetOf:self.highestValue
                                          withOrientation:SCUSliderViewConfigurationVertical];
        
        [self addSubview:self.ticsView];
        
        CGFloat handlesOffset = (self.ticsView.ticOffset - handleSize) / 2;

        NSDictionary *metrics = @{
                                  @"height": @(desiredHandleHeight),
                                  @"width": @(desiredHandleWidth),
                                  @"offset": @(self.ticsView.ticOffset),
                                  @"handleSize": @(handleSize),
                                  @"handleXOffset": @(handlesOffset)
                                  };
        
        NSDictionary *views = @{
                                @"desiredHandle": self.desiredSliderHandle,
                                @"currentHandle": self.currentStatusSliderHandle,
                                @"lowPoint":self.lowSliderHandle,
                                @"highPoint":self.highSliderHandle
                                };
        
        [self addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                    metrics:metrics
                                                                      views:views
                                                                    formats:@[
                                                                              @"desiredHandle.left = currentHandle.left",
                                                                              @"currentHandle.width = height / 1.4f",
                                                                              @"currentHandle.height = width",
                                                                              @"currentHandle.right = super.right - offset",
                                                                              @"highPoint.width = handleSize",
                                                                              @"highPoint.height = handleSize",
                                                                              @"highPoint.left = currentHandle.right + handleXOffset",
                                                                              
                                                                              @"lowPoint.width = handleSize",
                                                                              @"lowPoint.height = handleSize",
                                                                              @"lowPoint.left = currentHandle.right + handleXOffset"
                                                                              ]
                              ]];
        
        
        self.desiredHandleConstraintsForSingleSetPoint =
        [NSLayoutConstraint sav_constraintsWithOptions:0
                                               metrics:metrics
                                                 views:views
                                               formats:@[
                                                         @"desiredHandle.width = height / 1.4f",
                                                         @"desiredHandle.height = width",
                                                         ]];
        
        self.desiredHandleConstraintsForDualSetPoint =
        [NSLayoutConstraint sav_constraintsWithOptions:0
                                               metrics:nil
                                                 views:views
                                               formats:@[
                                                         @"[desiredHandle]|",
                                                         // @"desiredHandle.top = highPoint.centerY",
                                                         // @"desiredHandle.bottom = lowPoint.centerY"
                                                         ]];
        //-------------------------------------------------------------------
        // Makes sure adjustable handles are brought to front of tic view
        //-------------------------------------------------------------------
        [self bringSubviewToFront:self.currentStatusSliderHandle];
        [self bringSubviewToFront:self.desiredSliderHandle];
        [self bringSubviewToFront:self.highSliderHandle];
        [self bringSubviewToFront:self.lowSliderHandle];
        
        if ([self hasMultipleHandles])
        {
            self.desiredAlpha = 0.1;
            if (self.desiredHandleConstraintsForSingleSetPoint)
            {
                [self removeConstraints:self.desiredHandleConstraintsForSingleSetPoint];
            }
            [self addConstraints:self.desiredHandleConstraintsForDualSetPoint];
        }
        else
        {
            if (self.desiredHandleConstraintsForDualSetPoint)
            {
                [self removeConstraints:self.desiredHandleConstraintsForDualSetPoint];
            }
            [self addConstraints:self.desiredHandleConstraintsForSingleSetPoint];
            self.desiredAlpha = 1;
        }
        [self addLabelsToView];
    }
    
    //-------------------------------------------------------------------
    // Create Gestures
    //-------------------------------------------------------------------
    self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    self.longPress.minimumPressDuration = self.holdDelay;
    
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    self.tap.delegate = self;
    self.tap.numberOfTapsRequired = 2;
    [self.tap requireGestureRecognizerToFail:self.longPress];
    [self addGestureRecognizer:self.tap];
    
    if (!([self isTapOnly]))
    {
        [self addGestureRecognizer:self.longPress];
    }
    else
    {
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        singleTap.delegate = self;
        singleTap.numberOfTapsRequired = 1;
        [singleTap requireGestureRecognizerToFail:self.longPress];
        [singleTap requireGestureRecognizerToFail:self.tap];
        [self addGestureRecognizer:singleTap];
    }
}

- (void)setTicsViewScaleForRadio
{
    CGFloat scale = self.scaleValue;
    CGFloat lowestValue = self.lowestValue;
    CGFloat majorTicsAt;
    CGFloat minorTicsAt;
    CGFloat integerConversionFactor = 1;
    if (scale < 100)
    {
        scale *= 10;
        lowestValue *= 10;
        majorTicsAt = 50;
        minorTicsAt = 5;
        integerConversionFactor = 10;
    }
    else
    {
        majorTicsAt = 200;
        minorTicsAt = 25;
    }
    if (!self.ticsView)
    {
        self.ticsView = [[SCUTicView alloc] initWithFrame:CGRectZero
                                              withScaleOf:scale
                                              andOffsetOf:lowestValue
                                              majorTicsAt:majorTicsAt
                                              minorTicsAt:minorTicsAt
                                  integerConversionFactor:integerConversionFactor];
        
        [self addSubview:self.ticsView];
        [self sav_addFlushConstraintsForView:self.ticsView];
    }
    else
    {
        [self.ticsView changeScale:scale
                       andOffsetOf:lowestValue
                       majorTicsAt:majorTicsAt
                       minorTicsAt:minorTicsAt
           integerConversionFactor:integerConversionFactor];
    }
}

- (void)setSliderVisibility:(BOOL)visible
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:[UIDevice rotationSpeed]];
    [UIView setAnimationDelay:0];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    if (visible)
    {
        if ([self isVertical])
        {
            self.canReciveOutSideSetPoints = NO;
        }
        if ((isValaidValue(self.desiredValue) &&
            self.lowestValue < self.desiredValue && self.highestValue > self.desiredValue) ||
            [self isVertical])
        {
            self.desiredSliderHandle.alpha = self.desiredAlpha;
        }

//        fade duirng cross over doesn't look good so changeing to white value at cross over point
//        self.currentStatusSliderHandle.backgroundColor = (self.currentValue > self.desiredValue ?  self.minPointColor : self.maxPointColor);
//        self.currentStatusSliderHandle.alpha = (self.currentValue == self.desiredValue) ? 0.0f : 1.0f;
        self.desiredSliderHandle.userInteractionEnabled = YES;
        self.currentAlpha = 0.3f;
        self.currentStatusSliderHandle.alpha = self.currentAlpha;
//        UIColor *currentBackgroundColor = (self.currentValue == self.desiredValue) ?
//        self.desiredSliderHandle.backgroundColor
//        :(self.currentValue > self.desiredValue ? 
//          self.minPointColor
//          :self.maxPointColor);
//        self.currentStatusSliderHandle.backgroundColor = currentBackgroundColor;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(canReciveOutSideSetPointAgain) object:nil];
    }
    else
    {
        if ([self isVertical])
        {
            if ([self isPool])
            {
                self.currentAlpha = 0.3;
                self.desiredAlpha = 1.0f;
                self.desiredSliderHandle.userInteractionEnabled = YES;
            }
            else
            {
                self.currentAlpha = 1.0f;
                self.desiredSliderHandle.alpha = 0;
            }
            self.currentStatusSliderHandle.alpha = self.currentAlpha;
        }
        else
        {
            self.currentAlpha = 1;
            if (isValaidValue(self.desiredValue) &&
                self.lowestValue < self.desiredValue && self.highestValue > self.desiredValue)
            {
                self.desiredSliderHandle.alpha = 1;
            }
            else
            {
                self.desiredSliderHandle.alpha = 0;
            }
            self.desiredSliderHandle.userInteractionEnabled = NO;
        }
//        self.currentStatusSliderHandle.backgroundColor = self.desiredSliderHandle.backgroundColor;
        [self performSelector:@selector(canReciveOutSideSetPointAgain) withObject:nil afterDelay:5.0f];
    }
    [UIView commitAnimations];
}

- (void)canReciveOutSideSetPointAgain
{
    if (!self.canReciveOutSideSetPoints)
    {
        self.canReciveOutSideSetPoints = YES;
        [self getSetPoints];
        [self placeHandlesWithAnimationDuration:self.animationDuration];
    }
}

- (void)setMultipleHandlesWithRange:(NSInteger)range
{
    self.highSliderValue = self.desiredValue + range;
    self.lowSliderValue = self.desiredValue - range;
}

//-------------------------------------------------------------------
// This method creates the scale and configures the view. This should
// be called by the view controller
//-------------------------------------------------------------------
- (void)setScaleOfSliderFrom:(CGFloat)lowest To:(CGFloat)highest
{
    CGFloat newScale = highest - lowest;
    BOOL firstPass = (self.scaleValue < 1.1);
//    if (abs(newScale - self.scaleValue) > .1)
    {
        self.scaleValue = newScale;
        self.lowestValue = lowest;
        self.highestValue = highest;
        if ([self isHorizontal])
        {
            [self setTicsViewScaleForRadio];
        }
    }
    if (firstPass)
    {
       [self configureViewsAndGestures];
    }
    else
    {
        if ([self isVertical])
        {
            [self setTicBoundsLabelValues];
            [self.ticsView changeScaleWithLowestValue:self.lowestValue andHighValue:self.highestValue];
        }
        else
        {
            [self setTicsViewScaleForRadio];
        }
    }
}

- (void)setColorOfMainHandle:(UIColor *)color
{
    self.desiredSliderHandle.backgroundColor = color;
    self.currentStatusSliderHandle.backgroundColor = color;

    if ([self isPool])
    {
        self.currentAlpha = 0.3;
        self.desiredAlpha = 1.0f;
    }
    self.currentStatusSliderHandle.alpha = self.currentAlpha;
    
    if ([self isHorizontal])
    {
        if (isValaidValue(self.desiredValue) &&
            self.lowestValue < self.desiredValue && self.highestValue > self.desiredValue)
        {
            self.desiredSliderHandle.alpha = 1.0;
        }
        else
        {
            self.desiredSliderHandle.alpha = 0.0;
        }
    }
}

- (void)setColorOfMaxPoint:(UIColor *)maxColor andMinPoint:(UIColor *)minColor
{
    self.maxPointColor = maxColor;
    self.minPointColor = minColor;
    
    self.highSliderHandle.backgroundColor = maxColor;
    self.lowSliderHandle.backgroundColor = minColor;
}

- (void)addLabelsToView
{
    CGFloat labelWidth = self.ticsView.ticHeight * 3.0f;
    CGFloat fontSize = [UIDevice isPad] ? 20.0f : 14.0f;
    
    self.visibleHighLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.visibleHighLabel.textColor = [UIColor sav_colorWithRGBValue:0xFFFFFF];
    self.visibleHighLabel.font = [UIFont fontWithName:@"Gotham" size:fontSize];
    self.visibleHighLabel.textAlignment = NSTextAlignmentRight;
    if (self.visibleHighLabelText)
    {
        self.visibleHighLabel.text = self.visibleHighLabelText;
    }
    self.visibleLowLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.visibleLowLabel.textColor = [UIColor sav_colorWithRGBValue:0xFFFFFF];
    self.visibleLowLabel.font = [UIFont fontWithName:@"Gotham" size:fontSize];
    self.visibleLowLabel.textAlignment = NSTextAlignmentRight;
    if (self.visibleLowLabelText)
    {
        self.visibleLowLabel.text = self.visibleLowLabelText;
    }
    
    [self addSubview:self.visibleLowLabel];
    [self addSubview:self.visibleHighLabel];
    
    [self addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                metrics:@{
                                                                          @"width": @(labelWidth),
                                                                          @"height": @(self.labelHeight)
                                                                          }
                                                                  views:@{
                                                                          @"topLabel": self.visibleHighLabel,
                                                                          @"bottomLabel": self.visibleLowLabel,
                                                                          @"currentHandle": self.currentStatusSliderHandle,
                                                                          @"ticView": self.ticsView
                                                                          }
                                                                formats:@[
                                                                          @"topLabel.right = currentHandle.right",
                                                                          @"topLabel.width = width",
                                                                          
                                                                          @"bottomLabel.right = currentHandle.right",
                                                                          @"bottomLabel.width = width",
                                                                          
                                                                          @"|[ticView]|",
                                                                          @"V:|[topLabel(height)][ticView][bottomLabel(height)]|"
                                                                          ]]];
    [self setTicBoundsLabelValues];
}

- (void)changeConfigurationToMode:(SCUSliderSetPointMode)mode
{
    self.mode = mode;
    if (self.setPointTimer)
    {
        [self.setPointTimer invalidate];
        self.setPointTimer = nil;
    }
    SAVWeakSelf;
    self.setPointTimer = [NSTimer sav_scheduledTimerWithTimeInterval:0.5 repeats:YES block:^{
        [wSelf showHighLowSetPoints];
    }];

    BOOL isTapOnly = [self isTapOnly];
    BOOL isPool = [self isPool];

    SCUSliderViewConfiguration tempConfiguration = SCUSliderViewConfigurationVertical;
    if (isTapOnly)
    {
        tempConfiguration = tempConfiguration | SCUSliderViewConfigurationTapOnly;
    }
    if ([self showTwoPoints])
    {
        tempConfiguration = tempConfiguration | SCUSliderViewConfigurationMultipleHandles;
    }
    if (isPool)
    {
        tempConfiguration = tempConfiguration | SCUSliderViewConfigurationPool;
    }
    self.configuration = tempConfiguration;
    
    [self setSliderVisibility:NO];

    if (![self showTwoPoints])
    {
        self.desiredAlpha = 1.0;
        
        if (self.desiredHandleConstraintsForDualSetPoint)
        {
            [self removeConstraints:self.desiredHandleConstraintsForDualSetPoint];
        }
        if (self.desiredHandleConstraintsForSingleSetPoint)
        {
            [self addConstraints:self.desiredHandleConstraintsForSingleSetPoint];
        }
    }
    else
    {
        self.desiredAlpha = 0.1;
        
        if (self.desiredHandleConstraintsForSingleSetPoint)
        {
            [self removeConstraints:self.desiredHandleConstraintsForSingleSetPoint];
        }
        if (self.desiredHandleConstraintsForDualSetPoint)
        {
            [self addConstraints:self.desiredHandleConstraintsForDualSetPoint];
        }
    }
    [self showHighLowSetPoints];
    switch (mode)
    {
        case SCUSliderSetPointModeHighPointOnly://cool
            self.desiredValue = self.highSliderValue;
            break;
        case SCUSliderSetPointModeLowPointOnly://heat
            self.desiredValue = self.lowSliderValue;
            break;
        case SCUSliderSetPointModeSingleSetPointAuto:
            if (!isValaidValue(self.desiredValue))
            {
                self.desiredValue = self.lowSliderValue;
            }
            self.desiredSliderHandle.userInteractionEnabled = YES;
            break;
        case SCUSliderSetPointModeDualSetPointAuto://auto with DualSetPoint
            self.desiredSliderHandle.userInteractionEnabled = YES;
            break;
        case SCUSliderSetPointModeOff://off
            if ([self isPool])
            {
                self.desiredValue = self.highSliderValue;
                self.desiredSliderHandle.userInteractionEnabled = YES;
            }
            else
            {
                self.desiredSliderHandle.userInteractionEnabled = NO;
            }
            break;
    }
    if (mode != SCUSliderSetPointModeOff)
    {
        self.highSliderHandle.backgroundColor = self.maxPointColor;
    }
    if ([self hasMultipleHandles])
    {
        self.highSliderHandle.hidden = NO;
        self.lowSliderHandle.hidden = NO;
    }
    else if ([self inSetHighPointOnlyMode])
    {
        self.highSliderHandle.hidden = NO;
        self.lowSliderHandle.hidden = YES;
    }
    else if ([self inSetLowPointOnlyMode])
    {
        self.highSliderHandle.hidden = YES;
        self.lowSliderHandle.hidden = NO;
    }
    else if ([self inAutoSingleSetPointMode])
    {
        self.highSliderHandle.hidden = YES;
        self.lowSliderHandle.hidden = NO;
    }
    else
    {
        if (![self isPool])
        {
            self.highSliderHandle.hidden = YES;
            self.lowSliderHandle.hidden = YES;
        }
    }
    
    [self placeHandlesWithAnimationDuration:(self.animationDuration / 3.0)];
}

//-------------------------------------------------------------------
// Gesture Recognizer methods
//-------------------------------------------------------------------
- (void)handleLongPress:(UILongPressGestureRecognizer *)longPress
{
    CGFloat controlRange = self.longPressControlRange;
    CGPoint location = [longPress locationInView:self];
    NSUInteger controlRangeScaleFactor = 2;
    UIView *controlView = [[UIView alloc] initWithFrame:CGRectMake(location.x,
                                                                   location.y,
                                                                   controlRange * controlRangeScaleFactor,
                                                                   controlRange * controlRangeScaleFactor)];
    controlView.center = location;
    
    switch (longPress.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            CGPoint location = [longPress locationInView:self];

            //-------------------------------------------------------------------
            // When the view is cliced on, create the controlled handle and
            // begin sliding
            //-------------------------------------------------------------------
            BOOL hasSetPoint =  isValaidValue(self.lowSliderValue) || isValaidValue(self.highSliderValue) || isValaidValue(self.desiredValue);
            if (!hasSetPoint)
            {
                CGPoint newPoint = CGPointMake(location.x, location.y);
                CGFloat touchValue = [self pointToUintFloatValue:newPoint];
                [self changeSetPointsDesired:touchValue lowSetPoint:touchValue highSetPoint:touchValue AnimationDelay:NO];
                [self placeHandlesImmediately];
            }
            if (self.highSliderHandle.userInteractionEnabled && CGRectIntersectsRect(self.highSliderHandle.frame, controlView.frame) && (([self hasMultipleHandles] || [self inSetHighPointOnlyMode]) || ([self isPool] && [self inOffMode] && isValaidValue(self.highSliderValue))))
            {
                self.isHeld = YES;
                self.controlledHandle = self.highSliderHandle;
            }
            else if (self.lowSliderHandle.userInteractionEnabled && CGRectIntersectsRect(self.lowSliderHandle.frame, controlView.frame))
            {
                self.isHeld = YES;
                self.controlledHandle = self.lowSliderHandle;
            }
            else if (//true if moving the desiredSliderHandle
                     (self.desiredSliderHandle.userInteractionEnabled &&
                      (CGRectIntersectsRect(self.desiredSliderHandle.frame, controlView.frame) ||
                       (CGRectIntersectsRect(self.currentStatusSliderHandle.frame, controlView.frame) && self.desiredSliderHandle.alpha != self.desiredAlpha)
                       )) ||
                     //true if moving the highSliderHandle && inAutoSingleSetPointMode
                     ([self inAutoSingleSetPointMode] &&
                      self.lowSliderHandle.userInteractionEnabled &&
                      CGRectIntersectsRect(self.lowSliderHandle.frame, controlView.frame)) ||
                     //this for raido and i don't know what it does
                     ([self isHorizontal] && self.desiredSliderHandle.userInteractionEnabled &&
                      location.y > self.desiredSliderHandle.center.y - (CGRectGetHeight(self.desiredSliderHandle.bounds) / 2) &&
                      (location.y < self.desiredSliderHandle.center.y + (CGRectGetHeight(self.desiredSliderHandle.bounds)))))
            {
                self.isHeld = YES;
                self.controlledHandle = self.desiredSliderHandle;
            }
            else if ([self.delegate respondsToSelector:@selector(didTouchNonHandlePartOfSlider)])
            {
                self.controlledHandle = nil;
                controlRangeScaleFactor = 4;
                controlView = [[UIView alloc] initWithFrame:CGRectMake(location.x,
                                                                       location.y,
                                                                       controlRange * controlRangeScaleFactor,
                                                                       controlRange * controlRangeScaleFactor)];
                controlView.center = location;

                if (!((self.highSliderHandle.userInteractionEnabled && CGRectIntersectsRect(self.highSliderHandle.frame, controlView.frame) && ([self hasMultipleHandles] || [self inSetHighPointOnlyMode])) ||
                    (self.lowSliderHandle.userInteractionEnabled && CGRectIntersectsRect(self.lowSliderHandle.frame, controlView.frame)) ||
                     (//true if moving the desiredSliderHandle
                      (self.desiredSliderHandle.userInteractionEnabled &&
                       (CGRectIntersectsRect(self.desiredSliderHandle.frame, controlView.frame)
                        )) ||
                      //true if moving the highSliderHandle && inAutoSingleSetPointMode
                      ([self inAutoSingleSetPointMode] &&
                       self.lowSliderHandle.userInteractionEnabled &&
                       CGRectIntersectsRect(self.lowSliderHandle.frame, controlView.frame)) ||
                      //this for raido and i don't know what it does
                      ([self isHorizontal] &&
                       location.y > self.desiredSliderHandle.center.y - (CGRectGetHeight(self.desiredSliderHandle.bounds) / 2) &&
                       (location.y < self.desiredSliderHandle.center.y + (CGRectGetHeight(self.desiredSliderHandle.bounds)))))
                     ))
                {
                    [self.delegate didTouchNonHandlePartOfSlider];
                }
            }
            if (self.controlledHandle)
            {
                self.lastTocuhLocation = location;
            }
            
            //[self changeSetPointsDesired:desired lowSetPoint:low highSetPoint:high AnimationDelay:0];
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            if (self.isHeld)
            {
                self.isHeld = NO;
                if (self.lastTouch != UIGestureRecognizerStateBegan)
                {
                    CGPoint deltaMovement = CGPointZero;
                    deltaMovement.x = location.x - self.lastTocuhLocation.x;
                    deltaMovement.y = location.y - self.lastTocuhLocation.y;
                    
                    CGPoint newPoint = self.controlledHandle.center;
                    newPoint.x += deltaMovement.x;
                    newPoint.y += deltaMovement.y;
                    [self changeValueForHandle:self.controlledHandle toPoint:newPoint];
                }
                else
                {
                    [self tapLogicForLocation:[longPress locationInView:self]];
                }
                self.lastTocuhLocation = location;
            }
            self.lastTocuhLocation = CGPointZero;
            self.controlledHandle = nil;
            
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStatePossible:
        case UIGestureRecognizerStateChanged:
        {
            if (self.isHeld)
            {
                CGPoint deltaMovement = CGPointZero;
                deltaMovement.x = location.x - self.lastTocuhLocation.x;
                deltaMovement.y = location.y - self.lastTocuhLocation.y;
                
                CGPoint newPoint = self.controlledHandle.center;
                newPoint.x += deltaMovement.x;
                newPoint.y += deltaMovement.y;
                [self changeValueForHandle:self.controlledHandle toPoint:newPoint];
                self.lastTocuhLocation = location;
            }
            break;
        }
        case UIGestureRecognizerStateFailed:
            break;
    }
    self.lastTouch = longPress.state;
}

- (void)handleTap:(UITapGestureRecognizer *)tap
{
    switch (tap.state)
    {
        case UIGestureRecognizerStateRecognized:
        {
            //-------------------------------------------------------------------
            // Snaps handle to the tapped position
            //-------------------------------------------------------------------
            CGPoint tappedPosition = [tap locationInView:self];
            if (self.desiredSliderHandle.userInteractionEnabled &&
                (tappedPosition.x > self.desiredSliderHandle.center.x - (CGRectGetWidth(self.desiredSliderHandle.bounds) / 2)) &&
                (tappedPosition.x < self.desiredSliderHandle.center.x + (CGRectGetWidth(self.desiredSliderHandle.bounds) / 2)))
            {
                [self changeValueForHandle:self.desiredSliderHandle toPoint:[tap locationInView:self]];
            }

            break;
        }
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStatePossible:
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateFailed:
            break;
    }
}

- (void)handleSingleTap:(UITapGestureRecognizer *)tap
{
    switch (tap.state)
    {
        case UIGestureRecognizerStateRecognized:
        {
            [self tapLogicForLocation:[tap locationInView:self]];
            break;
        }
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStatePossible:
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateFailed:
            break;
    }
}

- (void)tapLogicForLocation:(CGPoint)location
{
    UIView *controlView = [[UIView alloc] initWithFrame:CGRectMake(location.x, location.y, 10, 10)];
    controlView.center = location;
    if ([self.delegate respondsToSelector:@selector(sliderView:didSelectSetPointHandle:)])
    {
        if (CGRectIntersectsRect(controlView.frame, self.highSliderHandle.frame) &&
            self.highSliderHandle.alpha == 1.0)
        {
            [self.delegate sliderView:self didSelectSetPointHandle:SCUHandleHighSetPoint];
        }
        else if (CGRectIntersectsRect(controlView.frame, self.lowSliderHandle.frame) &&
                 self.lowSliderHandle.alpha == 1.0)
        {
            [self.delegate sliderView:self didSelectSetPointHandle:SCUHandleLowSetPoint];
        }
        else if (CGRectIntersectsRect(controlView.frame, self.desiredSliderHandle.frame) &&
                 self.desiredSliderHandle.alpha == self.desiredAlpha)
        {
            [self.delegate sliderView:self didSelectSetPointHandle:SCUHandleCenterSetPoint];
        }
    }
}

//-------------------------------------------------------------------
// This method changes the desired handle while making sure it doesn't
// go outside the slider's visible scale
//-------------------------------------------------------------------
- (void)changeValueForHandle:(UIView *)handle toPoint:(CGPoint)point
{
    CGFloat newValue = [self pointToUintFloatValue:point];

    if ([self isVertical])
    {
        if (self.desiredSliderHandle.alpha == 0 && ([self hasMultipleHandles]))
        {
            [self setSliderVisibility:YES];
        }
    }
    CGFloat dummyValueForPool = sentinelValue;
    if (self.desiredSliderHandle == handle)
    {
        [self changeSetPointsDesired:newValue lowSetPoint:sentinelValue highSetPoint:sentinelValue AnimationDelay:NO];
    }
    else if (self.lowSliderHandle == handle)
    {
        if ([self isPool] || [self inAutoSingleSetPointMode])
        {
            dummyValueForPool = newValue;
        }
        [self changeSetPointsDesired:dummyValueForPool lowSetPoint:newValue highSetPoint:sentinelValue AnimationDelay:NO];
    }
    else if (self.highSliderHandle == handle)
    {
        if ([self isPool])
        {
            dummyValueForPool = newValue;
        }
        [self changeSetPointsDesired:dummyValueForPool lowSetPoint:sentinelValue highSetPoint:newValue AnimationDelay:NO];
    }
    [self sendValuesToViewController];
}

- (void)setCurrentValue:(NSInteger)currentValue
{
    _currentValue = currentValue;
}

- (CGFloat)moveValueInRange:(CGFloat)value
{
    if (value < self.lowestValue)
    {
        value = self.lowestValue;
    }
    else if (value > self.highestValue)
    {
        value = self.highestValue;
    }
    return value;
}

- (void)adjustPointsBasedOnMinDelta_highPoint:(CGFloat)highPoint lowPoint:(CGFloat)lowPoint
{
    BOOL highSet =  isValaidValue(highPoint);
    BOOL lowSet  =  isValaidValue(lowPoint);

    if ((highPoint < lowPoint) && highSet)
    {
        CGFloat temp = highPoint;
        highPoint = lowPoint;
        lowPoint = temp;
    }
    
    if ([self showTwoPoints] && (!lowSet || !highSet))
    {
        if (lowSet)
        {
            if (self.highSliderValue - lowPoint < self.minDeadband)
            {
                highPoint = lowPoint + self.minDeadband;
            }
        }
        else if (highSet)
        {
            if (highPoint - self.lowSliderValue < self.minDeadband)
            {
                lowPoint = highPoint - self.minDeadband;
            }
        }
    }

    highSet =  isValaidValue(highPoint);
    lowSet  =  isValaidValue(lowPoint);

    if (lowSet && highSet)
    {
        lowPoint = [self moveValueInRange:lowPoint];
        highPoint = [self moveValueInRange:highPoint];
        if (fabs(highPoint - lowPoint) < self.minDeadband)
        {
            if (fabs(highPoint - self.highestValue) < fabs(lowPoint - self.lowestValue))
            {
                lowPoint = highPoint - self.minDeadband;
            }
            else
            {
                highPoint = lowPoint + self.minDeadband;
            }
        }
    }
    
    if (lowSet)
    {
        self.lowSliderValue = lowPoint; // set bool termanil
    }
    else
    {
        lowPoint = self.lowSliderValue;
    }
    if (highSet)
    {
        self.highSliderValue = highPoint;// set bool termanil
    }
    else
    {
        highPoint = self.highSliderValue;
    }
    
    highSet =  isValaidValue(highPoint);
    lowSet  =  isValaidValue(lowPoint);

    if (highSet && lowSet)
    {
        self.desiredValue = (highPoint + lowPoint) / 2;
    }
}

- (void)changeSetPointsDesired:(CGFloat)desired lowSetPoint:(CGFloat)lowPoint highSetPoint:(CGFloat)highPoint AnimationDelay:(BOOL)delay
{
    CGFloat newValue = sentinelValue;
    BOOL highSet    =  isValaidValue(highPoint);
    BOOL desiredSet =  isValaidValue(desired);
    BOOL lowSet     =  isValaidValue(lowPoint);
    
    if ([self showTwoPoints])
    {
        if (highSet && !lowSet && !desiredSet)
        {
            [self setPointsBasedOnHighValue:highPoint]; //start bool value
            [self adjustPointsBasedOnMinDelta_highPoint:self.highSliderValue lowPoint:self.lowSliderValue];
        }
        else if (!highSet && lowSet && !desiredSet)
        {
            [self setPointsBasedOnLowValue:lowPoint]; //start bool value
        }
        else if (!highSet && !lowSet && desiredSet)
        {
            [self setPointsBasedOnDesiredValue:desired];
        }
        else if (highSet || lowSet || desiredSet)
        {
            if (lowSet)
            {
                lowPoint = [self moveValueInRange:lowPoint];
            }
            if (highSet)
            {
                highPoint = [self moveValueInRange:highPoint];
            }
            if (desiredSet)
            {
                desired = [self moveValueInRange:desired];
            }
            
            if (highSet && desiredSet && !lowSet)
            {
                lowPoint = [self moveValueInRange:(desired - (highPoint - desired))];
            }
            else if (lowSet && desiredSet && !highSet)
            {
                highPoint = [self moveValueInRange:(desired + (desired - lowPoint))];
            }

            [self adjustPointsBasedOnMinDelta_highPoint:highPoint lowPoint:lowPoint];
        }
    }
    else if (self.mode == SCUSliderSetPointModeLowPointOnly && lowSet)
    {
        newValue = [self moveValueInRange:lowPoint];
        self.lowSliderValue = newValue;
        self.desiredValue = newValue;
    }
    else if (self.mode == SCUSliderSetPointModeHighPointOnly && highSet)
    {
        newValue = [self moveValueInRange:highPoint];
        self.highSliderValue = newValue;
        self.desiredValue = newValue;
    }
    else if (desiredSet)
    {
        newValue = [self moveValueInRange:desired];
        self.desiredValue = newValue;
        if (self.mode == SCUSliderSetPointModeHighPointOnly || (self.mode == SCUSliderSetPointModeOff && [self isPool] && isValaidValue(self.highSliderValue)))
        {
            self.highSliderValue = newValue;// set bool termanil
        }
        else if (self.mode == SCUSliderSetPointModeLowPointOnly  || (self.mode == SCUSliderSetPointModeOff && [self isPool] && isValaidValue(self.lowSliderValue)))
        {
            self.lowSliderValue = newValue; // set bool termanil
        }
    }
    if (highSet || lowSet || desiredSet)
    {
        if (self.isHeld || !delay)
        {
            [self placeHandlesImmediately];
        }
        else
        {
            [self placeHandlesWithAnimationDuration:self.animationDuration];
        }
    }
}

- (void)setPointsBasedOnDesiredValue:(CGFloat)desiredValue
{
    CGFloat currentValue = self.desiredValue;
    
    desiredValue = [self moveValueInRange:desiredValue];

    if (isValaidValue(currentValue))
    {
        CGFloat deltaValue = desiredValue - currentValue;
        CGFloat lowSliderValue;
        CGFloat highSliderValue = sentinelValue;

        if (isValaidValue(self.lowSliderValue))
        {
            lowSliderValue = [self moveValueInRange:self.lowSliderValue + deltaValue];
        }
        else
        {
            lowSliderValue = [self moveValueInRange:desiredValue - self.minDeadband / 2];
        }
        
        if (isValaidValue(self.highSliderValue))
        {
            highSliderValue = [self moveValueInRange:self.highSliderValue + deltaValue];
        }
        else
        {
            highSliderValue = [self moveValueInRange:desiredValue + self.minDeadband / 2];
        }
        
        [self adjustPointsBasedOnMinDelta_highPoint:highSliderValue lowPoint:lowSliderValue];
    }
    else
    {
        self.desiredValue = desiredValue;
        if (isValaidValue(self.highSliderValue) && isValaidValue(self.lowSliderValue))
        {
            [self changeSetPointsDesired:self.desiredValue lowSetPoint:sentinelValue highSetPoint:sentinelValue AnimationDelay:0];
        }
    }
}

- (void)setPointsBasedOnLowValue:(CGFloat)lowSliderValue
{
    CGFloat currentValue = self.lowSliderValue;

    lowSliderValue = [self moveValueInRange:lowSliderValue];
    
    if (isValaidValue(currentValue))
    {
        [self adjustPointsBasedOnMinDelta_highPoint:sentinelValue lowPoint:lowSliderValue];
    }
    else
    {
        if (isValaidValue(self.highSliderValue))
        {
            [self changeSetPointsDesired:sentinelValue lowSetPoint:lowSliderValue highSetPoint:self.highSliderValue AnimationDelay:0];
        }
        else if (isValaidValue(self.desiredValue))
        {
            [self changeSetPointsDesired:self.desiredValue lowSetPoint:lowSliderValue highSetPoint:sentinelValue AnimationDelay:0];
        }
        else
        {
            self.lowSliderValue = lowSliderValue;
        }
    }
}

- (void)setPointsBasedOnHighValue:(CGFloat)highSliderValue
{
    CGFloat currentValue = self.highSliderValue;
    
    highSliderValue = [self moveValueInRange:highSliderValue];
    
    if (isValaidValue(currentValue))
    {
        [self adjustPointsBasedOnMinDelta_highPoint:highSliderValue lowPoint:sentinelValue];
    }
    else
    {
        if (isValaidValue(self.lowSliderValue))
        {
            [self changeSetPointsDesired:sentinelValue lowSetPoint:self.lowSliderValue highSetPoint:highSliderValue AnimationDelay:0];
        }
        else if (isValaidValue(self.desiredValue))
        {
            [self changeSetPointsDesired:self.desiredValue lowSetPoint:sentinelValue highSetPoint:highSliderValue AnimationDelay:0];
        }
        else
        {
            self.highSliderValue = highSliderValue;
        }
    }
}

- (void)changeValueOfHandleToValue:(CGFloat)value
{
    if (self.canReciveOutSideSetPoints)
    {
        if (fabs([self moveValueInRange:value] - value) < 0.00001)
        {
            [self changeSetPointsDesired:value lowSetPoint:sentinelValue highSetPoint:sentinelValue AnimationDelay:1];
        }
    }
}

- (void)changeValueOfMaxPointToValue:(CGFloat)value
{
    if (self.canReciveOutSideSetPoints)
    {
        if (fabs([self moveValueInRange:value] - value) < 0.00001)
        {
            [self changeSetPointsDesired:sentinelValue lowSetPoint:sentinelValue highSetPoint:value AnimationDelay:1];
        }
    }
}

- (void)changeValueOfMinPointToValue:(CGFloat)value
{
    if (self.canReciveOutSideSetPoints)
    {
        if (fabs([self moveValueInRange:value] - value) < 0.00001)
        {
            [self changeSetPointsDesired:sentinelValue lowSetPoint:value highSetPoint:sentinelValue AnimationDelay:1];
        }
    }
}

- (void)changeCurrentHandleToValue:(CGFloat)value
{
    [self setCurrentValue:value];
    if (isValaidValue(self.currentValue))
    {
        if (self.isHeld)
        {
            [UIView animateWithDuration:(self.animationDuration * 3) animations:^{
                [self placeCurrentHandle];
            }];
        }
        else
        {
            [self placeCurrentHandle];
        }
    }
    else
    {
        [self setNeedsLayout];
    }
}

- (void)setTargetHandle:(UIView *)handle ToPosition:(CGFloat)position
{
    if (position < 0.0001 || position > 1024)
    {
        return;
    }
    if ([self isHorizontal])
    {
        handle.center = CGPointMake(position, handle.center.y);
    }
    else
    {
        if (handle == self.desiredSliderHandle && [self showTwoPoints])
        {
            CGFloat desiredHeight = self.lowSliderHandle.frame.origin.y - self.highSliderHandle.frame.origin.y;
            self.desiredSliderHandle.frame = CGRectMake(self.desiredSliderHandle.frame.origin.x, position - desiredHeight / 2, self.desiredSliderHandle.frame.size.width, desiredHeight);
        }
        else
        {
            handle.center = CGPointMake(handle.center.x, position);
        }
    }
}

//-------------------------------------------------------------------
// This method finds the exact value within the visible scale and
// passes it to the callback method for the view controller
//-------------------------------------------------------------------
- (void)sendValuesToViewController
{
    if ([self isVertical])
    {
        if ([self.delegate respondsToSelector:@selector(sliderView:didChangeMultipleValuesWithHighestValue:andLowestValue:andDesiredValue:andHeldDown:)])
        {
              [self.delegate sliderView:self
didChangeMultipleValuesWithHighestValue:self.highSliderValue + 0.5
                         andLowestValue:self.lowSliderValue + 0.5
                        andDesiredValue:self.desiredValue + 0.5
                            andHeldDown:self.isHeld];
        }
    }
    else
    {
        if ([self.delegate respondsToSelector:@selector(sliderView:didChangeValueWithDesiredValue:andHeldDown:)])
        {
            [self.delegate sliderView:self
       didChangeValueWithDesiredValue:self.desiredValue
                          andHeldDown:self.isHeld];
        }
    }
}

#pragma mark - screen to value conversions

- (CGFloat)pointsPerUintConversion
{
    CGFloat pixelCount = [self isVertical] ? CGRectGetHeight(self.ticsView.bounds) : CGRectGetWidth(self.ticsView.bounds);
    pixelCount = pixelCount - (self.ticsView.edgePadding * 2);

    return pixelCount / ((self.scaleValue == 0) ? 1 : self.scaleValue);
}

- (CGFloat)pointToUintFloatValue:(CGPoint)point
{
    CGFloat vector;
    
    if ([self isVertical])
    {
        vector = point.y;
    }
    else
    {
        vector = point.x;
    }
    return [self pixelsToUintFloatValue:vector];
}

- (CGFloat)pixelsToUintFloatValue:(CGFloat)pixels
{  
    pixels -= (self.ticsView.edgePadding);
    
    if ([self isVertical])
    {
        pixels -= (self.ticsView.frame.origin.y);
    }
    
    CGFloat unitsFromTopOrLeftOfScale = pixels / [self pointsPerUintConversion];
    
    CGFloat value;
    if ([self isVertical])
    {
        value = self.highestValue - unitsFromTopOrLeftOfScale;
    }
    else
    {
        value = unitsFromTopOrLeftOfScale + self.lowestValue;
    }
    return value;
}

- (CGFloat)valueToPoint:(CGFloat)value
{
    if ([self isVertical])
    {
        value = self.highestValue - value;
    }
    else
    {
        value -= self.lowestValue;
    }

    CGFloat point = value * [self pointsPerUintConversion];
    
    point += (self.ticsView.edgePadding + self.labelHeight);
    
    return point;
}

#pragma mark - layout methods

- (void)setTicBoundsLabelValues
{
    if ([self.delegate respondsToSelector:@selector(interpretedDisplayValue:)])
    {
        self.visibleHighLabelText = [self.delegate interpretedDisplayValue:self.highestValue];
        self.visibleLowLabelText = [self.delegate interpretedDisplayValue:self.lowestValue];
    }
    else
    {
        self.visibleHighLabelText = [NSString stringWithFormat:@"%li", (long)self.highestValue];
        self.visibleLowLabelText = [NSString stringWithFormat:@"%li", (long)self.lowestValue];
    }

    if (self.visibleHighLabel)
    {
        self.visibleHighLabel.text = self.visibleHighLabelText;
    }
    if (self.visibleLowLabel)
    {
        self.visibleLowLabel.text = self.visibleLowLabelText;
    }
    [self placeHandlesImmediately];
}

- (void)placeHandlesWithAnimationDuration:(CGFloat)time
{
    if (time < 0.0001)
    {
        [self placeHandlesImmediately];
    }
    else
    {
        SAVWeakSelf;
        [UIView animateWithDuration:time
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [wSelf placeHandles];
                         }
                         completion:^(BOOL finished) {
                             [wSelf startSetPointTimer];
                         }];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self placeHandlesImmediately];
    self.animationDuration = 0.3;
}

- (void)placeHandlesImmediately
{
    [self placeHandles];
    [self startSetPointTimer];
}

- (void)placeCurrentHandle
{
    if (isValaidValue(self.currentValue))
    {
        [self setTargetHandle:self.currentStatusSliderHandle ToPosition:[self valueToPoint:self.currentValue]];
    }
}

- (void)placeHandles
{
    [self placeCurrentHandle];
    
    if (isValaidValue(self.lowestValue) && isValaidValue(self.highestValue) &&
        (!isValaidValue(self.desiredValue) || self.desiredValue < self.lowestValue || self.desiredValue > self.highestValue) &&
        [self isHorizontal])
    {
        [self setTargetHandle:self.desiredSliderHandle ToPosition:[self valueToPoint:
                                                                   ((self.lowestValue + self.highestValue) / 2)]];
    }

    if (isValaidValue(self.highSliderValue))
    {
        [self setTargetHandle:self.highSliderHandle ToPosition:[self valueToPoint:self.highSliderValue]];
    }
    if (isValaidValue(self.lowSliderValue))
    {
        [self setTargetHandle:self.lowSliderHandle ToPosition:[self valueToPoint:self.lowSliderValue]];
    }
    if (isValaidValue(self.desiredValue))
    {
        if ([self hasMultipleHandles])
        {
            [self setTargetHandle:self.desiredSliderHandle ToPosition:[self valueToPoint:
                                                                       (self.lowSliderValue + self.highSliderValue) / 2]];
        }
        else
        {
            [self setTargetHandle:self.desiredSliderHandle ToPosition:[self valueToPoint:self.desiredValue]];
            if ([self inAutoSingleSetPointMode])
            {
                [self setTargetHandle:self.lowSliderHandle ToPosition:[self valueToPoint:self.desiredValue]];
            }
        }
    }
}

- (void)startSetPointTimer
{
    if (self.setPointTimer)
    {
        [self.setPointTimer invalidate];
        self.setPointTimer = nil;
    }
    SAVWeakSelf;
    self.setPointTimer = [NSTimer sav_scheduledTimerWithTimeInterval:0.5 repeats:YES block:^{
        [wSelf showHighLowSetPoints];
    }];
}

- (void)showHighLowSetPoints
{
    BOOL killTimer = NO;
    if ([self isVertical])
    {
        if ([self inSetHighPointOnlyMode])
        {
            killTimer = (self.highSliderHandle.alpha == 1 && self.lowSliderHandle.alpha == 0);
        }
        else if ([self inSetLowPointOnlyMode] || [self inAutoSingleSetPointMode])
        {
            killTimer = (self.highSliderHandle.alpha == 0 && self.lowSliderHandle.alpha == 1);
        }
        else if ([self showTwoPoints])
        {
            killTimer = (self.highSliderHandle.alpha == 1 && self.lowSliderHandle.alpha == 1);
        }
        else if ([self inOffMode] && ![self isPool])
        {
            killTimer = (self.highSliderHandle.alpha == 0 && self.lowSliderHandle.alpha == 0);
        }
        if (fabs(self.currentStatusSliderHandle.alpha - self.currentAlpha) > 0.00001)
        {
            killTimer = NO;
        }
    }
    else
    {
        if (fabs(self.desiredSliderHandle.alpha - self.currentAlpha) > 0.00001)
        {
            killTimer = YES;
        }
    }

    if (killTimer)
    {
        if (self.setPointTimer)
        {
            [self.setPointTimer invalidate];
            self.setPointTimer = nil;
        }
    }
    
    __block BOOL shouldCallForSetPoints = NO;

    SAVWeakSelf;
    [UIView animateWithDuration:self.animationDuration
                          delay:0
                        options:(UIViewAnimationOptionTransitionNone)
                     animations:^{
                         if ([self isVertical])
                         {
                             if ([self inSetHighPointOnlyMode] || [self showTwoPoints] || ([self isPool] && [self inOffMode] && !isValaidValue(self.lowSliderValue)))
                             {
                                 if (isValaidValue(self.highSliderValue))
                                 {
                                     self.highSliderHandle.alpha = 1;
                                     if ([self isPool])
                                     {
                                         self.desiredSliderHandle.alpha = self.desiredAlpha;
                                     }
                                 }
                                 else
                                 {
                                     shouldCallForSetPoints = YES;
                                     self.highSliderHandle.alpha = 0;
                                 }
                             }
                             else
                             {
                                 self.highSliderHandle.alpha = 0;
                             }
                             
                             if ([self inSetLowPointOnlyMode] || [self showTwoPoints] || [self inAutoSingleSetPointMode] || ([self isPool] && [self inOffMode] && !isValaidValue(self.highSliderValue)))
                             {
                                 if (isValaidValue(self.lowSliderValue) || ([self inAutoSingleSetPointMode] && isValaidValue(self.desiredValue)))
                                 {
                                     self.lowSliderHandle.alpha = 1;
                                     if ([self isPool])
                                     {
                                         self.desiredSliderHandle.alpha = self.desiredAlpha;
                                     }
                                 }
                                 else
                                 {
                                     shouldCallForSetPoints = YES;
                                     self.lowSliderHandle.alpha = 0;
                                 }
                             }
                             else
                             {
                                 self.lowSliderHandle.alpha = 0;
                             }
                             
                             if (isValaidValue(self.currentValue))
                             {
                                 self.currentStatusSliderHandle.alpha = self.currentAlpha;
                             }
                             else
                             {
                                 shouldCallForSetPoints = YES;
                                 self.currentStatusSliderHandle.alpha = 0;
                             }
                         }
                         else
                         {
                             if (isValaidValue(self.desiredValue))
                             {
                                 if (self.desiredValue < self.highestValue && self.desiredValue > self.lowestValue)
                                 {
                                     self.desiredSliderHandle.alpha = 1;
                                 }
                             }
                             else
                             {
                                 shouldCallForSetPoints = YES;
                                 self.currentStatusSliderHandle.alpha = 0;
                                 self.desiredSliderHandle.alpha = 0;
                             }
                         }
                     }
                     completion:^(BOOL finished) {
                         if (shouldCallForSetPoints)
                         {
                             if (wSelf.canReciveOutSideSetPoints)
                             {
                                [wSelf getSetPoints];
                             }
                         }
                     }];
}

- (void)getSetPoints
{
    if ([self.delegate respondsToSelector:@selector(getCurrentSetPoints)])
    {
        NSDictionary *setPoints = [self.delegate getCurrentSetPoints];
        if ([setPoints count] > 0 || [self isPool])
        {
            if (setPoints[SCUSliderCurrentValue])
            {
                [self setCurrentValue:[setPoints[SCUSliderCurrentValue] floatValue]];
            }
            if (setPoints[SCUSliderLowSetPoint])
            {
                [self setLowSliderValue:[setPoints[SCUSliderLowSetPoint] floatValue]];
            }
            if (setPoints[SCUSliderHighSetPoint])
            {
                [self setHighSliderValue:[setPoints[SCUSliderHighSetPoint] floatValue]];
            }
            
            if (setPoints[SCUSliderMiddleSetPoint] && ([self inAutoSingleSetPointMode] || [self isHorizontal]))
            {
                [self setDesiredValue:[setPoints[SCUSliderMiddleSetPoint] floatValue]];
            }
            else if ([self inSetHighPointOnlyMode])
            {
                [self setDesiredValue:self.highSliderValue];
            }
            else if ([self inSetLowPointOnlyMode])
            {
                [self setDesiredValue:self.lowSliderValue];
            }
            else if (isValaidValue(self.lowSliderValue) && isValaidValue(self.highSliderValue))
            {
                [self setDesiredValue:((self.lowSliderValue + self.highSliderValue) / 2.0)];
            }
            else if ([self isPool])
            {
                if (isValaidValue(self.lowSliderValue))
                {
                    [self setDesiredValue:self.lowSliderValue];
                }
                else if (isValaidValue(self.highSliderValue))
                {
                    [self setDesiredValue:self.highSliderValue];
                }
            }
            [self placeHandlesWithAnimationDuration:self.animationDuration];
        }
    }
}

- (void)showHighLowSetPointsWithAnamationDuration:(CGFloat)duration delay:(CGFloat)delay
{
    [self performSelectorOnMainThread:@selector(showHighLowSetPoints) withObject:nil waitUntilDone:NO];
}

#pragma mark - helper methods

- (void)setDesiredValue:(CGFloat)desiredValue
{
    if (fabs(self.desiredValue - desiredValue) > self.scaleGranularity / 2 || self.isHeld)
    {
        _desiredValue = desiredValue;
        if ([self isHorizontal] && isValaidValue(desiredValue) &&
            self.desiredSliderHandle.alpha < 0.9 &&
            self.lowestValue < desiredValue && self.highestValue > desiredValue)
        {
            self.desiredSliderHandle.alpha = 1;
            [self setTargetHandle:self.desiredSliderHandle ToPosition:[self valueToPoint:self.desiredValue]];
        }
    }
}

- (void)setHighSliderValue:(CGFloat)highSliderValue
{
    if (self.isHeld)
    {
        _highSliderValue = highSliderValue;
    }
    else if (fabs(self.highSliderValue - highSliderValue) > self.scaleGranularity / 2)
    {
        _highSliderValue = highSliderValue;
    }
}

- (void)setLowSliderValue:(CGFloat)lowSliderValue
{
    if (self.isHeld)
    {
        _lowSliderValue = lowSliderValue;
    }
    else if (fabs(self.lowSliderValue - lowSliderValue) > self.scaleGranularity / 2)
    {
        _lowSliderValue = lowSliderValue;
    }
}

- (BOOL)canReciveOutSideSetPoints
{
    return !self.isHeld && ([self isHorizontal] ||(_canReciveOutSideSetPoints || self.setPointPopUp));
}

- (BOOL)showTwoPoints
{
    return (self.mode == SCUSliderSetPointModeDualSetPointAuto);
}

- (BOOL)inAutoSingleSetPointMode
{
    return (self.mode == SCUSliderSetPointModeSingleSetPointAuto);
}

- (BOOL)inSetLowPointOnlyMode
{
    return (self.mode == SCUSliderSetPointModeLowPointOnly);
}

- (BOOL)inSetHighPointOnlyMode
{
    return (self.mode == SCUSliderSetPointModeHighPointOnly);
}

- (BOOL)inOffMode
{
    return (self.mode == SCUSliderSetPointModeOff);
}

- (BOOL)isHorizontal
{
    return (self.configuration & SCUSliderViewConfigurationHorizontal);
}

- (BOOL)isVertical
{
    return (self.configuration & SCUSliderViewConfigurationVertical);
}

- (BOOL)isPool
{
    return (self.configuration & SCUSliderViewConfigurationPool);
}

- (BOOL)hasMultipleHandles
{
    return (self.configuration & SCUSliderViewConfigurationMultipleHandles);
}

- (BOOL)isTapOnly
{
    return (self.configuration & SCUSliderViewConfigurationTapOnly);
}

@end
