//
//  SCUStepper.m
//  SavantController
//
//  Created by Stephen Silber on 7/9/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUStepper.h"
@import Extensions;

@implementation SCUStepper

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        //-------------------------------------------------------------------
        // Default values
        //-------------------------------------------------------------------
        _value = 0.0;
        _minimumValue = -50.0;
        _maximumValue = 50.0;
        _stepValue = 10.0;
        
        //-------------------------------------------------------------------
        // Don't use properties here to avoid initializing UIApperance values
        //-------------------------------------------------------------------
        _disabledColor = [[SCUColors shared] color01];
        _color = [[SCUColors shared] color01];
        _backgroundColor = [[[SCUColors shared] color04] colorWithAlphaComponent:0.04];
        _selectedColor = [[SCUColors shared] color01];
        _selectedBackgroundColor = [[[SCUColors shared] color04] colorWithAlphaComponent:1.0];
    }
    return self;
}

- (instancetype)initWithTextArray:(NSArray *)textArray
{
    self = [super init];
    if (self)
    {
        if ([textArray count] == 2)
        {
            self.minimumValue = -50.0;
            self.maximumValue = 50.0;
            self.stepValue = 5.0;
            
            self.leftButton = [[SCUButton alloc] initWithTitle:textArray[0]];
            self.leftButton.frame = CGRectMake(0, 0, 25, 30);
            self.leftButton.titleLabel.font = [UIFont systemFontOfSize:30];
            self.leftButton.backgroundColor = [UIColor clearColor];
            self.leftButton.selectedColor = [[SCUColors shared] color04];
            self.leftButton.selectedBackgroundColor = [UIColor clearColor];
            self.leftButton.color = [[SCUColors shared] color01];
            self.leftButton.disabledColor = [[SCUColors shared] color03shade07];
            [self.leftButton setTitleColor:[[SCUColors shared] color04] forState:UIControlStateSelected];

            self.rightButton = [[SCUButton alloc] initWithTitle:textArray[1]];
            self.leftButton.frame = CGRectMake(0, 0, 25, 30);
            self.rightButton.titleLabel.font = [UIFont systemFontOfSize:30];
            self.rightButton.backgroundColor = [UIColor clearColor];
            self.rightButton.color = [[SCUColors shared] color01];
            self.rightButton.selectedColor = [[SCUColors shared] color04];
            self.rightButton.selectedBackgroundColor = [UIColor clearColor];
            self.rightButton.disabledColor = [[SCUColors shared] color03shade07];
            [self.rightButton setTitleColor:[[SCUColors shared] color04] forState:UIControlStateSelected];

            [self addSubview:self.leftButton];
            [self addSubview:self.rightButton];
            
            self.leftButton.target         = self;
            self.leftButton.holdAction     = @selector(leftButtonTapped:);
            self.leftButton.releaseAction  = @selector(leftButtonTapped:);
            self.leftButton.holdDelay      = 0.5;
            self.leftButton.holdTime       = 0.2;

            self.rightButton.target        = self;
            self.rightButton.holdAction    = @selector(rightButtonTapped:);
            self.rightButton.releaseAction = @selector(rightButtonTapped:);
            self.rightButton.holdDelay     = 0.5;
            self.rightButton.holdTime      = 0.2;

            NSDictionary *metrics = @{@"centerPadding": @5,
                                      @"leftPadding"  : @5,
                                      @"rightPadding" : @5};
            
            NSDictionary *views = @{@"leftButton": self.leftButton,
                                    @"rightButton":self.rightButton};
            
            [self addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                        views:views
                                                                        formats:@[@"|-leftPadding-[leftButton]-centerPadding-[rightButton]-rightPadding-|",
                                                                                  @"leftButton.centerY = super.centerY",
                                                                                  @"rightButton.centerY = super.centerY",
                                                                                  @"leftButton.width = rightButton.width",
                                                                                  @"leftButton.height = 30",
                                                                                  @"rightButton.height = leftButton.height"]]];
        }
    }
    
    return self;
}

#pragma mark - Properties

- (void)setColor:(UIColor *)color
{
    _color = color;
    [self.leftButton setTitleColor:color forState:UIControlStateNormal];
    [self.rightButton setTitleColor:color forState:UIControlStateNormal];
}

- (void)setSelectedColor:(UIColor *)selectedColor
{
    _selectedColor = selectedColor;
}

- (void)setLeftTitle:(NSString *)title
{
    self.leftButton.title = title;
}

- (void)setRightTitle:(NSString *)title
{
    self.rightButton.title = title;
}

- (void)setTitlesFromArray:(NSArray *)titleArray
{
    if ([titleArray count] == 2)
    {
        [self setLeftTitle:titleArray[0]];
        [self setRightTitle:titleArray[1]];
    }
    else
    {
        NSException *ex = [NSException exceptionWithName:NSInvalidArgumentException
												  reason:@"SCUStepper: Title array must contain 2 objects, the first being the left title and the second being the right title."
												userInfo:nil];
		@throw ex;
    }
}

- (void)setStepValue:(float)stepValue
{
	if (stepValue <= 0)
    {
		NSException *ex = [NSException exceptionWithName:NSInvalidArgumentException
												  reason:@"SCUStepper: Step value cannot be less than or equal to zero."
												userInfo:nil];
		@throw ex;
	}
    
	_stepValue = stepValue;
}

- (void)setMaximumValue:(float)maxValue
{
	if (maxValue < self.minimumValue)
    {
		NSException *ex = [NSException exceptionWithName:NSInvalidArgumentException
												  reason:@"SCUStepper: Maximum value cannot be less than the minimum value."
												userInfo:nil];
		@throw ex;
	}
    
    [self checkButtonInteraction];
	_maximumValue = maxValue;
}

- (void)setMinimumValue:(float)minValue
{
	if (minValue > self.maximumValue)
    {
		NSException *ex = [NSException exceptionWithName:NSInvalidArgumentException
												  reason:@"SCUStepper: Minimum value cannot be greater than the maximum value."
												userInfo:nil];
		@throw ex;
	}

    [self checkButtonInteraction];
	_minimumValue = minValue;
}

#pragma mark - Button Actions & States

- (void)setValue:(float)value
{
    if (value >= self.maximumValue)
    {
        _value = self.maximumValue;
    }
    else if (value <= self.minimumValue)
    {
        _value = self.minimumValue;
    }
    else
    {
        _value = value;
    }

    // Disable user interaction for visual effect if at min or max values
    [self checkButtonInteraction];
    
    if ([self.delegate respondsToSelector:@selector(stepperValueDidChange:)])
    {
        [self.delegate stepperValueDidChange:self];
    }
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)leftButtonTapped:(id)sender
{
    if (self.value > self.minimumValue)
    {
        self.value = (self.value -= self.stepValue);
        [self callCallback];
    }
}

- (void)rightButtonTapped:(id)sender
{
    if (self.value < self.maximumValue)
    {
        self.value = (self.value += self.stepValue);
        [self callCallback];
    }
}

- (void)updateButtonLabelSize:(NSString *)fontSize
{
    self.leftButton.titleLabel.font = [UIFont systemFontOfSize:[fontSize floatValue]];
    self.rightButton.titleLabel.font = [UIFont systemFontOfSize:[fontSize floatValue]];
}

- (void)checkButtonInteraction
{
    BOOL atMax = (self.value == self.maximumValue);
    BOOL atMin = (self.value == self.minimumValue);
    
    [self.leftButton setUserInteractionEnabled:!atMin];
    [self.rightButton setUserInteractionEnabled:!atMax];
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
