//
//  SCUNotificationAddServiceTableViewController.m
//  SavantController
//
//  Created by Stephen Silber on 1/20/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationAddServiceTableViewController.h"
#import "SCUNotificationAddServiceViewModel.h"
#import "SCUNotificationCreationViewController.h"
#import "SCUNotificationCreationTableViewControllerPrivate.h"
#import "SCUIconSelectView.h"

NSString *const SCUNotificationIconClimate = @"Climate";
NSString *const SCUNotificationIconEntertainment = @"Entertainment";
NSString *const SCUNotificationIconLighting = @"Lighting";

@interface SCUNotificationAddServiceTableViewController () <SCUNotificationsAddServiceViewDelegate>

@property (nonatomic) SCUIconSelectView *iconSelectView;
@property (nonatomic) SCUNotificationAddServiceViewModel *model;

@end

@implementation SCUNotificationAddServiceTableViewController

- (instancetype)initWithNotification:(SAVNotification *)notification
{
    self = [super init];
    
    if (self)
    {
        self.model = [[SCUNotificationAddServiceViewModel alloc] initWithNotification:notification];
        self.model.delegate = self;
        
        NSArray *services = [self.model availableServices];
        
        if (services.count > 1)
        {
            self.iconSelectView = [[SCUIconSelectView alloc] initWithImages:services];
            self.iconSelectView.frame = CGRectMake(0, 0, CGRectGetWidth(self.iconSelectView.frame), 100.0f);
            self.iconSelectView.delegate = self.model;
            
            if (self.creationVC.isEditing)
            {
                [self.iconSelectView selectIndex:[self.model indexForServiceType:self.model.notification.serviceType]];
            }
            
            [self.tableView setTableHeaderView:self.iconSelectView];
        }
        
        [self.tableView setRowHeight:60.0f];
        [self.tableView setScrollEnabled:YES];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);

    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelTapped:)]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *header = [[UIView alloc] initWithFrame:CGRectZero];
    header.backgroundColor = [[SCUColors shared] color03shade04];
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    headerLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h8];
    headerLabel.textColor = [[SCUColors shared] color04];
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.text = [self.model titleForHeaderInSection:section];
    
    [header addSubview:headerLabel];
    [header sav_addCenteredConstraintsForView:headerLabel];
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 60.0f;
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUDefaultTableViewCell class] forCellType:0];
}

- (void)cancelTapped:(UIBarButtonItem *)button
{
    //TODO: Discard SAVNotification
    [self popViewController];
}

- (void)moveToRuleScreen
{
    [self.creationVC wipeNotification];
    self.creationVC.notification.triggerValues = self.model.notification.triggerValues;
    self.creationVC.notification.serviceType = self.model.notification.serviceType;
    
    self.creationVC.activeState = SCUNotificationCreationState_AddRule;
}

#pragma mark - SCUNotificationsModelDelegate methods

- (void)reloadData
{
    [self.tableView reloadData];
}

- (void)changeSelectedIndex:(NSInteger)index
{
    [self.iconSelectView selectIndex:index];
}

@end
