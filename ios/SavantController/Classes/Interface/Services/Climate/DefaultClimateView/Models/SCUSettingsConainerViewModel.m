//
//  SCUSettingsConainerViewModel.m
//  SavantController
//
//  Created by Jason Wolkovitz on 7/29/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSettingsConainerViewModel.h"

@implementation SCUSettingsConainerViewModel

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.selectedModesArray = [@[] mutableCopy];
        self.modesDictionary = [@{} mutableCopy];
        self.settingsGroup = [@[] mutableCopy];
        self.titlesForSettingButtons = [[NSMutableArray alloc]initWithCapacity:2];
    }
    return self;
}

- (NSUInteger)numberOfSectionForSettingsIndex:(NSUInteger)index
{
    NSUInteger numberOfSections = 0;
    
    for (NSUInteger i = 0; i < [self.settingsGroup count]; i++)
    {
        if ([self.settingsGroup[i] unsignedIntegerValue] == index)
        {
            numberOfSections++;
        }
    }
    return numberOfSections;
}

- (NSUInteger)firstIndexForSettingIndex:(NSUInteger)settingIndex
{
    NSUInteger settingsArrayIndex = NSNotFound;
    if (settingIndex != NSNotFound)
    {        
        for (NSUInteger i = 0; i < [self.settingsGroup count]; i++)
        {
            if (settingIndex == [self.settingsGroup[i] unsignedIntegerValue])
            {
                settingsArrayIndex = i;
                break;
            }
        }
    }
    return settingsArrayIndex;
}

- (NSString *)titleForSection:(NSUInteger)section forSettingsIndex:(NSUInteger)index
{
    NSString *title;
    NSUInteger settingsArrayIndex = [self firstIndexForSettingIndex:index] + section;
    if (self.headerTiltesForSettingsCommandPopovers && [self.headerTiltesForSettingsCommandPopovers count] > settingsArrayIndex && self.modesAvailableArray && [self.modesAvailableArray count] > settingsArrayIndex)
    {
        if ([self.modesAvailableArray[settingsArrayIndex] count] > 0)
        {
            title = self.headerTiltesForSettingsCommandPopovers[settingsArrayIndex];
        }
        if ([title length] < 1)
        {
            title = nil;
        }
    }
    return title;
}

- (SAVEntityState)settingsModeSelectedAtIndexPath:(NSIndexPath *)indexPath forSettingIndex:(NSUInteger)settingIndex
{
    SAVEntityState settingCommandToSend = SAVEntityState_Unknown;
    NSUInteger settingsArrayIndex = indexPath.section + settingIndex;
    if ([self.modesAvailableArray count] > settingsArrayIndex &&
        [self.commandDelegate respondsToSelector:@selector(sendServiceRequestForSAVEntityState:)])
    {
        NSArray *modes = self.modesAvailableArray[settingsArrayIndex];
        if (modes && [modes count] > (NSUInteger)indexPath.row)
        {
            settingCommandToSend = [modes[indexPath.row] integerValue];
            [self.commandDelegate sendServiceRequestForSAVEntityState:settingCommandToSend];
        }
    }
    return settingCommandToSend;
}

- (BOOL)settingsIndex:(NSUInteger)settingIndex ModeIsSelected:(NSIndexPath *)indexPath
{
    BOOL settingsModeIsSelected = NO;
    NSUInteger modeArrayIndex = 0;
    for (NSUInteger i = 0; i < settingIndex; i++)
    {
        modeArrayIndex += [self numberOfSectionForSettingsIndex:i];
    }
    modeArrayIndex += indexPath.section;
    
    if ([self.modesAvailableArray count] > modeArrayIndex && [self.modesAvailableArray[modeArrayIndex] count] > (NSUInteger)indexPath.row)
    {
        if ([self.modesAvailableArray[modeArrayIndex][indexPath.row] integerValue] == [self.selectedModesArray[modeArrayIndex] integerValue])
        {
            settingsModeIsSelected = YES;
        }
    }
    return settingsModeIsSelected;
}

- (NSArray *)getSettingsOptionsArrayForSettingIndex:(NSUInteger)settingIndex subsectionIndex:(NSUInteger)subsection
{
    NSArray *settingsArray;

    if (settingIndex != NSNotFound)
    {
        NSUInteger settingsArrayIndex = [self firstIndexForSettingIndex:settingIndex];
        if (settingsArrayIndex != NSNotFound)
        {
            settingsArrayIndex += subsection;
            if (self.modesAvailableArray && [self.modesAvailableArray count] > settingsArrayIndex)
            {
                settingsArray = self.modesAvailableArray[settingsArrayIndex];
            }
        }
    }
    return settingsArray;
}

- (NSUInteger)realIndexForModeType:(SAVEntityState)mode forSettingsIndex:(NSUInteger)settingsIndex
{
    NSUInteger realIndex = [self firstIndexForSettingIndex:settingsIndex];
    NSUInteger numberOfSectionsAtIndex = [self numberOfSectionForSettingsIndex:settingsIndex];
    
    if (numberOfSectionsAtIndex > 1)
    {
        NSArray *settingsArray;
        for (NSUInteger i = 0; i < numberOfSectionsAtIndex; i++)
        {
            settingsArray = [self getSettingsOptionsArrayForSettingIndex:settingsIndex subsectionIndex:i];
            if ([settingsArray containsObject:@(mode)])
            {
                realIndex += i;
                break;
            }
        }
    }
    return realIndex;
}

