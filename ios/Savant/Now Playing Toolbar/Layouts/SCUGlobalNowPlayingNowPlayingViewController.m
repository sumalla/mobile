//
//  SCUGlobalNowPlayingNowPlayingViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 9/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUGlobalNowPlayingNowPlayingViewController.h"
#import "SCUNowPlayingViewControllerPrivate.h"
@import SDK;

@interface SCUGlobalNowPlayingNowPlayingViewController ()

@property (nonatomic) SCUButton *play;
@property (nonatomic) SCUButton *pause;
@property (nonatomic) SCUButton *fastforward;
@property (nonatomic) SCUButton *rewind;
@property (nonatomic) SCUButton *next;
@property (nonatomic) SCUButton *previous;
@property (nonatomic) UIView *transportContainer;
@property (nonatomic) NSArray *transportButtons;
@property (nonatomic) SAVServiceGroup *serviceGroup;

@end

@implementation SCUGlobalNowPlayingNowPlayingViewController

- (instancetype)initWithServiceGroup:(SAVServiceGroup *)serviceGroup
{
    self = [super initWithService:serviceGroup.wildCardedService serviceGroup:serviceGroup];
    if (self)
    {
        self.serviceGroup = serviceGroup;
        self.play = [self buttonWithTransportButtonType:SCUNowPlayingModelTransportButtonTypePlay];
        self.pause = [self buttonWithTransportButtonType:SCUNowPlayingModelTransportButtonTypePause];
        self.fastforward = [self buttonWithTransportButtonType:SCUNowPlayingModelTransportButtonTypeFastForward];
        self.rewind = [self buttonWithTransportButtonType:SCUNowPlayingModelTransportButtonTypeRewind];
        self.next = [self buttonWithTransportButtonType:SCUNowPlayingModelTransportButtonTypeNext];
        self.previous = [self buttonWithTransportButtonType:SCUNowPlayingModelTransportButtonTypePrevious];

        NSMutableArray *transportButtons = [NSMutableArray array];

        for (NSNumber *transportType in [SCUGlobalNowPlayingNowPlayingViewController transportButtonsForServiceGroup:serviceGroup])
        {
            SCUNowPlayingModelTransportButtonType type = [transportType integerValue];

            switch (type)
            {
                case SCUNowPlayingModelTransportButtonTypeNext:
                    [transportButtons addObject:self.next];
                    break;
                case SCUNowPlayingModelTransportButtonTypePlay:
                    [transportButtons addObject:self.play];
                    break;
                case SCUNowPlayingModelTransportButtonTypePlayStatic:
                    self.play = [self buttonWithTransportButtonType:SCUNowPlayingModelTransportButtonTypePlayStatic];
                    [transportButtons addObject:self.play];
                    break;
                case SCUNowPlayingModelTransportButtonTypePause:
                    [transportButtons addObject:self.pause];
                    break;
                case SCUNowPlayingModelTransportButtonTypePlayPause:
                    self.play = [self buttonWithTransportButtonType:SCUNowPlayingModelTransportButtonTypePlayPause];
                    [transportButtons addObject:self.play];
                    break;
                case SCUNowPlayingModelTransportButtonTypeFastForward:
                    [transportButtons addObject:self.fastforward];
                    break;
                case SCUNowPlayingModelTransportButtonTypeRewind:
                    [transportButtons addObject:self.rewind];
                    break;
                case SCUNowPlayingModelTransportButtonTypePrevious:
                    [transportButtons addObject:self.previous];
                    break;
                default:
                    break;

            }
        }

        self.transportButtons = transportButtons;
    }
    return self;
}

