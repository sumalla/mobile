//
//  SCUSensorTableViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 5/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSensorTableViewController.h"
#import "SCUSecuritySensorCell.h"
#import "SCUSecurityChartModel.h"
#import "SCUButton.h"

#import <SavantExtensions/SavantExtensions.h>

@interface SCUSensorTableViewController ()

@property (weak) SCUSecurityChartModel *model;

@end

@implementation SCUSensorTableViewController

- (instancetype)initWithModel:(SCUSecurityChartModel *)model
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self)
    {
        self.model = model;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorColor = [UIColor sav_colorWithRGBValue:0xffffff alpha:.05];
}

- (id <SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUSecuritySensorCell class] forCellType:0];
}

- (void)configureCell:(SCUDefaultTableViewCell *)cell withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    SCUSecuritySensorCell *sensorCell = (SCUSecuritySensorCell *)cell;

    SAVWeakSelf;
    [sensorCell.bypassButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        [wSelf.model bypassPressedForRow:indexPath.row bypass:!sensorCell.bypassButton.selected];
        sensorCell.bypassButton.selected = !sensorCell.bypassButton.selected;
    }];
}

@end
