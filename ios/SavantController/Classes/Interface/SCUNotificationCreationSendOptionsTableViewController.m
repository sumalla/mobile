//
//  SCUNotificationCreationSendOptionsTableViewController.m
//  SavantController
//
//  Created by Stephen Silber on 1/23/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationCreationTableViewControllerPrivate.h"
#import "SCUNotificationCreationSendOptionsViewModel.h"
#import "SCUNotificationCreationSendOptionsTableViewController.h"

@interface SCUNotificationCreationSendOptionsTableViewController () <SCUNotificationCreationSendOptionViewDelegate>

@property (nonatomic) SCUNotificationCreationSendOptionsViewModel *model;
@property SAVNotification *editingNotification;

@end

@implementation SCUNotificationCreationSendOptionsTableViewController

- (instancetype)initWithNotification:(SAVNotification *)notification
{
    self = [super initWithNotification:notification];
    
    if (self)
    {
        self.editingNotification = notification;
        self.model = [[SCUNotificationCreationSendOptionsViewModel alloc] initWithNotification:[notification copy]];
        self.model.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStylePlain target:self action:@selector(doneTapped:)];
    doneButton.tintColor = [[SCUColors shared] color01];
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)doneTapped:(UIBarButtonItem *)button
{
    [self.model doneEditing];
    
    [self.editingNotification applySettings:[self.model.notification dictionaryRepresentation]];
    
    [self popViewController];
}

- (void)reloadRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end
