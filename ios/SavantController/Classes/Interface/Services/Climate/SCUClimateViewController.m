//
//  SCUClimateViewController.m
//  SavantController
//
//  Created by David Fairweather on 5/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUClimateViewController.h"
#import "SCUSliderView.h"
#import "SCUButton.h"
#import "SCUSettingsContainerView.h"
#import "SCUPopoverController.h"
#import "SCUClimateServiceModel.h"
#import "SCUGradientView.h"

#import "SCUClimateViewControllerPrivate.h"

#define kServicesFirstiPadScaleValue 0.6f

@interface SCUClimateViewController () <SCUPickerViewDelegate, SCUSliderViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) SCUSettingsContainerView *settingsContainer;

@property (nonatomic) NSInteger currentBackgroundScheme;

@property (nonatomic) BOOL allowCurrentClimatePointToCenter;
@property (nonatomic) SCUClimateSetPointState climateSetPointState;

@property NSString *tabBarTitle;

@property (nonatomic) CGFloat desiredRangeSetPointLabelHeight;

@property (nonatomic) UIButton *darkeningButton;

@property (nonatomic) BOOL viewLayedOut;

@property NSMutableDictionary *lastSetPoints;
@property NSMutableDictionary *recivedSetPoints;


@property (nonatomic) NSTimer *sendSetPointsTimer;

@property (nonatomic, strong) SCUHVACPickerView *hvacPickerView;

@property (nonatomic, strong) SCUGradientView *movingCurrentPointUp;
@property (nonatomic, strong) SCUGradientView *movingCurrentPointDown;
@property (nonatomic) BOOL delayAnimation;

@end

@implementation SCUClimateViewController

- (instancetype)initWithService:(SAVService *)service
{
    self = [super initWithService:service];
    if (self)
    {
        [self initModelWithService:service];
        self.viewLayedOut = NO;
        self.isChangingUp = NO;
        self.isChangingDown = NO;
        
        self.delayAnimation = NO;
        self.visibilityTimer = nil;
        
        self.timePickerWidth = [UIDevice isPad] ? 120.0f : 70.0f;
        self.timePickerHeight = [UIDevice isPad] ? 200.0f : 100.0f;
        
        self.cornerLabelHeight = [UIDevice isPad] ? 100.0f : 100.0f;
        self.desiredSetPointLabelHeight = [UIDevice isPad] ? 146.0f : 80.0f;
        self.desiredRangeSetPointLabelHeight = [UIDevice isPad] ? 150.0f : 55.0f;

        self.titleLabelWidth = [UIDevice isPad] ? 100.0f : 70.0f;
        self.titleLabelHeight = [UIDevice isPad] ? 30.0f : 30.0f;
        
        self.centerLabelFontSize = [UIDevice isPad] ? 196.0f : 96.0f;
        self.rangeValueFontSize = [UIDevice isPad] ? 160.0f : 48.0f;
        self.cornerValueFontSize = [UIDevice isPad] ? 48.0f : 30.0f;
        self.cornerLabelFontSize = [UIDevice isPad] ? 10.0f : 7.0f;
        self.setPointPopoverFontSize = ([UIDevice isPad] ? 140.0f : 120.0f);

        self.centerLabelSuperScriptFontSize = self.centerLabelFontSize * 0.5;//default change in sub class
        self.setPointPopoverSuperScriptFontSize = self.setPointPopoverFontSize * 0.5;//default change in sub class

        self.centerButtonAndTimePickerWidth = [UIDevice isPad] ? 300.0f : 165.0f;
            
        self.offsetFromCenter = [UIDevice isPad] ? 150.0f : 80.0f;
            
        self.titleLabelFontSize = [UIDevice isPad] ? 15.0f : 10.0f;
        
        self.allowCurrentClimatePointToCenter = NO;
        self.climateSetPointState = SCUClimateSetPointStateNone;
        
        self.upDownArrowsType = SCUClimateAdjustmentNone;

        self.hvacPickerView = [[SCUHVACPickerView alloc] initWithHVACPickerModel:self.model.hvacPickerModel];
        
        [self setViewColors];
        
        if (self.lesserGradientBackground)
        {
            [self.movingCurrentPointDown setColors:self.lesserGradientBackground];
        }
        if (self.greaterGradientBackground)
        {
            [self.movingCurrentPointUp setColors:self.greaterGradientBackground];
        }
    }
    return self;
}

- (void)initModelWithService:(SAVService *)service
{
    //subclass for different model
    self.model = [[SCUClimateServiceModel alloc] initWithService:service];
    self.model.delegate = self;
}

- (void)loadView
{
    self.view = [[SCUGradientView alloc] initWithFrame:CGRectZero andColors:@[[[SCUColors shared] color03shade01], [[SCUColors shared] color03shade01]]];
    [self.gradientView setLocations:@[@(0.26), @(1)]];
    [self.sliderView setSliderVisibility:YES];
}

- (BOOL)hasHVACService
{
    return [self.hvacPickerView hasHVACService];
}

- (void)changeFormatsForServicesFirstiPadOnly
{
    self.desiredSetPointLabelHeight *= .8;
    self.timePickerWidth *= kServicesFirstiPadScaleValue;
    self.timePickerHeight *= kServicesFirstiPadScaleValue;
    self.cornerLabelHeight *= kServicesFirstiPadScaleValue;
    self.titleLabelWidth *= kServicesFirstiPadScaleValue;
    self.titleLabelHeight *= kServicesFirstiPadScaleValue;
    
    self.centerLabelFontSize *= kServicesFirstiPadScaleValue;
    self.cornerValueFontSize *= kServicesFirstiPadScaleValue;
    self.setPointPopoverFontSize *= kServicesFirstiPadScaleValue;
    
    self.centerLabelSuperScriptFontSize = self.centerLabelFontSize * 0.5;//default change in sub class
    self.setPointPopoverSuperScriptFontSize = self.setPointPopoverFontSize * 0.5;//default change in sub class
    
    self.centerButtonAndTimePickerWidth *= kServicesFirstiPadScaleValue;
    
    self.offsetFromCenter *= kServicesFirstiPadScaleValue;
    
    self.titleLabelFontSize *= kServicesFirstiPadScaleValue;
    self.rangeValueFontSize *= 0.46;
}

- (SCUGradientView *)gradientView
{
    return (SCUGradientView *)self.view;
}

- (void)setServicesFirst:(BOOL)servicesFirst
{
    if (self.servicesFirst != servicesFirst && servicesFirst && self.viewLayedOut && [UIDevice isPad])
    {
        [super setServicesFirst:servicesFirst];

        [self layoutSubviews];

        [self.currentClimatePointLabel  setAttributedText:[self attributedStringForClimateString:[self.currentClimatePointLabel.attributedText string] labelType:SCUClimateValueLabelCenter]];
        [self.desiredSetPointLabel      setAttributedText:[self attributedStringForClimateString:[self.desiredSetPointLabel.attributedText string]     labelType:SCUClimateValueLabelCenter]];
        [self.lowSetPointValueLabel     setAttributedText:[self attributedStringForClimateString:[self.lowSetPointValueLabel.attributedText string]    labelType:SCUClimateValueLabelCenterRangeLow]];
        [self.highSetPointValueLabel    setAttributedText:[self attributedStringForClimateString:[self.highSetPointValueLabel.attributedText string]   labelType:SCUClimateValueLabelCenterRangeHigh]];
    }
    else
    {
        [super setServicesFirst:servicesFirst];
    }
}