+ (NSArray *)transportButtonsForServiceGroup:(SAVServiceGroup *)serviceGroup
{
    NSMutableArray *transportButtons = [NSMutableArray array];

    if ([serviceGroup.serviceId containsString:@"LIVEMEDIAQUERY"] ||
        [serviceGroup.serviceId isEqualToString:@"SVC_AV_DIGITALAUDIO"])
    {
        transportButtons = [@[@(SCUNowPlayingModelTransportButtonTypePrevious), @(SCUNowPlayingModelTransportButtonTypePlay), @(SCUNowPlayingModelTransportButtonTypeNext)] mutableCopy];
    }
    else
    {
        NSArray *transportCommands = [[serviceGroup.services firstObject] transportCommands];

        if ([transportCommands containsObject:@"SkipDown"])
        {
            [transportButtons addObject:@(SCUNowPlayingModelTransportButtonTypePrevious)];
        }
        else if ([transportCommands containsObject:@"Rewind"] ||
                 [transportCommands containsObject:@"FastPlayReverse"] ||
                 [transportCommands containsObject:@"ScanDown"])
        {
            [transportButtons addObject:@(SCUNowPlayingModelTransportButtonTypeRewind)];
        }

        if ([serviceGroup.serviceId hasPrefix:@"SVC_AV_APPLEREMOTEMEDIASERVER"])
        {
            [transportButtons addObject:@(SCUNowPlayingModelTransportButtonTypePlayPause)];
        }
        else
        {
            if ([transportCommands containsObject:@"Pause"])
            {
                [transportButtons addObject:@(SCUNowPlayingModelTransportButtonTypePause)];
            }

            if ([transportCommands containsObject:@"Play"])
            {
                [transportButtons addObject:@(SCUNowPlayingModelTransportButtonTypePlayStatic)];
            }
        }

        if ([transportCommands containsObject:@"SkipUp"])
        {
            [transportButtons addObject:@(SCUNowPlayingModelTransportButtonTypeNext)];
        }
        else if ([transportCommands containsObject:@"FastForward"] ||
                 [transportCommands containsObject:@"FastPlayForward"] ||
                 [transportCommands containsObject:@"ScanUp"])
        {
            [transportButtons addObject:@(SCUNowPlayingModelTransportButtonTypeFastForward)];
        }
    }

    return [transportButtons copy];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    SAVViewDistributionConfiguration *configuration = [[SAVViewDistributionConfiguration alloc] init];
    configuration.interSpace = 40;
    configuration.fixedWidth = 40;

    __block NSString *horizontalFormat = @"|";
    __block NSMutableArray *allFormats = [NSMutableArray array];

    NSMutableDictionary *views = [NSMutableDictionary dictionary];

    self.transportContainer = [[UIView alloc] init];

    [self.transportButtons enumerateObjectsUsingBlock:^(SCUButton *button, NSUInteger idx, BOOL *stop) {
        NSString *viewString = [NSString stringWithFormat:@"view%ld", (unsigned long)idx];
        [self.transportContainer addSubview:button];
        views[viewString] = button;

        NSString *spacerString = [NSString stringWithFormat:@"spacer%ld", (unsigned long)idx];
        UIView *spacer = [[UIView alloc] init];
        [self.transportContainer addSubview:spacer];
        views[spacerString] = spacer;

        if (idx > 0)
        {
            horizontalFormat = [horizontalFormat stringByAppendingString:[NSString stringWithFormat:@"[%@(==spacer0)][%@]", spacerString, viewString]];
        }
        else
        {
            horizontalFormat = [horizontalFormat stringByAppendingString:[NSString stringWithFormat:@"[%@][%@]", spacerString, viewString]];
        }

        [allFormats addObject:[NSString stringWithFormat:@"V:|[%@]|", viewString]];
    }];

    NSString *spacerString = [NSString stringWithFormat:@"spacer%ld", (unsigned long)[self.transportButtons count]];
    UIView *spacer = [[UIView alloc] init];
    [self.transportContainer addSubview:spacer];
    views[spacerString] = spacer;

    horizontalFormat = [horizontalFormat stringByAppendingString:[NSString stringWithFormat:@"[%@(==spacer0)]|", spacerString]];

    [allFormats addObject:horizontalFormat];

    [self.transportContainer addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:nil
                                                                                     views:views
                                                                                   formats:allFormats]];

    [self.view addSubview:self.transportContainer];
    [self.view sav_pinView:self.transportContainer withOptions:SAVViewPinningOptionsVertically|SAVViewPinningOptionsHorizontally];
}

- (void)toggleHidden:(BOOL)hidden
{

}

- (NSArray *)states
{
    return @[@"CurrentPauseStatus"];
}

- (void)pauseStatusDidUpdateWithValue:(NSNumber *)value
{
    [super pauseStatusDidUpdateWithValue:value];

    if (self.play.tag == SCUNowPlayingModelTransportButtonTypePlay)
    {
        if ([value boolValue])
        {
            self.play.image = [UIImage sav_imageNamed:@"Play" tintColor:[[SCUColors shared] color04]];
        }
        else
        {
            self.play.image = [UIImage sav_imageNamed:@"Pause" tintColor:[[SCUColors shared] color04]];
        }
    }
}

@end
