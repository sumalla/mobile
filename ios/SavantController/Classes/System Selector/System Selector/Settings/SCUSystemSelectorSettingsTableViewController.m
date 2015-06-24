//
//  SCUSystemSelectorSettingsTableViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 8/25/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSystemSelectorSettingsTableViewController.h"
#import "SCUSystemSelectorSettingsModel.h"
@import MessageUI;

@interface SCUSystemSelectorSettingsTableViewController () <SCUSystemSelectorSettingsModelDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic) SCUSystemSelectorSettingsModel *model;

@end

@implementation SCUSystemSelectorSettingsTableViewController

@synthesize swingingDelegate = _swingingDelegate;

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.swingingDelegate contentOffsetDidChange:scrollView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.model = [[SCUSystemSelectorSettingsModel alloc] init];
    self.model.delegate = self;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 40)];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = [self.model version];
    label.textColor = [[SCUColors shared] color04];
    label.font = [UIFont systemFontOfSize:14];
    self.tableView.tableFooterView = label;
    self.tableView.sectionFooterHeight = 1;
    self.tableView.sectionHeaderHeight = 1;
}

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)configureCell:(SCUDefaultTableViewCell *)cell withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [[SCUColors shared] color03];
}

#pragma mark - SCUSystemSelectorSettingsModelDelegate methods

- (void)presentActionSheet:(SCUActionSheet *)actionSheet
{
    [actionSheet showInView:[UIView sav_topView]];
}

- (void)presentMailComposeVC:(MFMailComposeViewController *)viewController
{
    viewController.mailComposeDelegate = self;
    viewController.navigationBar.tintColor = [[SCUColors shared] color04];
    viewController.modalPresentationStyle = UIModalPresentationFormSheet;

    [self presentViewController:viewController animated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    }];
}

#pragma mark - MFMailComposeViewControllerDelegate methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
