//
//  SCUSceneLightingTableModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 7/29/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUExpandableDataSourceModel.h"

@class
SAVScene,
SAVService,
SAVSceneService,
SCUSlider,
SCUButton;

typedef NS_ENUM(NSUInteger, SCUSceneLightingTableModelCellType)
{
    SCUSceneLightingTableModelCellTypeToggleSwitch,
    SCUSceneLightingTableModelCellTypeToggleLabel,
    SCUSceneLightingTableModelCellTypeEmptyRoomImage,
    SCUSceneLightingTableModelCellTypeRoomImage,
    SCUSceneLightingTableModelCellTypeSlider,
    SCUSceneLightingTableModelCellTypeEdit,
    SCUSceneLightingTableModelCellTypeExcluded,
    SCUSceneLightingTableModelCellTypeFan,
    SCUSceneLightingTableModelCellTypePlain
};

@protocol SCUSceneLightingTableModel;

@interface SCUSceneLightingTableModel : SCUExpandableDataSourceModel

@property (nonatomic, weak) id<SCUSceneLightingTableModel> delegate;

@property (nonatomic, readonly) UIImage *roomImage;

@property (nonatomic) BOOL editMode;

@property (nonatomic, copy) NSArray *expandedState;

@property (nonatomic, readonly) SAVService *service;

- (instancetype)initWithScene:(SAVScene *)scene service:(SAVService *)service sceneService:(SAVSceneService *)sceneService;

- (void)listenToToggleSwitch:(UISwitch *)toggleSwitch forIndexPath:(NSIndexPath *)indexPath;

- (void)listenToSlider:(SCUSlider *)slider forParentIndexPath:(NSIndexPath *)indexPath;

- (void)listenToOffButton:(SCUButton *)offButton lowButton:(SCUButton *)lowButton medButton:(SCUButton *)medButton highButton:(SCUButton *)highButton forIndexPath:(NSIndexPath *)indexPath;

- (BOOL)entityIncludedAtIndexPath:(NSIndexPath *)indexPath;

- (void)commit;

- (void)rollback;

@end

@protocol SCUSceneLightingTableModel <NSObject>

- (void)reloadData;

- (void)reloadIndexPath:(NSIndexPath *)indexPath;

- (void)reloadChildrenBelowIndexPath:(NSIndexPath *)indexPath;

- (void)toggleIndexPath:(NSIndexPath *)indexPath;

- (void)toggleSwitchForIndexPath:(NSIndexPath *)indexPath;

- (BOOL)isFirstPass;

@end
