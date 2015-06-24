//
//  SCUSystemSelectorModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"
#import "SCUOnboardViewController.h"
#import <SavantControl/SavantControl.h>

typedef NS_ENUM(NSUInteger, SCUSystemSelectorViewModelCellType)
{
    SCUSystemSelectorViewModelCellTypeSystem,
    SCUSystemSelectorViewModelCellTypePlaceholder
};

@protocol SCUSystemSelectorViewModelDelegate;

@interface SCUSystemSelectorTableViewModel : SCUDataSourceModel

@property (nonatomic, weak) id<SCUSystemSelectorViewModelDelegate> delegate;

- (void)startDemoMode;

- (void)clearCheckMark;

@end

@protocol SCUSystemSelectorViewModelDelegate <NSObject>

- (void)reloadIndexPath:(NSIndexPath *)indexPath;

- (void)reloadTableAnimated:(BOOL)animated;

- (void)presentDemoModeDialog;

- (void)onboardSystem:(SAVSystem *)system showDoNotLink:(BOOL)showDoNotLink delegate:(id<SCUOnboardViewControllerDelegate>)delegate;

- (void)systemDidDisconnectWhileTryingToLogin;

@end
