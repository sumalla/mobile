//
//  SCUAVSettingsEqualizerPresetTableViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 5/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVSettingsEqualizerPresetTableViewController.h"
#import "SCUProgressTableViewCell.h"
#import "SCUTextFieldProgressTableViewCell.h"

@interface SCUAVSettingsEqualizerPresetTableViewController () <SCUAVSettingsEqualizerPresetModelDelegate>

@property (nonatomic) SCUAVSettingsEqualizerPresetModel *model;

@end

@implementation SCUAVSettingsEqualizerPresetTableViewController

- (instancetype)initWithModel:(SCUAVSettingsEqualizerPresetModel *)model
{
    self = [super init];

    if (self)
    {
        [self updateModel:model];
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Select a preset", nil);

    if ([UIDevice isPhone])
    {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(sav_dismiss)];
    }
}

- (void)updateModel:(SCUAVSettingsEqualizerPresetModel *)model
{
    self.model = model;
    self.model.delegate = self;
    [self.tableView reloadData];
}

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUProgressTableViewCell class] forCellType:SCUAVSettingsEqualizerPresetModelCellTypeFixed];
    [self.tableView sav_registerClass:[SCUTextFieldProgressTableViewCell class] forCellType:SCUAVSettingsEqualizerPresetModelCellTypeEditable];
}

- (void)configureCell:(SCUDefaultTableViewCell *)cell withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    if (type == SCUAVSettingsEqualizerPresetModelCellTypeEditable)
    {
        SCUTextFieldProgressTableViewCell *c = (SCUTextFieldProgressTableViewCell *)cell;
        c.fixed = YES;
        c.rightButtons = [self.model swipeButtonsForIndexPath:indexPath];

        if ([UIDevice isPad])
        {
            c.backgroundColor = [[SCUColors shared] color03shade01];
        }
        else
        {
            c.backgroundColor = [[SCUColors shared] color03shade07];
        }
    }
}

#pragma mark - SCUAVSettingsEqualizerPresetModelDelegate

- (void)dismiss
{
    [self sav_dismiss];
}

- (UITextField *)setEditing:(BOOL)editing forIndexPath:(NSIndexPath *)indexPath
{
    SCUTextFieldProgressTableViewCell *cell = (SCUTextFieldProgressTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];

    if (editing)
    {
        [cell closeAnimated:YES completion:^{
            cell.fixed = NO;
            [cell.textField becomeFirstResponder];
        }];
    }
    else
    {
        cell.fixed = YES;
        [cell.textField resignFirstResponder];
    }

    return cell.textField;
}

@end
