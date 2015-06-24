//
//  SCUPickerView.m
//  SavantController
//
//  Created by David Fairweather on 4/24/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUPickerView.h"
#import "SCUGradientView.h"
#import "SCUButton.h"
#import "SCUToolbarButton.h"

@import Extensions;

#define SCUPickerViewButtonTagOffset 1000

@interface SCUPickerView () <UIGestureRecognizerDelegate>

@property (nonatomic) SCUPickerViewConfiguration configuration;
@property (nonatomic) SCUButton *centerButton;

@property (nonatomic) NSInteger *highestValue;
@property (nonatomic) NSInteger *lowestValue;

@property (nonatomic) SCUButton *up;
@property (nonatomic) SCUButton *down;
@property (nonatomic) SCUButton *left;
@property (nonatomic) SCUButton *right;

@property (nonatomic) NSMutableArray *selectableArrows;
@property (nonatomic) NSArray *largerButtons;

@end

@implementation SCUPickerView

- (instancetype)initWithConfiguration:(SCUPickerViewConfiguration)config
{
    return [self initWithFrame:CGRectZero andConfiguration:config];
}

- (instancetype)initWithFrame:(CGRect)frame andConfiguration:(SCUPickerViewConfiguration)config
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        self.configuration = config;
        
        self.selectableArrows = [@[] mutableCopy];
        _tintColor = [[SCUColors shared] color04];
        _selectedTintColor = [[SCUColors shared] color01];
        [self configureViewsAndGestures];
    }
    return self;
}

- (void)configureViewsAndGestures
{
    self.centerButton = [[SCUButton alloc] init];
    [self.centerButton setTag:SCUPickerViewDirectionNone + SCUPickerViewButtonTagOffset];
    self.centerButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.centerButton.color = [[SCUColors shared] color04];
    self.centerButton.backgroundColor = nil;
    self.centerButton.selectedColor = nil;
    self.centerButton.selectedBackgroundColor = nil;
    CGFloat fontSize = [UIDevice isPad] ? [[SCUDimens dimens] regular].h9 : [[SCUDimens dimens] regular].h10;
    self.centerButton.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:fontSize];
    self.centerButton.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    [self addSubview:self.centerButton];

    NSMutableDictionary *views = [@{@"label": self.centerButton} mutableCopy];
    if (self.configuration & SCUPickerViewConfigurationTwoArrowsVertical || self.configuration & SCUPickerViewConfigurationTwoArrowsVerticalClimate || self.configuration & SCUPickerViewConfigurationFourArrows)
    {
        self.up = [[SCUButton alloc] initWithImage:[UIImage imageNamed:@"white_arrow_up"]];
        self.down = [[SCUButton alloc] initWithImage:[UIImage imageNamed:@"white_arrow_down"]];
        [self.up setTag:SCUPickerViewDirectionUp + SCUPickerViewButtonTagOffset];
        [self.down setTag:SCUPickerViewDirectionDown + SCUPickerViewButtonTagOffset];
        [self addSubview:self.up];
        [self addSubview:self.down];
        [self.selectableArrows addObjectsFromArray:@[self.up, self.down]];
        [views addEntriesFromDictionary: @{@"arrowUp": self.up, @"arrowDown": self.down}];
    }
    if (self.configuration & SCUPickerViewConfigurationTwoArrowsHorizontal || self.configuration & SCUPickerViewConfigurationFourArrows)
    {
        self.left = [[SCUButton alloc] initWithImage:[UIImage imageNamed:@"white_arrow_left"]];
        self.right = [[SCUButton alloc] initWithImage:[UIImage imageNamed:@"white_arrow_right"]];
        [self.left setTag:SCUPickerViewDirectionLeft + SCUPickerViewButtonTagOffset];
        [self.right setTag:SCUPickerViewDirectionRight + SCUPickerViewButtonTagOffset];
        [self addSubview:self.left];
        [self addSubview:self.right];
        [self.selectableArrows addObjectsFromArray:@[self.left, self.right]];
        [views addEntriesFromDictionary: @{@"arrowLeft": self.left, @"arrowRight": self.right}];
    }
    
    CGFloat largerTouchArea = ([UIDevice isPhone] ? 40 : 80);
    NSDictionary *metrics = @{@"largerTouchArea" : @(largerTouchArea)};
    NSArray *formats;

    if (self.configuration & SCUPickerViewConfigurationTwoArrowsVertical || self.configuration & SCUPickerViewConfigurationTwoArrowsVerticalClimate)
    {
        if (self.configuration & SCUPickerViewConfigurationTwoArrowsVerticalClimate)
        {
            formats = @[
                        @"V:|[arrowUp(30)]",
                        @"V:[arrowDown(30)]|",
                        @"|[arrowUp]|",
                        @"|[arrowDown]|"];
            [self.centerButton removeFromSuperview];
        }
        else
        {
            formats = @[@"label.centerY = super.centerY",
                        @"label.centerX = super.centerX",
                        @"V:|[arrowUp(30)]-[label]-[arrowDown(30)]|",
                        @"|[arrowUp]|",
                        @"|[label]|",
                        @"|[arrowDown]|"];
        }
    }
    else if (self.configuration & SCUPickerViewConfigurationTwoArrowsHorizontal)
    {
       formats = @[@"label.centerX = super.centerX",
                   @"|[arrowLeft(20)]-[label]-[arrowRight(20)]|",
                   @"V:|[arrowLeft]|",
                   @"V:|[label]|",
                   @"V:|[arrowRight]|"];
    }
    else
    {
        formats = @[@"arrowLeft.centerY = super.centerY",
                    @"arrowLeft.left = super.left",
                    @"arrowRight.centerY = super.centerY",
                    @"arrowRight.right = super.right",
                    @"arrowUp.centerX = super.centerX",
                    @"arrowUp.top = super.top",
                    @"arrowDown.centerX = super.centerX",
                    @"arrowDown.bottom = super.bottom",
                    @"label.centerX = super.centerX",
                    @"label.centerY = super.centerY"];
    }

    [self addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                metrics:metrics
                                                                  views:views
                                                                formats:formats]];
    
    NSMutableArray *largerButtons = [[NSMutableArray alloc]initWithCapacity:4];
    
    for (SCUButton *button in self.selectableArrows)
    {
        button.target = self;
        button.pressAction = @selector(buttonTapped:);
        button.releaseAction = @selector(buttonPressed:);
        button.selectedColor = self.selectedTintColor;
        button.color = self.tintColor;

        SCUButton *largerButton = [[SCUButton alloc] initWithFrame:CGRectZero];
        [largerButton setTag:button.tag + SCUPickerViewButtonTagOffset];
        largerButton.target = self;
        largerButton.pressAction = @selector(buttonTapped:);
        largerButton.releaseAction = @selector(buttonPressed:);
        
        [self addSubview:largerButton];
        [self sendSubviewToBack:largerButton];
        [largerButtons addObject:largerButton];
        [self addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                    metrics:metrics
                                                                      views:@{@"button":button,
                                                                              @"largerButton":largerButton}
                                                                    formats:@[@"largerButton.centerX = button.centerX",
                                                                              @"largerButton.centerY = button.centerY",
                                                                              @"largerButton.width = largerTouchArea",
                                                                              @"largerButton.height = largerTouchArea",
                                                                              ]]];
    }
    self.largerButtons = largerButtons;
}

