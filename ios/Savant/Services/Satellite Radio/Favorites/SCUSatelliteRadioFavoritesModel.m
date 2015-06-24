//
//  SCUSatelliteRadioFavoritesModel.m
//  SavantController
//
//  Created by Nathan Trapp on 9/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSatelliteRadioFavoritesModel.h"
#import "SCUEditableButtonsCollectionViewModelPrivate.h"

@implementation SCUSatelliteRadioFavoritesModel

- (void)applyFavorite:(SAVFavorite *)favorite
{
    NSString *command = [self.service.favoriteCommands firstObject];

    if ([command length] && [favorite.number length])
    {
        [self sendCommand:command withArguments:@{@"Frequency": favorite.number}];
    }
}

@end
