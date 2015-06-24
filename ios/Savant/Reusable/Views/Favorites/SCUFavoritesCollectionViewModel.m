//
//  SCUScenesModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 7/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUFavoritesCollectionViewModel.h"
#import "SCUDataSourceModelPrivate.h"
@import SDK;
#import "SCUScenesCollectionViewCell.h"
#import "SCUServiceViewModel.h"
#import "SCUAnalytics.h"

@interface SCUFavoritesCollectionViewModel () <StateDelegate, DISResultDelegate>

@property (nonatomic, copy) NSArray *dataSource;
@property (nonatomic) SAVDISRequestGenerator *generator;
@property (nonatomic) NSArray *feedbackNames;
@property (nonatomic) NSIndexPath *movingIndexPath;
@property (nonatomic) NSIndexPath *editingIndexPath;
@property (nonatomic, getter = isEditing) BOOL editing;
@property (nonatomic) NSString *currentEditingIdentifier;
@property (nonatomic, weak) SCUReorderableTileLayout *layout;
@property (nonatomic) NSArray *favoritesIdentifierOrder;
@property (nonatomic) SAVService *service;
@property (nonatomic) NSString *serviceType;
@property (nonatomic) SCUServiceViewModel *serviceModel;
@property (copy) SCUFavoriteSystemImageResults resultsBlock;

@end

@implementation SCUFavoritesCollectionViewModel

- (instancetype)initWithService:(SAVService *)service
{
    self = [super init];
    if (self)
    {
        self.serviceModel = [[SCUServiceViewModel alloc] initWithService:service];
        self.service = service;
        self.serviceType = [SAVServiceGroup genericServiceIdForServiceId:self.service.serviceId];
    }
    return self;
}

- (void)fetchSystemImages:(SCUFavoriteSystemImageResults)results
{
    self.resultsBlock = results;

    SAVDISRequest *fetchImages = [self.generator request:@"FetchSystemImages" withArguments:@{@"SVC_TYPE": self.serviceType}];
    [[Savant control] sendMessage:fetchImages];
}

- (void)removeFavoriteAtIndexPath:(NSIndexPath *)indexPath
{
    SAVDISRequest *removeFavorite = [self.generator request:@"RemoveFavorite" withArguments:@{@"id": [self favoriteIdentifierForIndexPath:indexPath], @"SVC_TYPE": self.serviceType}];
    [[Savant control] sendMessage:removeFavorite];

    [self.layout endEditing];
}

#pragma mark - SCUDataSourceModel methods

- (void)viewDidAppear
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [SCUAnalytics recordEvent:@"Favorites Tab Navigation" withKey:@"favoritesCount" value:[NSString stringWithFormat:@"%lu", (unsigned long)[self.dataSource count] - 1]];
    });
}

- (void)loadDataIfNecessary
{
    if (!self.generator)
    {
        self.generator = [[SAVDISRequestGenerator alloc] initWithApp:@"channelFavorites"];
        self.feedbackNames = [self.generator feedbackStringsWithStateNames:@[[NSString stringWithFormat:@"favorites.%@", self.serviceType]]];
        [[Savant states] registerForStates:self.feedbackNames forObserver:self];
        [[Savant control] addDISResultObserver:self forApp:@"channelFavorites"];
        [self loadFavorites:nil];
    }
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [super _modelObjectForIndexPath:indexPath];
    
    if ([self isIndexPathAddItem:indexPath])
    {
        modelObject = [modelObject dictionaryByAddingObject:@YES forKey:SCUScenesCellKeyIsActionCell];
    }

    if ([indexPath isEqual:self.editingIndexPath])
    {
        modelObject = [modelObject dictionaryByAddingObject:@YES forKey:SCUScenesCellKeyIsInEditMode];
    }

    if ([indexPath isEqual:self.movingIndexPath])
    {
        modelObject = [modelObject dictionaryByAddingObject:@YES forKey:SCUScenesCellKeyIsMoving];
    }

    return modelObject;
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isIndexPathAddItem:indexPath])
    {
        [self.delegate editFavorite:nil];
    }
    else
    {
        [self applyFavorite:[self favoriteForIndexPath:indexPath]];

        NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];

        SAVFavorite *favorite = (SAVFavorite *)modelObject[SCUDefaultCollectionViewCellKeyModelObject];

        if ([favorite isKindOfClass:[SAVFavorite class]])
        {
            NSMutableDictionary *properties = [NSMutableDictionary dictionary];
            [properties setValue:favorite.name forKey:@"favoriteName"];
            [properties setValue:favorite.number forKey:@"favoriteChannel"];
            [SCUAnalytics recordEvent:@"Favorite Selected" properties:[properties copy]];
        }
    }
}

