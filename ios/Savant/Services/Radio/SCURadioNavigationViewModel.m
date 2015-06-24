//
//  SCURadioNavigationViewModel.m
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCURadioNavigationViewModel.h"
@import SDK;
#import "SCUStateReceiver.h"

//-------------------------------------------------------------------
// temporary min/max frequencies
//-------------------------------------------------------------------
#define FM_MAX_FREQUENCY    108.5f
#define FM_MIN_FREQUENCY    87.0f

#define AM_MAX_FREQUENCY    1720.0f
#define AM_MIN_FREQUENCY    520.0f

@interface SCURadioNavigationViewModel () <SCUStateReceiver>

@property (nonatomic) SAVService *service;

@end

@implementation SCURadioNavigationViewModel

- (instancetype)initWithService:(SAVService *)service
{
    self = [super initWithService:service];
    if (self)
    {
        self.fmSignificance = 0.2f;
        self.amSignificance = 10.0f;
        self.isScanning = NO;
        
        self.currentBand = SCURadioTypeNone;
        self.isMultiBand = NO;
        
        if ([self.serviceId isEqualToString:@"SVC_AV_FMRADIO"])
        {
            self.currentBand = SCURadioTypeFM;
        }
        else if ([self.serviceId isEqualToString:@"SVC_AV_AMRADIO"])
        {
            self.currentBand = SCURadioTypeAM;
        }
        else if ([self.serviceId isEqualToString:@"SVC_AV_SATELLITERADIO"])
        {
            self.currentBand = SCURadioTypeSat;
        }
        else if ([self.serviceId isEqualToString:@"SVC_AV_MULTIBANDRADIO"])
        {
            self.isMultiBand = YES;
        }
    }
    return self;
}

- (CGFloat)maxFrequency
{
    CGFloat maxFrequency = 1;
    if (self.currentBand == SCURadioTypeAM)
    {
        maxFrequency = AM_MAX_FREQUENCY;
    }
    else if (self.currentBand != SCURadioTypeSat)
    {
        maxFrequency = FM_MAX_FREQUENCY;
    }
    return maxFrequency;
}

- (CGFloat)minFrequency
{
    CGFloat minFrequency = 0;
    if (self.currentBand == SCURadioTypeAM)
    {
        minFrequency = AM_MIN_FREQUENCY;
    }
    else if (self.currentBand != SCURadioTypeSat)
    {
        minFrequency = FM_MIN_FREQUENCY;
    }
    return minFrequency;
}

- (void)tuneDownFrequency
{
    [self sendCommand:@"DecrementRadioFrequency"];
}

- (void)tuneUpFrequency
{
    [self sendCommand:@"IncrementRadioFrequency"];
}

- (void)changeBandTo:(SCURadioType)radioType
{
    if (self.isMultiBand)
    {
        [self sendCommand:@"ToggleBand"];
        self.currentBand = radioType;
    }
    if (self.currentBand < self.maxFrequency && self.currentBand > self.minFrequency)
    {
        [self.delegate didReceiveCurrentFrequency:self.CurrentTunerFrequency];
    }
}

- (void)seekUp
{
    [self sendCommand:@"SeekUp"];
}

- (void)seekDown
{
    [self sendCommand:@"SeekDown"];
}

- (void)scanTP
{
    self.isScanning = YES;
    [self sendCommand:@"ScanTP"];
}

- (void)finishScan
{
    self.isScanning = NO;
    [self sendCommand:@"FinishTP"];
}

- (void)selectPreset:(NSInteger)presetNumber
{
    
}

- (void)selectDirectFrequency:(CGFloat)frequency
{

}

- (void)setFrequency:(CGFloat)frequency
{
    if (self.currentBand == SCURadioTypeAM)
    {
        [self sendCommand:@"SetRadioFrequency" withArguments:@{@"Frequency": @(frequency)}];
    }
    else if (self.currentBand == SCURadioTypeFM)
    {
        NSInteger frequencyWhole = (NSInteger)frequency;

        NSInteger frequencyPart = roundf((frequency - frequencyWhole) * 10);

        [self sendCommand:@"SetRadioFrequency" withArguments:@{@"FrequencyWhole": @(frequencyWhole),
                                                               @"FrequencyPart": @(frequencyPart)}];
    }
}

- (NSString *)serviceId
{
    return self.service.serviceId;
}

- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    if ([stateUpdate.state hasSuffix:@"CurrentTunerFrequency"])
    {
        CGFloat newTunerFrequency = [stateUpdate.value floatValue];
        if (newTunerFrequency > 0.1)
        {
            self.CurrentTunerFrequency = newTunerFrequency;
            BOOL isAM = self.CurrentTunerFrequency > 140;
            if (isAM)
            {
                [self changeBandTo:SCURadioTypeAM];
            }
            else
            {
                [self changeBandTo:SCURadioTypeFM];
            }
            if (isAM == (self.currentBand == SCURadioTypeAM))
            {
                [self.delegate didReceiveCurrentFrequency:self.CurrentTunerFrequency];
            }
        }
    }
}

- (NSArray *)statesToRegister
{
    return @[[NSString stringWithFormat:@"%@.CurrentTunerFrequency", self.stateScope]];
}

- (BOOL)radioContainsCommand:(NSString *)command
{
    NSArray *commands = self.serviceCommands;
    return [commands containsObject:command];
}

@end
