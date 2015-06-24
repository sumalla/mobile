//
//  SCULightingModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 8/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUExpandableDataSourceModel.h"
#import "SCUSlider.h"
#import "SCUButton.h"
@import SDK;

typedef NS_ENUM(NSUInteger, SCULightingModelCellType)
{
    SCULightingEntityTypeRoomImage,
    SCULightingModelCellTypeSlider,
    SCULightingModelCellTypeToggleSwitch,
    SCULightingModelCellTypeShadesRelative,
    SCULightingModelCellTypeEmptyRoomImage,
    SCULightingModelCellTypeRoomImage,
    SCULightingModelCellTypePlain,
    SCULightingModelCellTypeScene,
    SCULightingModelCellTypeFan
};

@protocol SCULightingModelDelegate <NSObject>

- (void)reloadData;

- (void)reloadIndexPath:(NSIndexPath *)indexPath;

- (void)toggleSwitchForIndexPath:(NSIndexPath *)indexPath;

@end

@protocol SCULightingModelRoomImageDelegate <NSObject>

- (void)roomImageDidUpdate:(UIImage *)image;

@end

@interface SCULightingModel : SCUExpandableDataSourceModel

@property (nonatomic, weak) id<SCULightingModelDelegate> delegate;

@property (nonatomic, weak) id<SCULightingModelRoomImageDelegate> roomImageDelegate;

@property (nonatomic, readonly) SAVService *service;

@property (nonatomic, getter = isRoomImageInTable) BOOL roomImageInTable;

- (instancetype)initWithService:(SAVService *)service;

- (void)listenToToggleSwitch:(UISwitch *)toggleSwitch forIndexPath:(NSIndexPath *)indexPath;

- (void)listenToSlider:(SCUSlider *)slider forParentIndexPath:(NSIndexPath *)indexPath;

- (void)listenToCloseButton:(SCUButton *)closeButton openButton:(SCUButton *)openButton forParentIndexPath:(NSIndexPath *)indexPath;

- (void)listenToCloseButton:(SCUButton *)closeButton stopButton:(SCUButton *)stopButton openButton:(SCUButton *)openButton forParentIndexPath:(NSIndexPath *)indexPath;

- (void)listenToOffButton:(SCUButton *)offButton lowButton:(SCUButton *)lowButton medButton:(SCUButton *)medButton highButton:(SCUButton *)highButton forParentIndexPath:(NSIndexPath *)indexPath;

- (void)listenToSceneHold:(UILongPressGestureRecognizer *)holdGesture forIndexPath:(NSIndexPath *)indexPath;

@property (nonatomic, readonly, strong) UIImage *roomImage;

@end
