//
//  SCUCDServiceViewModel.m
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUCDServiceViewModel.h"
#import "SCUStateReceiver.h"
#import "SCUButton.h"

@import Extensions;
@import SDK;

@interface SCUCDServiceViewModel () <SCUStateReceiver>

@property NSString *currentHour;
@property NSString *currentMinute;
@property NSString *currentSecond;
@property NSString *elapsedTime;

@property (getter = isShuffling) BOOL shuffling;
@property (getter = isRepeating) BOOL repeating;

@end

@implementation SCUCDServiceViewModel

- (NSArray *)transportBackCommands
{
    NSMutableArray *transportBackCommands = [NSMutableArray arrayWithArray:[super transportBackCommands]];
    [transportBackCommands removeObject:@"SkipDown"];

    return [transportBackCommands copy];
}

- (NSArray *)transportForwardCommands
{
    NSMutableArray *transportForwardCommands = [NSMutableArray arrayWithArray:[super transportForwardCommands]];
    [transportForwardCommands removeObject:@"SkipUp"];

    return transportForwardCommands;
}

- (void)updateElapsedTime
{
    if ([self.currentHour length] && [self.currentMinute length] && [self.currentSecond length])
    {
        NSString *elapsedTime = @"";

        NSInteger currentHour = [self.currentHour integerValue];
        NSInteger currentMinute = [self.currentMinute integerValue];
        NSInteger currentSecond = [self.currentSecond integerValue];

        if (currentHour)
        {
            elapsedTime = [elapsedTime stringByAppendingFormat:@"%02ld", (long)currentHour];
        }

        if ([elapsedTime length])
        {
            elapsedTime = [elapsedTime stringByAppendingString:@":"];
        }

        elapsedTime = [elapsedTime stringByAppendingFormat:@"%02ld", (long)currentMinute];

        if ([elapsedTime length])
        {
            elapsedTime = [elapsedTime stringByAppendingString:@":"];
        }

        elapsedTime = [elapsedTime stringByAppendingFormat:@"%02ld", (long)currentSecond];

        self.elapsedTime = elapsedTime;
    }
    else
    {
        self.elapsedTime = nil;
    }

    if ([self.delegate respondsToSelector:@selector(progressChanged:)])
    {
        [self.delegate progressChanged:self.elapsedTime];
    }
}

- (void)elapsedHourDidUpdateWithValue:(id)value
{
    if ([value isKindOfClass:[NSString class]])
    {
        self.currentHour = value;
    }
    else
    {
        self.currentHour = [value stringValue];
    }

    [self updateElapsedTime];
}

- (void)elapsedMinuteDidUpdateWithValue:(id)value
{
    if ([value isKindOfClass:[NSString class]])
    {
        self.currentMinute = value;
    }
    else
    {
        self.currentMinute = [value stringValue];
    }

    [self updateElapsedTime];
}

- (void)elapsedSecondDidUpdateWithValue:(id)value
{
    if ([value isKindOfClass:[NSString class]])
    {
        self.currentSecond = value;
    }
    else
    {
        self.currentSecond = [value stringValue];
    }
    
    [self updateElapsedTime];
}

#pragma mark - Repeat/Shuffle

- (void)toggleShuffle:(SCUButton *)sender
{
    [self sendCommand:@"ToggleShuffle"];

    self.shuffling = !self.isShuffling;
    sender.selected = self.isShuffling;
}

- (void)toggleRepeat:(SCUButton *)sender
{
    [self sendCommand:@"ToggleRepeat"];
    self.repeating = !self.isRepeating;
    sender.selected = self.isRepeating;
}

#pragma mark - State Receiver

- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    if ([stateUpdate.state hasSuffix:@"CurrentDiskNumber"])
    {
        [self.delegate diskChanged:stateUpdate.value];
    }
    else if ([stateUpdate.state hasSuffix:@"CurrentTrack"])
    {
        [self.delegate trackChanged:stateUpdate.value];
    }
    else if ([stateUpdate.state hasSuffix:@"CurrentElapsedHour"])
    {
        [self elapsedHourDidUpdateWithValue:stateUpdate.value];
    }
    else if ([stateUpdate.state hasSuffix:@"CurrentElapsedMinute"])
    {
        [self elapsedMinuteDidUpdateWithValue:stateUpdate.value];
    }
    else if ([stateUpdate.state hasSuffix:@"CurrentElapsedSecond"])
    {
        [self elapsedSecondDidUpdateWithValue:stateUpdate.value];
    }
}

- (NSArray *)statesToRegister
{
    return @[[NSString stringWithFormat:@"%@.CurrentDiskNumber", self.stateScope],
             [NSString stringWithFormat:@"%@.CurrentTrack", self.stateScope],
             [NSString stringWithFormat:@"%@.CurrentElapsedHour", self.stateScope],
             [NSString stringWithFormat:@"%@.CurrentElapsedMinute", self.stateScope],
             [NSString stringWithFormat:@"%@.CurrentElapsedSecond", self.stateScope]];
}

@end