- (SAVEntityState)selectedModeForSettingsIndex:(NSUInteger)settingsIndex
{
    SAVEntityState selectedMode = SAVEntityState_Unknown;
    if (self.selectedModesArray && [self.selectedModesArray count] > settingsIndex)
    {
        selectedMode = [self.selectedModesArray[settingsIndex] integerValue];
    }
    return selectedMode;
}

//toggles or brings up popover
- (void)settingsButtonTouchedWithIndex:(NSUInteger)index
{
    if ([self shouldShowPopupForSettings:index])
    {
        //brings up popover
        if ([self.delegate respondsToSelector:@selector(showSettingsPopupPickerForSettingsIndex:)])
        {
            [self.delegate showSettingsPopupPickerForSettingsIndex:index];
        }
    }
    else if ([self numberOfOptionsForSettingsIndex:index section:0] == 2)
    {
        NSArray *settingsOptions = [self getSettingsOptionsArrayForSettingIndex:index subsectionIndex:0];
        //toggle button
        SAVEntityState currentMode = [self selectedModeForSettingsIndex:[self firstIndexForSettingIndex:index]];
        for (NSUInteger i = 0; i < [settingsOptions count]; i++)
        {
            if ([settingsOptions[i] integerValue] != currentMode)
            {
                SAVEntityState settingCommandToSend = [settingsOptions[i] integerValue];
                [self sendServiceRequestForSAVEntityState:settingCommandToSend];
                break;
            }
        }
    }
}

- (void)showSettingsPopupPickerForSettingsIndex:(NSUInteger)index
{
    [self.delegate showSettingsPopupPickerForSettingsIndex:index];
}

- (void)sendServiceRequestForSAVEntityState:(SAVEntityState)settingCommandToSend
{
    if ([self.commandDelegate respondsToSelector:@selector(sendServiceRequestForSAVEntityState:)])
    {
        [self.commandDelegate sendServiceRequestForSAVEntityState:settingCommandToSend];
    }
}

- (BOOL)shouldShowPopupForSettings:(NSUInteger)index
{
    BOOL shouldShowPopup = NO;
    NSUInteger numberOfSections = [self numberOfSectionForSettingsIndex:index];
    
    SAVEntityState state = [self selectedModeForSettingsIndex:[self firstIndexForSettingIndex:index]];
    if (state == SAVEntityState_Unknown)
    {
        shouldShowPopup = YES;
    }
    else
    {
        for (NSUInteger i = 0; i < numberOfSections; i++)
        {
            NSUInteger numberOfOptions = [self numberOfOptionsForSettingsIndex:index section:i];
            if (numberOfOptions > 2 || (i != 0 && numberOfOptions > 1))
            {
                shouldShowPopup = YES;
                break;
            }
        }
    }
    return shouldShowPopup;
}

- (BOOL)shouldDismissPopUpAfterSingleSelection:(NSUInteger)settingsIndex
{
    BOOL shouldDismissTable = NO;
    NSUInteger numberOfSections = [self numberOfSectionForSettingsIndex:settingsIndex];
    if (numberOfSections < 2)
    {
        shouldDismissTable = YES;
    }
    else
    {
        NSUInteger numberOfSectionsWithOptions = 0;
        for (NSUInteger i = 0; i < numberOfSections; i++)
        {
            NSUInteger opitionsForGroup = [self numberOfOptionsForSettingsIndex:settingsIndex section:i];
            if (opitionsForGroup > 1)
            {
                numberOfSectionsWithOptions++;
            }
        }
        if (numberOfSectionsWithOptions < 2)
        {
            shouldDismissTable = YES;
        }
    }
    return shouldDismissTable;
}

- (NSUInteger)numberOfOptionsForSettingsIndex:(NSUInteger)index section:(NSUInteger)section
{
    return [[self getSettingsOptionsArrayForSettingIndex:index subsectionIndex:section] count];
}

- (NSObject *)imageOrTitleForSettingIndex:(NSUInteger)settingIndex atIndexPath:(NSIndexPath *)settingIndexPath
{
    SAVEntityState state = [self stateForSettingsIndex:settingIndex atIndexPath:settingIndexPath];
    
    UIImage *settingsImage = [self imageForState:state];
    if (settingsImage)
    {
        return settingsImage;
    }
    
    NSString *settingTilte = [self labelsForState:state];
    if (!settingTilte)
    {
        settingTilte = [NSString stringWithFormat:@"Unknown Settings type %ld", (long)settingIndexPath.row];
    }
    return settingTilte;
}

- (NSObject *)imageOrTitleForState:(SAVEntityState)state
{
    UIImage *settingsImage = [self imageForState:state];
    if (settingsImage)
    {
        return settingsImage;
    }
    
    NSString *settingTilte = [self labelsForState:state];
    
    return settingTilte;
}

