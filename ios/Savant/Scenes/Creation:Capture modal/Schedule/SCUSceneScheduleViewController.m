//
//  SCUSceneScheduleViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 8/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneScheduleViewController.h"
#import "SCUSceneCreationTableViewControllerPrivate.h"
#import "SCUSceneScheduleDataSource.h"
#import "SCUDatePickerCell.h"
#import "SCUDateCell.h"
#import "SCUDayPickerCell.h"
#import "SCUButton.h"
#import "SCUSceneChildCell.h"
#import "SCUSecondsPickerCell.h"
#import "SCUToggleSwitchTableViewCell.h"

@interface SCUSceneScheduleViewController () <SCUSceneScheduleDelegate>

@property SCUSceneScheduleDataSource *model;
@property SAVScene *editingScene;

@end

@implementation SCUSceneScheduleViewController

- (instancetype)initWithScene:(SAVScene *)scene andService:(SAVService *)service
{
    self = [super initWithScene:scene andService:service];
    if (self)
    {
        self.editingScene = scene;
        self.model = [[SCUSceneScheduleDataSource alloc] initWithScene:[scene copy] andService:service];
        self.model.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Schedule", nil);
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 16)];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(popViewControllerCanceled)];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(doneEditing)];
    self.navigationItem.rightBarButtonItem.tintColor = [[SCUColors shared] color01];

    SCUButton *removeSchedule = [[SCUButton alloc] initWithTitle:[NSLocalizedString(@"Remove Schedule", nil) uppercaseString]];
    removeSchedule.borderWidth = 1;
    removeSchedule.cornerRadius = 4;
    removeSchedule.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:14];
    removeSchedule.color = [[SCUColors shared] color01];
    removeSchedule.selectedColor = [[[SCUColors shared] color01] colorWithAlphaComponent:.7];
    removeSchedule.borderColor = [[SCUColors shared] color03shade02];
    removeSchedule.backgroundColor = nil;
    removeSchedule.selectedBackgroundColor = nil;
    removeSchedule.target = self;
    removeSchedule.releaseAction = @selector(removeSchedule);

    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 60)];
    [footerView addSubview:removeSchedule];
    [footerView sav_pinView:removeSchedule withOptions:SAVViewPinningOptionsVertically|SAVViewPinningOptionsCenterX];
    [footerView sav_setWidth:.9 forView:removeSchedule isRelative:YES];

    self.tableView.tableFooterView = footerView;
}

- (void)removeSchedule
{
    self.editingScene.scheduled = NO;

    [self popViewController];
}

- (void)doneEditing
{
    [self.model doneEditing];

    [self.editingScene applySettings:[self.model.scene dictionaryRepresentation]];

    [self popViewController];
}

- (CGFloat)heightForCellWithType:(NSUInteger)type
{
    switch (type)
    {
        case SCUSceneScheduleCellTypeDatePicker:
        case SCUSceneScheduleCellTypeNumericPicker:
            return 162;
        case SCUSceneScheduleCellTypeDayPicker:
        case SCUSceneScheduleCellTypeDefault:
        case SCUSceneScheduleCellTypeDate:
        case SCUSceneScheduleCellTypeToggle:
            return 60;
        default:
            return self.tableView.rowHeight;
    }
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUDefaultTableViewCell class] forCellType:SCUSceneScheduleCellTypeDefault];
    [self.tableView sav_registerClass:[SCUDatePickerCell class] forCellType:SCUSceneScheduleCellTypeDatePicker];
    [self.tableView sav_registerClass:[SCUDateCell class] forCellType:SCUSceneScheduleCellTypeDate];
    [self.tableView sav_registerClass:[SCUDayPickerCell class] forCellType:SCUSceneScheduleCellTypeDayPicker];
    [self.tableView sav_registerClass:[SCUSceneChildCell class] forCellType:SCUSceneScheduleCellTypeChild];
    [self.tableView sav_registerClass:[SCUSecondsPickerCell class] forCellType:SCUSceneScheduleCellTypeNumericPicker];
    [self.tableView sav_registerClass:[SCUToggleSwitchTableViewCell class] forCellType:SCUSceneScheduleCellTypeToggle];
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)t indexPath:(NSIndexPath *)indexPath
{
    SCUSceneScheduleCellTypes type = t;
    switch (type)
    {
        case SCUSceneScheduleCellTypeToggle:
        {
            SCUToggleSwitchTableViewCell *cell = (SCUToggleSwitchTableViewCell *)c;

            [self listenToAllYearSwitch:cell.toggleSwitch forIndexPath:indexPath];
            break;
        }
    }
}

- (void)listenToAllYearSwitch:(UISwitch *)toggleSwitch forIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    toggleSwitch.sav_didChangeHandler = ^(BOOL on){
        SAVStrongWeakSelf;
        if (on != sSelf.model.scene.isAllYear)
        {
            sSelf.model.scene.allYear = on;

            NSIndexPath *startPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
            NSIndexPath *endPath = [NSIndexPath indexPathForRow:indexPath.row + 2 inSection:indexPath.section];

            if (on)
            {
                [sSelf removeParentRowsAtIndexPaths:@[endPath, startPath] withRowAnimation:UITableViewRowAnimationTop updateBlock:^{
                    [sSelf.model prepareData];
                }];
            }
            else
            {
                [sSelf.model prepareData];
                [sSelf addParentRowsAtIndexPaths:@[startPath, endPath] withRowAnimation:UITableViewRowAnimationTop];
            }
        }
    };
}

- (void)reloadIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView reloadRowsAtIndexPaths:@[[self.model absoluteIndexPathForRelativeIndexPath:indexPath]] withRowAnimation:UITableViewRowAnimationNone];
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

- (void)reloadChildrenBelowIndexPath:(NSIndexPath *)indexPath
{
    [self reloadChildrenBelowIndexPath:indexPath animated:NO];
}

- (void)reloadData
{
    [self.tableView reloadData];
}

@end