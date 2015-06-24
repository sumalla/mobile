//
//  SCUSchedulingDayViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 7/14/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSchedulingDayViewController.h"
#import "SCUSchedulingDayModel.h"
#import "SCUDateCell.h"
#import "SCUDatePickerCell.h"
#import "SCUSchedulingToggleCell.h"
#import "SCUDayPickerCell.h"
#import <SavantControl/SAVClimateSchedule.h>

@interface SCUSchedulingDayViewController ()

@property SCUSchedulingDayModel *model;
@property NSIndexPath *pickerIndexPath;

@end

@implementation SCUSchedulingDayViewController

- (instancetype)initWithSchedule:(SAVClimateSchedule *)schedule
{
    self = [super init];
    if (self)
    {
        self.model = [[SCUSchedulingDayModel alloc] initWithSchedule:schedule];
        self.model.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.rowHeight = 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCUSchedulingDayCellType type = [self.model cellTypeForIndexPath:indexPath];

    switch (type)
    {
        case SCUSchedulingDayCellType_Date:
        case SCUSchedulingDayCellType_Days:
        {
            BOOL showNewPicker = (self.pickerIndexPath.row - 1 != indexPath.row);

            [self.tableView beginUpdates];

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

                self.pickerIndexPath = nil;
            }

            //-------------------------------------------------------------------
            // If the index path selected is not presenting a picker, present the picker
            //-------------------------------------------------------------------
            if (showNewPicker)
            {
                self.pickerIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1
                                                          inSection:indexPath.section];

                [self.tableView insertRowsAtIndexPaths:@[self.pickerIndexPath]
                                      withRowAnimation:UITableViewRowAnimationFade];
            }
            
            self.model.pickerIndexPath = self.pickerIndexPath;

            [self.tableView endUpdates];

            [self.delegate reloadData];
        }
            break;
        case SCUSchedulingDayCellType_AllYear:
        case SCUSchedulingDayCellType_Picker:
        case SCUSchedulingDayCellType_DayPicker:
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellHeight = 0;

    SCUSchedulingDayCellType type = [self.model cellTypeForIndexPath:indexPath];

    switch (type)
    {
        case SCUSchedulingDayCellType_AllYear:
        case SCUSchedulingDayCellType_Date:
        case SCUSchedulingDayCellType_Days:
        case SCUSchedulingDayCellType_DayPicker:
            cellHeight = self.tableView.rowHeight;
            break;
        case SCUSchedulingDayCellType_Picker:
            cellHeight = 162;
            break;
    }

    return cellHeight;
}

- (CGFloat)estimatedHeight
{
    CGFloat height = [super estimatedHeight];

    if ([self.model cellTypeForIndexPath:self.pickerIndexPath] == SCUSchedulingDayCellType_Picker)
    {
        height += 102;
    }

    return height;
}

#pragma mark - Methods to subclass

- (void)configureCell:(SCUDefaultTableViewCell *)cell withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    [super configureCell:cell withType:type indexPath:indexPath];

    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    switch (type)
    {
        case SCUSchedulingDayCellType_Picker:
        {
            SCUDatePickerCell *pickerCell = (SCUDatePickerCell *)cell;

            SAVWeakSelf;
            pickerCell.datePicker.handler = ^(NSDate *date, NSTimeInterval seconds){
                NSDictionary *modelObject = [wSelf.model modelObjectForIndexPath:indexPath];
                SCUSchedulingDayType type = [modelObject[SCUPickerCellKeyDateType] integerValue];
                switch (type)
                {
                    case SCUSchedulingDayType_Start:
                        wSelf.model.startDate = date;
                        break;
                    case SCUSchedulingDayType_End:
                        wSelf.model.endDate = date;
                        break;
                }

                [wSelf reloadData];
            };
        }
            break;
        case SCUSchedulingDayCellType_AllYear:
        {
            SCUSchedulingToggleCell *toggleCell = (SCUSchedulingToggleCell *)cell;

            SAVWeakSelf;
            toggleCell.toggleSwitch.sav_didChangeHandler = ^(BOOL on){
                if (wSelf.model.schedule.isAllYear != on)
                {
                    if (on != self.model.schedule.isAllYear)
                    {
                        self.pickerIndexPath = nil;
                        self.model.pickerIndexPath = nil;

                        if (on)
                        {
                            wSelf.model.schedule.dateRange = nil;
                        }
                        else
                        {
                            NSDateFormatter *df = [[NSDateFormatter alloc] init];
                            df.dateFormat = @"MM/dd/yyyy hh:mm:ss";

                            wSelf.model.schedule.dateRange = @{@"endDate": [df stringFromDate:wSelf.model.endDate], @"startDate": [df stringFromDate:wSelf.model.startDate]};
                        }

                        [wSelf reloadData];
                    }
                }
            };
        }
            break;
        case SCUSchedulingDayCellType_DayPicker:
        {
            SCUDayPickerCell *dayPickerCell = (SCUDayPickerCell *)cell;

            SAVWeakSelf;
            dayPickerCell.callback = ^(SCUDayPickerDays selectedDays){
                if (selectedDays == SCUDayPickerDays_None)
                {
                    wSelf.model.schedule.days = nil;
                }
                else
                {
                    NSMutableArray *days = [NSMutableArray array];

                    if (selectedDays & SCUDayPickerDays_Sunday)
                    {
                        [days addObject:@(SAVClimateScheduleDay_Sunday)];
                    }

                    if (selectedDays & SCUDayPickerDays_Monday)
                    {
                        [days addObject:@(SAVClimateScheduleDay_Monday)];
                    }

                    if (selectedDays & SCUDayPickerDays_Tuesday)
                    {
                        [days addObject:@(SAVClimateScheduleDay_Tuesday)];
                    }

                    if (selectedDays & SCUDayPickerDays_Wednesday)
                    {
                        [days addObject:@(SAVClimateScheduleDay_Wednesday)];
                    }

                    if (selectedDays & SCUDayPickerDays_Thursday)
                    {
                        [days addObject:@(SAVClimateScheduleDay_Thursday)];
                    }
                    
                    if (selectedDays & SCUDayPickerDays_Friday)
                    {
                        [days addObject:@(SAVClimateScheduleDay_Friday)];
                    }
                    
                    if (selectedDays & SCUDayPickerDays_Saturday)
                    {
                        [days addObject:@(SAVClimateScheduleDay_Saturday)];
                    }

                    wSelf.model.schedule.days = days;
                }

                [wSelf reloadData];
            };
        }
            break;
    }
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUDateCell class] forCellType:SCUSchedulingDayCellType_Date];
    [self.tableView sav_registerClass:[SCUDatePickerCell class] forCellType:SCUSchedulingDayCellType_Picker];
    [self.tableView sav_registerClass:[SCUDefaultTableViewCell class] forCellType:SCUSchedulingDayCellType_Days];
    [self.tableView sav_registerClass:[SCUSchedulingToggleCell class] forCellType:SCUSchedulingDayCellType_AllYear];
    [self.tableView sav_registerClass:[SCUDayPickerCell class] forCellType:SCUSchedulingDayCellType_DayPicker];
}

- (id<SCUExpandableDataSourceModel>)tableViewModel
{
    return self.model;
}

@end
