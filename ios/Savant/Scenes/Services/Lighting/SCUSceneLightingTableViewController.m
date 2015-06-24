//
//  SCUSceneLightingTableViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 7/29/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneLightingTableViewController.h"
#import "SCUToggleSwitchTableViewCell.h"
#import "SCUButtonTableViewCell.h"
#import "SCUSceneLightingSliderTableViewCell.h"
#import "SCURoomImageTableViewCell.h"
#import "SCUSceneLightingExcludedTableViewCell.h"
#import "SCUSceneLightingServiceViewController.h"
#import "SCUFanButtonsTableViewCell.h"

@interface SCUSceneLightingTableViewController () <SCUSceneLightingTableModel>

@property (nonatomic) SCUSceneLightingTableModel *model;
@property (nonatomic, copy) SCUSceneServiceBarButtonItemModifyBlock leftBarButtonItemModifyBlock;
@property (nonatomic, copy) SCUSceneServiceBarButtonItemModifyBlock rightBarButtonItemModifyBlock;
@property (nonatomic, getter = isShades) BOOL shades;

@end

@implementation SCUSceneLightingTableViewController

- (instancetype)initWithModel:(SCUSceneLightingTableModel *)model
{
    self = [super init];

    if (self)
    {
        self.model = model;
        self.model.delegate = self;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.rowHeight = 60;
    self.tableView.contentInset = [UIDevice isPad] ? UIEdgeInsetsMake(-18, 0, -2, 0) : UIEdgeInsetsMake(-35, 0, -2, 0);

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 0.5;
    [self.tableView addGestureRecognizer:longPress];

    SCUSceneLightingServiceViewController *parent = (SCUSceneLightingServiceViewController *)self.parentViewController;

    if ([parent isKindOfClass:[SCUSceneLightingServiceViewController class]])
    {
        self.leftBarButtonItemModifyBlock = parent.leftBarButtonModifyBlock;
        self.rightBarButtonItemModifyBlock = parent.rightBarButtonModifyBlock;
    }

    self.shades = [self.model.service.serviceId isEqualToString:@"SVC_ENV_SHADE"] ? YES : NO;
}

- (id<SCUExpandableDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUToggleSwitchTableViewCell class] forCellType:SCUSceneLightingTableModelCellTypeToggleSwitch];
    [self.tableView sav_registerClass:[SCUButtonTableViewCell class] forCellType:SCUSceneLightingTableModelCellTypeToggleLabel];
    [self.tableView sav_registerClass:[SCUDefaultTableViewCell class] forCellType:SCUSceneLightingTableModelCellTypeEmptyRoomImage];
    [self.tableView sav_registerClass:[SCURoomImageTableViewCell class] forCellType:SCUSceneLightingTableModelCellTypeRoomImage];
    [self.tableView sav_registerClass:[SCUSceneLightingSliderTableViewCell class] forCellType:SCUSceneLightingTableModelCellTypeSlider];
    [self.tableView sav_registerClass:[SCUDefaultTableViewCell class] forCellType:SCUSceneLightingTableModelCellTypeEdit];
    [self.tableView sav_registerClass:[SCUSceneLightingExcludedTableViewCell class] forCellType:SCUSceneLightingTableModelCellTypeExcluded];
    [self.tableView sav_registerClass:[SCUFanButtonsTableViewCell class] forCellType:SCUSceneLightingTableModelCellTypeFan];
    [self.tableView sav_registerClass:[SCUDefaultTableViewCell class] forCellType:SCUSceneLightingTableModelCellTypePlain];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        self.model.editMode = !self.model.editMode;

        if (self.model.editMode)
        {
            UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(endEditMode)];
            item.tintColor = [[SCUColors shared] color01];
            self.rightBarButtonItemModifyBlock(item);
            self.leftBarButtonItemModifyBlock((UIBarButtonItem *)[NSNull null]);
            self.parentViewController.title = NSLocalizedString(@"Edit", nil);
        }
        else
        {
            self.rightBarButtonItemModifyBlock(nil);
            self.leftBarButtonItemModifyBlock(nil);
            self.parentViewController.title = NSLocalizedString(@"Lighting", nil);
        }
        
        if (self.model.editMode)
        {
            self.model.expandedState = self.model.expandedIndexPaths;
            
            for (NSIndexPath *indexPath in self.model.expandedState)
            {
                [self.model toggleIndexPath:indexPath];
            }
        }
        else
        {
            for (NSIndexPath *indexPath in self.model.expandedState)
            {
                if (!self.model.editMode && [self.model entityIncludedAtIndexPath:indexPath])
                {
                    [self.model toggleIndexPath:indexPath];
                }
            }
        }

        if (!self.model.editMode)
        {
            self.model.expandedState = nil;
        }
        
        [self.tableView reloadData];
    }
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    if (![self.model entityIncludedAtIndexPath:indexPath] && !self.model.editMode)
    {
        c.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    SCUSceneLightingTableModelCellType cellType = (SCUSceneLightingTableModelCellType)type;

    switch (cellType)
    {
        case SCUSceneLightingTableModelCellTypeToggleSwitch:
        {
            SCUToggleSwitchTableViewCell *cell = (SCUToggleSwitchTableViewCell *)c;
            [self.model listenToToggleSwitch:cell.toggleSwitch forIndexPath:indexPath];
            break;
        }
        case SCUSceneLightingTableModelCellTypeRoomImage:
        {
            SCURoomImageTableViewCell *cell = (SCURoomImageTableViewCell *)c;
            cell.roomImage.image = self.model.roomImage;
            break;
        }
        case SCUSceneLightingTableModelCellTypeEmptyRoomImage:
        {
            c.backgroundColor = [UIColor clearColor];
            c.borderColor = [UIColor clearColor];
            c.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
    }
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)type forChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    SCUSceneLightingTableModelCellType cellType = (SCUSceneLightingTableModelCellType)type;
    c.backgroundColor = [[SCUColors shared] color03shade03];

    if (cellType == SCUSceneLightingTableModelCellTypeSlider)
    {
        SCUSceneLightingSliderTableViewCell *cell = (SCUSceneLightingSliderTableViewCell *)c;
        SCUSlider *slider = cell.slider;
        [self.model listenToSlider:slider forParentIndexPath:indexPath];

        if (self.isShades)
        {
            cell.minImage = [UIImage sav_imageNamed:@"ShadesClosed" tintColor:[[SCUColors shared] color03shade08]];
            cell.maxImage = [UIImage sav_imageNamed:@"ShadesOpen" tintColor:[[SCUColors shared] color03shade08]];
        }
    }
    else if (cellType == SCUSceneLightingTableModelCellTypeFan)
    {
        SCUFanButtonsTableViewCell *cell = (SCUFanButtonsTableViewCell *)c;
        [self.model listenToOffButton:cell.offButton lowButton:cell.lowButton medButton:cell.mediumButton highButton:cell.highButton forIndexPath:indexPath];
    }
}