- (SCUSliderViewConfiguration)sliderConfiguration
{
    SCUSliderViewConfiguration sliderConfiguration = SCUSliderViewConfigurationVertical;
    
    if ([self.model sliderIsTappableOnly])
    {
        sliderConfiguration = sliderConfiguration | SCUSliderViewConfigurationTapOnly;
    }
    
    if ([self.model sliderHasMultipleSetPoints])
    {
        sliderConfiguration = sliderConfiguration | SCUSliderViewConfigurationMultipleHandles;
    }
    
    return sliderConfiguration;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.viewLayedOut = YES;
    UIColor *whiteAlhph4 = [UIColor sav_colorWithRGBValue:0xffffff alpha:0.04];
    
    
    self.darkeningButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.darkeningButton addTarget:self action:@selector(backToCurrentValueMode) forControlEvents:UIControlEventTouchUpInside];

    [self.darkeningButton setBackgroundColor:[UIColor blackColor]];
    [self.darkeningButton setAlpha:0];
    [self.contentView addSubview:self.darkeningButton];

    self.currentBackgroundScheme = SCUGradientBackgroundColorSchemeNormal;
    
    self.sliderView = [[SCUSliderView alloc] initWithFrame:CGRectZero andConfiguration:[self sliderConfiguration]];
    self.sliderView.minDeadband = self.model.minimumDeadband;
    self.sliderView.delegate = self;
    
    self.currentClimatePointLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.currentClimatePointLabel.textColor = [[SCUColors shared] color04];
    self.currentClimatePointLabel.textAlignment = NSTextAlignmentLeft;
    self.currentClimatePointLabel.alpha = 1.0f;
    
    self.currentTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.currentTitleLabel.textAlignment = NSTextAlignmentLeft;
    self.currentTitleLabel.textColor = self.currentClimatePointLabel.textColor;
    self.currentTitleLabel.text = NSLocalizedString(@"CURRENT", nil);
    self.currentTitleLabel.alpha = 0;
    
    self.desiredSetPointLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.desiredSetPointLabel.textColor = [[SCUColors shared] color04];
    self.desiredSetPointLabel.textAlignment = NSTextAlignmentRight;
    self.desiredSetPointLabel.alpha = 0;
    
    self.doAtSetPointLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.doAtSetPointLabel.textColor = [[SCUColors shared] color04];
    self.doAtSetPointLabel.textAlignment = NSTextAlignmentRight;
    self.doAtSetPointLabel.alpha = 0;

    //self.currentClimatePointLabel.adjustsFontSizeToFitWidth = YES;
    self.currentClimatePointLabel.minimumScaleFactor = 0.5;
    
    self.desiredTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.desiredTitleLabel.textColor = [[SCUColors shared] color04];
    self.desiredTitleLabel.textAlignment = NSTextAlignmentLeft;
    self.desiredTitleLabel.text = @"Desired";
    self.desiredTitleLabel.alpha = 0;
    
    self.doAtTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.doAtTitleLabel.textColor = [[SCUColors shared] color04];
    self.doAtTitleLabel.textAlignment = NSTextAlignmentLeft;
    self.doAtTitleLabel.alpha = 0;
    
    self.highSetPointValueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.highSetPointValueLabel.textAlignment = NSTextAlignmentRight;
    self.highSetPointValueLabel.alpha = 0.0f;
    
    self.lowSetPointValueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.lowSetPointValueLabel.textColor =  self.sliderView.minPointColor;
    self.lowSetPointValueLabel.textAlignment = NSTextAlignmentLeft;
    self.lowSetPointValueLabel.alpha = 0;
    
    self.rangeSetPointTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.rangeSetPointTitleLabel.textColor = [[SCUColors shared] color04];
    self.rangeSetPointTitleLabel.textAlignment = NSTextAlignmentLeft;
    self.rangeSetPointTitleLabel.text = NSLocalizedString(@"DESIRED RANGE", nil);
    self.rangeSetPointTitleLabel.alpha = 0;

    self.dashLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.dashLabel.textColor = [[SCUColors shared] color04];
    self.dashLabel.textAlignment = NSTextAlignmentCenter;
    self.dashLabel.text = @"-";
    self.dashLabel.alpha = 0;
    
    [self.contentView addSubview:self.sliderView];
    [self.contentView addSubview:self.currentClimatePointLabel];
    [self.contentView addSubview:self.currentTitleLabel];
    [self.contentView addSubview:self.desiredSetPointLabel];
    [self.contentView addSubview:self.desiredTitleLabel];
    
    [self.contentView addSubview:self.lowSetPointValueLabel];
    [self.contentView addSubview:self.dashLabel];
    [self.contentView addSubview:self.highSetPointValueLabel];
    [self.contentView addSubview:self.rangeSetPointTitleLabel];
    
    [self.contentView addSubview:self.doAtTitleLabel];
    [self.contentView addSubview:self.doAtSetPointLabel];
    
    self.timePickerBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:self.timePickerBackgroundView];
    
    self.timePicker = [[SCUSetChangePickerView alloc] initWithFrame:CGRectZero];
    self.timePicker.backgroundColor = whiteAlhph4;

    [self.contentView addSubview:self.timePicker];
    [self.contentView bringSubviewToFront:self.timePicker];
    
    self.timePicker.alpha = 0;
    
    self.centerButtonAndTimePickerHeight = self.timePicker.componentHeight;
    
    self.timePicker.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tap.numberOfTapsRequired = 1;
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
    
    self.upDownArrows = [[SCUPickerView alloc] initWithFrame:CGRectZero andConfiguration:SCUPickerViewConfigurationTwoArrowsVerticalClimate];
    self.upDownArrows.delegate = self;
    [self.contentView addSubview:self.upDownArrows];
    
    self.upDownArrowsForOverLay = [[SCUPickerView alloc] initWithFrame:CGRectZero andConfiguration:SCUPickerViewConfigurationTwoArrowsVerticalClimate];
    self.upDownArrowsForOverLay.delegate = self;
    [self.contentView addSubview:self.upDownArrowsForOverLay];
    self.upDownArrowsForOverLay.alpha = 0;
    
    if (self.settingsContainer)
    {
        [self.contentView addSubview:self.settingsContainer];
        [self.settingsContainer loadView];
    }
    
    [self layoutSubviews];
}

- (void)layoutSubviews
{
    //-------------------------------------------------------------------
    // Layout Constraints
    //-------------------------------------------------------------------
    
    [self.contentView removeConstraints:self.contentView.constraints];
    
    CGFloat titleOffsetFromLabel = [self widthOfSuffixCharacterWithFont:
                                    [UIFont fontWithName:@"Gotham-ExtraLight"
                                                    size:self.centerLabelSuperScriptFontSize]];
    
    BOOL needAdjustmentForServicesFirst = [UIDevice isPad] && self.isServicesFirst;
    
    CGFloat arrowValueOffsetFromCenter = [UIDevice isPad] ? 124.0f : 60.0f;

    CGFloat centerValueLabelOffset = ([UIDevice isPad] ? 82.0f : 30.0f) + titleOffsetFromLabel;
    
    CGFloat dashCenterOffset = ([UIDevice isPad] ? 80.0 : 50.0f);
    CGFloat rangeLabelOffset = ([UIDevice isPad] ? 80.0 : -16.0f);
    CGFloat lowValueCenterOffset = ([UIDevice isPad] ? 210.0 : 68.0f);
    CGFloat highValueCenterOffset = ([UIDevice isPad] ? 276.0f : 85.0f);
    
    CGFloat settingsPadding = ([UIDevice isPad] ? 30.0f : 16.0f);
    
    CGFloat cornerValueHOffset = ([UIDevice isPad] ? 10.0f : 12.0f);
    CGFloat cornerValueVOffset = ([UIDevice isPad] ? -90.0 : -40.0f);
    
    CGFloat cornerTitleOffset = [UIDevice isPad] ? 45.0f : 16.0f;
    CGFloat cornerValueHight = [UIDevice isPad] ? 58.0f : 38;
    CGFloat darkeningButtonOffsetRight = -100;
    CGFloat arrowOffSetForServiesFirst = 0;
    if (needAdjustmentForServicesFirst)
    {
        [self changeFormatsForServicesFirstiPadOnly];
        darkeningButtonOffsetRight = -30;
        cornerTitleOffset = 20;
        centerValueLabelOffset = titleOffsetFromLabel ;
        arrowValueOffsetFromCenter *= kServicesFirstiPadScaleValue;
        cornerValueHOffset *= kServicesFirstiPadScaleValue;
        
        cornerValueVOffset *= kServicesFirstiPadScaleValue;
        lowValueCenterOffset *= 0.46;
        highValueCenterOffset *= 0.46;
        dashCenterOffset += 16;
        arrowOffSetForServiesFirst = 14 + centerValueLabelOffset;
    }
    self.dashLabel.font = [UIFont fontWithName:@"Gotham-Thin" size:self.rangeValueFontSize];
    self.doAtTitleLabel.font = [UIFont fontWithName:@"Gotham" size:self.titleLabelFontSize];
    self.currentTitleLabel.font = [UIFont fontWithName:@"Gotham" size:self.titleLabelFontSize];
    self.desiredTitleLabel.font = [UIFont fontWithName:@"Gotham" size:self.titleLabelFontSize];
    self.rangeSetPointTitleLabel.font = [UIFont fontWithName:@"Gotham" size:self.titleLabelFontSize];
    [self.rangeSetPointTitleLabel sizeToFit];
    [self.dashLabel sizeToFit];
    
    self.titleOffsetFromCorrnerLabel = [self widthOfSuffixCharacterWithFont:
                                        [UIFont fontWithName:@"Gotham-ExtraLight"
                                                        size:self.cornerLabelSuperScriptFontSize]];// [UIDevice isPad] ? 38.0f : 18.0f;
    
    NSDictionary *metrics = @{
                              @"cornerTitleOffset": @(cornerTitleOffset),
                              @"titleWidth": @(self.titleLabelWidth),
                              @"cornerValueHOffset": @(cornerValueHOffset),
                              @"cornerValueVOffset": @(cornerValueVOffset),
                              @"cornerValueHight":@(cornerValueHight),
                              @"centerOptionsWidth": @(self.centerButtonAndTimePickerWidth),
                              @"centerOffset": @(self.offsetFromCenter),
                              @"centerOffset": @(self.offsetFromCenter),
                              @"centerOptionsHeight": @(self.centerButtonAndTimePickerHeight),
                              @"centerLabelHeight": @(self.desiredSetPointLabelHeight),
                              @"updownArrowsHeight": @(self.desiredSetPointLabelHeight - (([UIDevice isPad] && self.servicesFirst) ? 24 : 0)),
                              @"upDownArrowsWidth":@(80),
                              @"upDownArrowsOffset":@(80 - 44 - 15),
                              @"desiredClimatePickerCenterOffset": @((self.centerButtonAndTimePickerWidth / 2) + arrowOffSetForServiesFirst + 20),
                              @"centerValueLabelOffset": @(centerValueLabelOffset),
                              @"settingsPadding": @(settingsPadding),
                              @"desiredRangeSetPointLabelHeight": @(self.desiredRangeSetPointLabelHeight),
                              @"dashCenterOffset":@(dashCenterOffset),
                              @"highValueOffset":@(highValueCenterOffset),
                              @"lowValueOffset":@(lowValueCenterOffset),
                              @"rangeLabelOffset":@(rangeLabelOffset),
                              @"sliderWidth":@(self.sliderView.minimumWidth),
                              @"darkeningButtonOffset":@(-100),
                              @"darkeningButtonOffsetRight":@(darkeningButtonOffsetRight),
                              @"arrowValueOffsetFromCenter":@(arrowValueOffsetFromCenter),
                              @"doAtLabelOffset":@([UIDevice isPad] ? 10 : 4),
                              };
    
    NSMutableDictionary *views = [@{
                                    @"currentValue": self.currentClimatePointLabel,
                                    @"currentTitle": self.currentTitleLabel,
                                    @"desiredValue": self.desiredSetPointLabel,
                                    @"timePicker": self.timePicker,
                                    @"timePickerBG": self.timePickerBackgroundView,
                                    @"desiredTitle": self.desiredTitleLabel,
                                    @"upDownArrows":self.upDownArrows,
                                    @"upDownArrowsForOverLay":self.upDownArrowsForOverLay,
//                                    centerButtonAndTimePickerWidth
                                    @"lowSetPointValueLabel": self.lowSetPointValueLabel,
                                    @"highSetPointValueLabel": self.highSetPointValueLabel,
                                    @"dashLabel": self.dashLabel,
                                    @"rangeSetPointTitleLabel": self.rangeSetPointTitleLabel,
                                    @"sliderView": self.sliderView,
                                    @"darkeningButton":self.darkeningButton,
                                    @"doAtTitleLabel":self.doAtTitleLabel,
                                    @"doAtSetPointLabel":self.doAtSetPointLabel,
                                    } mutableCopy];
    
    NSMutableArray *formats = [@[
                                 @"[sliderView(sliderWidth)]|",
                                 @"V:|[sliderView]|",
                                 
                                 @"|-(darkeningButtonOffsetRight)-[darkeningButton]-(darkeningButtonOffset)-|",
                                 @"V:|-(darkeningButtonOffset)-[darkeningButton]-(darkeningButtonOffset)-|",
                                 
                                 @"|-(cornerTitleOffset)-[currentTitle(titleWidth)]",
                                 @"V:|-(cornerTitleOffset)-[currentTitle]",
                                 
                                 @"desiredTitle.centerY = super.centerY / 2",
                                 (needAdjustmentForServicesFirst ?  @"|-[desiredTitle]" : @"desiredTitle.centerX = super.centerX - centerOffset"),
                                 
                                 @"rangeSetPointTitleLabel.centerY = super.centerY / 2",
                                 @"rangeSetPointTitleLabel.left = lowSetPointValueLabel.left",
                                 
                                 @"desiredValue.right = super.centerX + centerValueLabelOffset",
                                 @"V:[desiredTitle][desiredValue(centerLabelHeight)]-[timePicker(centerOptionsHeight)]",
                                 
                                 @"dashLabel.centerX = super.centerX - dashCenterOffset",
                                 @"V:[rangeSetPointTitleLabel][dashLabel]",
                                 
                                 @"highSetPointValueLabel.right = dashLabel.centerX + highValueOffset",
                                 @"V:[rangeSetPointTitleLabel][highSetPointValueLabel]",
                                 
                                 @"lowSetPointValueLabel.left = dashLabel.left - lowValueOffset",
                                 @"V:[rangeSetPointTitleLabel][lowSetPointValueLabel]",
                                 
                                 @"timePicker.width = centerOptionsWidth",
                                 @"timePicker.centerX = super.centerX - centerOffset",
                                 
                                 @"upDownArrows.width = upDownArrowsWidth",
                                 @"upDownArrows.height = updownArrowsHeight",
                                 @"upDownArrows.centerY = desiredValue.centerY",
                                 [UIDevice isPhone] ?
                                 @"upDownArrows.right = super.centerX - 84":
                                 @"upDownArrows.right = super.centerX - desiredClimatePickerCenterOffset",
                                 
                                 @"doAtTitleLabel.left = doAtSetPointLabel.left + doAtLabelOffset",
                                 @"doAtTitleLabel.height = desiredTitle.height",
                                 @"doAtTitleLabel.centerY = desiredTitle.centerY",
                                 
                                 @"doAtSetPointLabel.left = super.centerX - arrowValueOffsetFromCenter",
                                 @"doAtSetPointLabel.height = centerLabelHeight",
                                 @"doAtSetPointLabel.centerY = desiredValue.centerY",
                                 
                                 @"upDownArrowsForOverLay.right = doAtSetPointLabel.left + upDownArrowsOffset",
                                 @"upDownArrowsForOverLay.height = upDownArrows.height",
                                 @"upDownArrowsForOverLay.width = upDownArrows.width",
                                 @"upDownArrowsForOverLay.centerY = upDownArrows.centerY",
                                 ] mutableCopy];
    
    if (self.settingsContainer)
    {
        [views setValue:self.settingsContainer forKey:@"settingsContainer"];
        
        [formats addObjectsFromArray:@[@"|-(settingsPadding)-[settingsContainer]",
                                       @"V:[settingsContainer]-(settingsPadding)-|"]];
    }
    
    [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                            metrics:metrics
                                                                              views:views
                                                                            formats:formats]];
    
    self.centeredConstraint = [NSLayoutConstraint sav_constraintsWithOptions:0
                                                                     metrics:metrics
                                                                       views:views
                                                                     formats:[self centerConstraintFormatsForView]];
    
    self.cornerConstraint = [NSLayoutConstraint
                             sav_constraintsWithOptions:0
                             metrics:metrics
                             views:views
                             formats:[self cornerConstraintFormatsForView]];
    
    [self.contentView addConstraints:self.centeredConstraint];
    
    if (!self.isChangingUp || !self.isChangingDown)
    {
        [self.gradientView setColors:self.normalGradientBackground];
    }
    
    [self setupSliderAndPickerViews];
    self.highSetPointValueLabel.textColor = self.sliderView.maxPointColor;
    self.lowSetPointValueLabel.textColor =  self.sliderView.minPointColor;

    [self setAttributedStringForLabel:self.currentClimatePointLabel withValue:NSNotFound];
    [self setAttributedStringForLabel:self.desiredSetPointLabel withValue:NSNotFound];
    [self setAttributedStringForLabel:self.lowSetPointValueLabel withValue:NSNotFound];
    [self setAttributedStringForLabel:self.highSetPointValueLabel withValue:NSNotFound];
}

