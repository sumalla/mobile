//
//  SCUSignInTableViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSignInTableViewController.h"
#import "SCUTextFieldProgressTableViewCell.h"
#import "SCUTextFieldProgressTableViewCell.h"
#import "SCUSignInFixedTableViewCell.h"

@interface SCUSignInTableViewController () <SCUSignInViewModelDelegate>

@property (nonatomic) SCUSignInViewModel *model;

@end

@implementation SCUSignInTableViewController

- (instancetype)initWithModel:(SCUSignInViewModel *)model
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

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self.model action:@selector(signIn)];
    self.navigationItem.rightBarButtonItem.tintColor = [[SCUColors shared] color01];

    if (self.forceCancel || ([UIDevice isPad] && !self.isInNavigationController))
    {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(sav_dismiss)];
    }

    self.tableView.rowHeight = 60;
}

#pragma mark - Methods to subclass

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUSignInFixedTableViewCell class] forCellType:SCUSignInViewModelCellTypeFixed];
    [self.tableView sav_registerClass:[SCUTextFieldProgressTableViewCell class] forCellType:SCUSignInViewModelCellTypeEditable];
}

- (void)configureCell:(SCUDefaultTableViewCell *)cell withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    SCUSignInViewModelCellType cellType = (SCUSignInViewModelCellType)type;

    switch (cellType)
    {
        case SCUSignInViewModelCellTypeFixed:
            break;
        case SCUSignInViewModelCellTypeEditable:
            [self.model listenToTextField:((SCUTextFieldProgressTableViewCell *)cell).textField forIndexPath:indexPath];
            break;
    }
}

#pragma mark - SCUSignInViewModelDelegate methods

- (void)setFirstResponderForIndexPath:(NSIndexPath *)indexPath
{
    SCUTextFieldProgressTableViewCell *cell = (SCUTextFieldProgressTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];

    if ([cell isKindOfClass:[SCUTextFieldProgressTableViewCell class]])
    {
        [cell.textField becomeFirstResponder];
    }
}

- (void)endEditing
{
    [self.view endEditing:YES];
}

- (void)reloadIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)updateTitle:(NSString *)title
{
    self.title = title;
}

@end
