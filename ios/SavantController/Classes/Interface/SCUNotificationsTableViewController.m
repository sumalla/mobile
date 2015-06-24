//
//  SCUNotificationsTableViewController.m
//  SavantController
//
//  Created by Julian Locke on 1/15/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationsTableViewController.h"
#import "SCUNotificationToggleTableViewCell.h"
#import "SCUNotificationInvisibleTableViewCell.h"
#import "SCUNotificationAddServiceTableViewController.h"
#import "SCUNotificationCreationViewController.h"
#import "SCUMainNavbarManager.h"
#import "SCUNotificationsModel.h"
#import "SCUNotificationManager.h"
#import "SCUToolbarButtonAnimated.h"

#import <SavantControl/SavantControl.h>

#import "SCUNavBarToolbar.h"
#import "SCUInterface.h"

@interface SCUNotificationsTableViewController () <SCUNotificationsModelDelegate>

@property (nonatomic) SCUNotificationsModel *model;
@property (nonatomic) BOOL hasLoadedInitialData;
@property (nonatomic) UIActivityIndicatorView *loadingSpinner;
@property (nonatomic, weak) NSTimer *loadingSpinnerTimer;
@property (nonatomic, getter = isInitialAppearance) BOOL initialAppearance;

@end

@implementation SCUNotificationsTableViewController

- (instancetype)initWithNotification:(SAVNotification *)notification
{

    self = [super initWithNotification:notification];
    
    if (self)
    {
        SCUNotificationsModel *model = [[SCUNotificationsModel alloc] initWithNotification:notification];
        self.model = model;
        self.model.delegate = self;
        
        self.initialAppearance = YES;
        
        UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
        [refresh addTarget:self action:@selector(forceModelToReloadData) forControlEvents:UIControlEventValueChanged];
        self.refreshControl = refresh;
        
        UIView *footer = [[UIView alloc] initWithFrame:CGRectZero];
        
        footer.backgroundColor = [UIColor clearColor];
        
        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        textLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h11];
        textLabel.textColor = [[SCUColors shared] color03shade07];
        textLabel.textAlignment = NSTextAlignmentLeft;
        textLabel.text = NSLocalizedString(@"Create custom notifications for things that are important to you. Categories include Climate, Lighting, and Entertainment. Tap \"Add\" to get started.", nil);
        textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        textLabel.numberOfLines = 0;
        
        [footer addSubview:textLabel];
        
        CGFloat space = [[SCUDimens dimens] regular].globalMargin1;
        
        if ([UIDevice isPad])
        {
            space = 0.f;
        }
        
        [footer sav_pinView:textLabel withOptions:SAVViewPinningOptionsHorizontally withSpace:space];
        [footer sav_pinView:textLabel withOptions:SAVViewPinningOptionsCenterY];
        
        footer.frame = CGRectMake(0, 0, CGRectGetWidth(footer.frame), 125.0f);

        self.tableView.sectionFooterHeight = 0.f;
        self.tableView.tableFooterView = footer;
    }
    
    return self;
}

- (void)forceModelToReloadData
{
    [self.model loadData];
}

#pragma mark - Table View

- (id<SCUExpandableDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[SCUNotificationManager sharedInstance] start:YES];
    
    self.title = NSLocalizedString(@"Notifications", nil);
        
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add", nil) style:UIBarButtonItemStylePlain target:self action:@selector(presentAddNotification)];
    [addButton setTintColor:[[SCUColors shared] color01]];
    self.navigationItem.rightBarButtonItem = addButton;

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage sav_imageNamed:@"Hamburger" tintColor:[[SCUColors shared] color04]] style:UIBarButtonItemStylePlain target:[SCUInterface sharedInstance] action:@selector(presentNavigation:)];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.model loadData];
    
    if (self.isInitialAppearance)
    {
        self.initialAppearance = NO;
        
        SAVWeakSelf;
        self.loadingSpinnerTimer = [NSTimer sav_scheduledBlockWithDelay:.5 block:^{
            SAVStrongWeakSelf;
            sSelf.loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            sSelf.loadingSpinner.hidesWhenStopped = YES;
            [sSelf.view addSubview:sSelf.loadingSpinner];
            [sSelf.view sav_addCenteredConstraintsForView:sSelf.loadingSpinner];
            [sSelf.loadingSpinner startAnimating];
        }];
    }
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUNotificationToggleTableViewCell class] forCellType:SCUNotificationsCellTypeToggle];
    [self.tableView sav_registerClass:[SCUNotificationInvisibleTableViewCell class] forCellType:SCUNotificationsCellTypeInvisible];
}