- (NSArray *)cornerConstraintFormatsForView
{
    return @[
             @"currentValue.centerX = currentTitle.centerX - cornerValueHOffset", //super.right - cornerValueHOffset",
             @"V:[currentTitle]-(cornerValueVOffset)-[currentValue]",
             ];
}

- (NSArray *)centerConstraintFormatsForView
{
    return @[
             @"currentValue.right = desiredValue.right",
             @"currentValue.height = centerLabelHeight",
             @"V:[currentValue]-[timePicker(centerOptionsHeight)]"
             ];
}

- (void)setupSliderAndPickerViews
{
    self.upDownArrows.hidden = ![self.model canShowSetPointPicker];
    self.upDownArrows.userInteractionEnabled = !self.upDownArrows.hidden;
    
    //shouldn't to 0 at startup should wait till values are fetched
    [self.sliderView setScaleOfSliderFrom:[self.model sliderMinimumValue]
                                       To:[self.model sliderMaximumValue]];
    [self.sliderView setColorOfMainHandle:[[SCUColors shared] color04]];
}

- (void)setViewColors
{
    //white with alpha
    self.inCornerLabelColor = [UIColor sav_colorWithRGBValue:0Xffffff alpha:0.6f];

    if ([self.greaterGradientBackground count] > 1)
    {
        self.movingCurrentPointUp = [[SCUGradientView alloc] initWithFrame:CGRectZero andColors:self.greaterGradientBackground];
        [self.movingCurrentPointUp setLocations:@[@(0.26), @(1)]];
        [self.movingCurrentPointUp setAlpha:0.0];
        [self.view addSubview:self.movingCurrentPointUp];
        [self.view sendSubviewToBack:self.movingCurrentPointUp];
        [self.view sav_addFlushConstraintsForView:self.movingCurrentPointUp];
    }
    if ([self.lesserGradientBackground count] > 1)
    {
        self.movingCurrentPointDown = [[SCUGradientView alloc] initWithFrame:CGRectZero andColors:self.lesserGradientBackground];
        [self.movingCurrentPointDown setLocations:@[@(0.26), @(1)]];
        [self.movingCurrentPointDown setAlpha:0.0];
        [self.view addSubview:self.movingCurrentPointDown];
        [self.view sendSubviewToBack:self.movingCurrentPointDown];
        [self.view sav_addFlushConstraintsForView:self.movingCurrentPointDown];
    }
    // child view controllers
}

- (void)handleTap:(UITapGestureRecognizer *)tap
{
    UIView *tapFrame = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    tapFrame.center = [tap locationInView:self.view];
    switch (tap.state)
    {
        case UIGestureRecognizerStateRecognized:
            if (CGRectIntersectsRect(self.timePicker.frame, tapFrame.frame))
            {
                [self.timePicker showPickerVisibility:YES];
            }
            else
            {
                [self.timePicker showPickerVisibility:NO];
            }
            
            break;
        case UIGestureRecognizerStateBegan:
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStatePossible:
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateFailed:
            break;
    }
}

- (void)activateAutoClimateMode:(SCUButton *)button
{
    if (self.model.selectedPrimaryMode != [self.model savEntityStateForSCUClimateModeType:(SCUClimateModeAuto) allowSubstitute:YES])
    {
        [self.model sendServiceRequestForSAVEntityState:[self.model savEntityStateForSCUClimateModeType:(SCUClimateModeAuto) allowSubstitute:YES]];
    }
}

- (void)currentClimatePointFallBackToCenter
{
    [self animateLabelToCorner:NO withTimer:NO];
}

- (void)hideSetPointPickerView
{
    self.allowCurrentClimatePointToCenter = YES;
    self.sliderView.setPointPopUp = NO;
    [self forceToCenter];
}