- (void)applyFavorite:(SAVFavorite *)favorite
{
    ; // Subclass this
}

- (void)sendCommand:(NSString *)command withArguments:(NSDictionary *)arguments
{
    [self.serviceModel sendCommand:command withArguments:arguments];
}

- (void)configureCell:(id)c withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    SCUScenesCollectionViewCell *cell = (SCUScenesCollectionViewCell *)c;

    SAVFavorite *favorite = [self favoriteForIndexPath:indexPath];
    if (favorite)
    {
        if (favorite.image)
        {
            cell.displayingDefaultImage = NO;
            cell.backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;
            cell.backgroundImageView.image = favorite.image;
            cell.textLabel.text = nil;
        }
        else
        {
            cell.displayingDefaultImage = YES;
            cell.backgroundImageView.contentMode = UIViewContentModeCenter;
            cell.backgroundImageView.image = [UIImage sav_imageNamed:@"no_channel_art" tintColor:[[SCUColors shared] color03shade04]];
        }
    }
    else
    {
        cell.backgroundImageView.image = nil;
    }

    SAVWeakSelf;
    favorite.imageChangeCallback = ^(UIImage *image){
        [wSelf.delegate reloadIndexPaths:@[indexPath]];
    };

    [cell.editSceneButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        [wSelf.delegate editFavorite:[wSelf favoriteForIndexPath:indexPath]];
    }];
}

#pragma mark - SCUReorderableTileLayoutDelegate methods

- (void)layout:(SCUReorderableTileLayout *)layout moveIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSMutableArray *dataSource = [self.dataSource mutableCopy];
    NSDictionary *dictionary = [self _modelObjectForIndexPath:fromIndexPath];
    [dataSource removeObjectAtIndex:fromIndexPath.row];
    [dataSource insertObject:dictionary atIndex:toIndexPath.row];
    self.dataSource = dataSource;
}

- (void)layout:(SCUReorderableTileLayout *)layout updateModelWithIndexPathOrdering:(NSArray *)indexPathOrdering
{
    NSMutableArray *newDataSource = [NSMutableArray array];

    for (NSIndexPath *indexPath in indexPathOrdering)
    {
        id modelObject = [self _modelObjectForIndexPath:indexPath];
        [newDataSource addObject:modelObject];
    }

    self.dataSource = newDataSource;
}

- (BOOL)layout:(SCUReorderableTileLayout *)layout canEditItemAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canEdit = YES;

    if ([self isIndexPathAddItem:indexPath])
    {
        canEdit = NO;
    }

    return canEdit;
}

- (void)layoutDidEnterEditingMode:(SCUReorderableTileLayout *)layout
{
    [self.delegate setEditingMode:YES];
    self.layout = layout;
}

- (void)layoutDidEndEditingMode:(SCUReorderableTileLayout *)layout
{
    [self.delegate setEditingMode:NO];

    NSMutableArray *identifierOrder = [NSMutableArray array];

    for (NSDictionary *modelObject in self.dataSource)
    {
        SAVFavorite *favorite = modelObject[SCUDefaultCollectionViewCellKeyModelObject];
        if (favorite)
        {
            [identifierOrder addObject:favorite.identifier];
        }
    }

    if (![self.favoritesIdentifierOrder isEqualToArray:identifierOrder])
    {
        self.favoritesIdentifierOrder = identifierOrder;

        SAVDISRequest *orderFavorites = [self.generator request:@"OrderFavorites" withArguments:@{@"order": self.favoritesIdentifierOrder, @"SVC_TYPE": self.serviceType}];
        [[Savant control] sendMessage:orderFavorites];
    }
}

