//
//  SCUNotificationCreationSendOptionsViewModel.h
//  SavantController
//
//  Created by Stephen Silber on 1/23/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationCreationDataSource.h"

@protocol SCUNotificationCreationSendOptionViewDelegate <NSObject>

- (void)reloadRowAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface SCUNotificationCreationSendOptionsViewModel : SCUNotificationCreationDataSource

@property (nonatomic, weak) id<SCUNotificationCreationSendOptionViewDelegate> delegate;

@end