- (void)configureCell:(SCUDefaultTableViewCell *)cell withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    if (type == SCUNotificationsCellTypeInvisible)
    {
        cell.borderType = SCUDefaultTableViewCellBorderTypeNone;
        cell.bottomLineType = SCUDefaultTableViewCellBottomLineTypeNone;
    }

    else if (type == SCUNotificationsCellTypeToggle)
    {
        SCUNotificationToggleTableViewCell *c = (SCUNotificationToggleTableViewCell *)cell;
        [self.model listenToToggleSwitch:c.toggleSwitch forIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [self.model deleteAtIndexPath:indexPath];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == (NSInteger)self.model.dataSource.count)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.model cellTypeForIndexPath:indexPath] == SCUNotificationsCellTypeToggle)
    {
        NSString *title = [self.model modelObjectForIndexPath:indexPath][SCUDefaultTableViewCellKeyDetailTitle];
        NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h9]};
        
        CGRect frame = [title boundingRectWithSize:CGSizeMake((CGRectGetWidth(self.tableView.bounds) - (2 * [[SCUDimens dimens] regular].globalMargin1)), CGFLOAT_MAX)
                                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                                              attributes:attributes
                                                                 context:nil];
        
        return CGRectGetHeight(frame) + 90;
    }
    else
    {
        return 125.f;
    }
}

#pragma mark - SCUNotificationsModelDelegate methods

- (void)reloadData
{
    [self invalidateSpinner];
    
    [self.tableView reloadData];
}

- (void)presentEditNotification:(SAVNotification *)notification
{
    self.creationVC.editingNotification = notification;
    self.creationVC.editing = YES;
    self.creationVC.activeState = SCUNotificationCreationState_AddRule;
}

- (void)reloadIndexPath:(NSIndexPath *)indexPath
{
    [self invalidateSpinner];
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Actions

- (void)presentAddNotification
{
    [self.creationVC wipeNotification];
    self.creationVC.editing = NO;
    self.creationVC.activeState = SCUNotificationCreationState_SelectServiceList;
}

#pragma mark - SCUMainNavbarManager

- (SCUMainNavbarItems)mainNavbarItems
{
    return SCUMainNavbarItemsNavigation | SCUMainNavbarItemsRightButtons;
}

- (NSArray *)mainNavbarRightButtonItems
{
    SCUToolbarButtonAnimated *add = [[SCUToolbarButtonAnimated alloc] initWithTitle:NSLocalizedString(@"Add", nil)];
    add.titleLabel.font = [UIFont fontWithName:@"Gotham-Medium" size:[[SCUDimens dimens] regular].h9];
    add.color = [[SCUColors shared] color01];
    add.selectedColor = [[[SCUColors shared] color01] colorWithAlphaComponent:.6];
    add.target = self;

    add.releaseAction = @selector(presentAddNotification);
    return @[add];
}

- (NSNumber *)mainNavbarItemsRightSpacing
{
    return @0;
}

- (BOOL)mainToolbarIsVisible
{
    return NO;
}

#pragma mark -

- (void)invalidateSpinner
{
    self.initialAppearance = NO;
    
    if (self.loadingSpinner)
    {
        [self.loadingSpinner removeFromSuperview];
        self.loadingSpinner = nil;
    }
    
    [self.loadingSpinnerTimer invalidate];
    self.loadingSpinnerTimer = nil;
}

- (void)endRefresh
{
    [self.refreshControl endRefreshing];
}

@end
