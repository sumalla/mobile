//
//  SCURadioFavoritesModel.m
//  SavantController
//
//  Created by Nathan Trapp on 9/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCURadioFavoritesModel.h"
#import "SCUEditableButtonsCollectionViewModelPrivate.h"

@implementation SCURadioFavoritesModel

- (void)applyFavorite:(SAVFavorite *)favorite
{
    NSString *command = [self.service.favoriteCommands firstObject];

    if ([command length] && [favorite.number length])
    {
        NSArray *components = [favorite.number componentsSeparatedByString:@"."];

        if ([components count] == 2)
        {
            [self sendCommand:command withArguments:@{@"FrequencyWhole": components[0],
                                                      @"FrequencyPart": components[1]}];
        }
        else
        {
            [self sendCommand:command withArguments:@{@"Frequency": favorite.number}];
        }
    }
}

@end