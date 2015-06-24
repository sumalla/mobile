//
//  SCUClimateHumidityViewController.m
//  SavantController
//
//  Created by David Fairweather on 5/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUClimateHumidityViewController.h"
#import "SCUHumidityServiceModel.h"

#import "SCUClimateViewControllerPrivate.h"

@implementation SCUClimateHumidityViewController

- (instancetype)initWithService:(SAVService *)service
{
    self = [super initWithService:service];
    if (self)
    {
        self.centerLabelSuperScriptFontSize = [UIDevice isPad] ? 70 : 30;
        self.cornerLabelSuperScriptFontSize = [UIDevice isPad] ? 24 : 10;
    }
    return self;
}

- (void)initModelWithService:(SAVService *)service
{
    self.model = [[SCUHumidityServiceModel alloc] initWithService:service];
    self.model.delegate = self;
}

- (void)setupSliderAndPickerViews
{
    [super setupSliderAndPickerViews];
    
    [self.sliderView setColorOfMaxPoint:[UIColor sav_colorWithRGBValue:0xebe182]
                            andMinPoint:[UIColor sav_colorWithRGBValue:0x4ef259]];
    if (((SCUHumidityServiceModel *)self.model).isAlwayOn)
    {
        SAVEntityState pseudoState = self.model.selectedPrimaryMode;
        
        [self didReceiveClimateSetPointMode:pseudoState];
    }
}

- (void)setViewColors
{
    //larger space
    self.lesserGradientBackground = @[[UIColor sav_colorWithRGBValue:0xe76927], [UIColor sav_colorWithRGBValue:0xef7131]];
    self.greaterGradientBackground = @[[UIColor sav_colorWithRGBValue:0x0290aa], [UIColor sav_colorWithRGBValue:0x00b4d5]];
    
    [super setViewColors];
}

- (NSString *)notificationChangingDownText
{
    return @"DEHUMIDIFY";
}

- (NSString *)notificationChangingUpText
{
    return @"HUMIDIFY";
}

- (UIImage *)tabBarIcon
{
    return [UIImage imageNamed:@"humidity"];
}

- (UIColor *)tabBarButtonColor
{
    return [[SCUColors shared] color01];
}

#pragma -  Model Delegates

- (void)didReceiveClimateSetPointMode:(SAVEntityState)mode
{
    if (((mode != self.model.selectedPrimaryMode && !((SCUHumidityServiceModel *)self.model).isAlwayOn)||
         (((SCUHumidityServiceModel *)self.model).isAlwayOn && (mode != SAVEntityState_HumidityModeOff))
         ) &&
        mode != SAVEntityState_Unknown)
    {
        [self forceToCenter];
        if (mode != SAVEntityState_ModeAuto && mode != SAVEntityState_ModeHumidity)
        {
            self.isChangingUp = NO;
            self.isChangingDown = NO;
        }
        switch (mode)
        {
            case SAVEntityState_ModeHumidify:
                [self.sliderView changeConfigurationToMode:SCUSliderSetPointModeLowPointOnly];
                break;
            case SAVEntityState_ModeACDehumidify:
            case SAVEntityState_ModeDehumidify:
                [self.sliderView changeConfigurationToMode:SCUSliderSetPointModeHighPointOnly];
                break;
            case SAVEntityState_ModeHumidity:
                //  if (allows muiltil set points)
            {
                [self.sliderView changeConfigurationToMode:SCUSliderSetPointModeSingleSetPointAuto];
            }
                break;
            case SAVEntityState_HumidityModeOff:
//            case SAVEntityState_ModeOff:
                [self.sliderView changeConfigurationToMode:SCUSliderSetPointModeOff];
                break;
            default:
                break;
        }
    }
}

- (NSString *)setAttributedStringForLabel:(UILabel *)label withValue:(NSInteger)value
{
    if (value < 1 || value > 100)
    {
        value = NSNotFound;
    }
    return [super setAttributedStringForLabel:label withValue:value];
}

@end