- (void)animateLabelToCorner:(BOOL)inCorner withTimer:(BOOL)isTimed
{
    if (inCorner)
    {
        CGFloat desiredPointFloat = self.sliderView.desiredValue;
        CGFloat lowPointFloat = self.sliderView.lowSliderValue;
        CGFloat highPointFloat = self.sliderView.highSliderValue;
        
        NSInteger desiredPoint;
        NSInteger lowPoint;
        NSInteger highPoint;
        
        if (fabs(desiredPointFloat - NSNotFound) < 1 || desiredPointFloat < -1000)
        {
            desiredPoint = NSNotFound;
        }
        else
        {
            desiredPoint = (NSInteger)(desiredPointFloat + 0.5);
        }
        if (fabs(lowPointFloat - NSNotFound) < 1 || lowPointFloat < -1000)
        {
            lowPoint = NSNotFound;
        }
        else
        {
            lowPoint = (NSInteger)(lowPointFloat + 0.5);
        }
        if (fabs(highPointFloat - NSNotFound) < 1 || highPointFloat < -1000)
        {
            highPoint = NSNotFound;
        }
        else
        {
            highPoint = (NSInteger)(highPointFloat + 0.5);
        }
        
        SAVEntityState currentSetState = self.model.selectedPrimaryMode;

        if (currentSetState == [self.model savEntityStateForSCUClimateModeType:(SCUClimateModeAuto) allowSubstitute:NO])
        {
            if (highPoint == NSNotFound)
            {
                highPoint = self.model.maxSetPoint;
            }
            if (lowPoint == NSNotFound)
            {
                lowPoint = self.model.maxSetPoint;
            }
            if (lowPoint != NSNotFound && highPoint != NSNotFound)
            {
                [self setAttributedStringForLabel:self.highSetPointValueLabel withValue:highPoint];
                [self setAttributedStringForLabel:self.lowSetPointValueLabel  withValue:lowPoint];
            }
            else
            {
                inCorner = NO;
            }
        }
        else
        {
            if (desiredPoint == NSNotFound)
            {
                if (currentSetState == [self.model savEntityStateForSCUClimateModeType:(SCUClimateModeAutoSingleSetPoint) allowSubstitute:NO])
                {
                    desiredPoint = self.model.desiredPoint;
                }
                else if (currentSetState == [self.model savEntityStateForSCUClimateModeType:SCUClimateModeDecrease allowSubstitute:NO])
                {
                    desiredPoint = self.model.maxSetPoint;
                }
                else if (currentSetState == [self.model savEntityStateForSCUClimateModeType:SCUClimateModeIncrease allowSubstitute:NO])
                {
                    desiredPoint = self.model.minSetPoint;
                }
            }
            if (desiredPoint != NSNotFound)
            {
                [self setAttributedStringForLabel:self.desiredSetPointLabel withValue:desiredPoint];
            }
            else
            {
                inCorner = NO;
            }
        }
    }
    
    BOOL shouldBeInConner = (inCorner || !self.allowCurrentClimatePointToCenter) &&
    (([self.model isSingleSetPoint] && [self doesLabelHaveValue:self.desiredSetPointLabel]) ||
     (![self.model isSingleSetPoint] && [self doesLabelHaveValue:self.highSetPointValueLabel] && [self doesLabelHaveValue:self.lowSetPointValueLabel]));
    SCUClimateSetPointState setPointState = shouldBeInConner ? SCUClimateSetPointStateInConner : SCUClimateSetPointStateNone;
    if (setPointState != self.climateSetPointState || self.sliderView.setPointPopUp == YES)
    {
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveLinear animations:^{
                                if (shouldBeInConner)
                                {
                                    self.allowCurrentClimatePointToCenter = NO;
                                    self.climateSetPointState = SCUClimateSetPointStateInConner;
                                    [self.sliderView setSliderVisibility:YES];

                                    [self startSliderSetPointAddjustment];

                                    self.doAtSetPointLabel.alpha = 0.0;
                                    self.doAtTitleLabel.alpha = 0.0;
                                    self.upDownArrows.alpha = 0.0;
                                    self.upDownArrowsType = SCUClimateAdjustmentNone;
                                }
                                else
                                {
                                    [self.sliderView setSliderVisibility:NO];

                                    [self endSliderSetPointAddjustment];
                                    
                                    if (!self.sliderView.setPointPopUp)
                                    {
                                        self.climateSetPointState = SCUClimateSetPointStateNone;

                                        [self.contentView sendSubviewToBack:self.darkeningButton];
                                        self.darkeningButton.alpha = 0.0;
                                        
                                        self.doAtSetPointLabel.alpha = 0.0;
                                        self.doAtTitleLabel.alpha = 0.0;
                                        
                                        self.upDownArrowsType = SCUClimateAdjustmentNone;

                                        self.upDownArrowsForOverLay.alpha = 0.0;
                                        self.upDownArrowsForOverLay.userInteractionEnabled = NO;
                                        
                                        self.upDownArrows.alpha = 0.0;
                                        self.upDownArrows.userInteractionEnabled = NO;
                                    }
                                    else
                                    {
                                        self.climateSetPointState = SCUClimateSetPointStateArrowViewUp;
                                        [self.contentView bringSubviewToFront:self.darkeningButton];
                                        [self.contentView bringSubviewToFront:self.upDownArrowsForOverLay];
                                        [self.contentView bringSubviewToFront:self.doAtSetPointLabel];
                                        [self.contentView bringSubviewToFront:self.doAtTitleLabel];
                                        self.darkeningButton.alpha = 0.88;
                                        self.doAtSetPointLabel.alpha = 1.0;
                                        self.doAtTitleLabel.alpha = 1.0;
                                        self.currentClimatePointLabel.alpha = 0;

                                        self.upDownArrowsForOverLay.alpha = 1.0;
                                        self.upDownArrowsForOverLay.userInteractionEnabled = YES;
                                        
                                        self.upDownArrows.alpha = 1.0;
                                        self.upDownArrows.userInteractionEnabled = [self.model canShowSetPointPicker];
                                    }
                                }
                                
                                [self.currentClimatePointLabel layoutIfNeeded];
                                [self.currentTitleLabel layoutIfNeeded];

                            } completion:nil];
    }
    
    if ((isTimed && inCorner) || self.sliderView.setPointPopUp)
    {
        if (self.visibilityTimer)
        {
            [self.visibilityTimer invalidate];
            self.visibilityTimer = nil;
        }
        SAVWeakSelf;
        self.visibilityTimer = [NSTimer sav_scheduledTimerWithTimeInterval:5.0f
                                                                   repeats:NO
                                                                     block:
                                ^{
                                    [wSelf hideSetPointPickerView];
                                }];
    }
}

- (void)startSliderSetPointAddjustment
{
    if (self.centeredConstraint)
    {
        [self.contentView removeConstraints:self.centeredConstraint];
    }
    if (self.cornerConstraint)
    {
        [self.contentView removeConstraints:self.cornerConstraint];
    }

    [self.contentView addConstraints:self.cornerConstraint];
    [self scaleCurrentValueLable];
    
    if ([self.model isSingleSetPoint])
    {
        self.desiredSetPointLabel.alpha = 1.0f; //= self.desiredTitleLabel.alpha
        self.highSetPointValueLabel.alpha = self.lowSetPointValueLabel.alpha = self.dashLabel.alpha = self.rangeSetPointTitleLabel.alpha = 0.0f;
    }
    else
    {
        self.desiredSetPointLabel.alpha = self.desiredTitleLabel.alpha = 0.0f;
        self.highSetPointValueLabel.alpha = self.lowSetPointValueLabel.alpha = self.dashLabel.alpha = self.rangeSetPointTitleLabel.alpha = 1.0f;
    }
    self.currentTitleLabel.alpha = 1.0f;
    self.currentTitleLabel.textColor = self.currentClimatePointLabel.textColor = self.inCornerLabelColor;
    
    [self.contentView sendSubviewToBack:self.settingsContainer];
    self.darkeningButton.alpha = 0.88;
}

- (void)endSliderSetPointAddjustment
{
    if (self.centeredConstraint)
    {
        [self.contentView removeConstraints:self.centeredConstraint];
    }
    if (self.cornerConstraint)
    {
        [self.contentView removeConstraints:self.cornerConstraint];
    }

    self.currentClimatePointLabel.transform = CGAffineTransformMakeScale(1.0, 1.0);
    [self.contentView addConstraints:self.centeredConstraint];

    [self setFontForClimateLabel:self.currentClimatePointLabel inCorner:NO];
    [self.contentView addConstraints:self.centeredConstraint];
    
    self.desiredTitleLabel.alpha = self.desiredSetPointLabel.alpha = 0.0f;
    self.highSetPointValueLabel.alpha = self.lowSetPointValueLabel.alpha = self.dashLabel.alpha = self.rangeSetPointTitleLabel.alpha = 0.0f;
    self.currentTitleLabel.textColor = self.currentClimatePointLabel.textColor = [[SCUColors shared] color04];
    self.currentTitleLabel.alpha = 0.0f;
    
    if (!self.sliderView.setPointPopUp)
    {
        self.currentClimatePointLabel.alpha = 1;
    }
    else
    {
        self.currentClimatePointLabel.alpha = 0;
    }
}

- (void)scaleCurrentValueLable
{
    CGFloat scaleFactor = 0.3f;
    
    self.currentClimatePointLabel.transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
}

- (BOOL)doesLabelHaveValue:(UILabel *)valueLabel
{
    return ([valueLabel.text length] > 0 ||
            [valueLabel.attributedText length] > 0) &&
    !([[valueLabel.attributedText string] containsString:@"--"] ||
      [valueLabel.text containsString:@"--"]);
}

- (void)backToCurrentValueMode
{
    self.sliderView.setPointPopUp = NO;
    self.upDownArrowsType = SCUClimateAdjustmentNone;
    [self forceToCenter];
}
               
- (void)forceToCenter
{
    self.allowCurrentClimatePointToCenter = YES;
    [self currentClimatePointFallBackToCenter];
}

#pragma mark - Tab Bar Controller

- (SCUMainToolbarItems)mainToolbarItems
{
    SCUMainToolbarItems items = SCUMainToolbarItemsLeftButtons;
    if (!self.servicesFirst)
    {
        items = items | ([UIDevice isPad] ? SCUMainToolbarItemsCenterButtons : SCUMainToolbarItemsRightButtons);
    }
    return  items;
}

#pragma mark Center Toolbar Items

- (NSArray *)mainToolbarRightItems
{
    return @[[self.hvacPickerView labelOrHVACSelector]];
}

- (NSArray *)mainToolbarCenterItems
{
    return @[[self.hvacPickerView labelOrHVACSelector]];
}

- (void)changeService
{
    self.visibilityTimer = nil;
    [self forceToCenter];
    [self turnOffFeedbackTimer];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(currentClimatePointFallBackToCenter) object:nil];
    [self backToCurrentValueMode];
    
    self.climateSetPointState = SCUClimateSetPointStateNone;
    [self setAttributedStringForLabel:self.currentClimatePointLabel withValue:NSNotFound];
    [self setAttributedStringForLabel:self.desiredSetPointLabel withValue:NSNotFound];
    [self setAttributedStringForLabel:self.lowSetPointValueLabel withValue:NSNotFound];
    [self setAttributedStringForLabel:self.highSetPointValueLabel withValue:NSNotFound];
    
    if (self.model.entity)
    {
        if (self.model && self.model.settingsModel)
        {
            if (!self.settingsContainer)
            {
                self.settingsContainer = [[SCUSettingsContainerView alloc] initWithSettingsContainerModel:self.model.settingsModel];
                if (self.settingsContainer)
                {
                    CGFloat settingsPadding = ([UIDevice isPad] ? 30.0f : 16.0f);
                    [self.contentView addSubview:self.settingsContainer];
                    [self.settingsContainer setModel:self.model.settingsModel];
                    [self.settingsContainer loadView];
                    [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                                            metrics:@{@"settingsPadding": @(settingsPadding)}
                                                                                              views:@{@"settingsContainer": self.settingsContainer}
                                                                                            formats:@[@"|-(settingsPadding)-[settingsContainer]",
                                                                                                      @"V:[settingsContainer]-(settingsPadding)-|"]]];
                }
            }
            else
            {
                [self.settingsContainer setModel:self.model.settingsModel];
            }
        }
    }
}

