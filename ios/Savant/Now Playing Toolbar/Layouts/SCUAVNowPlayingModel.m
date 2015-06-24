//
//  SCUDVDNowPlayingModel.m
//  SavantController
//
//  Created by Nathan Trapp on 5/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVNowPlayingModel.h"
#import "SCUNowPlayingModelPrivate.h"

@import SDK;

@interface SCUAVNowPlayingModel () <StateDelegate>

@property (nonatomic) NSString *currentHour;
@property (nonatomic) NSString *currentMinute;
@property (nonatomic) NSString *currentSecond;
@property (nonatomic) NSString *elapsedTime;

@property SAVDISRequestGenerator *generator;
@property NSString *serviceType;
@property NSArray *favoriteStates;

@end

@implementation SCUAVNowPlayingModel

- (instancetype)initWithService:(SAVService *)service serviceGroup:(SAVServiceGroup *)serviceGroup delegate:(id<SCUNowPlayingModelDelegate>)delegate
{
    self = [super initWithService:service serviceGroup:serviceGroup delegate:delegate];
    if (self)
    {
        self.serviceType = [SAVServiceGroup genericServiceIdForServiceId:service.serviceId];
        self.generator = [[SAVDISRequestGenerator alloc] initWithApp:@"channelFavorites"];
        self.favoriteStates = [self.generator feedbackStringsWithStateNames:@[[NSString stringWithFormat:@"favorites.%@", self.serviceType]]];

        [[Savant states] registerForStates:self.favoriteStates forObserver:self];
    }
    return self;
}

#pragma mark - Elapsed Time

- (void)dealloc
{
    [[Savant states] unregisterForStates:self.favoriteStates forObserver:self];
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

    if ([self.delegate respondsToSelector:@selector(elapsedTimeDidUpdateWithValue:)])
    {
        [self.delegate elapsedTimeDidUpdateWithValue:self.elapsedTime];
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

#pragma mark - States

- (void)didReceiveDISFeedback:(SAVDISFeedback *)feedback
{
    if ([feedback.state hasPrefix:@"favorites"])
    {
        NSArray *favorites = [feedback.value arrayByMappingBlock:^id(NSDictionary *favoriteSettings) {
            if ([favoriteSettings isKindOfClass:[NSDictionary class]])
            {
                return [SAVFavorite favoriteWithSettings:favoriteSettings];
            }
            else
            {
                return nil;
            }
        }];

        [self.delegate favoritesDidUpdate:favorites];
    }
}

- (NSDictionary *)stateNamesToDelegateSelectors
{
    NSMutableDictionary *stateNames = [NSMutableDictionary dictionaryWithDictionary:[super stateNamesToDelegateSelectors]];

    [stateNames addEntriesFromDictionary:@{@"CurrentDiskNumber": NSStringFromSelector(@selector(diskNumberDidUpdateWithValue:)),
                                           @"CurrentChapter": NSStringFromSelector(@selector(chapterDidUpdateWithValue:)),
                                           @"CurrentTitle": NSStringFromSelector(@selector(titleDidUpdateWithValue:)),

                                           @"CurrentMajorChannelNumber": NSStringFromSelector(@selector(currentMajorChannelDidUpdateWithValue:)),
                                           @"CurrentMinorChannelNumber": NSStringFromSelector(@selector(currentMinorChannelDidUpdateWithValue:)),
                                           @"CurrentTunerFrequency": NSStringFromSelector(@selector(currentTunerFrequencyDidUpdateWithValue:)),
                                           @"CurrentStation": NSStringFromSelector(@selector(currentStationDidUpdateWithValue:)),

                                           @"CurrentDiskText": NSStringFromSelector(@selector(textDidUpdateWithValue:)),

                                           @"CurrentElapsedHour": NSStringFromSelector(@selector(elapsedHourDidUpdateWithValue:)),
                                           @"CurrentElapsedMinute": NSStringFromSelector(@selector(elapsedMinuteDidUpdateWithValue:)),
                                           @"CurrentElapsedSecond": NSStringFromSelector(@selector(elapsedSecondDidUpdateWithValue:))}];

    [stateNames removeObjectForKey:@"CurrentElapsedTime"];

    return stateNames;
}

- (NSArray *)stateNamesEffectingVisibility
{
    NSMutableArray *stateNames = [NSMutableArray arrayWithArray:[super stateNamesEffectingVisibility]];

    [stateNames addObjectsFromArray:@[@"CurrentElapsedHour", @"CurrentElapsedMinute",
                                      @"CurrentElapsedSecond", @"CurrentMajorChannelNumber", @"CurrentMinorChannelNumber", @"CurrentFrequency", @"CurrentStation",
                                      @"CurrentDiskNumber", @"CurrentChapter", @"CurrentTitle"]];

    return stateNames;
}

@end
