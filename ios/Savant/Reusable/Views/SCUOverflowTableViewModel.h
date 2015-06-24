//
//  SCUTVOverlayTableViewModel.h
//  SavantController
//
//  Created by Stephen Silber on 2/2/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"

@class SCUServiceViewModel, SAVService;

@protocol SCUOverflowViewDelegate <NSObject>

- (void)reloadData;

- (void)removeRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;

@end

@protocol SCUOverflowAddViewDelegate <NSObject>

- (void)reloadData;

- (void)removeRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;

- (void)popViewController;

@end

@interface SCUOverflowTableViewModel : SCUDataSourceModel

@property (nonatomic, weak) id<SCUOverflowViewDelegate> delegate;

@property (nonatomic, weak) id<SCUOverflowAddViewDelegate> addDelegate;

@property (nonatomic, readonly) SCUServiceViewModel *serviceModel;

@property (nonatomic, getter=isAdding) BOOL adding;

- (instancetype)initWithService:(SAVService *)service;

- (void)moveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

- (void)loadButtons;

- (BOOL)deleteItemAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)isAddButtonEnabled;

- (NSIndexPath *)indexPathForAddButton;

@end
