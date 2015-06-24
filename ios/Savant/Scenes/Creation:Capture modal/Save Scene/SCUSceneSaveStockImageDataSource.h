//
//  SCUSceneSaveStockImageDataSource.h
//  SavantController
//
//  Created by Stephen Silber on 10/13/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"
@import SDK;

@protocol SCUScenesSaveStockImageDelegate;

@interface SCUSceneSaveStockImageDataSource : SCUDataSourceModel

@property (nonatomic, weak) id<SCUScenesSaveStockImageDelegate> delegate;

- (instancetype)initWithScene:(SAVScene *)scene;

- (void)saveSelectedImage;

@end

@protocol SCUScenesSaveStockImageDelegate <NSObject>

- (void)reloadData;

- (void)reloadCellAtIndexPath:(NSIndexPath *)indexPath;

@end

