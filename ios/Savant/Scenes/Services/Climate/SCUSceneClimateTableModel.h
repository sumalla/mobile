//
//  SCUSceneClimateTableModel.h
//  SavantController
//
//  Created by Stephen Silber on 8/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUExpandableDataSourceModel.h"

@class SAVScene, SAVService, SAVSceneService, SCUSlider, SCUClimatePicker;

typedef NS_ENUM(NSUInteger, SCUSceneClimateTableModelCellType)
{
    SCUSceneClimateTableModelCellTypeDefault,
    SCUSceneClimateTableModelCellTypePicker,
    SCUSceneClimateTableModelCellTypeChild
};

@protocol SCUSceneClimateTableModel;

@interface SCUSceneClimateTableModel : SCUExpandableDataSourceModel


@property (nonatomic, weak) id<SCUSceneClimateTableModel> delegate;

@property (nonatomic, readonly) NSMutableDictionary *roomImages;

- (instancetype)initWithScene:(SAVScene *)scene service:(SAVService *)service sceneService:(SAVSceneService *)sceneService;

- (void)listenToPickerView:(SCUClimatePicker *)pickerView forParentIndexPath:(NSIndexPath *)indexPath;

- (void)commit;

- (void)rollback;

@end

@protocol SCUSceneClimateTableModel <NSObject>

- (void)reloadData;

- (void)reloadIndexPath:(NSIndexPath *)indexPath;

- (void)toggleIndex:(NSIndexPath *)indexPath;

- (void)toggleIndex:(NSIndexPath *)indexPath animated:(BOOL)animated;

- (void)reloadChildrenBelowIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;

- (void)reloadTableHeader;

- (void)removeRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)addRowsAtIndexPaths:(NSArray *)indexPaths;

- (void)addRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)removeRowsAtIndexPaths:(NSArray *)indexPaths;

- (void)reconfigureIndexPaths:(NSArray *)indexPaths;

@end