- (UIColor *)tabBarButtonColor
{
    return [[SCUColors shared] color01];
}

- (void)changeBackgroundColors:(SCUGradientBackgroundColorScheme)scheme
{
    BOOL isCurrentScheme = (self.currentBackgroundScheme == scheme);
    self.currentBackgroundScheme = scheme;
    if (!isCurrentScheme)
    {
        self.delayAnimation = YES;
        SAVWeakSelf;
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             switch (scheme)
                             {
                                 case SCUGradientBackgroundColorSchemeDecreaseCurrentClimatePoint:
                                 {
                                     if (self.movingCurrentPointDown)
                                     {
                                         [self.movingCurrentPointDown setAlpha:0];
                                     }
                                     if (self.movingCurrentPointUp)
                                     {
                                         [self.movingCurrentPointUp setAlpha:1];
                                     }
                                     [self.view sendSubviewToBack:self.movingCurrentPointDown];
                                     break;
                                 }
                                 case SCUGradientBackgroundColorSchemeIncreaseCurrentClimatePoint:
                                 {
                                     if (self.movingCurrentPointDown)
                                     {
                                         [self.movingCurrentPointDown setAlpha:1];
                                     }
                                     if (self.movingCurrentPointUp)
                                     {
                                         [self.movingCurrentPointUp setAlpha:0];
                                     }
                                     [self.view sendSubviewToBack:self.movingCurrentPointUp];
                                     break;
                                 }
                                 case SCUGradientBackgroundColorSchemeNormal:
                                     self.timePicker.userInteractionEnabled = NO;
                                     self.timePicker.alpha = 0.0f;
                                     self.timePickerBackgroundView.alpha = 0;
                                 {
                                     if (self.movingCurrentPointDown)
                                     {
                                         [self.movingCurrentPointDown setAlpha:0];
                                     }
                                     if (self.movingCurrentPointUp)
                                     {
                                         [self.movingCurrentPointUp setAlpha:0];
                                     }
                                     break;
                                 }
                             }
                         }
                         completion:^(BOOL finished) {
                             wSelf.delayAnimation = NO;
                         }];
    }
}

- (void)waitForFeedback:(NSDictionary *)valueDict
{
    [self turnOffFeedbackTimer];

    SAVWeakSelf;
    self.feedbackWaitTimer = [NSTimer sav_scheduledTimerWithTimeInterval:5.0f repeats:NO block:^{
        if (valueDict[@"desired"])
        {
            if (wSelf.model.desiredPoint != [valueDict[@"desired"] integerValue])
            {
                if (wSelf.model.desiredPoint == NSNotFound)
                {
                    [wSelf performSelectorOnMainThread:@selector(currentClimatePointFallBackToCenter) withObject:nil waitUntilDone:NO];
                }
                else
                {
                    [wSelf.sliderView changeValueOfHandleToValue:wSelf.model.desiredPoint];
                }
            }
        }
        
        if (valueDict[@"min"])
        {
            if (wSelf.model.minSetPoint != [valueDict[@"min"] integerValue])
            {
                [wSelf.sliderView changeValueOfMinPointToValue:wSelf.model.minSetPoint];
            }
            if (wSelf.model.selectedPrimaryMode == [wSelf.model savEntityStateForSCUClimateModeType:SCUClimateModeIncrease allowSubstitute:YES])
            {
                if (wSelf.model.desiredPoint == NSNotFound)
                {
                    [wSelf performSelectorOnMainThread:@selector(currentClimatePointFallBackToCenter) withObject:nil waitUntilDone:NO];
                }
            }
        }
        
        if (valueDict[@"max"])
        {
            if (wSelf.model.maxSetPoint != [valueDict[@"max"] integerValue])
            {
                [wSelf.sliderView changeValueOfMaxPointToValue:wSelf.model.maxSetPoint];
            }
            if (wSelf.model.selectedPrimaryMode == [wSelf.model savEntityStateForSCUClimateModeType:SCUClimateModeDecrease allowSubstitute:YES])
            {
                if (wSelf.model.desiredPoint == NSNotFound)
                {
                    [wSelf performSelectorOnMainThread:@selector(currentClimatePointFallBackToCenter) withObject:nil waitUntilDone:NO];
                }
            }
        }
    }];
}

- (void)turnOffFeedbackTimer
{
    if (self.feedbackWaitTimer)
    {
        [self.feedbackWaitTimer invalidate];
        self.feedbackWaitTimer = nil;
    }
}

- (void)resendSetPointsToModel
{
    if (self.lastSetPoints)
    {
        if (self.lastSetPoints[@(SCUClimateAdjustmentSetDesiredClimatePoint)])
        {
            [self.model climatePointAdjustmentType:SCUClimateAdjustmentSetDesiredClimatePoint setValue:self.lastSetPoints[@(SCUClimateAdjustmentSetDesiredClimatePoint)]];
        }
        if (self.lastSetPoints[@(SCUClimateAdjustmentSetMinPoint)])
        {
            [self.model climatePointAdjustmentType:SCUClimateAdjustmentSetMinPoint setValue:self.lastSetPoints[@(SCUClimateAdjustmentSetMinPoint)]];
        }
        if (self.lastSetPoints[@(SCUClimateAdjustmentSetMaxPoint)])
        {
            [self.model climatePointAdjustmentType:SCUClimateAdjustmentSetMaxPoint setValue:self.lastSetPoints[@(SCUClimateAdjustmentSetMaxPoint)]];
        }
        [self removeLastSetPoints];
    }
}

- (void)setLastSetPoint:(NSInteger)setPoint setpointType:(SCUClimateAdjustmentType)type
{
    if (!self.lastSetPoints)
    {
        self.lastSetPoints = [NSMutableDictionary dictionary];
    }
    self.lastSetPoints[@(type)] = @(setPoint);
}

- (void)removeLastSetPoints
{
    if (self.lastSetPoints)
    {
        [self.lastSetPoints removeAllObjects];
    }
}

- (void)sendSetPointsToSlider:(NSDictionary *)setPoints
{
    if (setPoints)
    {
        if (setPoints[@(SCUClimateAdjustmentSetDesiredClimatePoint)])
        {
            [self.sliderView changeValueOfHandleToValue:[setPoints[@(SCUClimateAdjustmentSetDesiredClimatePoint)] floatValue]];
        }
        if (setPoints[@(SCUClimateAdjustmentSetMinPoint)])
        {
            [self.sliderView changeValueOfMinPointToValue:[setPoints[@(SCUClimateAdjustmentSetMinPoint)] floatValue]];
        }
        if (setPoints[@(SCUClimateAdjustmentSetMaxPoint)])
        {
            [self.sliderView changeValueOfMaxPointToValue:[setPoints[@(SCUClimateAdjustmentSetMaxPoint)] floatValue]];
        }
        [self removeRecivedSetPoints];
        [self turnOffFeedbackTimer];
    }
}

- (void)setRecivedSetPoints:(NSInteger)setPoint setpointType:(SCUClimateAdjustmentType)type
{
    if (self.sendSetPointsTimer)
    {
        [self.sendSetPointsTimer invalidate];
        self.sendSetPointsTimer = nil;
    }
    
    if (!self.recivedSetPoints)
    {
        self.recivedSetPoints = [NSMutableDictionary dictionary];
    }
    self.recivedSetPoints[@(type)] = @(setPoint);
    if ([self.model isSingleSetPoint])
    {
        [self sendSetPointsToSlider:self.recivedSetPoints];
    }
    else
    {
        SAVWeakSelf;
        self.sendSetPointsTimer = [NSTimer sav_scheduledTimerWithTimeInterval:2.0f repeats:NO block:^{
            [wSelf sendSetPointsToSlider:self.recivedSetPoints];
        }];
    }
}

- (void)removeRecivedSetPoints
{
    if (self.recivedSetPoints)
    {
        [self.recivedSetPoints removeAllObjects];
    }
    if (self.sendSetPointsTimer)
    {
        [self.sendSetPointsTimer invalidate];
        self.sendSetPointsTimer = nil;
    }
}

- (void)updateScale
{
    [self.sliderView setScaleOfSliderFrom:self.model.sliderMinimumValue To:self.model.sliderMaximumValue];
}

- (void)adjustClimatePoint:(SCUClimateAdjustmentType)type forValue:(NSInteger)value
{
    [self.model climatePointAdjustmentType:type setValue:@(value)];
    [self setLastSetPoint:value setpointType:type];
}

#pragma SCUSliderViewDelegate - methods

