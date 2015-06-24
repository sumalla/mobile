//
//  SCUSystemSelectorSettingsModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 8/25/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"
#import "SCUActionSheet.h"

@class MFMailComposeViewController;

@protocol SCUSystemSelectorSettingsModelDelegate <NSObject>

- (void)presentActionSheet:(SCUActionSheet *)actionSheet;
- (void)presentMailComposeVC:(MFMailComposeViewController *)viewController;

@end

@interface SCUSystemSelectorSettingsModel : SCUDataSourceModel

@property (nonatomic, weak) id<SCUSystemSelectorSettingsModelDelegate> delegate;

@property (nonatomic, readonly, copy) NSString *version;

@end