//can be in the subclass or supper class
- (UIImage *)imageForState:(SAVEntityState)state
{
    UIImage *tempImage;
    switch (state)
    {
        case SAVEntityState_ModeCool:
            tempImage = [UIImage imageNamed:@"cooling"];
            break;
        case SAVEntityState_SolarHeaterModeOn:
        case SAVEntityState_SpaHeaterModeOn:
        case SAVEntityState_PoolHeaterModeOn:
        case SAVEntityState_SecondaryPoolHeaterModeOn:
        case SAVEntityState_ModeHeat:
            tempImage = [UIImage imageNamed:@"heat"];
            break;
        default:
            break;
    }
    return tempImage;//subclass if images are shown for modes
}

- (NSString *)labelsForState:(SAVEntityState)state
{
    NSString *climateLabel;
    switch (state)
    {
        case SAVEntityState_FanOn:
        case SAVEntityState_FanmodeOn:
        case SAVEntityState_PumpModeOn:
        case SAVEntityState_PoolHeaterModeOn:
        case SAVEntityState_SpaHeaterModeOn:
        case SAVEntityState_SecondaryPoolHeaterModeOn:
        case SAVEntityState_SpaModeOn:
        case SAVEntityState_WaterfallModeOn:
        case SAVEntityState_CleaningSystemModeOn:
        {
            climateLabel = @"On";
        }
            break;
        case SAVEntityState_FanmodeOff:
        case SAVEntityState_ModeOff:
        case SAVEntityState_HumidityModeOff:
        case SAVEntityState_PumpModeOff:
        case SAVEntityState_PoolHeaterModeOff:
        case SAVEntityState_SpaHeaterModeOff:
        case SAVEntityState_SecondaryPoolHeaterModeOff:
        case SAVEntityState_SolarHeaterModeOff:
        case SAVEntityState_SpaModeOff:
        case SAVEntityState_WaterfallModeOff:
        case SAVEntityState_CleaningSystemModeOff:

        {
            climateLabel = @"Off";
        }
            break;
        case SAVEntityState_PumpSpeedHigh:
        case SAVEntityState_FanSpeedHigh:
        {
            climateLabel = @"High";
        }
            break;
        case SAVEntityState_FanSpeedMediumHigh:
        {
            climateLabel = @"Medium High";
        }
            break;
        case SAVEntityState_FanSpeedMedium:
        {
            climateLabel = @"Medium";
        }
            break;
        case SAVEntityState_FanSpeedMediumLow:
        {
            climateLabel = @"Medium Low";
        }
            break;
        case SAVEntityState_PumpSpeedLow:
        case SAVEntityState_FanSpeedLow:
        {
            climateLabel = @"Low";
        }
            break;
        case SAVEntityState_ModeAuto:
        case SAVEntityState_FanmodeAuto:
        {
            climateLabel = @"Auto";
        }
            break;
        case SAVEntityState_ModeCool:
        {
            climateLabel = @"Cool";
        }
            break;
        case SAVEntityState_ModeHeat:
        {
            climateLabel = @"Heat";
        }
            break;
        case SAVEntityState_HumidityModeOn:
            
        case SAVEntityState_ModeHumidity:
        {
            climateLabel = @"Humidity";
        }
            break;
        case SAVEntityState_ModeHumidify:
        {
            climateLabel = @"Humidify";
        }
            break;
        case SAVEntityState_ModeDehumidify:
        {
            climateLabel = @"Dehumidify";
        }
            break;
        case SAVEntityState_ModeACDehumidify:
        {
            climateLabel = @"AC Dehumidify";
        }
            break;
        case SAVEntityState_Unknown:
        default:
        {
            climateLabel = nil;
        }
            //SAVEntityEvent_ModeHumidityAuto //don't know if this is a command but this would be a dual setpoint system
            //SAVEntityEvent_ModeHumidityOff
            break;
    }
    return climateLabel;
}

- (SAVEntityState)stateForSettingsIndex:(NSUInteger)settingsIndex atIndexPath:(NSIndexPath *)settingIndexPath
{
    SAVEntityState state = SAVEntityState_Unknown;
    NSArray *states = [self getSettingsOptionsArrayForSettingIndex:settingsIndex subsectionIndex:settingIndexPath.section];
    if (states && ((NSInteger)[states count] > settingIndexPath.row))
    {
        state = [states[settingIndexPath.row] integerValue];
    }
    return state;
}

- (void)setSelectedMode:(SAVEntityState)mode forSettingsIndex:(NSUInteger)settingsIndex
{
    if (self.selectedModesArray && [self.selectedModesArray count] > settingsIndex)
    {
        NSUInteger realIndex = [self realIndexForModeType:mode forSettingsIndex:settingsIndex];
        self.selectedModesArray[realIndex] = @(mode);
        [self.delegate didReceiveClimateSetPointMode:mode withIndex:settingsIndex];
    }
}

- (void)setDelegate:(id<SCUSettingsConainerViewModelDelegate>)delegate
{
    _delegate = delegate;
}

@end
