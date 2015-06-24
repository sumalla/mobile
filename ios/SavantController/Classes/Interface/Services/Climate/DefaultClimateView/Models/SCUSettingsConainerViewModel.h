//
//  SCUSettingsConainerViewModel.h
//  SavantController
//
//  Created by Jason Wolkovitz on 7/29/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import <SavantControl/SavantControl.h>


@protocol SCUSettingsConainerViewModelDelegate <NSObject>

@optional

- (void)didReceiveClimateSetPointMode:(SAVEntityState)mode withIndex:(NSUInteger)index;
- (void)showSettingsPopupPickerForSettingsIndex:(NSUInteger)index;

@end

@protocol SCUSettingsConainerViewModelCommandDelegate <NSObject>

@optional

- (void)sendServiceRequestForSAVEntityState:(SAVEntityState)settingCommandToSend;

@end

@interface SCUSettingsConainerViewModel : NSObject

@property (nonatomic, weak) id<SCUSettingsConainerViewModelDelegate>delegate;//the settings box view controller
@property (nonatomic, weak) id<SCUSettingsConainerViewModelCommandDelegate>commandDelegate;//the Service model that send commands

//list of
@property (nonatomic, strong) NSMutableArray *titlesForSettingButtons;
@property (nonatomic, strong) NSMutableArray *headerTiltesForSettingsCommandPopovers;
@property (nonatomic, strong) NSMutableArray *settingsGroup;
//SAVEntityState
@property (nonatomic, strong) NSMutableArray *selectedModesArray;
@property (nonatomic, strong) NSMutableArray *modesAvailableArray;//for the settings buttons
@property (nonatomic, strong) NSMutableDictionary *modesDictionary;//used to compaire correct states


- (NSUInteger)firstIndexForSettingIndex:(NSUInteger)settingIndex;

- (SAVEntityState)selectedModeForSettingsIndex:(NSUInteger)settingsIndex;

- (NSString *)labelsForState:(SAVEntityState)state;

- (UIImage *)imageForState:(SAVEntityState)state;

- (NSMutableArray *)selectedModesArray;

- (void)settingsButtonTouchedWithIndex:(NSUInteger)index;

- (BOOL)shouldDismissPopUpAfterSingleSelection:(NSUInteger)settingsIndex;

- (NSUInteger)numberOfOptionsForSettingsIndex:(NSUInteger)index section:(NSUInteger)section;

- (NSUInteger)numberOfSectionForSettingsIndex:(NSUInteger)index;

- (NSString *)titleForSection:(NSUInteger)section forSettingsIndex:(NSUInteger)index;

- (NSObject *)imageOrTitleForSettingIndex:(NSUInteger)settingIndex atIndexPath:(NSIndexPath *)settingIndexPath;

- (NSObject *)imageOrTitleForState:(SAVEntityState)state;

- (BOOL)settingsIndex:(NSUInteger)settingIndex ModeIsSelected:(NSIndexPath *)indexPath;

- (SAVEntityState)settingsModeSelectedAtIndexPath:(NSIndexPath *)indexPath forSettingIndex:(NSUInteger)index;

- (NSArray *)getSettingsOptionsArrayForSettingIndex:(NSUInteger)settingIndex subsectionIndex:(NSUInteger)subsection;

- (void)setSelectedMode:(SAVEntityState)mode forSettingsIndex:(NSUInteger)settingsIndex;

@end
