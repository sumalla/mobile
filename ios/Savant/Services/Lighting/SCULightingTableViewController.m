//
//  SCULightingTableViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 6/25/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCULightingTableViewController.h"
#import "SCULightingModel.h"
#import "SCUToggleSwitchTableViewCell.h"
#import "SCUButtonTableViewCell.h"
#import "SCUSceneLightingSliderTableViewCell.h"
#import "SCURoomImageTableViewCell.h"
#import "SCURelativeShadesTableViewCell.h"
#import "SCULightingSceneButtonTableViewCell.h"
#import "SCUShadeSliderTableViewCell.h"
#import "SCUFanButtonsTableViewCell.h"

static NSString *SCULightingTableHeaderFooterReuseIdentifier = @"SCULightingTableHeaderFooterReuseIdentifier";

@interface SCULightingTableViewController () <SCULightingModelDelegate>

@property (nonatomic) SCULightingModel *model;
@property (nonatomic, getter = isShades) BOOL shades;

@end

@implementation SCULightingTableViewController

- (instancetype)initWithModel:(SCULightingModel *)model
{
    self = [super init];

    if (self)
    {
        self.model = model;
        self.model.delegate = self;

        if ([self.model.service.serviceId isEqualToString:@"SVC_ENV_SHADE"])
        {
            self.shades = YES;
        }

        if ([UIDevice isPhone])
        {
            self.roomImageAlwaysInTable = YES;
        }
    }

    return self;
}

- (void)setRoomImageAlwaysInTable:(BOOL)roomImageAlwaysInTable
{
    _roomImageAlwaysInTable = roomImageAlwaysInTable;
    self.model.roomImageInTable = roomImageAlwaysInTable;
}

- (id<SCUExpandableDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.rowHeight = 60;

    self.tableView.backgroundColor = [[SCUColors shared] color03shade01];
    self.tableView.contentInset = UIEdgeInsetsMake(-35, 0, 0, 0);

    if ([UIDevice isPad])
    {
        if (UIInterfaceOrientationIsPortrait([UIDevice interfaceOrientation]))
        {
            self.model.roomImageInTable = YES;
        }
    }
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUToggleSwitchTableViewCell class] forCellType:SCULightingModelCellTypeToggleSwitch];
    [self.tableView sav_registerClass:[SCURelativeShadesTableViewCell class] forCellType:SCULightingModelCellTypeShadesRelative];
    [self.tableView sav_registerClass:[SCUFanButtonsTableViewCell class] forCellType:SCULightingModelCellTypeFan];
    
    if (self.isShades)
    {
        [self.tableView sav_registerClass:[SCUShadeSliderTableViewCell class] forCellType:SCULightingModelCellTypeSlider];
    }
    else
    {
        [self.tableView sav_registerClass:[SCUSceneLightingSliderTableViewCell class] forCellType:SCULightingModelCellTypeSlider];
    }

    [self.tableView sav_registerClass:[SCUDefaultTableViewCell class] forCellType:SCULightingModelCellTypeEmptyRoomImage];
    [self.tableView sav_registerClass:[SCURoomImageTableViewCell class] forCellType:SCULightingModelCellTypeRoomImage];
    [self.tableView sav_registerClass:[SCUDefaultTableViewCell class] forCellType:SCULightingModelCellTypePlain];
    [self.tableView sav_registerClass:[SCULightingSceneButtonTableViewCell class] forCellType:SCULightingModelCellTypeScene];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [self animateInterfaceRotationChangeWithCoordinator:coordinator block:^(UIInterfaceOrientation orientation) {
        if (!self.isRoomImageAlwaysInTable)
        {
            if ([UIDevice isPad])
            {
                if (UIInterfaceOrientationIsPortrait(orientation))
                {
                    self.model.roomImageInTable = YES;
                }
                else
                {
                    self.model.roomImageInTable = NO;
                }
            }
        }
    }];
}

- (void)reconfigureIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *absolutePath = [self.model absoluteIndexPathForRelativeIndexPath:indexPath];
    SCUDefaultTableViewCell *cell = (SCUDefaultTableViewCell *)[self.tableView cellForRowAtIndexPath:absolutePath];
    [cell configureWithInfo:[self.model modelObjectForIndexPath:indexPath]];
}

- (void)expandIndex:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    [self reconfigureIndexPath:indexPath];
}

