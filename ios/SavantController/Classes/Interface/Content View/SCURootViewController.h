//
//  SCURootViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 6/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceTabBarController.h"

typedef NS_ENUM(NSUInteger, SCURootViewActiveTab)
{
    SCURootViewActiveTabRooms         = 0,
    SCURootViewActiveTabServices      = 1,
    SCURootViewActiveTabScenes        = 2,
    SCURootViewActiveTabSettings      = 3,
    SCURootViewActiveTabNotifications = 4,
};

@protocol SCURootViewControllerDelegate;

@interface SCURootViewController : SCUServiceTabBarController

@property (weak) id <SCURootViewControllerDelegate> delegate;

@end

@protocol SCURootViewControllerDelegate <NSObject>

- (void)viewDidLoad;

@end