- (void)sliderView:(SCUSliderView *)sliderView didChangeMultipleValuesWithHighestValue:(NSInteger)high andLowestValue:(NSInteger)low andDesiredValue:(NSInteger)value andHeldDown:(BOOL)hold
{
    if (!hold)
    {
        if (value > -1000 && low < -1000 && high < -1000)
        {
            [self.model climatePointAdjustmentType:SCUClimateAdjustmentSetDesiredClimatePoint setValue:@(value)];
            [self setLastSetPoint:value setpointType:SCUClimateAdjustmentSetDesiredClimatePoint];
        }
        
        BOOL setMin = (self.model.minSetPoint != low && low > -1000);
        BOOL setMax = (self.model.maxSetPoint != high && high > -1000);
        
        if (self.model.minSetPoint - low > 0) // if new values are lower then the old value only need to check one since if only one point changes the other is not set
        {
            if (setMax && setMin)
            {
                if ([self.lastSetPoints[@(SCUClimateAdjustmentSetMaxPoint)] integerValue] < high && [self.lastSetPoints[@(SCUClimateAdjustmentSetMinPoint)] integerValue] < low)
                {
                    [self adjustClimatePoint:SCUClimateAdjustmentSetMaxPoint forValue:high];
                    [self adjustClimatePoint:SCUClimateAdjustmentSetMinPoint forValue:low];
                }
                else
                {
                    [self adjustClimatePoint:SCUClimateAdjustmentSetMinPoint forValue:low];
                    [self adjustClimatePoint:SCUClimateAdjustmentSetMaxPoint forValue:high];
                }
            }
            else
            {
                if (setMax)
                {
                    [self adjustClimatePoint:SCUClimateAdjustmentSetMaxPoint forValue:high];
                }
                if (setMin)
                {
                    [self adjustClimatePoint:SCUClimateAdjustmentSetMinPoint forValue:low];
                }
            }
        }
        else
        {
            if (setMax && setMin)
            {
                if ([self.lastSetPoints[@(SCUClimateAdjustmentSetMaxPoint)] integerValue] < high && [self.lastSetPoints[@(SCUClimateAdjustmentSetMinPoint)] integerValue] < low)
                {
                    [self adjustClimatePoint:SCUClimateAdjustmentSetMaxPoint forValue:high];
                    [self adjustClimatePoint:SCUClimateAdjustmentSetMinPoint forValue:low];
                }
                else
                {
                    [self adjustClimatePoint:SCUClimateAdjustmentSetMinPoint forValue:low];
                    [self adjustClimatePoint:SCUClimateAdjustmentSetMaxPoint forValue:high];
                }
            }
            else
            {
                if (setMax)
                {
                    [self adjustClimatePoint:SCUClimateAdjustmentSetMaxPoint forValue:high];
                }
                if (setMin)
                {
                    [self adjustClimatePoint:SCUClimateAdjustmentSetMinPoint forValue:low];
                }
            }
        }
        
        NSDictionary *feedbackDictionary = @{@"desired": @(value),
                                             @"max": @(high),
                                             @"min": @(low)};
        
        [self waitForFeedback:feedbackDictionary];
    }
    [self animateLabelToCorner:YES withTimer:YES];
}

- (void)sliderView:(SCUSliderView *)sliderView didChangeValueWithDesiredValue:(CGFloat)value andHeldDown:(BOOL)hold
{
    NSDictionary *feedbackDictionary = [[NSDictionary alloc] init];
    
    if (!hold)
    {
        if (self.model.selectedPrimaryMode == [self.model savEntityStateForSCUClimateModeType:SCUClimateModeIncrease allowSubstitute:YES])
        {
            [self.model climatePointAdjustmentType:SCUClimateAdjustmentSetMinPoint setValue:@(value)];
            feedbackDictionary = @{@"min": @(value)};
        }
        else if (self.model.selectedPrimaryMode == [self.model savEntityStateForSCUClimateModeType:SCUClimateModeDecrease allowSubstitute:YES])
        {
            [self.model climatePointAdjustmentType:SCUClimateAdjustmentSetMaxPoint setValue:@(value)];
            
            feedbackDictionary = @{@"max": @(value)};
        }
        else if (self.model.selectedPrimaryMode == [self.model savEntityStateForSCUClimateModeType:SCUClimateModeAutoSingleSetPoint allowSubstitute:NO])
        {
            [self.model climatePointAdjustmentType:SCUClimateAdjustmentSetDesiredClimatePoint setValue:@(value)];
            
            feedbackDictionary = @{@"desired": @(value)};
        }
        
        [self waitForFeedback:feedbackDictionary];
    }
    
    if (self.model.selectedPrimaryMode == [self.model savEntityStateForSCUClimateModeType:SCUClimateModeOff allowSubstitute:NO])
    {
        if (self.model.desiredPoint != value)
        {
            [self.model climatePointAdjustmentType:SCUClimateAdjustmentSetDesiredClimatePoint setValue:@(value)];
            feedbackDictionary = @{@"desired": @(value)};
            [self waitForFeedback:feedbackDictionary];
        }
        
        [self.model sendServiceRequestForSAVEntityState:[self.model savEntityStateForSCUClimateModeType:SCUClimateModeDecrease allowSubstitute:YES]];
    }
    else
    {
        if (self.isChangingUp || self.isChangingDown || hold)
        {
            [self animateLabelToCorner:YES withTimer:NO];
        }
        else
        {
            [self animateLabelToCorner:YES withTimer:YES];
        }
    }
}

- (void)sliderView:(SCUSliderView *)slider didSelectSetPointHandle:(SCUHandleType)handleType
{
    slider.setPointPopUp = YES;
    self.climateSetPointState = SCUClimateSetPointStateArrowViewUp;
    [self forceToCenter];

    SCUClimateModeType climateSetPointType;
    if ([self.model selectedPrimaryMode] == [self.model savEntityStateForSCUClimateModeType:SCUClimateModeAutoSingleSetPoint allowSubstitute:NO])
    {
        climateSetPointType = SCUClimateModeAutoSingleSetPoint;
    }
    else
    {
        switch (handleType)
        {
            case SCUHandleCenterSetPoint:
                if ([self.model selectedPrimaryMode] == [self.model savEntityStateForSCUClimateModeType:SCUClimateModeDecrease allowSubstitute:NO])
                {
                    climateSetPointType = SCUClimateModeDecrease;
                }
                else if ([self.model selectedPrimaryMode] == [self.model savEntityStateForSCUClimateModeType:SCUClimateModeIncrease allowSubstitute:NO])
                {
                    climateSetPointType = SCUClimateModeIncrease;
                }
                else if ([self.model selectedPrimaryMode] == [self.model savEntityStateForSCUClimateModeType:SCUClimateModeAutoSingleSetPoint allowSubstitute:NO])
                {
                    climateSetPointType = SCUClimateModeAutoSingleSetPoint;
                }
                else if ([self.model selectedPrimaryMode] == [self.model savEntityStateForSCUClimateModeType:SCUClimateModeAuto allowSubstitute:NO])
                {
                    climateSetPointType = SCUClimateModeAuto;
                }
                else
                {
                    climateSetPointType = SCUClimateModeOff;
                }
                break;
            case SCUHandleHighSetPoint:
                climateSetPointType = SCUClimateModeDecrease;
                break;
            case SCUHandleLowSetPoint:
                climateSetPointType = SCUClimateModeIncrease;
                break;
        }
    }

    UIColor *setPointTextColor;
    NSInteger currentSetPoint = NSNotFound;
    SCUClimateAdjustmentType adjustmentType = SCUClimateAdjustmentNone;
    switch (climateSetPointType)
    {
        case SCUClimateModeDecrease:
            setPointTextColor = slider.maxPointColor;
            currentSetPoint = self.model.maxSetPoint;
            adjustmentType = SCUClimateAdjustmentSetMaxPoint;
            self.doAtTitleLabel.text = [self atClimateChangeDownText];
            break;
        case SCUClimateModeIncrease:
            setPointTextColor = slider.minPointColor;
            currentSetPoint = self.model.minSetPoint;
            adjustmentType = SCUClimateAdjustmentSetMinPoint;
            self.doAtTitleLabel.text = [self atClimateChangeUpText];
            break;
        default:
            setPointTextColor = [[SCUColors shared] color04];
            currentSetPoint = self.model.desiredPoint;
            adjustmentType = SCUClimateAdjustmentSetDesiredClimatePoint;
            self.doAtTitleLabel.text = nil;
            break;
    }
    if (currentSetPoint != NSNotFound)
    {
        self.doAtSetPointLabel.attributedText =  [self attributedStringForClimateString:[self.model climateValueWithAppendedSuffix:[NSString stringWithFormat:@"%li", (long)currentSetPoint]]
                                                                              labelType:SCUClimateValueLabelCenter];
        self.doAtSetPointLabel.textColor = setPointTextColor;
        self.doAtTitleLabel.textColor = setPointTextColor;
        
        self.upDownArrowsType = adjustmentType;
    }
}

- (NSString *)interpretedDisplayValue:(NSInteger)value
{
    return [self.model climateValueWithAppendedSuffix:[NSString stringWithFormat:@"%ld", (long)value]];
}

- (NSDictionary *)getCurrentSetPoints
{
    NSMutableDictionary *setPoints = [@{} mutableCopy];
    
    if (self.model.currentClimatePoint != NSNotFound)
    {
        [setPoints setObject:@(self.model.currentClimatePoint) forKey:SCUSliderCurrentValue];
    }
    
    if (self.model.minSetPoint != NSNotFound)
    {
        [setPoints setObject:@(self.model.minSetPoint) forKey:SCUSliderLowSetPoint];
    }
    
    if (self.model.maxSetPoint != NSNotFound)
    {
        [setPoints setObject:@(self.model.maxSetPoint) forKey:SCUSliderHighSetPoint];
    }
    
    if (self.model.desiredPoint != NSNotFound)
    {
        [setPoints setObject:@(self.model.desiredPoint) forKey:SCUSliderMiddleSetPoint];
    }
    
    return setPoints;
}

- (void)didTouchNonHandlePartOfSlider
{
    [self forceToCenter];
}

#pragma SCUPickerViewDelegate - methods

