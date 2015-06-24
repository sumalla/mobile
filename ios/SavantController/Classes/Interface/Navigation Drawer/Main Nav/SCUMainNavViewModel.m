//
//  SCUMainNavViewModel.m
//  SavantController
//
//  Created by Nathan Trapp on 6/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMainNavViewModel.h"
#import "SCUDefaultTableViewCell.h"
#import "SCUSettingsModelPrivate.h"
#import "SCUInterface.h"
#import "SCURootViewController.h"

#import <SAVSettings.h>

@interface SCUMainNavViewModel ()

@property NSArray *dataSource;
@property NSArray *moreActions;
@property SCUMainNavSelectedView selectedView;

@end

@implementation SCUMainNavViewModel

#pragma mark - SCUDataSourceModel methods

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.moreActions = @[
                             @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Rooms", nil),
                               SCUSettingsKeyAction: NSStringFromSelector(@selector(showRooms))},

                             @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Services", nil),
                               SCUSettingsKeyAction: NSStringFromSelector(@selector(showServices))},

                             @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"My Scenes", nil),
                               SCUSettingsKeyAction: NSStringFromSelector(@selector(showScenes))}
                             ];

        self.dataSource = [self parseActions:self.moreActions];
    }
    return self;
}

- (void)showRooms
{
    [self selectView:SCUMainNavSelectedViewRooms];
    [[SCUInterface sharedInstance] presentRooms];
}

- (void)showScenes
{
    [self selectView:SCUMainNavSelectedViewScenes];
    [[SCUInterface sharedInstance] presentScenes];
}

- (void)showServices
{
    [self selectView:SCUMainNavSelectedViewServices];
    [[SCUInterface sharedInstance] presentServices];
}

- (BOOL)selectView:(SCUMainNavSelectedView)type
{
    BOOL didSelectView = NO;

    if (self.selectedView != type)
    {
        self.selectedView = type;

        didSelectView = YES;

        [self.delegate selectedViewDidChange];
    }
    else
    {
        didSelectView = YES;
        [self.delegate selectedViewDidChange];
    }

    return didSelectView;
}

- (BOOL)shouldDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL shouldDeselect = YES;

    if (indexPath.row == self.selectedView)
    {
        shouldDeselect = NO;
    }

    return shouldDeselect;
}

- (void)viewWillAppear
{
    SCURootViewController *rvc = [[SCUInterface sharedInstance] currentRootViewController];

    self.selectedView = [rvc.viewControllers indexOfObject:rvc.activeVC];

    [self.delegate selectedViewDidChange];
}

@end
