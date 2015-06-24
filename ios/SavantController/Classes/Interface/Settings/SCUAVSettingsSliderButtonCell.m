//
//  SCUAVSliderButtonCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 5/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVSettingsSliderButtonCell.h"
#import <SavantExtensions/SavantExtensions.h>

@interface SCUAVSettingsSliderButtonCell ()

@property (nonatomic) SCUButton *minusButton;

@property (nonatomic) SCUButton *addButton;

@property (nonatomic) SCUSlider *slider;

@property (nonatomic) SCUCenteredSlider *centerSlider;

@property (nonatomic) UILabel *topLabel;

@property (nonatomic) UILabel *topValueLabel;

@property (nonatomic) SCUButton *bottomButton;

@end

NSString *const SCUAVSettingsSliderButtonCellKeyTopTitle    = @"SCUAVSettingsSliderButtonCellKeyTopTitle";
NSString *const SCUAVSettingsSliderButtonCellKeyTopValue    = @"SCUAVSettingsSliderButtonCellKeyTopValue";
NSString *const SCUAVSettingsSliderButtonCellKeyBottomTitle = @"SCUAVSettingsSliderButtonCellKeyBottomTitle";
NSString *const SCUAVSettingsSliderButtonCellSliderType     = @"SCUAVSettingsSliderButtonCellSliderType";
NSString *const SCUAVSettingsSliderButtonCellSliderValue    = @"SCUAVSettingsSliderButtonCellSliderValue";
NSString *const SCUAVSettingsSliderCellValueRange           = @"SCUAVSettingsSliderCellValueRange";

@implementation SCUAVSettingsSliderButtonCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        //--------------------------------------------------------
        // Minus button setup
        //--------------------------------------------------------
        self.minusButton = [[SCUButton alloc] initWithTitle:@"-"];
        self.minusButton.titleLabel.font = [UIFont systemFontOfSize:30.0f];
        self.minusButton.frame = CGRectZero;
        self.minusButton.backgroundColor = [UIColor clearColor];
        [self.minusButton setSelectedBackgroundColor:[UIColor clearColor]];
        [self.minusButton setTitleColor:[[SCUColors shared] color01] forState:UIControlStateNormal];

        [self.contentView addSubview:self.minusButton];

        //--------------------------------------------------------
        // Add button setup
        //--------------------------------------------------------
        self.addButton = [[SCUButton alloc] initWithTitle:@"+"];
        self.addButton.titleLabel.font = [UIFont systemFontOfSize:30.0f];
        self.addButton.frame = CGRectZero;
        self.addButton.backgroundColor = [UIColor clearColor];
        self.addButton.titleLabel.textColor = [[SCUColors shared] color01];
        [self.addButton setTitleColor:[[SCUColors shared] color01] forState:UIControlStateNormal];
        [self.addButton setSelectedBackgroundColor:[UIColor clearColor]];
        
        [self.contentView addSubview:self.addButton];

        //--------------------------------------------------------
        // Slider setup (thumb images are set in AppDelegate
        //--------------------------------------------------------
        self.slider = [[SCUSlider alloc] initWithFrame:CGRectZero];
        self.slider.tintColor = [[SCUColors shared] color01];
        self.centerSlider.thumbColor = [[SCUColors shared] color04];
        self.slider.hidden = YES;
        self.slider.fillColor = [[SCUColors shared] color01];

        [self.contentView addSubview:self.slider];
        
        self.centerSlider = [[SCUCenteredSlider alloc] initWithFrame:CGRectZero];
        self.centerSlider.hidden = YES;
        self.centerSlider.thumbColor = [[SCUColors shared] color04];
        self.centerSlider.fillColor = [[SCUColors shared] color01];
        [self.contentView addSubview:self.centerSlider];
        
        //--------------------------------------------------------
        // Top label setup
        //--------------------------------------------------------
        self.topLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.topLabel.textColor = [[SCUColors shared] color04];
        
        [self.contentView addSubview:self.topLabel];

        //--------------------------------------------------------
        // Top value label setup
        //--------------------------------------------------------
        self.topValueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.topValueLabel.textColor = [[SCUColors shared] color04];

        [self.contentView addSubview:self.topValueLabel];
        
        //--------------------------------------------------------
        // Bottom button setup
        //--------------------------------------------------------
        self.bottomButton = [[SCUButton alloc] initWithFrame:CGRectZero];
        self.bottomButton.backgroundColor = [UIColor clearColor];
        
        [self.contentView addSubview:self.bottomButton];

        NSDictionary *metrics = @{@"buttonPadding": @15,
                                  @"buttonWidth"  : @25,
                                  @"labelHeight"  : @20};

        NSDictionary *views = @{@"minusButton": self.minusButton,
                                @"addButton": self.addButton,
                                @"slider": self.slider,
                                @"topLabel": self.topLabel,
                                @"bottomButton": self.bottomButton,
                                @"topValueLabel": self.topValueLabel,
                                @"centerSlider": self.centerSlider};

        [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                                metrics:metrics
                                                                                  views:views
                                                                                formats:@[@"|-buttonPadding-[minusButton(buttonWidth)]-[centerSlider]-[addButton(buttonWidth)]-buttonPadding-|",
                                                                                          @"|-buttonPadding-[minusButton(buttonWidth)]-[slider]-[addButton(buttonWidth)]-buttonPadding-|",
                                                                                          @"minusButton.centerY = super.centerY",
                                                                                          @"centerSlider.centerY = super.centerY",
                                                                                          @"slider.centerY = super.centerY",
                                                                                          @"bottomButton.centerX = super.centerX",
                                                                                          @"addButton.centerY = super.centerY",
                                                                                          @"V:|[topLabel]-[centerSlider]-[bottomButton]|",
                                                                                          @"V:|[topLabel]-[slider]-[bottomButton]|",
                                                                                          @"|-buttonPadding-[topLabel]",
                                                                                          @"topValueLabel.centerY = topLabel.centerY",
                                                                                          @"topValueLabel.left = topLabel.right + 5"]]];

    }

    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];
    
    self.topLabel.text = info[SCUAVSettingsSliderButtonCellKeyTopTitle];

    self.slider.value = [info[SCUAVSettingsSliderButtonCellSliderValue] floatValue];
    self.centerSlider.value = [info[SCUAVSettingsSliderButtonCellSliderValue] floatValue];
    
    if (info[SCUAVSettingsSliderButtonCellSliderValue])
     {
         self.topValueLabel.text = info[SCUAVSettingsSliderButtonCellSliderValue];
     }
    
    // Select which slider we need based on the type of value (-50 -> 50 or 0 -> 100)
    if ([info[SCUAVSettingsSliderButtonCellSliderType] unsignedIntegerValue] == SCUAVSettingsSliderTypeCenter)
    {
        self.centerSlider.hidden = NO;
    }
    else
    {
        self.slider.hidden = NO;
    }
    
    if ([info[SCUAVSettingsSliderButtonCellKeyBottomTitle] length])
    {
        self.bottomButton.titleLabel.text = info[SCUAVSettingsSliderButtonCellKeyBottomTitle];
    }

    if (info[SCUAVSettingsSliderCellValueRange])
    {
        NSDictionary *range = info[SCUAVSettingsSliderCellValueRange];
        self.slider.minimumValue = [range[@"min"] floatValue];
        self.slider.maximumValue = [range[@"max"] floatValue];
        self.centerSlider.minimumValue = [range[@"min"] floatValue];
        self.centerSlider.maximumValue = [range[@"max"] floatValue];
    }
}

- (void)sliderUpdatedValue:(float)value
{
    self.topValueLabel.text = [NSString stringWithFormat:@"%.0f", value];
}

- (void)updateSliderValues:(float)value withAnimation:(BOOL)animation
{
    //-----------------------------------
    // Makes it easier to just set a single
    // value instead of checking cell type
    //-----------------------------------
    [self.centerSlider setValue:value animated:animation];
    [self.slider setValue:value animated:animation];
}

- (void)setSliderValue:(float)value
{
    self.centerSlider.value = value;
    self.slider.value = value;
    
    [self updateSliderValueLabel:value];
}

- (void)updateSliderValueLabel:(float)value
{
    self.topValueLabel.text = [NSString stringWithFormat:@"%.0f", value];
}

- (void)incrementSlider
{
    if ((self.slider.value + 1) <= self.slider.maximumValue)
    {
        self.slider.value += 1;
    }
    if ((self.centerSlider.value + 1) <= self.centerSlider.maximumValue)
    {
        self.centerSlider.value += 1;
    }
}

- (void)decrementSlider
{
    if ((self.slider.value - 1) >= self.slider.minimumValue)
    {
        self.slider.value -=1;
    }
    if ((self.centerSlider.value -1) >= self.centerSlider.minimumValue)
    {
        self.centerSlider.value -= 1;
    }
}

@end