- (void)layout:(SCUReorderableTileLayout *)layout setEditingIndexPath:(NSIndexPath *)indexPath
{
    self.editingIndexPath = indexPath;
}

- (BOOL)layout:(SCUReorderableTileLayout *)layout canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self layout:layout canEditItemAtIndexPath:indexPath];
}

- (BOOL)layout:(SCUReorderableTileLayout *)layout canReplaceItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self layout:layout canEditItemAtIndexPath:indexPath];
}

- (void)layout:(SCUReorderableTileLayout *)layout setMovingIndexPath:(NSIndexPath *)indexPath
{
    self.movingIndexPath = indexPath;
}

#pragma mark - StateDelegate methods

- (void)didReceiveDISFeedback:(SAVDISFeedback *)feedback
{
    if ([feedback.state hasPrefix:@"favorites"])
    {
        [self loadFavorites:[feedback value]];
    }
}

#pragma mark - DISResultDelegate

- (void)disRequestDidCompleteWithResults:(SAVDISResults *)results
{
    if (self.resultsBlock)
    {
        self.resultsBlock(results.results);
    }

    self.resultsBlock = nil;
}

#pragma mark - Scene Creation Delegate

- (void)saveFavorite:(SAVFavorite *)favorite
{
    SAVDISRequest *request = nil;

    NSDictionary *favoriteDictionary = [favorite dictionaryRepresentation];
    favoriteDictionary = [favoriteDictionary dictionaryByAddingObject:self.serviceType forKey:@"SVC_TYPE"];

    if (favorite.identifier)
    {
        request = [self.generator request:@"UpdateFavorite" withArguments:favoriteDictionary];
    }
    else
    {
        request = [self.generator request:@"CreateFavorite" withArguments:favoriteDictionary];
    }

    [[Savant control] sendMessage:request];
}

#pragma mark -

- (void)loadFavorites:(NSArray *)favorites
{
    NSMutableArray *dataSource = [NSMutableArray array];
    NSMutableArray *favoriteIdentifiers = [NSMutableArray array];

    //-------------------------------------------------------------------
    // Add scenes
    //-------------------------------------------------------------------
    for (NSDictionary *favoriteDict in favorites)
    {
        SAVFavorite *favorite = [SAVFavorite favoriteWithSettings:favoriteDict];

        if (favorite && favorite.name)
        {
            NSDictionary *dict = @{SCUDefaultCollectionViewCellKeyModelObject: favorite,
                                   SCUDefaultCollectionViewCellKeyTitle: favorite.name};

            [dataSource addObject:dict];
            [favoriteIdentifiers addObject:favorite.identifier];
        }
    }

    //-------------------------------------------------------------------
    // Create the add scene button
    //-------------------------------------------------------------------
    {
        NSDictionary *addItem = @{SCUDefaultCollectionViewCellKeyTitle: NSLocalizedString(@"New Favorite", nil),
                                  SCUDefaultCollectionViewCellKeyImage: @"VolumePlus"};

        [dataSource addObject:addItem];
    }

    self.favoritesIdentifierOrder = favoriteIdentifiers;
    self.dataSource = dataSource;
    [self.delegate reloadData];
}

- (BOOL)isIndexPathAddItem:(NSIndexPath *)indexPath
{
    return (indexPath.row == ((NSInteger)([self.dataSource count] - 1)));
}

- (SAVFavorite *)favoriteForIndexPath:(NSIndexPath *)indexPath
{
    SAVFavorite *favorite = nil;

    if (indexPath)
    {
        favorite = [self _modelObjectForIndexPath:indexPath][SCUDefaultCollectionViewCellKeyModelObject];
    }

    return favorite;
}

- (NSString *)favoriteIdentifierForIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = nil;

    SAVFavorite *favorite = [self favoriteForIndexPath:indexPath];
    identifier = favorite.identifier;

    return identifier;
}

@end
