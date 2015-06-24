//
//  SCUHomeCollectionViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 4/29/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceCollectionViewController.h"

@class SAVRoom, SAVRoomGroup, SCUHomeCollectionViewModel;
@protocol SCUHomeCollectionViewControllerDelegate;

@interface SCUHomeCollectionViewController : SCUServiceCollectionViewController

@property (weak) id <SCUHomeCollectionViewControllerDelegate> delegate;
@property (nonatomic, readonly) SAVRoom *currentRoom;
@property (nonatomic) BOOL viewHasLoaded;

- (instancetype)initWithRoom:(SAVRoom *)room delegate:(id <SCUHomeCollectionViewControllerDelegate>)delegate model:(SCUHomeCollectionViewModel *)model;
- (void)scrollToRoomGroup:(NSString *)groupId;

@end

@protocol SCUHomeCollectionViewControllerDelegate <NSObject>

@optional
- (void)willSwitchToRoom:(SAVRoom *)room;
- (void)didSwitchRoom;
- (void)willSwitchToRoomGroup:(SAVRoomGroup *)roomGroup;
- (void)didSwitchRoomGroups;

@end