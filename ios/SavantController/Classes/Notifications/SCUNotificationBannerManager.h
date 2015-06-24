//
//  SCUNotificationBannerManager.h
//  SavantController
//
//  Created by Cameron Pulsford on 2/11/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import <SavantControl/SavantControl.h>

@interface SCUNotificationBannerManager : NSObject

- (void)presentBannerWithInfo:(NSDictionary *)info interactionHandler:(dispatch_block_t)interactionHandler;

@end
