//
//  SCUDVDNowPlayingViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 5/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVNowPlayingViewController.h"
#import "SCUNowPlayingViewControllerPrivate.h"
#import "SCUAVNowPlayingModel.h"

@import SDK;

@interface SCUAVNowPlayingViewController () <SCUNowPlayingModelDelegate>

@property (nonatomic) NSString *diskNumber;
@property (nonatomic) NSString *chapterNumber;
@property (nonatomic) NSString *titleNumber;
@property (nonatomic) NSString *titleName;
@property (nonatomic) NSString *currentMajorChannel;
@property (nonatomic) NSString *currentMinorChannel;
@property (nonatomic) NSString *currentFrequency;
@property (nonatomic) NSString *currentStation;
@property (nonatomic) NSArray  *favorites;
@property (nonatomic) NSString *station;

@end

@implementation SCUAVNowPlayingViewController

- (instancetype)initWithService:(SAVService *)service serviceGroup:(SAVServiceGroup *)serviceGroup
{
    self = [super initWithService:service serviceGroup:serviceGroup];

    if (self)
    {
        self.model = [[SCUAVNowPlayingModel alloc] initWithService:service serviceGroup:serviceGroup delegate:self];
        self.model.delegate = self;
    }

    return self;
}

- (void)addSubviews
{
    [self.view addSubview:self.elapsedTimeLabel];
    [self.view addSubview:self.label];

    self.label.textAlignment = NSTextAlignmentRight;

    [self.view sav_pinView:self.elapsedTimeLabel withOptions:SAVViewPinningOptionsToLeft|SAVViewPinningOptionsVertically withSpace:SAVViewAutoLayoutStandardSpace];
    [self.view sav_pinView:self.label withOptions:SAVViewPinningOptionsToRight|SAVViewPinningOptionsVertically withSpace:SAVViewAutoLayoutStandardSpace];
    [self.view sav_pinView:self.label withOptions:SAVViewPinningOptionsToRight ofView:self.elapsedTimeLabel withSpace:SAVViewAutoLayoutStandardSpace];
}

- (void)updateLabel
{
    [super updateLabel];

    NSMutableAttributedString *baseString = [self.label.attributedText mutableCopy];

    if ([self.titleName length])
    {
        NSString *strippedTitle = [self.titleName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [baseString appendAttributedString:[[NSAttributedString alloc] initWithString:strippedTitle
                                                                           attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Gotham-Bold" size:17]}]];
    }

    if ([self.diskNumber length])
    {
        NSString *strippedDisc = [NSLocalizedString(@"Disc", nil) stringByAppendingFormat:@" %@", [self.diskNumber stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        NSString *disc = [baseString length] ? [NSString stringWithFormat:@" - %@", strippedDisc] : strippedDisc;

        [baseString appendAttributedString:[[NSAttributedString alloc] initWithString:disc
                                                                           attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Gotham" size:17]}]];
    }

    if ([self.chapterNumber length])
    {
        NSString *strippedChapter = [NSLocalizedString(@"Chapter", nil) stringByAppendingFormat:@" %@", [self.chapterNumber stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        NSString *chapter = [baseString length] ? [NSString stringWithFormat:@" - %@ ", strippedChapter] : strippedChapter;

        [baseString appendAttributedString:[[NSAttributedString alloc] initWithString:chapter
                                                                           attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Gotham" size:17]}]];
    }

    if ([self.titleNumber length])
    {
        NSString *strippedTitleNumber = [NSLocalizedString(@"Title", nil) stringByAppendingFormat:@" %@", [self.titleNumber stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        NSString *titleNumber = [baseString length] ? [NSString stringWithFormat:@" - %@ ", strippedTitleNumber] : strippedTitleNumber;

        [baseString appendAttributedString:[[NSAttributedString alloc] initWithString:titleNumber
                                                                           attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Gotham" size:17]}]];
    }

    if ([self.station length])
    {
        if ([self.favorites count])
        {
            for (SAVFavorite *favorite in self.favorites)
            {
                if ([favorite.number isEqualToString:self.station])
                {
                    NSString *strippedFavorite = [favorite.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    NSString *favoriteName = [baseString length] ? [NSString stringWithFormat:@" - %@ ", strippedFavorite] : strippedFavorite;

                    [baseString appendAttributedString:[[NSAttributedString alloc] initWithString:favoriteName
                                                                                       attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Gotham-Bold" size:17]}]];

                    break;
                }
            }
        }

        NSString *strippedChannel = [NSLocalizedString(@"Channel", nil) stringByAppendingFormat:@" %@", [self.currentStation stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        NSString *channel = [baseString length] ? [NSString stringWithFormat:@" - %@", strippedChannel] : strippedChannel;

        [baseString appendAttributedString:[[NSAttributedString alloc] initWithString:channel
                                                                           attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Gotham" size:17]}]];
    }

    [baseString addAttribute:NSForegroundColorAttributeName
                       value:[[SCUColors shared] color01]
                       range:NSMakeRange(0, [baseString length])];

    self.label.attributedText = [baseString copy];
    [self.label setNeedsLayout];
    [self.label layoutIfNeeded];
}

- (void)clearStates
{
    self.diskNumber = nil;
    self.chapterNumber = nil;
    self.titleNumber = nil;
    self.titleName = nil;

    [self updateLabel];
}

#pragma mark - SCUNowPlayingModelDelegate

- (void)diskNumberDidUpdateWithValue:(NSString *)value
{
    self.diskNumber = value;
    [self updateLabel];
}

- (void)chapterDidUpdateWithValue:(NSString *)value
{
    self.chapterNumber = value;
    [self updateLabel];
}

- (void)titleDidUpdateWithValue:(NSString *)value
{
    self.titleNumber = value;
    [self updateLabel];
}

- (void)textDidUpdateWithValue:(NSString *)value
{
    self.titleName = value;
    [self updateLabel];
}

- (void)currentMajorChannelDidUpdateWithValue:(NSString *)value
{
    self.currentMajorChannel = value;

    if (self.currentMinorChannel)
    {
        self.station = [self.currentMajorChannel stringByAppendingString:self.currentMinorChannel];
    }
    else
    {
        self.station = self.currentMajorChannel;
    }

    [self updateLabel];
}

- (void)currentMinorChannelDidUpdateWithValue:(NSString *)value
{
    self.currentMinorChannel = value;

    if (self.currentMinorChannel)
    {
        self.station = [self.currentMajorChannel stringByAppendingString:self.currentMinorChannel];
    }
    else
    {
        self.station = self.currentMajorChannel;
    }

    [self updateLabel];
}

- (void)currentTunerFrequencyDidUpdateWithValue:(NSString *)value
{
    self.currentFrequency = value;

    self.station = self.currentFrequency;

    [self updateLabel];
}

- (void)currentStationDidUpdateWithValue:(NSString *)value
{
    self.currentStation = value;

    if (![self.currentMajorChannel length] && ![self.currentFrequency length])
    {
        self.station = value;
    }

    [self updateLabel];
}

- (void)favoritesDidUpdate:(NSArray *)favorites
{
    self.favorites = favorites;
    [self updateLabel];
}

@end
