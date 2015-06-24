//
//  SCUSceneMediaHeaderView.m
//  SavantController
//
//  Created by Nathan Trapp on 8/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneMediaHeaderView.h"
@import Extensions;
@import SDK;

@implementation SCUSceneMediaHeaderView

- (instancetype)initWithService:(SAVSceneService *)service
{
    self = [super initWithFrame:CGRectMake(0, 0, 0, 130)];
    if (self)
    {
        NSDictionary *states = service.combinedStates;

        UIView *containerView = [[UIView alloc] init];
        containerView.backgroundColor = [[SCUColors shared] color03shade03];
        containerView.borderWidth = [UIScreen screenPixel];
        containerView.borderColor = [[SCUColors shared] color03shade04];

        [self addSubview:containerView];
        [self sav_addConstraintsForView:containerView withEdgeInsets:UIEdgeInsetsMake(14, 0, 14, 0)];

        UIImageView *checkmark = [[UIImageView alloc] initWithImage:[UIImage sav_imageNamed:@"TableCheckmark" tintColor:[[SCUColors shared] color03shade07]]];
        checkmark.contentMode = UIViewContentModeScaleAspectFit;
        [containerView addSubview:checkmark];

        UIImageView *artwork = [[UIImageView alloc] init];
        artwork.contentMode = UIViewContentModeScaleAspectFill;
        [containerView addSubview:artwork];

        UIView *infoView = [[UIView alloc] init];
        [containerView addSubview:infoView];

        NSUInteger numberOfLabels = 0;

        UILabel *songName = [[UILabel alloc] init];
        if (states[@"CurrentSongName"])
        {
            NSMutableAttributedString *baseString = [[NSMutableAttributedString alloc] init];

            [baseString appendAttributedString:[[NSAttributedString alloc] initWithString:[[NSLocalizedString(@"Song", nil) stringByAppendingString:@"\n"] uppercaseString]
                                                                               attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Gotham-Book" size:8],
                                                                                            NSForegroundColorAttributeName: [[SCUColors shared] color03shade07]}]];

            NSString *currentSong = states[@"CurrentSongName"];

            if (!currentSong)
            {
                currentSong = @"";
            }

            [baseString appendAttributedString:[[NSAttributedString alloc] initWithString:currentSong
                                                                               attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Gotham" size:14],
                                                                                            NSForegroundColorAttributeName: [[SCUColors shared] color04]}]];

            songName.attributedText = baseString;
            songName.numberOfLines = 2;
            numberOfLabels++;
        }

        [infoView addSubview:songName];

        UILabel *albumName = [[UILabel alloc] init];
        if (states[@"CurrentSongName"])
        {
            NSMutableAttributedString *baseString = [[NSMutableAttributedString alloc] init];

            [baseString appendAttributedString:[[NSAttributedString alloc] initWithString:[[NSLocalizedString(@"Album", nil) stringByAppendingString:@"\n"] uppercaseString]
                                                                               attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Gotham-Book" size:8],
                                                                                            NSForegroundColorAttributeName: [[SCUColors shared] color03shade07]}]];

            NSString *currentAlbum = states[@"CurrentAlbumName"];

            if (!currentAlbum)
            {
                currentAlbum = @"";
            }

            [baseString appendAttributedString:[[NSAttributedString alloc] initWithString:currentAlbum
                                                                               attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Gotham" size:14],
                                                                                            NSForegroundColorAttributeName: [[SCUColors shared] color04]}]];

            albumName.attributedText = baseString;
            albumName.numberOfLines = 2;
            numberOfLabels++;
        }

        [infoView addSubview:albumName];

        UILabel *artistName = [[UILabel alloc] init];
        if (states[@"CurrentSongName"])
        {
            NSMutableAttributedString *baseString = [[NSMutableAttributedString alloc] init];

            [baseString appendAttributedString:[[NSAttributedString alloc] initWithString:[[NSLocalizedString(@"Artist", nil) stringByAppendingString:@"\n"] uppercaseString]
                                                                               attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Gotham-Book" size:8],
                                                                                            NSForegroundColorAttributeName: [[SCUColors shared] color03shade07]}]];

            NSString *currentArtist = states[@"CurrentArtistName"];

            if (!currentArtist)
            {
                currentArtist = @"";
            }

            [baseString appendAttributedString:[[NSAttributedString alloc] initWithString:currentArtist
                                                                               attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Gotham" size:14],
                                                                                            NSForegroundColorAttributeName: [[SCUColors shared] color04]}]];

            artistName.attributedText = baseString;
            artistName.numberOfLines = 2;
            numberOfLabels++;
        }

        [infoView addSubview:artistName];

        if (states[@"CurrentArtworkPath"])
        {
            [[Savant images] imageForKey:states[@"CurrentArtworkPath"]
                                                             type:SAVImageTypeLMQNowPlayingArtwork
                                                             size:SAVImageSizeOriginal
                                                          blurred:NO
                                             requestingIdentifier:self
                                              componentIdentifier:service.component
                                                completionHandler:^(UIImage *image, BOOL isDefault) {
                                                                 artwork.image = image;
                                                    [containerView sav_setWidth:60 forView:artwork isRelative:NO];
                                                             }];
        }

        [infoView sav_pinView:albumName withOptions:SAVViewPinningOptionsToTop|SAVViewPinningOptionsHorizontally];
        [infoView sav_pinView:artistName withOptions:SAVViewPinningOptionsHorizontally];
        [infoView sav_pinView:songName withOptions:SAVViewPinningOptionsHorizontally];
        [infoView sav_pinView:artistName withOptions:SAVViewPinningOptionsToBottom ofView:albumName withSpace:2];
        [infoView sav_pinView:songName withOptions:SAVViewPinningOptionsToBottom ofView:artistName withSpace:2];
        [containerView sav_setHeight:numberOfLabels * 27 forView:infoView isRelative:NO];

        [containerView sav_setWidth:-15 forView:artwork isRelative:NO];
        [containerView sav_pinView:artwork withOptions:SAVViewPinningOptionsVertically|SAVViewPinningOptionsToLeft withSpace:15];
        [containerView sav_pinView:infoView withOptions:SAVViewPinningOptionsCenterY|SAVViewPinningOptionsToRight ofView:artwork withSpace:15];
        [containerView sav_pinView:infoView withOptions:SAVViewPinningOptionsToLeft ofView:checkmark withSpace:15];
        [containerView sav_setWidth:30 forView:checkmark isRelative:NO];
        [containerView sav_pinView:checkmark withOptions:SAVViewPinningOptionsCenterY|SAVViewPinningOptionsToRight withSpace:10];
    }
    return self;
}

@end
