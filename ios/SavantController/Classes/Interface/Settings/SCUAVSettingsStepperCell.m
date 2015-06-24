//
//  SCUAVSettingsStepperCell.m
//  SavantController
//
//  Created by Stephen Silber on 7/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVSettingsStepperCell.h"
#import <SavantExtensions/SavantExtensions.h>

@interface SCUAVSettingsStepperCell () <SCUStepperDelegate>

@property (nonatomic) SCUStepper *stepper;

@property (nonatomic) SCUButton *defaultButton;

@property (nonatomic) UILabel *rightLabel;

@property (nonatomic) BOOL formattedValue;

@end

//NSString *const SCUAVSettingsCellValueLabel = @"SCUAVSettingsCellValueLabel";
NSString *const SCUAVSettingsStepperCellTextArray      = @"SCUAVSettingsStepperCellTextArray";
NSString *const SCUAVSettingsStepperCellButtonSize     = @"SCUAVSettingsStepperCellButtonSize";
NSString *const SCUAVSettingsStepperCellValueRange     = @"SCUAVSettingsStepperCellValueRange";
NSString *const SCUAVSettingsStepperCellFormattedValue = @"SCUAVSettingsStepperCellFormattedValue";

@implementation SCUAVSettingsStepperCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.rightLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.rightLabel.textColor = [[SCUColors shared] color03shade07];
        self.rightLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:self.rightLabel];
        
        self.defaultButton = [[SCUButton alloc] initWithTitle:@"Default"];
        self.defaultButton.selectedBackgroundColor = [UIColor clearColor];
        self.defaultButton.backgroundColor = [UIColor clearColor];
        
        [self.defaultButton setTitleColor:[[SCUColors shared] color03shade07] forState:UIControlStateNormal];
        [self.contentView addSubview:self.defaultButton];
        
        self.stepper = [[SCUStepper alloc] initWithTextArray:@[@"-", @"+"]];
        self.stepper.minimumValue = -6;
        self.stepper.maximumValue = 6;
        self.stepper.stepValue = 1.0;
        
        self.stepper.color = [[SCUColors shared] color01];
        self.stepper.selectedColor = [[SCUColors shared] color03shade06];

        [self.stepper addTarget:self action:@selector(updateStepperValueLabel) forControlEvents:UIControlEventValueChanged];

        [self.contentView addSubview:self.stepper];
                
        NSDictionary *metrics = @{@"smallPadding": @10};
        
        NSDictionary *views = @{@"stepper": self.stepper,
                                @"rightLabel" : self.rightLabel,
                                @"titleLabel" : self.textLabel,
                                @"defaultButton":self.defaultButton};
        
        [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                                metrics:metrics
                                                                                  views:views
                                                                                formats:@[@"|-15-[titleLabel]-smallPadding-[rightLabel]",
                                                                                          @"[defaultButton]-smallPadding-[stepper]-smallPadding-|",
                                                                                          @"stepper.centerY = super.centerY",
                                                                                          @"rightLabel.centerY = titleLabel.centerY",
                                                                                          @"titleLabel.centerY = super.centerY",
                                                                                          @"stepper.width = 75",
                                                                                          @"stepper.height = super.height",
                                                                                          @"defaultButton.centerY = super.centerY"]]];
    }
    
    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];
    
    self.textLabel.text = info[SCUDefaultTableViewCellKeyTitle];
    self.rightLabel.text = info[SCUAVSettingsCellValueLabel];

    [self updateStepperValueLabel];
    
    if ([info[SCUAVSettingsStepperCellTextArray] count])
    {
        [self.stepper setTitlesFromArray:info[SCUAVSettingsStepperCellTextArray]];
    }
    
    if (info[SCUAVSettingsStepperCellButtonSize])
    {
        [self.stepper updateButtonLabelSize:info[SCUAVSettingsStepperCellButtonSize]];
    }
    
    if (info[SCUAVSettingsStepperCellValueRange])
    {
        NSDictionary *range = info[SCUAVSettingsStepperCellValueRange];
        self.stepper.minimumValue = [range[@"min"] floatValue];
        self.stepper.maximumValue = [range[@"max"] floatValue];
    }
    
    if (info[SCUAVSettingsStepperCellFormattedValue])
    {
        self.formattedValue = [info[SCUAVSettingsStepperCellFormattedValue] boolValue];
    }
}

- (void)updateStepperFromFormattedValue:(NSString *)value
{
    NSArray *balanceArray = [value componentsSeparatedByString:@" "];
    float balanceValue = 0.0;
    if ([balanceArray count] == 2)
    {
        if ([[balanceArray firstObject] isEqualToString:@"L"])
        {
            balanceValue = -([[balanceArray lastObject] floatValue]);
        }
        else if ([[balanceArray firstObject] isEqualToString:@"R"])
        {
            balanceValue = [[balanceArray lastObject] floatValue];
        }
    }
    [self updateStepper:balanceValue];
}

- (void)updateStepper:(float)value
{
    self.stepper.value = value;
    [self updateStepperValueLabel:value];
}

- (void)updateStepperValueLabel:(float)value
{
    if (self.formattedValue)
    {
        NSString *prefix = (value < 0) ? @"L " : @"R ";
        
        if (value == 0)
        {
            prefix = @"";
        }

        value = fabsf(value);
        self.rightLabel.text = [NSString stringWithFormat:@"%@%.0f", prefix, value];
    }
    else
    {
        self.rightLabel.text = [NSString stringWithFormat:@"%.0f", value];
    }

}

- (void)updateStepperValueLabel
{
    [self updateStepperValueLabel:self.stepper.value];
}

@end