- (void)reconfigureIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *absolutePath = [self.model absoluteIndexPathForRelativeIndexPath:indexPath];
    SCUDefaultTableViewCell *cell = (SCUDefaultTableViewCell *)[self.tableView cellForRowAtIndexPath:absolutePath];
    [cell configureWithInfo:[self.model modelObjectForIndexPath:indexPath]];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCUSceneLightingTableModelCellType cellType = [self.model cellTypeForAbsoluteIndexPath:indexPath];

    if (cellType == SCUSceneLightingTableModelCellTypeEmptyRoomImage)
    {
        return 2;
    }
    else if (cellType == SCUSceneLightingTableModelCellTypeRoomImage)
    {
        return 200;
    }
    else if (cellType == SCUSceneLightingTableModelCellTypeSlider)
    {
        return 44;
    }
    else if (cellType == SCUSceneLightingTableModelCellTypeFan)
    {
        return 50;
    }
    else
    {
        return self.tableView.rowHeight;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 0;
    }
    
    return 5.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 0.0f;
    }
    
    return 32.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[super tableView:tableView titleForHeaderInSection:section] uppercaseString];
}

#pragma mark - SCUSceneLightingTableModel methods

- (void)reloadData
{
    [self.tableView reloadData];
}

- (void)reloadIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)reloadChildrenBelowIndexPath:(NSIndexPath *)indexPath
{
    [self reloadChildrenBelowIndexPath:indexPath animated:NO];
}

- (void)toggleIndexPath:(NSIndexPath *)indexPath
{
    [self toggleIndex:indexPath animated:YES];
    [self reconfigureIndexPath:indexPath];
}

- (void)toggleSwitchForIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *absoluteIndexPath = [self.model absoluteIndexPathForRelativeIndexPath:indexPath];
    SCUToggleSwitchTableViewCell *cell = (SCUToggleSwitchTableViewCell *)[self.tableView cellForRowAtIndexPath:absoluteIndexPath];

    UISwitch *toggleSwitch = cell.toggleSwitch;
    [toggleSwitch setOn:!toggleSwitch.isOn animated:YES];
}

- (BOOL)isFirstPass
{
    SCUSceneLightingServiceViewController *parent = (SCUSceneLightingServiceViewController *)self.parentViewController;

    if ([parent isKindOfClass:[SCUSceneLightingServiceViewController class]])
    {
        return parent.creationVC.isEnvAdd;
    }
    else
    {
        return YES;
    }
}

#pragma mark -

- (void)endEditMode
{
    self.model.editMode = NO;
    self.rightBarButtonItemModifyBlock(nil);
    self.leftBarButtonItemModifyBlock(nil);
    [self.tableView reloadData];
    self.parentViewController.title = NSLocalizedString(@"Lighting", nil);
}

@end
