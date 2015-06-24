//
//  SCUSceneClimateTableViewController.m
//  SavantController
//
//  Created by Stephen Silber on 8/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneClimatePickerCell.h"
#import "SCUSceneChildCell.h"
#import "SCUZoneImagesView.h"
#import "SCUSceneClimateTableViewController.h"

@interface SCUSceneClimateTableViewController () <SCUSceneClimateTableModel>

@property (nonatomic) SCUSceneClimateTableModel *model;

@end

@implementation SCUSceneClimateTableViewController

- (instancetype)initWithModel:(SCUSceneClimateTableModel *)model
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
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.tableHeaderView = [self headerView];
    self.tableView.rowHeight = 60;
}

- (id<SCUExpandableDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUDefaultTableViewCell class] forCellType:SCUSceneClimateTableModelCellTypeDefault];
    [self.tableView sav_registerClass:[SCUSceneChildCell class] forCellType:SCUSceneClimateTableModelCellTypeChild];
    [self.tableView sav_registerClass:[SCUSceneClimatePickerCell class] forCellType:SCUSceneClimateTableModelCellTypePicker];

}

- (void)reloadTableHeader
{
    self.tableView.tableHeaderView = [self headerView];
}

- (UIView *)headerView
{
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 225)];
    
    SCUZoneImagesView *imagesView = [[SCUZoneImagesView alloc] initWithFrame:CGRectZero];
    [imagesView setImagesFromArray:[self.model.roomImages allValues]];
    [header addSubview:imagesView];
    [header sav_setHeight:200.0f forView:imagesView isRelative:NO];
    [header sav_addFlushConstraintsForView:imagesView];

    return header;
}

- (void)toggleIndex:(NSIndexPath *)indexPath
{
    [self.tableView beginUpdates];
    for (NSIndexPath *expandedPath in self.model.expandedIndexPaths)
    {
        if (![expandedPath isEqual:indexPath])
        {
            [self toggleIndex:expandedPath animated:YES];
        }
    }
    
    [self toggleIndex:indexPath animated:YES];
    [self.tableView endUpdates];
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    SCUSceneClimateTableModelCellType cellType = (SCUSceneClimateTableModelCellType)type;
    
    c.textLabel.font       = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h9];
    c.detailTextLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h9];
    c.textLabel.textColor       = [[SCUColors shared] color04];
    c.detailTextLabel.textColor = [[SCUColors shared] color03shade07];
    
    switch (cellType)
    {
        case SCUSceneClimateTableModelCellTypeDefault:
        {
            break;
        }
    }
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)type forChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    SCUSceneClimateTableModelCellType cellType = (SCUSceneClimateTableModelCellType)type;
    
    c.textLabel.font       = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h10];
    c.textLabel.textColor  = [[SCUColors shared] color04];

    switch (cellType)
    {
        case SCUSceneClimateTableModelCellTypePicker:
        {
            SCUSceneClimatePickerCell *cell = (SCUSceneClimatePickerCell *)c;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [self.model listenToPickerView:cell.pickerView forParentIndexPath:indexPath];
            break;
         }
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCUSceneClimateTableModelCellType cellType = [self.model cellTypeForAbsoluteIndexPath:indexPath];
    
    if (cellType == SCUSceneClimateTableModelCellTypePicker)
    {
        return 175.0f;
    }
    else if (cellType == SCUSceneClimateTableModelCellTypeChild)
    {
        return 50.0f;
    }
    else
    {
        return self.tableView.rowHeight;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 25.0f;
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

- (void)addRowsAtIndexPaths:(NSArray *)indexPaths
{
    [self addParentRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
}

- (void)addRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self addParentRowAtIndexPath:indexPath withRowAnimation:UITableViewRowAnimationNone];
}

- (void)removeRowsAtIndexPaths:(NSArray *)indexPaths
{
    [self removeParentRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone updateBlock:NULL];
}

- (void)removeRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self removeParentRowAtIndexPath:indexPath withRowAnimation:UITableViewRowAnimationNone updateBlock:NULL];
}

- (void)reloadIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end
