//
//  SCUClimateModeTableViewController.h
//  SavantController
//
//  Created by David Fairweather on 5/19/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

#import "SCUSettingsConainerViewModel.h"

@protocol SCUClimateModeTableViewControllerDelegate;

@protocol SCUClimateModeTableViewControllerDelegate <NSObject>

- (void)settingsUpdatedWithIndexPath:(NSIndexPath *)indexPath settingsIndex:(NSUInteger)settingsIndex shouldDismissTable:(BOOL)dismiss;

@end

@interface SCUClimateModeTableViewController : UITableViewController

@property (nonatomic, weak) id<SCUClimateModeTableViewControllerDelegate> delegate;

@property (nonatomic, readonly) CGSize tabelViewSize;

- (instancetype)initWithStyle:(UITableViewStyle)style withSettingsModel:(SCUSettingsConainerViewModel *)model settingsIndex:(NSUInteger)index;

@end
