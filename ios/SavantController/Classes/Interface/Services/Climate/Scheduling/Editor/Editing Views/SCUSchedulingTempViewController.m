    //
//  SCUSchedulingTempViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 7/14/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSchedulingTempViewController.h"
#import "SCUSchedulingTempModel.h"
#import "SCUSchedulingPickerCell.h"
#import "SCURangeViewController.h"
#import "SCUPopoverController.h"
#import "SCUPopoverMenu.h"
#import "SCUButton.h"
#import "SCUActionSheet.h"

#import <SavantControl/SAVClimateSchedule.h>

@interface SCUSchedulingTempViewController () <UIPopoverControllerDelegate>

@property SCUSchedulingTempModel *model;
@property SCUPopoverController *popover;

@end

@implementation SCUSchedulingTempViewController

- (instancetype)initWithSchedule:(SAVClimateSchedule *)schedule
{
    self = [super init];
    if (self)
    {
        self.model = [[SCUSchedulingTempModel alloc] initWithSchedule:schedule];
        self.model.delegate = self;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.model.possibleModes = [self.model getPossibleModes];
    [self reloadData];
}

- (id<SCUExpandableDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.rowHeight = 250;
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUSchedulingPickerCell class] forCellType:0];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = self.tableView.rowHeight;
    
    NSDictionary *modelObject = [[self tableViewModel] modelObjectForIndexPath:indexPath];
    SCUSchedulingPickerCellType type = [modelObject[SCUSchedulingPickerCellKeyCellType] integerValue];

    if (!modelObject)
    {
        height = 44;
    }
    
    switch (type)
    {
        case SCUSchedulingPickerCellTypeAdd:
        case SCUSchedulingPickerCellTypeMode:
            height = 44;
    }
    
    return height;
}

- (NSArray *)buttonTitlesForModes
{
    NSMutableArray *titles = [NSMutableArray array];
    
    for (id mode in self.model.possibleModes)
    {
        [titles addObject:[self.model nameForScheduleMode:[mode integerValue]]];
    }
    
    return titles;
}

- (void)reconfigureIndexPath:(NSIndexPath *)fromIndex toIndexPath:(NSIndexPath *)toIndex
{
    SCUSchedulingPickerCell *cell = (SCUSchedulingPickerCell *)[self.tableView cellForRowAtIndexPath:fromIndex];
    [cell configureWithInfo:[self.model modelObjectForIndexPath:fromIndex]];

    SAVWeakSelf;
    [cell.timeButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        SCURangeViewController *rangeVC = [[SCURangeViewController alloc] init];
        rangeVC.endOnly = YES;
        rangeVC.dateFormat = @"h:mm a";
        rangeVC.datePickerFormat = @"hmma";
        rangeVC.view.tag = toIndex.row;
        rangeVC.endDate = [self.model timeForRow:toIndex.row];
        
        wSelf.popover = [[SCUPopoverController alloc] initWithContentViewController:rangeVC];
        wSelf.popover.delegate = self;
        wSelf.popover.backgroundColor = [UIColor sav_colorWithRGBValue:0x333333];
        wSelf.popover.popoverContentSize = CGSizeMake(320, 250);
        [wSelf.popover presentPopoverFromButton:cell.timeButton
                       permittedArrowDirections:UIPopoverArrowDirectionAny
                                       animated:YES];
    }];
}

- (NSIndexPath *)indexPathForCell:(UITableViewCell *)cell
{
    return [self.tableView indexPathForCell:cell];
}

- (void)reorderIndexPathsWithData:(NSArray *)newData
{
    CGFloat duration = 0.55;
    [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:0.95 initialSpringVelocity:5 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [self.tableView beginUpdates];
        
        NSArray *oldData = (self.model.isHumidityModel) ? self.model.schedule.humiditySetPoints : self.model.schedule.temperatureSetPoints;
        
        for (NSInteger i = 0; i < (long)newData.count; i++)
        {
            NSUInteger newRow = [newData indexOfObject:oldData[i]];
            
            NSInteger buffer = self.model.modePresent ? 1 : 0;

            NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:newRow + buffer inSection:0];
            NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:i + buffer inSection:0];
            
            [self reconfigureIndexPath:oldIndexPath toIndexPath:newIndexPath];

            if (![newIndexPath isEqual:oldIndexPath])
            {
                [self.tableView moveRowAtIndexPath:oldIndexPath toIndexPath:newIndexPath];
                
            }
            
            [self.model configureCell:[self cellForRowAtIndexPath:newIndexPath] withType:0 indexPath:newIndexPath];
        }
        
        [self.tableView endUpdates];
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    [super configureCell:c withType:type indexPath:indexPath];

    SCUSchedulingPickerCell *cell = (SCUSchedulingPickerCell *)c;

    SAVWeakSelf;
    [cell.timeButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        SCURangeViewController *rangeVC = [[SCURangeViewController alloc] init];
        rangeVC.endOnly = YES;
        rangeVC.dateFormat = @"h:mm a";
        rangeVC.datePickerFormat = @"hmma";
        rangeVC.view.tag = indexPath.row;
        rangeVC.endDate = [self.model timeForRow:indexPath.row];

        wSelf.popover = [[SCUPopoverController alloc] initWithContentViewController:rangeVC];
        wSelf.popover.delegate = self;
        wSelf.popover.backgroundColor = [UIColor sav_colorWithRGBValue:0x333333];
        wSelf.popover.popoverContentSize = CGSizeMake(320, 250);
        [wSelf.popover presentPopoverFromButton:cell.timeButton
                       permittedArrowDirections:UIPopoverArrowDirectionAny
                                       animated:YES];
    }];
    
    [cell.modeButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        NSArray *buttonTitles = [self buttonTitlesForModes];
        if (buttonTitles.count)
        {
            SCUActionSheet *actionSheet = [[SCUActionSheet alloc] initWithButtonTitles:buttonTitles];
            [actionSheet showFromRect:cell.modeButton.frame inView:self.view withMaxWidth:320.0f];
            
            [actionSheet setCallback:^(NSInteger buttonIndex) {
                [self.model setModeAtIndex:buttonIndex];
                [self reloadData];
            }];
        }
    }];
}

#pragma mark - Popover Delegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    SCURangeViewController *rangeVC = (SCURangeViewController *)popoverController.contentViewController;
    [self.model setTime:rangeVC.endDate forRow:rangeVC.view.tag];
    
    // TODO: This adds an extra cell for some reason. Will investigate at a later date
//    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:newRow inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];

    self.popover = nil;
}

- (CGFloat)estimatedHeight
{
    return ([self.model numberOfItemsInSection:0] - 1) * [self tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] + [self tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
}

@end