- (void)pickerView:(SCUPickerView *)pickerView didSelectArrowWithDirection:(SCUPickerViewDirection)direction
{
    SCUClimateAdjustmentType adjustmentType = SCUClimateAdjustmentNone;
    SAVEntityState mode = self.model.selectedPrimaryMode;

    if (mode == [self.model.settingsModel.modesDictionary[@(SCUClimateModeDecrease)] integerValue])
    {
        adjustmentType = SCUClimateAdjustmentSetMaxPoint;
    }
    else if (mode == [self.model.settingsModel.modesDictionary[@(SCUClimateModeIncrease)] integerValue])
    {
        adjustmentType = SCUClimateAdjustmentSetMinPoint;
    }
    else if (mode == [self.model.settingsModel.modesDictionary[@(SCUClimateModeAutoSingleSetPoint)] integerValue])
    {
        adjustmentType = SCUClimateAdjustmentSetDesiredClimatePoint;
    }
    else if (mode == [self.model.settingsModel.modesDictionary[@(SCUClimateModeAuto)] integerValue] ||
             mode == [self.model.settingsModel.modesDictionary[@(SAVEntityState_ModeOff)] integerValue])
    {
        if (self.upDownArrowsType == SCUClimateAdjustmentNone)
        {
            adjustmentType = SCUClimateAdjustmentSetDesiredClimatePoint;
        }
        else
        {
            adjustmentType = self.upDownArrowsType;
        }
    }
    
    switch (adjustmentType)
    {
        case SCUClimateAdjustmentSetMaxPoint:
        {
            if (direction == SCUPickerViewDirectionUp)
            {
                adjustmentType = SCUClimateAdjustmentIncrementMaxPoint;
            }
            else if (direction == SCUPickerViewDirectionDown)
            {
                adjustmentType = SCUClimateAdjustmentDecrementMaxPoint;
            }
            else
            {
                adjustmentType = SCUClimateAdjustmentNone;
            }
        }
            break;
        case SCUClimateAdjustmentSetDesiredClimatePoint:
        {
            if (direction == SCUPickerViewDirectionUp)
            {
                adjustmentType = SCUClimateAdjustmentIncrementDesiredClimatePoint;
            }
            else if (direction == SCUPickerViewDirectionDown)
            {
                adjustmentType = SCUClimateAdjustmentDecrementDesiredClimatePoint;
            }
            else
            {
                adjustmentType = SCUClimateAdjustmentNone;
            }
        }
            break;
        case SCUClimateAdjustmentSetMinPoint:
        {
            if (direction == SCUPickerViewDirectionUp)
            {
                adjustmentType = SCUClimateAdjustmentIncrementMinPoint;
            }
            else if (direction == SCUPickerViewDirectionDown)
            {
                adjustmentType = SCUClimateAdjustmentDecrementMinPoint;
            }
            else
            {
                adjustmentType = SCUClimateAdjustmentNone;
            }
        }
            break;
        case SCUClimateAdjustmentNone:
        default:
            break;
    }
    
    if (adjustmentType != SCUClimateAdjustmentNone)
    {
        if (self.visibilityTimer)
        {
            [self.visibilityTimer invalidate];
            self.visibilityTimer = nil;
        }
        
        if (self.sliderView.setPointPopUp)
        {
            SAVWeakSelf;
            self.visibilityTimer = [NSTimer sav_scheduledTimerWithTimeInterval:5.0f
                                                                       repeats:NO
                                                                         block:
                                    ^{
                                        [wSelf hideSetPointPickerView];
                                    }];
        }

        [self.model climatePointAdjustmentType:adjustmentType setValue:nil];
    }    
}

//SCUClimateModeType is used as used as a setpointType
- (void)climateAdjustmentWithDirection:(SCUPickerViewDirection)direction forClimateSetPointType:(SCUClimateModeType)climateModeType
{
    SCUClimateAdjustmentType adjustmentTypeUp = SCUClimateAdjustmentNone;
    SCUClimateAdjustmentType adjustmentTypeDown = SCUClimateAdjustmentNone;
    
    switch (climateModeType)
    {
        case SCUClimateModeIncrease://cool or low setpoint
            adjustmentTypeUp = SCUClimateAdjustmentIncrementMinPoint;
            adjustmentTypeDown = SCUClimateAdjustmentDecrementMinPoint;
            break;
        case SCUClimateModeDecrease://heat or high setpoint
            adjustmentTypeUp = SCUClimateAdjustmentIncrementMaxPoint;
            adjustmentTypeDown = SCUClimateAdjustmentDecrementMaxPoint;
            break;
        case SCUClimateModeAuto://auto or desired setpoint
        case SCUClimateModeAutoSingleSetPoint:
            adjustmentTypeUp = SCUClimateAdjustmentIncrementDesiredClimatePoint;
            adjustmentTypeDown = SCUClimateAdjustmentDecrementDesiredClimatePoint;
            break;
        default:
            break;
    }
    BOOL up = (direction == SCUPickerViewDirectionUp);
    if (adjustmentTypeDown != SCUClimateAdjustmentNone && adjustmentTypeUp != SCUClimateAdjustmentNone)
    {
        [self.model climatePointAdjustmentType:up ? adjustmentTypeUp : adjustmentTypeDown setValue:nil];
    }
    [self.sliderView setSliderVisibility:YES];
}

#pragma Model Delegate methods

- (void)didReceiveClimateSetPointMode:(SAVEntityState)mode
{

}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    dispatch_async_main(^{
        [self forceToCenter];
    });
}

- (void)receivedCurrentClimatePoint:(NSNumber *)value
{
    NSInteger numberValue = NSNotFound;
    
    if (value)
    {
        if ([value isKindOfClass:[NSString class]] && [((NSString *)value) length] > 0)
        {
            numberValue = [value integerValue];
        }
        else if ([value isKindOfClass:[NSNumber class]])
        {
            numberValue = [value integerValue];
        }
    }
    if (numberValue != NSNotFound)
    {
        [self.sliderView changeCurrentHandleToValue:numberValue];
        
        NSString *displayText = [self setAttributedStringForLabel:self.currentClimatePointLabel withValue:numberValue];
        
        self.tabBarTitle = displayText;
    }
}

- (void)receivedClimateSetPoint:(NSNumber *)value setPointType:(SCUClimateAdjustmentType)setPointType
{
    NSInteger numberValue = NSNotFound;

    if (value)
    {
        if ([value isKindOfClass:[NSString class]] && [((NSString *)value) length] > 0)
        {
            numberValue = [value integerValue];
        }
        else if ([value isKindOfClass:[NSNumber class]])
        {
            numberValue = [value integerValue];
        }
    }
    if (numberValue != NSNotFound)
    {
        [self turnOffFeedbackTimer];
        
        SAVEntityState targetState = SAVEntityState_Unknown;
        
        switch (setPointType)
        {
            case SCUClimateAdjustmentSetMinPoint:
                [self setRecivedSetPoints:numberValue setpointType:SCUClimateAdjustmentSetMinPoint];
                targetState = [self.model savEntityStateForSCUClimateModeType:SCUClimateModeIncrease allowSubstitute:YES];
                break;
            case SCUClimateAdjustmentSetMaxPoint:
                [self setRecivedSetPoints:numberValue setpointType:SCUClimateAdjustmentSetMaxPoint];
                targetState = [self.model savEntityStateForSCUClimateModeType:SCUClimateModeDecrease allowSubstitute:YES];
                break;
            case SCUClimateAdjustmentSetDesiredClimatePoint:
            {
                SAVEntityState currentSetState = self.model.selectedPrimaryMode;
                NSInteger desiredPoint = NSNotFound;

                if (currentSetState == [self.model savEntityStateForSCUClimateModeType:SCUClimateModeAutoSingleSetPoint allowSubstitute:NO] && currentSetState != SAVEntityState_Unknown)
                {
                    [self setRecivedSetPoints:numberValue setpointType:SCUClimateAdjustmentSetDesiredClimatePoint];
                    desiredPoint = self.model.desiredPoint;

                }
                else if (currentSetState == [self.model savEntityStateForSCUClimateModeType:SCUClimateModeAuto allowSubstitute:NO])
                {
                    if (self.model.maxSetPoint != NSNotFound)
                    {
                        [self setAttributedStringForLabel:self.highSetPointValueLabel withValue:self.sliderView.highSliderValue + 0.5];
                    }
                    if (self.model.minSetPoint != NSNotFound)
                    {
                        [self setAttributedStringForLabel:self.lowSetPointValueLabel withValue:self.sliderView.lowSliderValue + 0.5];
                    }
                }
                else if (currentSetState == [self.model savEntityStateForSCUClimateModeType:SCUClimateModeDecrease allowSubstitute:YES])
                {
                    desiredPoint = self.model.maxSetPoint;
                }
                else if (currentSetState == [self.model savEntityStateForSCUClimateModeType:SCUClimateModeIncrease allowSubstitute:YES])
                {
                    desiredPoint = self.model.minSetPoint;
                }

                if (desiredPoint != NSNotFound)
                {
                    [self setAttributedStringForLabel:self.desiredSetPointLabel withValue:desiredPoint];
                }
            }
                break;
            default:
                break;
        }
        if (targetState != SAVEntityState_Unknown &&
            self.model.selectedPrimaryMode != [self.model savEntityStateForSCUClimateModeType:SCUClimateModeAuto allowSubstitute:YES] &&
            SAVEntityState_Unknown != [self.model savEntityStateForSCUClimateModeType:SCUClimateModeAuto allowSubstitute:YES])
        {
            if (self.model.selectedPrimaryMode == targetState)
            {
                [self setRecivedSetPoints:numberValue setpointType:SCUClimateAdjustmentSetDesiredClimatePoint];
            }
        }
    }
    if (setPointType == self.upDownArrowsType)
    {
        self.doAtSetPointLabel.attributedText = [self attributedStringForClimateString:[self.model climateValueWithAppendedSuffix:
                                                                                        [NSString stringWithFormat:@"%li", (long)[value integerValue]]]
                                                                             labelType:SCUClimateValueLabelCenter];
    }
}

- (void)actionToChangeCurrentClimatePoint
{
    if (self.delayAnimation)
    {
        [self performSelector:@selector(actionToChangeCurrentClimatePoint) withObject:nil afterDelay:2.0];
        return;
    }
    self.isChangingUp = [self.model isIncreasingCurrentClimatePoint];
    self.isChangingDown = [self.model isDecreasingCurrentClimatePoint];
    
    if ([self.model isIncreasingCurrentClimatePoint])
    {
        [self changeBackgroundColors:SCUGradientBackgroundColorSchemeIncreaseCurrentClimatePoint];
    }
    else if ([self.model isDecreasingCurrentClimatePoint])
    {
        [self changeBackgroundColors:SCUGradientBackgroundColorSchemeDecreaseCurrentClimatePoint];
    }
    else if (![self.model isIncreasingCurrentClimatePoint] && ![self.model isDecreasingCurrentClimatePoint])
    {
        [self changeBackgroundColors:SCUGradientBackgroundColorSchemeNormal];
    }
}

