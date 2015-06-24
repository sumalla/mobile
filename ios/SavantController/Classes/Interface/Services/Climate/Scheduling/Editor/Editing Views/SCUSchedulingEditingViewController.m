//
//  SCUSchedulingEditingViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 7/14/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSchedulingEditingViewController.h"
#import "SCUSchedulingEditingModel.h"
#import "SCUSchedulingDayViewController.h"
#import "SCUSchedulingRoomsViewController.h"
#import "SCUSchedulingTempViewController.h"
#import "SCUSchedulingHumidityViewController.h"

@interface SCUSchedulingEditingViewController ()

@end

@implementation SCUSchedulingEditingViewController

+ (Class)classForType:(SCUSchedulingEditorType)type
{
    Class c = Nil;

    switch (type)
    {
        case SCUSchedulingEditorType_Days:
            c = [SCUSchedulingDayViewController class];
            break;
        case SCUSchedulingEditorType_Rooms:
            c = [SCUSchedulingRoomsViewController class];
            break;
        case SCUSchedulingEditorType_Humidity:
            c = [SCUSchedulingHumidityViewController class];
            break;
        case SCUSchedulingEditorType_Temp:
            c = [SCUSchedulingTempViewController class];
            break;
    }

    if (!c)
    {
        c = [self class];
    }

    return c;
}

+ (instancetype)editingViewControllerForType:(SCUSchedulingEditorType)type andSchedule:(SAVClimateSchedule *)schedule
{
    return [[[SCUSchedulingEditingViewController classForType:type] alloc] initWithSchedule:schedule];;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, .01)];
    self.tableView.scrollEnabled = [UIDevice isPad];
}

- (void)configureCell:(SCUDefaultTableViewCell *)cell withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    UIView *divider = [[UIView alloc] initWithFrame:CGRectZero];
    divider.backgroundColor = [[[SCUColors shared] color04] colorWithAlphaComponent:.2];
    cell.backgroundColor = [[SCUColors shared] color03shade03];

    cell.customSeparator = divider;

    [cell.contentView sav_pinView:divider withOptions:SAVViewPinningOptionsCenterX|SAVViewPinningOptionsToBottom];
    [cell.contentView sav_setHeight:[UIScreen screenPixel] forView:divider isRelative:NO];
    [cell.contentView sav_setWidth:1 forView:divider isRelative:YES];
}

- (instancetype)initWithSchedule:(SAVClimateSchedule *)schedule
{
    return [super init];
}

- (CGFloat)estimatedHeight
{
    return [self tableView:self.tableView numberOfRowsInSection:0] * self.tableView.rowHeight;
}

- (void)reloadData
{
    [self.tableView reloadData];
    [self.delegate reloadData];
}

- (UITableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.tableView cellForRowAtIndexPath:indexPath];
}

- (void)reloadRowAtIndexPath:(NSIndexPath *)indexPath withRowAnimation:(UITableViewRowAnimation)animation
{
    if (indexPath)
    {
        if ([self.tableView numberOfRowsInSection:indexPath.section])
        {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:animation];
        }
        
        [self.delegate reloadData];
        [self reconfigureCells];
    }
}

- (void)reconfigureIndexPath:(NSIndexPath *)indexPath
{
    SCUDefaultTableViewCell *cell = (SCUDefaultTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell configureWithInfo:[self.tableViewModel modelObjectForIndexPath:indexPath]];
}

- (void)reloadRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath)
    {
        [self reloadRowAtIndexPath:indexPath withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)insertRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath)
    {
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
        if ([UIDevice isPad])
        {
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
        }
        [self.delegate reloadData];
        [self reconfigureCells];        
    }
}

- (void)deleteRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath)
    {
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
        [self.delegate reloadData];
        [self reconfigureCells];
    }
}

@end