- (void)collapseIndex:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    [self reconfigureIndexPath:indexPath];
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    SCULightingModelCellType cellType = (SCULightingModelCellType)type;

    switch (cellType)
    {
        case SCULightingModelCellTypeToggleSwitch:
        {
            SCUToggleSwitchTableViewCell *cell = (SCUToggleSwitchTableViewCell *)c;
            [self.model listenToToggleSwitch:cell.toggleSwitch forIndexPath:indexPath];
            break;
        }
        case SCULightingModelCellTypeEmptyRoomImage:
        {
            c.backgroundColor = [UIColor clearColor];
            c.borderColor = [UIColor clearColor];
            c.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
        case SCULightingModelCellTypeRoomImage:
        {
            SCURoomImageTableViewCell *cell = (SCURoomImageTableViewCell *)c;
            if (self.model.roomImageInTable || self.isRoomImageAlwaysInTable)
            {
                cell.roomImage.image = [self.model roomImage];
            }
            break;
        }
        case SCULightingModelCellTypePlain:
        {
            c.selectionStyle = UITableViewCellSelectionStyleNone;
            
            if ([self.model.expandedIndexPaths containsObject:indexPath])
            {
                c.bottomLineType = SCUDefaultTableViewCellBottomLineTypeNone;
            }
            
            break;
        }
        case SCULightingModelCellTypeScene:
        {
            SCULightingSceneButtonTableViewCell *cell = (SCULightingSceneButtonTableViewCell *)c;
            [self.model listenToSceneHold:cell.holdGesture forIndexPath:indexPath];
        }
    }
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)type forChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    SCULightingModelCellType cellType = (SCULightingModelCellType)type;
    c.backgroundColor = [[SCUColors shared] color03shade03];
    if (cellType == SCULightingModelCellTypeSlider)
    {
        SCUSceneLightingSliderTableViewCell *cell = (SCUSceneLightingSliderTableViewCell *)c;
        SCUSlider *slider = cell.slider;
        [self.model listenToSlider:slider forParentIndexPath:indexPath];

        if (self.isShades)
        {
            SCUShadeSliderTableViewCell *shadeCell = (SCUShadeSliderTableViewCell *)cell;
            [self.model listenToCloseButton:shadeCell.closeButton openButton:shadeCell.openButton forParentIndexPath:indexPath];
        }
    }
    else if (cellType == SCULightingModelCellTypeShadesRelative)
    {
        SCURelativeShadesTableViewCell *cell = (SCURelativeShadesTableViewCell *)c;
        [self.model listenToCloseButton:cell.closeButton stopButton:cell.stopButton openButton:cell.openButton forParentIndexPath:indexPath];
    }
    else if (cellType == SCULightingModelCellTypeFan)
    {
        SCUFanButtonsTableViewCell *cell = (SCUFanButtonsTableViewCell *)c;
        cell.borderType = SCUDefaultTableViewCellBorderTypeNone;
        cell.bottomLineType = SCUDefaultTableViewCellBottomLineTypeFull;
        [self.model listenToOffButton:cell.offButton lowButton:cell.lowButton medButton:cell.mediumButton highButton:cell.highButton forParentIndexPath:indexPath];
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCULightingModelCellType cellType = [self.model cellTypeForAbsoluteIndexPath:indexPath];

    switch (cellType)
    {
        case SCULightingModelCellTypeEmptyRoomImage:
            return 2;
        case SCULightingModelCellTypeRoomImage:
            return 200;
        case SCULightingModelCellTypeSlider:
        case SCULightingModelCellTypeShadesRelative:
            return 44;
        case SCULightingModelCellTypeFan:
            return 50;
        default:
            return self.tableView.rowHeight;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 0;
    }
    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0 || section == 1)
    {
        return 0;
    }
    
    return 45.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (section == 0)
    {
        return [[UIView alloc] initWithFrame:CGRectZero];
    }
    
    return [super tableView:tableView viewForFooterInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[super tableView:tableView titleForHeaderInSection:section] uppercaseString];
}

#pragma mark - SCULightingModelDelegate methods

- (void)reloadData
{
    [self.tableView reloadData];
}

- (void)reloadIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)toggleSwitchForIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *absoluteIndexPath = [self.model absoluteIndexPathForRelativeIndexPath:indexPath];
    SCUToggleSwitchTableViewCell *cell = (SCUToggleSwitchTableViewCell *)[self.tableView cellForRowAtIndexPath:absoluteIndexPath];

    UISwitch *toggleSwitch = cell.toggleSwitch;
    [toggleSwitch setOn:!toggleSwitch.isOn animated:YES];
}

- (void)roomImageDidUpdate:(UIImage *)image
{
    ;
}

@end
