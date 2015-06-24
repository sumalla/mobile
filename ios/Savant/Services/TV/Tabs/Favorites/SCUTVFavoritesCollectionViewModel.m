//
//  SCUTVFavoritesCollectionViewModel.m
//  SavantController
//
//  Created by Nathan Trapp on 9/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUTVFavoritesCollectionViewModel.h"
#import "SCUEditableButtonsCollectionViewModelPrivate.h"

@implementation SCUTVFavoritesCollectionViewModel

- (void)applyFavorite:(SAVFavorite *)favorite
{
    NSString *command = [self.service.favoriteCommands firstObject];

    if ([command length] && [favorite.number length])
    {
        [self sendCommand:command withArguments:@{@"ChannelNumber": favorite.number}];
    }
}

@end