- (void)enlargeButtonsInPickerViewBySize:(CGFloat)size
{
    self.centerButton.bounds = CGRectMake(CGRectGetMinX(self.centerButton.bounds), CGRectGetMinY(self.centerButton.bounds), CGRectGetWidth(self.centerButton.bounds) - size, CGRectGetHeight(self.centerButton.bounds) - size);
    
    for (SCUButton *button in self.selectableArrows)
    {
        button.frame = CGRectMake(CGRectGetMinX(button.frame), CGRectGetMinY(button.frame), CGRectGetWidth(button.frame) + size, CGRectGetHeight(button.frame) + size);
        button.imageView.frame = CGRectMake(CGRectGetMinX(button.imageView.frame), CGRectGetMinY(button.imageView.frame), CGRectGetWidth(button.imageView.frame) + size, CGRectGetHeight(button.imageView.frame) + size);
        button.imageView.contentMode = UIViewContentModeScaleToFill;
    }
}

- (void)changeColorOfButtonsToColor:(UIColor *)color
{
    for (SCUButton *button in self.selectableArrows)
    {
        button.color = color;
    }
}

- (void)addHoldAction
{
    for (SCUButton *button in self.selectableArrows)
    {
        button.holdAction = @selector(buttonPressed:);
        button.holdTime = self.holdTime;
        button.holdDelay = self.holdDelay;
    }
}

- (void)buttonTapped:(SCUButton *)button
{
    SCUPickerViewDirection direction = button.tag % SCUPickerViewButtonTagOffset;

    if ([self.delegate respondsToSelector:@selector(pickerView:didTapArrowWithDirection:)])
    {
        [self.delegate pickerView:self didTapArrowWithDirection:direction];
    }
    if (self.tappedHandler)
    {
        self.tappedHandler(direction);
    }
}

- (void)buttonPressed:(SCUButton *)button
{
    SCUPickerViewDirection direction = button.tag % SCUPickerViewButtonTagOffset;

    if ([self.delegate respondsToSelector:@selector(pickerView:didSelectArrowWithDirection:)])
    {
        [self.delegate pickerView:self didSelectArrowWithDirection:direction];
    }

    if (self.handler)
    {
        self.handler(direction);
    }
}

//allows the touch to be outside the parent view container but not its parent view container, used for the larger hit region for buttons
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL inside = [super pointInside:point withEvent:event];

    if (!inside)
    {
        for (UIView *bigButton in self.largerButtons)
        {
            CGPoint newPoint = [bigButton convertPoint:point fromCoordinateSpace:self];
            inside = [bigButton pointInside:newPoint withEvent:event];
            if (inside)
            {
                break;
            }
        }
    }
    return inside;
}

#pragma mark - Properties

- (void)setSelectedTintColor:(UIColor *)selectedTintColor
{
    _selectedTintColor = selectedTintColor;

    for (SCUButton *button in self.selectableArrows)
    {
        button.selectedColor = selectedTintColor;
    }
}

- (void)setTintColor:(UIColor *)tintColor
{
    _tintColor = tintColor;

    for (SCUButton *button in self.selectableArrows)
    {
        button.color = tintColor;
    }
}

- (void)setTitle:(NSString *)title
{
    self.centerButton.title = title;
}

- (NSString *)title
{
    return self.centerButton.title;
}

- (void)setHoldTime:(CGFloat)holdTime
{
    _holdTime = holdTime;

    [self addHoldAction];
}

- (void)setHoldDelay:(CGFloat)holdDelay
{
    _holdDelay = holdDelay;

    [self addHoldAction];
}

@end

