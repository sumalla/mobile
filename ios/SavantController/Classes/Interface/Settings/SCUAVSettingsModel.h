//
//  SCUInitialSettingsModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 4/30/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"
#import "SCUOnboardViewController.h"
@class SCUAVSettingsEqualizerModel, SCUAVSettingsAudioModel, SCUAVSettingsVideoModel;

typedef NS_ENUM(NSUInteger, SCUAVSettingsModelType)
{
    SCUAVSettingsModelTypeVideo,
    SCUAVSettingsModelTypeAudio,
    SCUAVSettingsModelTypeEqualizer
};

@protocol SCUAVSettingsModelDelegate;

@interface SCUAVSettingsModel : SCUDataSourceModel

@property (nonatomic, weak) id<SCUAVSettingsModelDelegate> delegate;

@property (nonatomic, readonly, copy) NSString *title;

@end

@protocol SCUAVSettingsModelDelegate <NSObject>

- (void)navigateBack;

- (void)reloadData;

- (void)presentUserList;

- (void)presentUser:(SAVCloudUser *)user;

- (void)onboardSystem:(SAVSystem *)system showDoNotLink:(BOOL)showDoNotLink delegate:(id<SCUOnboardViewControllerDelegate>)delegate;

- (void)presentNextAVSettingsViewControllerWithModel:(SCUAVSettingsModel *)model;

- (void)presentEqualizerScreenWithModel:(SCUAVSettingsEqualizerModel *)model;
- (void)presentVideoSettingsScreenWithModel:(SCUAVSettingsVideoModel *)model;
- (void)presentAudioSettingsScreenWithModel:(SCUAVSettingsAudioModel *)model;

@end
