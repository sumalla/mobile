//
//  SCUSceneFavoritesDataSource.m
//  SavantController
//
//  Created by Nathan Trapp on 8/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneFavoritesDataSource.h"
#import "SCUDefaultTableViewCell.h"

@import SDK;

@interface SCUSceneFavoritesDataSource () <StateDelegate>

@property SAVService *service;
@property SAVScene *scene;
@property SAVSceneService *sceneSerice;
@property NSArray *dataSource;
@property (weak) id <SCUSceneFavoritesDelegate> delegate;
@property NSArray *feedbackNames;
@property SAVDISRequestGenerator *generator;
@property NSString *serviceType;
@property NSArray *lastFavorites;

@end

@implementation SCUSceneFavoritesDataSource

- (instancetype)initWithScene:(SAVScene *)scene service:(SAVService *)service sceneService:(SAVSceneService *)sceneService delegate:(id<SCUSceneFavoritesDelegate>)delegate
{
    self = [super init];
    if (self)
    {
        self.scene = scene;
        self.sceneSerice = sceneService;
        self.service = service;
        self.delegate = delegate;
        self.serviceType = [SAVServiceGroup genericServiceIdForServiceId:self.service.serviceId];

        self.generator = [[SAVDISRequestGenerator alloc] initWithApp:@"channelFavorites"];
        self.feedbackNames = [self.generator feedbackStringsWithStateNames:@[[NSString stringWithFormat:@"favorites.%@", self.serviceType]]];
        [[Savant states] registerForStates:self.feedbackNames forObserver:self];

        [self loadFavorites:nil];
    }
    return self;
}

- (void)dealloc
{
    [[Savant states] unregisterForStates:self.feedbackNames forObserver:self];
}

- (void)loadFavorites:(NSArray *)favorites
{
    if (favorites)
    {
        self.lastFavorites = favorites;
    }
    else
    {
        favorites = self.lastFavorites;
    }

    BOOL hasSelectedFavorite = NO;
    BOOL hasOriginalStation = NO;
    NSString *currentStation = self.sceneSerice.combinedStates[@"CurrentStation"];
    NSString *originalSelectedStation = self.sceneSerice.states[@"CurrentStation"];

    NSMutableArray *dataSource = [NSMutableArray array];

    NSMutableDictionary *previousChannel = [@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Previous Station", nil),
                                              SCUDefaultTableViewCellKeyAccessoryType: @(UITableViewCellAccessoryNone)} mutableCopy];

    [dataSource addObject:previousChannel];

    for (NSDictionary *favoriteSettings in favorites)
    {
        SAVFavorite *favorite = [SAVFavorite favoriteWithSettings:favoriteSettings];
        NSMutableDictionary *modelObject = [NSMutableDictionary dictionary];

        modelObject[SCUDefaultTableViewCellKeyModelObject] = favorite;

        if ([favorite.description length])
        {
            modelObject[SCUDefaultTableViewCellKeyTitle] = favorite.name;
        }
        else if (favorite.number)
        {
            modelObject[SCUDefaultTableViewCellKeyTitle] = favorite.number;
        }

        if (favorite.imageKey)
        {
            if (favorite.image)
            {
                modelObject[SCUDefaultTableViewCellKeyImage] = favorite.image;
            }

            SAVWeakSelf;
            favorite.imageChangeCallback = ^(UIImage *image){
                if (image)
                {
                    modelObject[SCUDefaultTableViewCellKeyImage] = image;
                    [wSelf.delegate reloadData];
                }
            };
        }

        if (originalSelectedStation && [originalSelectedStation isEqualToString:favorite.number])
        {
            hasOriginalStation = YES;
        }

        if (currentStation && [currentStation isEqualToString:favorite.number])
        {
            modelObject[SCUDefaultTableViewCellKeyAccessoryType] = @(UITableViewCellAccessoryCheckmark);
            hasSelectedFavorite = YES;
        }
        else
        {
            modelObject[SCUDefaultTableViewCellKeyAccessoryType] = @(UITableViewCellAccessoryNone);
        }

        [dataSource addObject:modelObject];
    }

    if (!hasOriginalStation && originalSelectedStation)
    {
        NSMutableDictionary *modelObject = [NSMutableDictionary dictionary];
        modelObject[SCUDefaultTableViewCellKeyTitle] = originalSelectedStation;

        if ([currentStation isEqualToString:originalSelectedStation])
        {
            modelObject[SCUDefaultTableViewCellKeyAccessoryType] = @(UITableViewCellAccessoryCheckmark);
            hasSelectedFavorite = YES;
        }
        else
        {
            modelObject[SCUDefaultTableViewCellKeyAccessoryType] = @(UITableViewCellAccessoryNone);
        }

        [dataSource addObject:modelObject];
    }

    if (!hasSelectedFavorite)
    {
        previousChannel[SCUDefaultTableViewCellKeyAccessoryType] = @(UITableViewCellAccessoryCheckmark);
    }

    self.dataSource = dataSource;

    [self.delegate reloadData];
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    SAVFavorite *favorite = [self modelObjectForIndexPath:indexPath][SCUDefaultTableViewCellKeyModelObject];

    if (favorite)
    {
        NSString *channelNumber = favorite.number;

        if ([self.sceneSerice.combinedStates[@"CurrentStation"] isEqualToString:channelNumber])
        {
            [self.sceneSerice applyValue:nil forSetting:@"CurrentStation" immediately:NO];
        }
        else
        {
            [self.sceneSerice applyValue:channelNumber forSetting:@"CurrentStation" immediately:NO];
        }
    }
    else
    {
        [self.sceneSerice applyValue:nil forSetting:@"CurrentStation" immediately:NO];
    }

    [self loadFavorites:nil];
    [self.delegate reloadData];
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"Favorites", nil);
}

#pragma mark - StateDelegate methods

- (void)didReceiveDISFeedback:(SAVDISFeedback *)feedback
{
    if ([feedback.state hasPrefix:@"favorites"])
    {
        [self loadFavorites:[feedback value]];
    }
}

@end
