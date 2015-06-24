//
//  SCUSignInViewModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"
#import <SavantControl/SavantControl.h>

typedef NS_ENUM(NSUInteger, SCUSignInViewModelCellType)
{
    SCUSignInViewModelCellTypeFixed,
    SCUSignInViewModelCellTypeEditable,
};

typedef NS_ENUM(NSUInteger, SCUSignInViewModelCellAccessoryType)
{
    SCUSignInViewModelCellAccessoryTypeNone,
    SCUSignInViewModelCellAccessoryTypeSpinner,
    SCUSignInViewModelCellAccessoryTypeCheckmark
};

@protocol SCUSignInViewModelDelegate;

@interface SCUSignInViewModel : SCUDataSourceModel

@property (nonatomic, weak) id<SCUSignInViewModelDelegate> delegate;

- (instancetype)initWithUser:(SAVLocalUser *)user;

- (void)signIn;

- (void)listenToTextField:(UITextField *)textField forIndexPath:(NSIndexPath *)indexPath;

@end

@protocol SCUSignInViewModelDelegate <NSObject>

- (void)setFirstResponderForIndexPath:(NSIndexPath *)indexPath;

- (void)endEditing;

- (void)reloadIndexPath:(NSIndexPath *)indexPath;

- (void)updateTitle:(NSString *)title;

@end
