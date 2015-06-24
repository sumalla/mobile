//
//  SCUAVSettingsEqualizerSendToTableViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 5/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVSettingsEqualizerSendToTableViewController.h"
#import "SCUProgressTableViewCell.h"

@interface SCUAVSettingsEqualizerSendToTableViewController ()

@property (nonatomic) SCUAVSettingsEqualizerSendToModel *model;

@end

@implementation SCUAVSettingsEqualizerSendToTableViewController

- (instancetype)initWithModel:(SCUAVSettingsEqualizerSendToModel *)model
{
    self = [super init];

    if (self)
    {
        self.model = model;
    }

    return self;
}

- (void)updateModel:(SCUAVSettingsEqualizerSendToModel *)model
{
    self.model = model;
    [self.tableView reloadData];
    self.title = self.model.title;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = self.model.title;

    if ([UIDevice isPhone])
    {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
    }
}

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUProgressTableViewCell class] forCellType:0];
}

#pragma mark -

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
