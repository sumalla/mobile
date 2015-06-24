//
//  SCUCreateInviteTableViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 8/20/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUUserModifyTableViewController.h"
#import "SCUUserModifyTableDataModel.h"
#import "SCUTextFieldProgressTableViewCell.h"
#import "SCUToggleSwitchTableViewCell.h"
#import "SCUButton.h"
#import "SCUChangePasswordViewController.h"
#import "SCUUserPermissionsTableViewController.h"
#import "SCUUserModifyTableViewCell.h"
#import "SCUToolbarButtonAnimated.h"

@interface SCUUserModifyTableViewController () <SCUUserModifyTableDataModelDelegate>

@property (nonatomic) SCUUserModifyTableDataModel *model;
@property (nonatomic) UIFont *sizingFont;
@property (nonatomic) SCUToolbarButtonAnimated *animatedDoneButton;

@end

@implementation SCUUserModifyTableViewController

- (instancetype)initWithCloudUser:(SAVCloudUser *)user
{
    self = [super init];

    if (self)
    {
        if (user.firstName)
        {
            self.title = user.firstName;
        }
        else
        {
            self.title = user.email;
        }

        self.model = [[SCUUserModifyTableDataModel alloc] initWithCloudUser:user];
        self.model.delegate = self;
        self.sizingFont = [[SCUUserModifyTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DoesntMatter"].detailTextLabel.font;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.animatedDoneButton = [[SCUToolbarButtonAnimated alloc] initWithTitle:NSLocalizedString(@"Done", nil)];
    self.animatedDoneButton.color = [[SCUColors shared] color01];
    self.animatedDoneButton.selectedColor = [[[SCUColors shared] color01] colorWithAlphaComponent:.6];
    self.animatedDoneButton.target = self.model;
    self.animatedDoneButton.releaseAction = @selector(finishEditing);

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.animatedDoneButton];

    if ([self.model shouldAddDeleteRow])
    {
        self.tableView.delaysContentTouches = NO;
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 80)];

        NSString *title = NSLocalizedString(@"REMOVE USER", nil);

        SCUButton *button = [[SCUButton alloc] initWithTitle:title];
        button.roundedCorners = YES;
        button.color = [[SCUColors shared] color01];
        button.backgroundColor = [UIColor clearColor];
        button.borderWidth = [UIScreen screenPixel];
        button.borderColor = [[SCUColors shared] color03shade04];
        button.target = self.model;
        button.releaseAction = @selector(delete);
        [view addSubview:button];
        [view sav_addConstraintsForView:button withEdgeInsets:UIEdgeInsetsMake(10, 10, 10, 10)];

        self.tableView.tableFooterView = view;
    }

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 60;
    self.tableView.rowHeight = 60;
}

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUTextFieldProgressTableViewCell class] forCellType:SCUCreateInviteCellTypeTextEntry];
    [self.tableView sav_registerClass:[SCUToggleSwitchTableViewCell class] forCellType:SCUCreateInviteCellTypeToggle];
    [self.tableView sav_registerClass:[SCUUserModifyTableViewCell class] forCellType:SCUCreateInviteCellTypeNormal];
    [self.tableView sav_registerClass:[SCUDefaultTableViewCell class] forCellType:SCUCreateInviteCellTypeFixed];
    [self.tableView sav_registerClass:[SCUUserModifyTableViewCell class] forCellType:SCUCreateInviteCellTypeDouble];
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)t indexPath:(NSIndexPath *)indexPath
{
    SCUCreateInviteCellType type = (SCUCreateInviteCellType)t;

    switch (type)
    {
        case SCUCreateInviteCellTypeTextEntry:
        {
            SCUTextFieldProgressTableViewCell *cell = (SCUTextFieldProgressTableViewCell *)c;
            cell.fixed = YES;
            [self.model listenToTextField:cell.textField forIndexPath:indexPath];
            break;
        }
        case SCUCreateInviteCellTypeToggle:
        {
            SCUToggleSwitchTableViewCell *cell = (SCUToggleSwitchTableViewCell *)c;
            [self.model listenToToggleSwitch:cell.toggleSwitch forIndexPath:indexPath];
        }
        case SCUCreateInviteCellTypeFixed:
        {
            c.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
        case SCUCreateInviteCellTypeDouble:
        {
            c.detailTextLabel.numberOfLines = 0;
            break;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.model cellTypeForIndexPath:indexPath] == SCUCreateInviteCellTypeDouble)
    {
        NSString *title = [self.model modelObjectForIndexPath:indexPath][SCUDefaultTableViewCellKeyDetailTitle];
        return [self.tableView sav_heightForText:title font:self.sizingFont];
    }
    else
    {
        return self.tableView.estimatedRowHeight;
    }
}

#pragma mark - SCUCreateInviteTableDataModelDelegate methods

- (void)reloadData
{
    [self.tableView reloadData];
}

- (void)endEditing
{
    [self.view endEditing:YES];
    [self setFirstResponderAtIndexPath:nil];
}

- (void)editingComplete
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)changePasswordForUser:(SAVCloudUser *)user
{
    SCUChangePasswordViewController *changePassword = [[SCUChangePasswordViewController alloc] initWithCloudUser:user];
    [self.navigationController pushViewController:changePassword animated:YES];
}

- (void)navigateBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showZoneBlacklistTableForUser:(SAVCloudUser *)user
{
    SCURoomsPermissionsDataModel *roomsDataModel = [[SCURoomsPermissionsDataModel alloc] initWithUser:user];
    SCUUserPermissionsTableViewController *viewController = [[SCUUserPermissionsTableViewController alloc] initWithRoomsModel:roomsDataModel];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    viewController.title = NSLocalizedString(@"Rooms", nil);
    [self presentViewController:navController animated:YES completion:NULL];
}

- (void)showServiceBlacklistTableForUser:(SAVCloudUser *)user
{
    SCUServicesPermissionsDataModel *servicesModel = [[SCUServicesPermissionsDataModel alloc] initWithUser:user];
    SCUUserPermissionsTableViewController *viewController = [[SCUUserPermissionsTableViewController alloc] initWithServicesModel:servicesModel];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    viewController.title = NSLocalizedString(@"Services", nil);
    [self presentViewController:navController animated:YES completion:NULL];
}

- (void)setFirstResponderAtIndexPath:(NSIndexPath *)indexPath
{
    {
        SCUTextFieldProgressTableViewCell *cell = (SCUTextFieldProgressTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];

        if ([cell isKindOfClass:[SCUTextFieldProgressTableViewCell class]])
        {
            cell.fixed = NO;
            [cell.textField becomeFirstResponder];
            [cell.textField restore];
        }
    }

    for (NSIndexPath *ip in [self.tableView indexPathsForVisibleRows])
    {
        if ([ip isEqual:indexPath])
        {
            continue;
        }

        SCUTextFieldProgressTableViewCell *cell = (SCUTextFieldProgressTableViewCell *)[self.tableView cellForRowAtIndexPath:ip];

        if ([cell isKindOfClass:[SCUTextFieldProgressTableViewCell class]])
        {
            if (!cell.textField.errorMessage)
            {
                cell.fixed = YES;
                [cell configureWithInfo:[self.tableViewModel modelObjectForIndexPath:ip]];
            }
        }
    }
}

- (void)setDoneButtonAnimating:(BOOL)animating
{
    self.animatedDoneButton.animating = animating;
}

@end
