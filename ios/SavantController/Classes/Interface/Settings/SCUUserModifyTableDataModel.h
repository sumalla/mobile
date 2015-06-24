//
//  SCUCreateInviteDataModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 8/20/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"
#import <SavantControl/SavantControl.h>

typedef NS_ENUM(NSUInteger, SCUCreateInviteCellType)
{
    SCUCreateInviteCellTypeTextEntry,
    SCUCreateInviteCellTypeToggle,
    SCUCreateInviteCellTypeNormal,
    SCUCreateInviteCellTypeFixed,
    SCUCreateInviteCellTypeDouble
};

@protocol SCUUserModifyTableDataModelDelegate <NSObject>

- (void)reloadData;

- (void)endEditing;

- (void)editingComplete;

- (void)changePasswordForUser:(SAVCloudUser *)user;

- (void)navigateBack;

- (void)showZoneBlacklistTableForUser:(SAVCloudUser *)user;

- (void)showServiceBlacklistTableForUser:(SAVCloudUser *)user;

- (void)setFirstResponderAtIndexPath:(NSIndexPath *)indexPath;

- (void)setDoneButtonAnimating:(BOOL)animating;

@end

@interface SCUUserModifyTableDataModel : SCUDataSourceModel

@property (nonatomic, weak) id<SCUUserModifyTableDataModelDelegate> delegate;

- (instancetype)initWithCloudUser:(SAVCloudUser *)user;

- (void)finishEditing;

- (void)listenToTextField:(UITextField *)textField forIndexPath:(NSIndexPath *)indexPath;

- (void)listenToToggleSwitch:(UISwitch *)toggleSwitch forIndexPath:(NSIndexPath *)indexPath;

@property (nonatomic, readonly) BOOL shouldAddDeleteRow;

- (void)delete;

@end