- (NSString *)setToChangeDownText
{
    if (!_setToChangeDownText)
    {
        _setToChangeDownText = [NSString stringWithFormat:@"Set To %@", self.notificationChangingDownText];
    }
    return _setToChangeDownText;
}

- (NSString *)setToChangeUpText
{
    if (!_setToChangeUpText)
    {
        _setToChangeUpText = [NSString stringWithFormat:@"Set To %@", self.notificationChangingUpText];
    }
    return _setToChangeUpText;
}

- (NSString *)atClimateChangeDownText
{
    if (!_atClimateChangeDownText)
    {
        _atClimateChangeDownText = [NSString stringWithFormat:@"%@ AT", self.notificationChangingDownText];
    }
    return _atClimateChangeDownText;
}

- (NSString *)atClimateChangeUpText
{
    if (!_atClimateChangeUpText)
    {
        _atClimateChangeUpText = [NSString stringWithFormat:@"%@ AT", self.notificationChangingUpText];
    }
    return _atClimateChangeUpText;
}

- (NSString *)textForUpDownSetPointType:(SCUClimateModeType)setPointType
{
    NSString *text;
    switch (setPointType)
    {
        case SCUClimateModeAuto:
        case SCUClimateModeAutoSingleSetPoint:
            text = [NSString stringWithFormat:NSLocalizedString(@"Set %@ Point", nil), NSLocalizedString(@"Desired", nil)];
            break;
        case SCUClimateModeDecrease:
            text = [NSString stringWithFormat:NSLocalizedString(@"Set %@ Point", nil), self.notificationChangingDownText];
            break;
        case SCUClimateModeIncrease:
            text = [NSString stringWithFormat:NSLocalizedString(@"Set %@ Point", nil), self.notificationChangingUpText];
            break;
        default:
            break;
    }
    return text;
}

- (NSString *)turnOnIncreaseCurrentClimatePointText
{
    return [NSString stringWithFormat:NSLocalizedString(@"Turn On %@", @"HVAC turn on heating cooling or humidity"), self.notificationChangingUpText];
}

- (NSString *)turnOnDecreaseCurrentClimatePointText
{
    return [NSString stringWithFormat:NSLocalizedString(@"Turn On %@", @"HVAC turn on heating cooling or humidity"), self.notificationChangingDownText];
}

- (NSString *)setAttributedStringForLabel:(UILabel *)label withValue:(NSInteger)value
{
    //value = 100;
    NSAttributedString *oldString = label.attributedText;
    NSUInteger oldStringLength = [oldString length];

    UIFont *numberFont;
    UIFont *superScriptFont;
    CGFloat superScriptOffset;
    if (oldStringLength > 0)
    {
        numberFont = [oldString attributesAtIndex:0 effectiveRange:nil][NSFontAttributeName];
    }
    if (oldStringLength == 1 && [[oldString string] integerValue] > 0)
    {
        oldStringLength = 2;
    }
    NSString *climateValue = (value == NSNotFound) ? @"--" : [NSString stringWithFormat:@"%li", (long)value];
    NSString *climateValueWithAppendedSuffix;
    
    if (label && label == self.lowSetPointValueLabel)
    {
        climateValueWithAppendedSuffix = climateValue;
    }
    else
    {
        climateValueWithAppendedSuffix = [self.model climateValueWithAppendedSuffix:climateValue];
    }
    
    if (label && climateValueWithAppendedSuffix)
    {
        NSInteger suffixPosition = [climateValueWithAppendedSuffix length] - 1;
        
        NSMutableAttributedString *attributedClimateValueWithAppendedSuffix = [[[NSAttributedString alloc] initWithString:climateValueWithAppendedSuffix] mutableCopy];
        BOOL isInCorner = NO;
        switch (oldStringLength)
        {
            case 1:
                isInCorner = (numberFont.pointSize == self.cornerValueFontSize);
            case 0:
                [label setAttributedText:attributedClimateValueWithAppendedSuffix];
                [self setFontForClimateLabel:label inCorner:isInCorner];
                break;
            default: // >= 2
                if ([climateValue isEqualToString:climateValueWithAppendedSuffix])
                {
                    [attributedClimateValueWithAppendedSuffix addAttribute:NSFontAttributeName value:numberFont range:NSMakeRange(0, [climateValueWithAppendedSuffix length])];
                }
                else
                {
                    superScriptFont = [oldString attributesAtIndex:(oldStringLength - 1) effectiveRange:nil][NSFontAttributeName];
                    superScriptOffset = [[oldString attributesAtIndex:(oldStringLength - 1) effectiveRange:nil][NSBaselineOffsetAttributeName] floatValue];
                    
                    [attributedClimateValueWithAppendedSuffix addAttribute:NSFontAttributeName value:superScriptFont range:NSMakeRange(suffixPosition, 1)];
                    [attributedClimateValueWithAppendedSuffix addAttribute:NSBaselineOffsetAttributeName value:@(superScriptOffset) range:NSMakeRange(suffixPosition, 1)];
                    
                    [attributedClimateValueWithAppendedSuffix addAttribute:NSFontAttributeName value:numberFont range:NSMakeRange(0, suffixPosition)];
                }
                [label setAttributedText:attributedClimateValueWithAppendedSuffix];
                break;
        }
    }
    return climateValueWithAppendedSuffix;
}

- (void)setFontForClimateLabel:(UILabel *)label inCorner:(BOOL)inCorner
{
    SCUClimateValueLabelType labelType = inCorner ? SCUClimateValueLabelCorner : SCUClimateValueLabelCenter;
    if (labelType == SCUClimateValueLabelCenter)
    {
        if (label == self.highSetPointValueLabel)
        {
            labelType = SCUClimateValueLabelCenterRangeHigh;
        }
        else if (label == self.lowSetPointValueLabel)
        {
            labelType = SCUClimateValueLabelCenterRangeLow;
        }
    }
    NSAttributedString *newAttributedString = [self attributedStringForClimateString:[label.attributedText string] labelType:labelType];
  
    [label setAttributedText:newAttributedString];
}

- (NSAttributedString *)attributedStringForClimateString:(NSString *)string labelType:(SCUClimateValueLabelType)labelType
{
    NSMutableAttributedString *newAttributedString = [[NSMutableAttributedString alloc] initWithString:string];
    NSUInteger stringLength = [newAttributedString length];
    CGFloat numberFontSize;
    CGFloat superScriptFontSize;
    switch (labelType)
    {
        case SCUClimateValueLabelCenterRangeHigh:
            numberFontSize = self.rangeValueFontSize;
            superScriptFontSize = ((self.centerLabelSuperScriptFontSize / self.centerLabelFontSize) * self.rangeValueFontSize);
            break;
        case SCUClimateValueLabelCenterRangeLow:
            numberFontSize = self.rangeValueFontSize;
            superScriptFontSize = 0;
            break;
        case SCUClimateValueLabelCenter:
            numberFontSize = self.centerLabelFontSize;
            superScriptFontSize = self.centerLabelSuperScriptFontSize;
            break;
        case SCUClimateValueLabelCorner:
            numberFontSize = self.cornerValueFontSize;
            superScriptFontSize = self.cornerLabelSuperScriptFontSize;
            break;
        case SCUClimateValueLabelSetPointPopover:
            numberFontSize = self.setPointPopoverFontSize;
            superScriptFontSize = self.setPointPopoverSuperScriptFontSize;
            break;
    }
    if (stringLength > 0)
    {
        [newAttributedString removeAttribute:NSFontAttributeName range:NSMakeRange(0, stringLength)];
        [newAttributedString removeAttribute:NSBaselineOffsetAttributeName range:NSMakeRange(0, stringLength)];
        
        UIFont *numberFont = [UIFont fontWithName:@"Gotham-ExtraLight"
                                             size:numberFontSize];
        UIFont *superScriptFont = [UIFont fontWithName:@"Gotham-ExtraLight"
                                                  size:superScriptFontSize];
        
        [newAttributedString addAttribute:NSFontAttributeName
                                    value:numberFont
                                    range:NSMakeRange(0, stringLength - 1)];
        
        [newAttributedString addAttribute:NSFontAttributeName
                                    value:superScriptFont
                                    range:NSMakeRange(stringLength - 1, 1)];
        [newAttributedString addAttribute:NSBaselineOffsetAttributeName
                                    value:@(((numberFont.lineHeight / 1.0) - superScriptFont.lineHeight * 1.0) / 1.7)
                                    range:NSMakeRange(stringLength - 1, 1)];
    }
    return newAttributedString;
}

- (CGFloat)widthOfSuffixCharacterWithFont:(UIFont *)font
{
    NSString *stringChar = [self.model climateValueWithAppendedSuffix:@" "];
    stringChar = [stringChar stringByReplacingOccurrencesOfString:@" " withString:@""];// may require removing /1.7 at end of method 
    NSUInteger stringLength = [stringChar length];
    
    CGFloat width = 0.0f;
    if (stringLength >= 1)
    {
        NSMutableDictionary *attributes = [[NSMutableDictionary alloc] initWithCapacity:1];
        attributes[NSFontAttributeName] = font;
        CGSize textSize = [stringChar sizeWithAttributes:attributes];
        width = textSize.width;// [UIDevice isPad] ? 38.0f : 18.0f;
    }
    return width / 1.7f;
}

- (void)settingsButtonPressed:(SCUButton *)button
{
    [self.settingsContainer settingsButtonPressed:button];
}

- (void)setModel:(SCUClimateServiceModel *)model
{
    [super setModel:model];

    if ([model isKindOfClass:[SCUClimateServiceModel class]] && self.model && self.model.settingsModel)
    {
        self.settingsContainer = [[SCUSettingsContainerView alloc] initWithSettingsContainerModel:self.model.settingsModel];
    }
}

- (NSInteger)contentViewPadding
{
    return [UIDevice isPad] ? 4 : 0;
}

#pragma mark - SCUMainToolbarManager

- (BOOL)mainToolbarIsVisible
{
    return YES;
}

@end
