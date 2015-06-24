//
//  SCUNowPlayingModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/21/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUNowPlayingModel.h"
#import "SCUNowPlayingModelPrivate.h"
#import "SCUStateReceiver.h"
@import SDK;

@interface SCUNowPlayingModel () <StateDelegate>

@property (nonatomic) NSArray *stateNames;
@property (nonatomic) NSMutableDictionary *currentStates;
@property (nonatomic) NSDictionary *cachedStateNamesToDelegateSelectors;
@property (nonatomic) NSArray *cachedStateNamesEffectingVisibility;
@property (nonatomic) NSString *artworkState;
@property (nonatomic, getter = isRegisteredForStates) BOOL registeredForStates;

@end

@implementation SCUNowPlayingModel

- (void)dealloc
{
    [[Savant states] unregisterForStates:self.stateNames forObserver:self];
}

- (instancetype)initWithService:(SAVService *)service serviceGroup:(SAVServiceGroup *)serviceGroup delegate:(id<SCUNowPlayingModelDelegate>)delegate
{
    NSParameterAssert(serviceGroup);

    self = [super initWithService:service];

    if (self)
    {
        self.delegate = delegate;
        self.cachedStateNamesToDelegateSelectors = [self stateNamesToDelegateSelectors];
        self.cachedStateNamesEffectingVisibility = [self stateNamesEffectingVisibility];

        NSArray *states = nil;

        if ([self.delegate respondsToSelector:@selector(states)])
        {
            states = [self.delegate states];
        }

        self.stateNames = [[self.cachedStateNamesToDelegateSelectors allKeys] arrayByMappingBlock:^id(NSString *stateName) {

            if (states && ![states containsObject:stateName])
            {
                return nil;
            }

            NSString *state = [NSString stringWithFormat:@"%@.%@", serviceGroup.stateScope, stateName];

            if ([stateName isEqualToString:@"CurrentArtworkPath"])
            {
                self.artworkState = state;
                state = nil;
            }
            
            return state;
        }];

        NSString *artworkState = [NSString stringWithFormat:@"%@.%@", serviceGroup.stateScope, @"CurrentArtworkPath"];

        if ([self.stateNames containsObject:artworkState])
        {
            self.artworkState = artworkState;
        }

        self.currentStates = [NSMutableDictionary dictionaryWithCapacity:[self.stateNames count]];
    }

    return self;
}

- (BOOL)shouldPowerOn
{
    return NO;
}

- (void)sendCommandWithTransportButtonType:(SCUNowPlayingModelTransportButtonType)buttonType forState:(NSInteger)state
{
    SAVService *service = [self.serviceGroup.activeServices count] ? [self.serviceGroup.activeServices firstObject] : self.service;
    SAVServiceRequest *request = [[SAVServiceRequest alloc] initWithService:service];
    request.request = [self _commandWithButtonType:buttonType forState:state];
    [[Savant control] sendMessage:request];
}

- (void)viewDidAppear
{
    //-------------------------------------------------------------------
    // Register for all normal states only once.
    //-------------------------------------------------------------------
    if (!self.isRegisteredForStates)
    {
        self.registeredForStates = YES;
        [[Savant states] registerForStates:self.stateNames forObserver:self];
    }

    //-------------------------------------------------------------------
    // Register/unregister for the artwork state every time the view
    // appears/disappears.
    //-------------------------------------------------------------------
    if (self.artworkState)
    {
        [[Savant states] registerForStates:@[self.artworkState] forObserver:self];
    }
}

- (void)viewDidDisappear
{
    if (self.artworkState)
    {
        [[Savant states] unregisterForStates:@[self.artworkState] forObserver:self];
    }
}

#pragma mark - SCUStateReceiver methods

- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    NSString *stateName = [stateUpdate stateName];

    self.currentStates[stateName] = stateUpdate.value;

    if ([stateName length])
    {
        SEL selector = NSSelectorFromString(self.cachedStateNamesToDelegateSelectors[stateName]);

        if ([self respondsToSelector:selector])
        {
            SAVFunctionForSelector(function, (id)self, selector, void, id);
            function(self, selector, stateUpdate.value);
        }
        else if ([self.delegate respondsToSelector:selector])
        {
            SAVFunctionForSelector(function, (id)self.delegate, selector, void, id);
            function(self.delegate, selector, stateUpdate.value);
        }
    }

    if ([self toolbarVisibleStateForStates:[self.currentStates dictionaryWithValuesForKeys:self.cachedStateNamesEffectingVisibility]])
    {
        [self.delegate toolbarShouldShow];
    }
    else
    {
        [self.delegate toolbarShouldHide];
    }
}

#pragma mark -

