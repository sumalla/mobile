//
//  SCURangeViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 7/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCURangeViewController.h"
#import "SCURangeDataSource.h"
#import "SCUDateCell.h"
#import "SCUDatePickerCell.h"

@import Extensions;

@interface SCURangeViewController ()

@property SCURangeDataSource *model;
@property CGFloat pickerRowHeight;
@property NSIndexPath *pickerIndexPath;

@end

@implementation SCURangeViewController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.model = [[SCURangeDataSource alloc] init];
        self.pickerRowHeight = 162;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    //-------------------------------------------------------------------
    // Start with picker presented
    //-------------------------------------------------------------------
    NSIndexPath *firstIdx = [NSIndexPath indexPathForRow:0 inSection:0];
    [self tableView:self.tableView didSelectRowAtIndexPath:firstIdx];
    [self.tableView selectRowAtIndexPath:firstIdx animated:YES scrollPosition:UITableViewScrollPositionBottom];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL showNewPicker = (self.pickerIndexPath.row - 1 != indexPath.row);

    [self.tableView beginUpdates];

    //-------------------------------------------------------------------
    // If the index path selected is not presenting a picker, present the picker
    //-------------------------------------------------------------------
    if (showNewPicker)
    {
        if (self.pickerIndexPath)
        {
            NSIndexPath *deselectPath = [NSIndexPath indexPathForRow:(self.pickerIndexPath.row - 1)
                                                           inSection:self.pickerIndexPath.section];

            [self.tableView deselectRowAtIndexPath:deselectPath animated:YES];
            [self.tableView deleteRowsAtIndexPaths:@[self.pickerIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];

            //-------------------------------------------------------------------
            // Decrease the incoming row by 1, to handle the removed row
            //-------------------------------------------------------------------
            if (self.pickerIndexPath.row < indexPath.row)
            {
                indexPath = [NSIndexPath indexPathForRow:(indexPath.row - 1) inSection:indexPath.section];
            }
        }

        self.pickerIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1
                                                      inSection:indexPath.section];

        [self.tableView insertRowsAtIndexPaths:@[self.pickerIndexPath]
                              withRowAnimation:UITableViewRowAnimationFade];
    }

    self.model.pickerIndexPath = self.pickerIndexPath;

    [self.tableView endUpdates];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ([self.pickerIndexPath isEqual:indexPath] ? self.pickerRowHeight : self.tableView.rowHeight);
}

#pragma mark - Methods to subclass

- (void)configureCell:(SCUDefaultTableViewCell *)cell withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    switch (type)
    {
        case SCURangeDataSourceType_Range:
            cell.textLabel.highlightedTextColor = [[SCUColors shared] color01];
            cell.detailTextLabel.highlightedTextColor = [[SCUColors shared] color01];
            break;
        case SCURangeDataSourceType_Picker:
        {
            SCUDatePickerCell *pickerCell = (SCUDatePickerCell *)cell;

            SAVWeakSelf;
            pickerCell.datePicker.handler = ^(NSDate *date, NSTimeInterval seconds) {
                SAVStrongWeakSelf;
                NSDictionary *modelObject = [sSelf.model modelObjectForIndexPath:indexPath];
                SCURangeDateType type = [modelObject[SCUPickerCellKeyDateType] integerValue];
                switch (type)
                {
                    case SCURangeDateType_Start:
                        sSelf.model.startDate = date;
                        break;
                    case SCURangeDateType_End:
                        sSelf.model.endDate = date;
                        break;
                }

                NSIndexPath *selectedRow = [sSelf.tableView indexPathForSelectedRow];
                [sSelf.tableView reloadData];
                [sSelf.tableView selectRowAtIndexPath:selectedRow animated:NO scrollPosition:UITableViewScrollPositionNone];
            };
        }
            break;
    }
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUDateCell class] forCellType:SCURangeDataSourceType_Range];
    [self.tableView sav_registerClass:[SCUDatePickerCell class] forCellType:SCURangeDataSourceType_Picker];
}

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

#pragma mark - Properties

- (void)setEndOnly:(BOOL)endOnly
{
    self.model.endOnly = endOnly;
}

- (BOOL)endOnly
{
    return self.model.endOnly;
}

- (void)setStartDate:(NSDate *)startDate
{
    self.model.startDate = startDate;
    [self.tableView reloadData];
}

- (NSDate *)startDate
{
    return self.model.startDate;
}

- (void)setEndDate:(NSDate *)endDate
{
    self.model.endDate = endDate;
    [self.tableView reloadData];
}

- (NSDate *)endDate
{
    return self.model.endDate;
}

- (void)setMinDate:(NSDate *)endDate
{
    self.model.minDate = endDate;
}

- (NSDate *)minDate
{
    return self.model.endDate;
}

- (void)setDateFormat:(NSString *)dateFormat
{
    self.model.dateFormat = dateFormat;
}

- (NSString *)dateFormat
{
    return self.model.dateFormat;
}

- (void)setDatePickerFormat:(NSString *)datePickerFormat
{
    self.model.datePickerFormat = datePickerFormat;
}

- (NSString *)datePickerFormat
{
    return self.model.datePickerFormat;
}

@end
