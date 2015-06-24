//
//  SCUTemperatureViewController.m
//  SavantController
//
//  Created by David Fairweather on 7/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUTemperatureViewController.h"

#import "SCUTemperatureServiceModel.h"
#import "SCUClimateViewControllerPrivate.h"

@implementation SCUTemperatureViewController

- (instancetype)initWithService:(SAVService *)service
{
    self = [super initWithService:service];
    if (self)
    {
        self.centerLabelSuperScriptFontSize = [UIDevice isPad] ? 90 : 34;
        self.cornerLabelSuperScriptFontSize = [UIDevice isPad] ? 24 : 10;
    }
    return self;
}

- (void)initModelWithService:(SAVService *)service
{
    self.model = [[SCUTemperatureServiceModel alloc] initWithService:service];
    self.model.delegate = self;
}

- (void)setupSliderAndPickerViews
{
    [super setupSliderAndPickerViews];
    
    [self.sliderView setColorOfMaxPoint:[UIColor sav_colorWithRGBValue:0xb3e6f9]
                            andMinPoint:[UIColor sav_colorWithRGBValue:0xfc8423]];
}

#pragma - specific methods to override for Temperature

- (UIImage *)tabBarIcon
{
    return [UIImage imageNamed:@"Climate"];
}

- (void)setViewColors
{
    //larger space
    self.lesserGradientBackground = @[[UIColor sav_colorWithRGBValue:0xf27428], [UIColor sav_colorWithRGBValue:0xcb540d]];
    self.greaterGradientBackground = @[[UIColor sav_colorWithRGBValue:0x0d98cb], [UIColor sav_colorWithRGBValue:0x0686b5]];
    
    [super setViewColors];
}

- (NSString *)notificationChangingDownText
{
    return @"COOL";
}

- (NSString *)notificationChangingUpText
{
    return @"HEAT";
}

#pragma -  Model Delegates

- (void)didReceiveClimateSetPointMode:(SAVEntityState)mode
{
    if (mode != self.model.selectedPrimaryMode && mode != SAVEntityState_Unknown)
    {
        [self forceToCenter];
        if (mode != SAVEntityState_ModeAuto)
        {
            self.isChangingUp = NO;
            self.isChangingDown = NO;
        }
        switch (mode)
        {
            case SAVEntityState_ModeHeat:
                [self.sliderView changeConfigurationToMode:SCUSliderSetPointModeLowPointOnly];
                break;
            case SAVEntityState_ModeCool:
                [self.sliderView changeConfigurationToMode:SCUSliderSetPointModeHighPointOnly];
                break;
            case SAVEntityState_ModeAuto:
                //  if (allows muiltil set points)
            {
                [self.sliderView changeConfigurationToMode:SCUSliderSetPointModeDualSetPointAuto];
            }
                break;
            case SAVEntityState_ModeOff:
                [self.sliderView changeConfigurationToMode:SCUSliderSetPointModeOff];
                break;
            default:
                break;
        }
    }
}

@end
