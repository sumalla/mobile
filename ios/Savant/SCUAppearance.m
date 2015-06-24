//
//  SCUAppearance.m
//  Prototype
//
//  Created by Nathan Trapp on 3/5/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUAppearance.h"
@import Extensions;
#import "SCUDefaultTableViewCell.h"
#import "SCULoadingView.h"
#import "SCUSlider.h"
#import "SCUPassthroughViewController.h"
#import "SCUMediaServiceViewController.h"
#import "SCUServiceTabBarController.h"
#import "SCUButton.h"
#import "SCUDefaultCollectionViewCell.h"
#import "SCUStandardCollectionViewCell.h"

#import "SCUDatePickerCell.h"
#import "SCUDayPickerCell.h"
#import "SCUMediaTableViewCell.h"
#import "SCUSceneCreationViewController.h"
#import "SCUSceneVariantCell.h"
#import "SCUSceneChildCell.h"
#import "SCUSecondsPickerCell.h"
#import "SCUSceneClimatePickerCell.h"
#import "SCUSliderWithMinMaxImageCell.h"

#import "SCUSwipeView.h"

@implementation SCUAppearance

+ (void)setupAppearance
{
    SCUColors *colors = [SCUColors shared];

    UIFont *book17 = [UIFont fontWithName:@"Gotham-Book" size:17];

    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setFont:[UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h10]];

    [[SCUSwipeCell appearance] setBackgroundColor:[colors color03shade03]];
    [[SCUSwipeCell appearanceWhenContainedIn:[UIPopoverController class], nil] setBackgroundColor:[UIColor sav_colorWithRGBValue:0x555555]];
    [[UINavigationBar appearanceWhenContainedIn:[UINavigationController class], nil] setTitleTextAttributes:@{NSForegroundColorAttributeName: [colors color04],
                                                                                                              NSFontAttributeName: [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h8]}];


    [[SCUSlider appearance] setTrackColor:[UIColor sav_colorWithRGBValue:0xe6e6e6]];
    [[SCUSlider appearance] setFillColor:[colors color01]];
    [[SCUSlider appearance] setThumbColor:[colors color04]];

    [[UISwitch appearance] setOnTintColor:[colors color01]];
    [[UISwitch appearance] setTintColor:[colors color03shade05]];

    [[UIToolbar appearanceWhenContainedIn:[SCUPassthroughViewController class], nil]
     setBackgroundImage:[[UIImage alloc] init]
     forToolbarPosition:UIBarPositionAny
     barMetrics:UIBarMetricsDefault];
    [[UIToolbar appearanceWhenContainedIn:[SCUPassthroughViewController class], nil]
     setShadowImage:[[UIImage alloc] init]
     forToolbarPosition:UIBarPositionAny];

    [[UITableView appearanceWhenContainedIn:[SCUMediaServiceViewController class], nil] setSectionIndexColor:[colors color01]];
    [[UIToolbar appearanceWhenContainedIn:[SCUServiceTabBarController class], nil] setBarTintColor:[[colors color03shade04] colorWithAlphaComponent:0.9]];

    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName: book17} forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [[SCUColors shared] color03shade08],
                                                           NSFontAttributeName: book17} forState:UIControlStateDisabled];

    UIView *selectedBackground = [[UIView alloc] init];
    selectedBackground.backgroundColor = [colors color03shade04];

    //-------------------------------------------------------------------
    // General tables
    //-------------------------------------------------------------------
    [[SCUDefaultTableViewCell appearance] setBackgroundColor:[colors color03shade03]];
    [[SCUDefaultTableViewCell appearance] setSelectedBackgroundView:selectedBackground];
    [[SCUDefaultTableViewCell appearance] setBottomLineColor:[colors color03shade04]];
    [[SCUDefaultTableViewCell appearance] setBottomLineType:SCUDefaultTableViewCellBottomLineTypeFull];
    [[SCUDefaultTableViewCell appearance] setBorderType:SCUDefaultTableViewCellBorderTypeSection];
    [[SCUDefaultTableViewCell appearance] setBorderColor:[colors color03shade04]];
    [[UITableView appearance] setSav_separatorStyle:UITableViewCellSeparatorStyleNone];
    [[UITableView appearance] setSectionIndexBackgroundColor:[UIColor clearColor]];
    [[UITableView appearance] setSectionIndexColor:[colors color01]];
    [[UITableView appearance] setSectionIndexMinimumDisplayRowCount:15];

    //-------------------------------------------------------------------
    // General collection views
    //-------------------------------------------------------------------
    [[SCUDefaultCollectionViewCell appearance] setBackgroundColor:[colors color03shade03]];
    [[SCUDefaultCollectionViewCell appearance] setBorderWidth:[UIScreen screenPixel]];
    [[SCUDefaultCollectionViewCell appearance] setBorderColor:[colors color03shade04]];
    [[SCUStandardCollectionViewCell appearance] setBackgroundColor:[colors color03shade03]];
    [[SCUStandardCollectionViewCell appearance] setBorderWidth:[UIScreen screenPixel]];
    [[SCUStandardCollectionViewCell appearance] setBorderColor:[colors color03shade04]];


    //-------------------------------------------------------------------
    // Scenes
    //-------------------------------------------------------------------
    [[SCUSceneVariantCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBackgroundColor:[colors color03shade02]];
    [[SCUSceneVariantCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineType:SCUDefaultTableViewCellBottomLineTypePartial];
    [[SCUSceneVariantCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBorderType:SCUDefaultTableViewCellBorderTypeBottomAndSides];
    [[SCUSceneVariantCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineColor:[colors color03shade04]];

    [[SCUSceneChildCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBackgroundColor:[colors color03shade02]];
    [[SCUSceneChildCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineType:SCUDefaultTableViewCellBottomLineTypePartial];
    [[SCUSceneChildCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBorderType:SCUDefaultTableViewCellBorderTypeBottomAndSides];
    [[SCUSceneChildCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineColor:[colors color03shade04]];

    [[SCUSecondsPickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBackgroundColor:[colors color03shade02]];
    [[SCUSecondsPickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineType:SCUDefaultTableViewCellBottomLineTypePartial];
    [[SCUSecondsPickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBorderType:SCUDefaultTableViewCellBorderTypeBottomAndSides];
    [[SCUSecondsPickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineColor:[colors color03shade04]];

    [[SCUSceneClimatePickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBackgroundColor:[colors color03shade02]];
    [[SCUSceneClimatePickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineType:SCUDefaultTableViewCellBottomLineTypePartial];
    [[SCUSceneClimatePickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBorderType:SCUDefaultTableViewCellBorderTypeBottomAndSides];
    [[SCUSceneClimatePickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineColor:[colors color03shade04]];

    [[SCUSliderWithMinMaxImageCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setMinImage:[UIImage sav_imageNamed:@"decreaseVolume" tintColor:[[SCUColors shared] color03shade05]]];
    [[SCUSliderWithMinMaxImageCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setMaxImage:[UIImage sav_imageNamed:@"increaseVolume" tintColor:[[SCUColors shared] color03shade05]]];
    [[SCUSliderWithMinMaxImageCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBackgroundColor:[colors color03shade02]];
    [[SCUSliderWithMinMaxImageCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineType:SCUDefaultTableViewCellBottomLineTypePartial];
    [[SCUSliderWithMinMaxImageCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBorderType:SCUDefaultTableViewCellBorderTypeBottomAndSides];
    [[SCUSliderWithMinMaxImageCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineColor:[colors color03shade04]];

    [[SCUDatePickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBackgroundColor:[colors color03shade02]];
    [[SCUDatePickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineType:SCUDefaultTableViewCellBottomLineTypePartial];
    [[SCUDatePickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBorderType:SCUDefaultTableViewCellBorderTypeBottomAndSides];
    [[SCUDatePickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineColor:[colors color03shade04]];

    [[SCUDayPickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBackgroundColor:[colors color03shade02]];
    [[SCUDayPickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineType:SCUDefaultTableViewCellBottomLineTypePartial];
    [[SCUDayPickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBorderType:SCUDefaultTableViewCellBorderTypeBottomAndSides];
    [[SCUDayPickerCell appearanceWhenContainedIn:[SCUScenesNavController class], nil] setBottomLineColor:[colors color03shade04]];

    [[SCUSwipeView appearance] setBackgroundColor:[[SCUColors shared] color03]];
    [[SCUSwipeView appearance] setBorderWidth:[UIScreen screenPixel]];
    [[SCUSwipeView appearance] setBorderColor:[[SCUColors shared] color03shade02]];
    [[SCUSwipeView appearance] setSwipeColor:[[SCUColors shared] color01]];
    [[SCUSwipeView appearance] setArrowColor:[[SCUColors shared] color04]];
}

@end