- (NSDictionary *)stateNamesToDelegateSelectors
{
    return @{@"CurrentPauseStatus": NSStringFromSelector(@selector(pauseStatusDidUpdateWithValue:)),
             @"CurrentArtistName": NSStringFromSelector(@selector(artistDidUpdateWithValue:)),
             @"CurrentAlbumName": NSStringFromSelector(@selector(albumDidUpdateWithValue:)),
             @"CurrentSongName": NSStringFromSelector(@selector(songDidUpdateWithValue:)),
             @"CurrentRepeatStatus": NSStringFromSelector(@selector(repeatDidUpdateWithValue:)),
             @"CurrentShuffleStatus": NSStringFromSelector(@selector(shuffleDidUpdateWithValue:)),
             @"CurrentElapsedTime": NSStringFromSelector(@selector(elapsedTimeDidUpdateWithValue:)),
             @"CurrentProgress": NSStringFromSelector(@selector(progressTimeDidUpdateWithValue:)),
             @"CurrentRemainingTime": NSStringFromSelector(@selector(remainingTimeDidUpdateWithValue:)),
             @"CurrentArtworkPath": NSStringFromSelector(@selector(artworkURLDidUpdate:)),
             @"PlayType": NSStringFromSelector(@selector(playTypeDidUpdateWithValue:))};
}

- (NSArray *)stateNamesEffectingVisibility
{
    NSArray *stateNamesEffectingVisibility = nil;

    if ([self.delegate respondsToSelector:@selector(stateNamesEffectingVisibility)])
    {
        stateNamesEffectingVisibility = [self.delegate stateNamesEffectingVisibility];
    }

    if (!stateNamesEffectingVisibility)
    {
        stateNamesEffectingVisibility = @[@"CurrentArtistName", @"CurrentAlbumName", @"CurrentSongName", @"CurrentElapsedTime", @"CurrentProgress", @"CurrentRemainingTime", @"CurrentArtworkPath"];;
    }

    return stateNamesEffectingVisibility;
}

- (BOOL)toolbarVisibleStateForStates:(NSDictionary *)stateValues
{
    BOOL visible = NO;

    for (id stateValue in [stateValues allValues])
    {
        if ([stateValue isKindOfClass:[NSString class]])
        {
            visible = [(NSString *)stateValue length] ? YES : NO;
        }
        else if ([stateValue isKindOfClass:[NSNumber class]])
        {
            visible = [stateValue integerValue] ? YES : NO;
        }

        if (visible)
        {
            break;
        }
    }

    return visible;
}

#pragma mark -

- (NSString *)commandWithButtonType:(SCUNowPlayingModelTransportButtonType)buttonType forState:(NSInteger)state
{
    return nil;
}

- (NSString *)_commandWithButtonType:(SCUNowPlayingModelTransportButtonType)buttonType forState:(NSInteger)state
{
    NSString *command = [self commandWithButtonType:buttonType forState:state];

    if (!command)
    {
        switch (buttonType)
        {
            case SCUNowPlayingModelTransportButtonTypePrevious:
                command = @"SkipDown";
                break;
            case SCUNowPlayingModelTransportButtonTypeNext:
                command = @"SkipUp";
                break;
            case SCUNowPlayingModelTransportButtonTypePlay:
                if (state == 0)
                {
                    command = @"Pause";
                }
                else
                {
                    command = @"Play";
                }

                break;
            case SCUNowPlayingModelTransportButtonTypePause:
                command = @"Pause";
                break;
            case SCUNowPlayingModelTransportButtonTypePlayPause:
            case SCUNowPlayingModelTransportButtonTypePlayStatic:
                command = @"Play";
                break;
            case SCUNowPlayingModelTransportButtonTypeShuffle:

                if ([self.service.serviceId hasPrefix:@"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIA"])
                {
                    command = @"ToggleShuffle";
                }
                else
                {
                    if (state == 0)
                    {
                        command = @"ShuffleOn";
                    }
                    else
                    {
                        command = @"ShuffleOff";
                    }
                }

                break;
            case SCUNowPlayingModelTransportButtonTypeRepeat:

                if ([self.service.serviceId hasPrefix:@"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIA"])
                {
                    command = @"ToggleRepeat";
                }
                else
                {
                    if (state == 0)
                    {
                        command = @"RepeatOn";
                    }
                    else
                    {
                        command = @"RepeatOff";
                    }
                }

                break;
            case SCUNowPlayingModelTransportButtonTypeFastForward:
                if ([self.service.transportForwardCommands containsObject:@"FastForward"])
                {
                    command = @"FastForward";
                }
                else if ([self.service.transportForwardCommands containsObject:@"FastPlayForward"])
                {
                    command = @"FastPlayForward";
                }
                else
                {
                    command = @"ScanUp";
                }
                break;
            case SCUNowPlayingModelTransportButtonTypeThumbsDown:
                command = @"DislikeSong";
                break;
            case SCUNowPlayingModelTransportButtonTypeThumbsUp:
                command = @"LikeSong";
                break;
            case SCUNowPlayingModelTransportButtonTypeRewind:
                if ([self.service.transportBackCommands containsObject:@"Rewind"])
                {
                    command = @"Rewind";
                }
                else if ([self.service.transportBackCommands containsObject:@"FastPlayReverse"])
                {
                    command = @"FastPlayReverse";
                }
                else
                {
                    command = @"ScanDown";
                }
                break;
        }
    }

    return command;
}

@end
