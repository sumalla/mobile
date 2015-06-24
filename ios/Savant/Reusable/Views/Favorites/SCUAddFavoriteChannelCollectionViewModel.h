//
//  SCUAddFavoriteChannelCollectionViewModel.h
//  SavantController
//
//  Created by Stephen Silber on 10/15/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUButtonCollectionViewModel.h"

@protocol SCUAddFavoriteModelDelegate;

@interface SCUAddFavoriteChannelCollectionViewModel : SCUButtonCollectionViewModel

@property (nonatomic, weak) id <SCUAddFavoriteModelDelegate> delegate;
@property (nonatomic) NSArray *systemImages;

- (BOOL)isSystemImage:(NSIndexPath *)indexPath;
- (UIImage *)imageForIndexPath:(NSIndexPath *)indexPath;
- (NSString *)commandForIndexPath:(NSIndexPath *)indexPath;

@end

@protocol SCUAddFavoriteModelDelegate <NSObject>

- (void)reloadIndexPath:(NSIndexPath *)indexPath;

@end
