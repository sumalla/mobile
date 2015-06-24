//
//  SCUGenericCOmmandTableViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 10/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUGenericCommandTableViewController.h"
#import "SCUGenericCommandTableModel.h"

@interface SCUGenericCommandTableViewController ()

@property (nonatomic) SCUGenericCommandTableModel *model;

@end

@implementation SCUGenericCommandTableViewController

- (instancetype)initWithCommands:(NSArray *)commands
{
    self = [super init];

    if (self)
    {
        self.model = [[SCUGenericCommandTableModel alloc] initWithCommands:commands];
    }

    return self;
}

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Commands", nil);
    self.tableView.rowHeight = 60;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"x"]
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(dismiss)];
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
