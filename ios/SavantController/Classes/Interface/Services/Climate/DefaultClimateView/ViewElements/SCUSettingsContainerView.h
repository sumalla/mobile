//
//  SCUSettingsContainerView.h
//  SavantController
//
//  Created by Jason Wolkovitz on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;
#import "SCUSettingsConainerViewModel.h"
#import "SCUClimateModeTableViewController.h"
#import "SCUButton.h"
#import "SCUPopoverController.h"

#define scuSettingsButtonKey(i) ([NSString stringWithFormat:@"settingsButtonKey%lu", (unsigned long)i])
#define scuSettingsLabelKey(i) ([NSString stringWithFormat:@"settingsLabelKey%lu", (unsigned long)i])

@interface SCUSettingsContainerView : UIView <SCUSettingsConainerViewModelDelegate, SCUClimateModeTableViewControllerDelegate>

@property (nonatomic, strong) NSMutableArray *settingsButtons;
@property (nonatomic, strong) NSMutableArray *settingsButtonsLabels;

@property (nonatomic) SCUSettingsConainerViewModel *model;
@property (nonatomic) UIView *settingsBackground;

@property (nonatomic) SCUPopoverController *tablePopover;
@property (nonatomic) SCUClimateModeTableViewController *settingsPicker;

@property (nonatomic) CGFloat minimumWidth;
@property (nonatomic) CGFloat columnsSpacing;

@property (nonatomic) NSArray *defaultConstraints;

- (instancetype)initWithSettingsContainerModel:(SCUSettingsConainerViewModel *)model;

- (void)settingsButtonPressed:(SCUButton *)button;

- (void)loadView;

- (CGFloat)longestLocalizeStringLengthInArrayOrNestedArray:(NSArray *)stringsArray withFont:(UIFont *)font;

- (NSArray *)getFormatsForDefaultLayout;

- (NSDictionary *)getMetricsForDefaultLayout;

- (NSMutableDictionary *)getViewsForDefaultLayout;

- (NSArray *)getFormatsForMaxColumns:(NSUInteger)maxColumns;

- (UIPopoverArrowDirection)popoverArrowDirection;

@end
