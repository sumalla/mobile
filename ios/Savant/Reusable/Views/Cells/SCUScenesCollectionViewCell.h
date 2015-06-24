//
//  SCUScenesCollectionViewCell.h
//  SavantController
//
//  Created by Cameron Pulsford on 7/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUStandardCollectionViewCell.h"
#import "SCUButton.h"

extern NSString *const SCUScenesCellKeyIsInEditMode;
extern NSString *const SCUScenesCellKeyScheduleType;
extern NSString *const SCUScenesCellKeyScheduleActive;
extern NSString *const SCUScenesCellKeyScheduleCountdown;
extern NSString *const SCUScenesCellKeyIsWaitingForSceneToEdit;
extern NSString *const SCUScenesCellKeyIsMoving;
extern NSString *const SCUScenesCellKeyIsActionCell;

@interface SCUScenesCollectionViewCell : SCUStandardCollectionViewCell

@property (nonatomic, readonly) SCUButton *editSceneButton;

@property (nonatomic, readonly) SCUButton *deleteSceneButton;

@property (nonatomic, readonly) SCUButton *scheduleSceneButton;

@property (nonatomic, getter = isDisplayingDefaultImage) BOOL displayingDefaultImage;

@property (nonatomic) BOOL noGradientView;

@end
