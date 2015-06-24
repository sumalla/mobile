//
//  SCUMoreActionsViewModel.h
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSettingsModel.h"

@protocol SCUMoreActionsViewModelDelegate;

@interface SCUMoreActionsViewModel : SCUSettingsModel

@property (nonatomic, weak) id<SCUMoreActionsViewModelDelegate> delegate;

- (void)loadData;
- (void)updateCloudState;

@end

@protocol SCUMoreActionsViewModelDelegate <NSObject>

- (void)reloadData;

@end
