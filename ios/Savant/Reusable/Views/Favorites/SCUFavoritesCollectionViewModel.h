//
//  SCUScenesModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 7/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"
#import "SCUReorderableTileLayout.h"

@protocol SCUFavoritesCollectionViewModelDelegate;
@class SAVFavorite, SCUServiceViewModel, SAVService;

typedef void (^SCUFavoriteSystemImageResults)(NSArray *systemImages);

@interface SCUFavoritesCollectionViewModel : SCUDataSourceModel <SCUReorderableTileLayoutDelegate>

@property (nonatomic, weak) id<SCUFavoritesCollectionViewModelDelegate> delegate;
@property (nonatomic, readonly) SAVService *service;
@property (nonatomic, readonly) SCUServiceViewModel *serviceModel;
@property (nonatomic, readonly) NSArray *systemImages;

- (instancetype)initWithService:(SAVService *)service;
- (void)saveFavorite:(SAVFavorite *)favorite;
- (void)removeFavoriteAtIndexPath:(NSIndexPath *)indexPath;
- (void)applyFavorite:(SAVFavorite *)favorite;
- (void)sendCommand:(NSString *)command withArguments:(NSDictionary *)arguments;
- (void)fetchSystemImages:(SCUFavoriteSystemImageResults)results;

@end

@protocol SCUFavoritesCollectionViewModelDelegate <NSObject>

- (void)editFavorite:(SAVFavorite *)favorite;

- (void)reloadData;

- (void)reloadIndexPaths:(NSArray *)indexPaths;

- (void)reconfigureIndexPaths:(NSArray *)indexPaths;

- (void)setEditingMode:(BOOL)editing;

@end
