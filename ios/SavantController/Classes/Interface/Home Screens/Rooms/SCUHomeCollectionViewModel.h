//
//  SCUHomeCollectionViewModel.h
//  SavantController
//
//  Created by Nathan Trapp on 4/29/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"
#import "SCUServiceViewModel.h"
#import "SCUHomeCollectionViewController.h"
#import <SavantControl/SavantControl.h>

@protocol SCUHomeCollectionViewModelDelegate;

@interface SCUHomeCollectionViewModel : SCUServiceViewModel <SCUDataSourceModel, SCUHomeCollectionViewControllerDelegate>

@property (weak) id <SCUHomeCollectionViewModelDelegate> delegate;

@property (readonly) BOOL hasRoomGroups;

@property (readonly) NSArray *roomGroups;

@property (nonatomic) id filterRoomGroup;

@property (readonly, nonatomic) NSString *selectedRoomGroupName;

/**
 *  Provides the current active service for a given index path
 *
 *  @param indexPath The index path
 *
 *  @return An active service or nil
 */
- (SAVService *)activeServiceForIndexPath:(NSIndexPath *)indexPath;

/**
 *  Provides the lights are on state for a given index path
 *
 *  @param indexPath the index path
 *
 *  @return A true or false status representing the lights are on status
 */
- (BOOL)lightsAreOnForIndexPath:(NSIndexPath *)indexPath;

- (BOOL)fansAreOnForIndexPath:(NSIndexPath *)indexPath;

- (NSString *)currentTemperatureForIndexPath:(NSIndexPath *)indexPath;
- (BOOL)hasSecurityAlertForIndexPath:(NSIndexPath *)indexPath;

/**
 *  Provides a room model for a given index path.
 *
 *  @param indexPath the index path
 *
 *  @return A room object.
 */
- (SAVRoom *)roomForIndexPath:(NSIndexPath *)indexPath;

/**
 *  Queries the entire model for the index path of the given room object.
 *
 *  @param room A room identifier.
 *
 *  @return The index path of the given room.
 */
- (NSIndexPath *)indexPathForRoom:(NSString *)room;

- (UIImage *)imageForIndexPath:(NSIndexPath *)indexPath isDefault:(BOOL *)isDefault;

@end

@protocol SCUHomeCollectionViewModelDelegate <NSObject>

@property (nonatomic, readonly) NSIndexPath *currentIndex;

- (void)activeServiceChangedForIndexPath:(NSIndexPath *)indexPath;
- (void)lightsAreOnChangedForIndexPath:(NSIndexPath *)indexPath;
- (void)fansAreOnChangedForIndexPath:(NSIndexPath *)indexPath;
- (void)securityStatusChangedForIndexPath:(NSIndexPath *)indexPath;
- (void)currentTemperatureChangedForIndexPath:(NSIndexPath *)indexPath;
- (void)updateImage:(UIImage *)image forIndexPath:(NSIndexPath *)indexPath isDefault:(BOOL)isDefault;


@optional
- (void)presentServiceDrawer:(BOOL)animated;
- (void)presentFullscreenView:(BOOL)animated;

@end