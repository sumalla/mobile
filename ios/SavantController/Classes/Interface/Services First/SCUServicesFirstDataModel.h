//
//  SCUServicesFirstDataModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 7/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"
#import "SCUReorderableTileLayout.h"
#import "SCUEditableButtonsCollectionViewModel.h"

typedef NS_ENUM(NSUInteger, SCUServicesFirstCollectionViewCellType)
{
    SCUServicesFirstCollectionViewCellTypeLarge = 2,
    SCUServicesFirstCollectionViewCellTypeClimate = 3,
    SCUServicesFirstCollectionViewCellTypeSecurity = 4,
};

@protocol SCUServicesFirstDataModelDelegate <NSObject>

- (void)setAllItemsAre1x1:(BOOL)allItemsAre1x1;

- (void)presentViewController:(UIViewController *)viewController;

- (void)reloadIndexPaths:(NSArray *)indexPaths;

- (NSArray *)visibleIndexPaths;

- (void)setSpinnerVisible:(BOOL)visible;

@end

extern NSString *const SCUServicesFirstCellKeyMoving;

@interface SCUServicesFirstDataModel : SCUEditableButtonsCollectionViewModel <SCUReorderableTileLayoutDelegate>

@property (nonatomic, weak) id<SCUServicesFirstDataModelDelegate> delegate;

@end
