//
//  SCUClimateHistoryViewController.m
//  SavantController
//
//  Created by David Fairweather on 5/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUClimateHistoryViewController.h"
#import "SCUClimateHistoryModel.h"
#import "SCUPickerView.h"
#import "SCUButton.h"
#import "SCUTabBarController.h"
#import "SCUClimateHistoryWeekViewController.h"
#import "SCUClimateHistoryDayViewController.h"
#import "SCUPopoverController.h"
#import "SCURangeViewController.h"
#import "SCUClimateHistoryDataFilterViewController.h"

#import <SavantControl/SavantControl.h>

typedef NS_ENUM(NSInteger, SCUHVACHistoryType)
{
    SCUHVACHistoryType_Unknown = -1,
    SCUHVACHistoryType_Week = 0,
    SCUHVACHistoryType_Day = 1
};

#define kSecondsInDay 86400
#define kSecondsInWeek (kSecondsInDay * 7)
#define kSecondsInYear (kSecondsInWeek * 52)

@interface SCUClimateHistoryViewController () <SCUClimateHistoryDelegate, SCUPickerViewDelegate, UIPopoverControllerDelegate>

@property UIView *weekDayToggle;
@property SCUPickerView *rangePicker;
@property SCUButton *dataFilter;
@property SCUTabBarController *tabController;
@property NSArray *buttons;
@property NSTimeInterval currentStartDate, currentEndDate;
@property SCUHVACHistoryType currentType;
@property SCUPopoverController *popover;

@property (nonatomic, strong) SCUHVACPickerView *hvacPickerView;

@property NSArray *weekConstraints, *dayConstraints;

@property (nonatomic) SCUClimateHistoryModel *model;

@end

@implementation SCUClimateHistoryViewController

- (instancetype)initWithService:(SAVService *)service
{
    self = [super initWithService:service];
    if (self)
    {
        self.model = [[SCUClimateHistoryModel alloc] initWithService:service];
        self.model.delegate = self;
        [self setupViewControllers];
        self.hvacPickerView = [[SCUHVACPickerView alloc] initWithHVACPickerModel:self.model.hvacPickerModel];
    }
    return self;
}

#pragma mark - Tab Bar Controller
#pragma mark Center Toolbar Items

- (NSArray *)mainToolbarRightItems
{
    return @[[self.hvacPickerView labelOrHVACSelector]];
}

- (NSArray *)mainToolbarCenterItems
{
    return @[[self.hvacPickerView labelOrHVACSelector]];
}

- (SCUMainToolbarItems)mainToolbarItems
{
    SCUMainToolbarItems items = SCUMainToolbarItemsLeftButtons;
    if (!self.servicesFirst)
    {
        items = items | ([UIDevice isPad] ? SCUMainToolbarItemsCenterButtons : SCUMainToolbarItemsRightButtons);
    }
    return  items;
}

- (BOOL)hasHVACService
{
    return [self.hvacPickerView hasHVACService];
}

- (BOOL)hasHVACHistory
{
    return [self.hvacPickerView hasHVACHistory];
}

- (void)setupViewControllers
{

    self.tabController = [[SCUTabBarController alloc] init];
    
    SCUClimateHistoryWeekViewController *weekVC = [[SCUClimateHistoryWeekViewController alloc] initWithModel:self.model];
    SCUClimateHistoryDayViewController *dayVC = [[SCUClimateHistoryDayViewController alloc] initWithDataSource:self.model];
    
    self.tabController.viewControllers = @[weekVC, dayVC];
    self.tabController.toolbarHeight = 0;
    self.currentType = SCUHVACHistoryType_Unknown;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.currentEndDate = [[NSDate today] timeIntervalSince1970];
    self.currentStartDate = self.currentEndDate - (kSecondsInDay * 6);

    [self sav_addChildViewController:self.tabController];

    self.rangePicker = [[SCUPickerView alloc] initWithConfiguration:SCUPickerViewConfigurationTwoArrowsHorizontal];
    self.rangePicker.delegate = self;
    [self.rangePicker.centerButton defaultStyle];
    self.rangePicker.centerButton.selectedBackgroundColor = nil;
    self.rangePicker.centerButton.selectedColor = [[SCUColors shared] color01];
    self.rangePicker.centerButton.target = self;
    self.rangePicker.centerButton.releaseAction = @selector(rangePickerTapped:);
    self.rangePicker.centerButton.titleLabel.adjustsFontSizeToFitWidth = NO;
    self.rangePicker.centerButton.borderWidth = [UIScreen screenPixel];
    self.rangePicker.centerButton.borderColor = [[SCUColors shared] color03shade04];
    self.rangePicker.selectedTintColor = [[SCUColors shared] color01];
    [self.view addSubview:self.rangePicker];

    SCUButton *weekButton = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"Week", nil)];
    weekButton.selectedColor = [[SCUColors shared] color01];
    weekButton.titleLabel.font = ([UIDevice isPad]) ? [UIFont fontWithName:@"Gotham-Light" size:17] : [UIFont fontWithName:@"Gotham-Light" size:16];
    weekButton.selectedBackgroundColor = nil;
    weekButton.target = self;
    weekButton.releaseAction = @selector(toggleWeekView:);
    weekButton.borderWidth = [UIScreen screenPixel];
    weekButton.borderColor = [[SCUColors shared] color03shade04];

    SCUButton *dayButton = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"Day", nil)];
    dayButton.selectedColor = [[SCUColors shared] color01];
    dayButton.titleLabel.font = ([UIDevice isPad]) ? [UIFont fontWithName:@"Gotham-Light" size:17] : [UIFont fontWithName:@"Gotham-Light" size:16];
    dayButton.selectedBackgroundColor = nil;
    dayButton.target = self;
    dayButton.releaseAction = @selector(toggleDayView:);
    dayButton.borderWidth = [UIScreen screenPixel];
    dayButton.borderColor = [[SCUColors shared] color03shade04];

    SAVViewDistributionConfiguration *config = [[SAVViewDistributionConfiguration alloc] init];
    config.distributeEvenly = YES;
    config.minimumWidth = 0;
    config.interSpace = 4;

    self.buttons = @[weekButton, dayButton];

    self.weekDayToggle = [UIView sav_viewWithEvenlyDistributedViews:self.buttons withConfiguration:config];
    [self.view addSubview:self.weekDayToggle];

    self.dataFilter = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"Data", nil)];
    self.dataFilter.selectedColor = [[SCUColors shared] color01];
    self.dataFilter.selectedBackgroundColor = nil;
    self.dataFilter.target = self;
    self.dataFilter.releaseAction = @selector(dataFilterTapped:);
    self.dataFilter.borderWidth = [UIScreen screenPixel];
    self.dataFilter.borderColor = [[SCUColors shared] color03shade04];
    [self.view addSubview:self.dataFilter];

    NSDictionary *views = @{@"rangePicker": self.rangePicker,
                            @"content": self.tabController.view,
                            @"weekDayToggle": self.weekDayToggle,
                            @"dataFilter": self.dataFilter};

    if ([UIDevice isPad])
    {
        NSDictionary *metrics = @{@"contentInset": @15,
                                  @"leftInset": @11,
                                  @"topInset": @9,
                                  @"centerSpacing": @12,
                                  @"pickerHeight": @50,
                                  @"pickerWidth": @230,
                                  @"toggleWidth": @105};

        [self.view addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                           views:views
                                                                         formats:@[@"|-(leftInset)-[weekDayToggle(toggleWidth)]",
                                                                                   @"rangePicker.centerX = super.centerX",
                                                                                   @"rangePicker.width = pickerWidth",
                                                                                   @"V:|-(topInset)-[rangePicker(pickerHeight)]-(centerSpacing)-[content]|",
                                                                                   @"V:|-(topInset)-[weekDayToggle(rangePicker)]-(centerSpacing)-[content]|",
                                                                                   @"|-(contentInset)-[content]-(contentInset)-|"]]];

        self.dayConstraints = [NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                       views:views
                                                                     formats:@[@"[dataFilter(toggleWidth)]-(leftInset)-|",
                                                                               @"V:|-(topInset)-[dataFilter(rangePicker)]-(centerSpacing)-[content]|"]];
    }
    else
    {
        NSDictionary *metrics = @{@"spacing": @5,
                                  @"pickerHeight": @30,
                                  @"toggleWidth": @100,
                                  @"pickerDayWidth": @130,
                                  @"pickerWeekWidth": @200};

        [self.view addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                           views:views
                                                                         formats:@[@"V:|-(spacing)-[rangePicker(pickerHeight)]-(spacing)-[content]|",
                                                                                   @"V:|-(spacing)-[weekDayToggle(rangePicker)]-(spacing)-[content]|",
                                                                                   @"|[content]|"]]];

        self.weekConstraints = [NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                       views:views
                                                                     formats:@[@"|-(spacing)-[weekDayToggle(toggleWidth)]-(spacing)-[rangePicker(pickerWeekWidth)]-(spacing)-|"]];

        self.dayConstraints = [NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                       views:views
                                                                     formats:@[@"|-(spacing)-[weekDayToggle(toggleWidth)]-(spacing)-[rangePicker(pickerDayWidth)]-(spacing)-[dataFilter]-(spacing)-|",
                                                                               @"V:|-(spacing)-[dataFilter(rangePicker)]-(spacing)-[content]|"]];
    }

    //-------------------------------------------------------------------
    // Restore Saved View
    //-------------------------------------------------------------------
    if ([[SAVSettings localSettings] objectForKey:[self historySaveKey]])
    {
        SCUHVACHistoryType type = (SCUHVACHistoryType)[[[SAVSettings localSettings] objectForKey:[self historySaveKey]] integerValue];

        switch (type)
        {
            case SCUHVACHistoryType_Week:
                [self toggleWeekView:nil];
                break;
            case SCUHVACHistoryType_Day:
                [self toggleDayView:nil];
                break;
        }
    }
    else
    {
        [self toggleWeekView:nil];
    }
}

- (NSString *)historySaveKey
{
    return [SCUSavedTabsPrefix stringByAppendingString:@".hvacHistoryType"];
}

- (void)toggleWeekView:(SCUButton *)button
{
    if (self.currentType != SCUHVACHistoryType_Week)
    {
        [self.view removeConstraints:self.dayConstraints];

        if (self.weekConstraints)
        {
            [self.view removeConstraints:self.weekConstraints];
            [self.view addConstraints:self.weekConstraints];
        }

        self.dataFilter.hidden = YES;

        [self.buttons[SCUHVACHistoryType_Day] setSelected:NO];
        [self.buttons[SCUHVACHistoryType_Week] setSelected:YES];
        self.tabController.activeVC = self.tabController.viewControllers[SCUHVACHistoryType_Week];

        [[SAVSettings localSettings] setObject:@(SCUHVACHistoryType_Week) forKey:[self historySaveKey]];
        [[SAVSettings localSettings] synchronize];

        [self fetchWeekData];
        
        self.currentType = SCUHVACHistoryType_Week;
    }
}

- (void)toggleDayView:(SCUButton *)button
{
    if (self.currentType != SCUHVACHistoryType_Day)
    {
        if (self.weekConstraints)
        {
            [self.view removeConstraints:self.weekConstraints];
        }

        [self.view removeConstraints:self.dayConstraints];
        [self.view addConstraints:self.dayConstraints];
        self.dataFilter.hidden = NO;

        [self.buttons[SCUHVACHistoryType_Week] setSelected:NO];
        [self.buttons[SCUHVACHistoryType_Day] setSelected:YES];
        self.tabController.activeVC = self.tabController.viewControllers[SCUHVACHistoryType_Day];

        [[SAVSettings localSettings] setObject:@(SCUHVACHistoryType_Day) forKey:[self historySaveKey]];
        [[SAVSettings localSettings] synchronize];

        [self fetchDayData];
        
        self.currentType = SCUHVACHistoryType_Day;
    }
}

- (void)dataFilterTapped:(SCUButton *)sender
{
    if (self.currentType == SCUHVACHistoryType_Day)
    {
        sender.selected = YES;
        SCUClimateHistoryDayViewController *dayViewController = (SCUClimateHistoryDayViewController *)self.tabController.activeVC;

        SCUClimateHistoryDataFilterViewController *dataFilter = [[SCUClimateHistoryDataFilterViewController alloc] initWithDelegate:dayViewController];

        self.popover = [[SCUPopoverController alloc] initWithContentViewController:dataFilter];
        self.popover.delegate = self;
        self.popover.backgroundColor = [UIColor sav_colorWithRGBValue:0x333333];
        self.popover.popoverContentSize = CGSizeMake(320, 250);
        [self.popover presentPopoverFromRect:sender.frame
                                      inView:[sender superview]
                    permittedArrowDirections:UIPopoverArrowDirectionUp
                                    animated:YES];
        
    }
}

- (void)rangePickerTapped:(SCUButton *)sender
{
    sender.selected = YES;
    SCURangeViewController *rangeVC = [[SCURangeViewController alloc] init];
    
    rangeVC.endDate = [NSDate dateWithTimeIntervalSince1970:self.currentEndDate];
    rangeVC.minDate = [NSDate dateWithTimeIntervalSince1970:[[NSDate today] timeIntervalSince1970] - (6 * kSecondsInYear)];

    if (self.currentType == SCUHVACHistoryType_Day)
    {
        rangeVC.endOnly = YES;
    }

    self.popover = [[SCUPopoverController alloc] initWithContentViewController:rangeVC];
    self.popover.delegate = self;
    self.popover.backgroundColor = [UIColor sav_colorWithRGBValue:0x333333];
    self.popover.popoverContentSize = CGSizeMake(320, 250);
    [self.popover presentPopoverFromRect:sender.frame
                                  inView:[sender superview]
                permittedArrowDirections:UIPopoverArrowDirectionUp
                                animated:YES];
}

- (void)fetchWeekData
{
    [self.model fetchStageDataFromStartTime:self.currentStartDate toEndTime:self.currentEndDate];

    self.rangePicker.title = [NSString stringWithFormat:@"%@ - %@", [self dateStringFromDateStamp:self.currentStartDate], [self dateStringFromDateStamp:self.currentEndDate]];
}

- (void)fetchDayData
{
    [self.model fetchAllDataForTime:self.currentEndDate];

    self.rangePicker.title = [self dateStringFromDateStamp:self.currentEndDate];
}

- (void)fetchCurrentData
{
    switch (self.currentType)
    {
        case SCUHVACHistoryType_Week:
            [self fetchWeekData];
            break;
        case SCUHVACHistoryType_Day:
            [self fetchDayData];
            break;
    }
}

- (NSString *)dateStringFromDateStamp:(NSTimeInterval)dateStamp
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:dateStamp];

    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateStyle = NSDateFormatterShortStyle;

    return [df stringFromDate:date];
}

#pragma mark - Picker View Delegate

- (void)pickerView:(SCUPickerView *)pickerView didSelectArrowWithDirection:(SCUPickerViewDirection)direction
{
    BOOL fetch = YES;

    CGFloat pickerOffest = 0;

    switch (self.currentType)
    {
        case SCUHVACHistoryType_Week:
            pickerOffest = kSecondsInWeek;
            break;
        case SCUHVACHistoryType_Day:
            pickerOffest = kSecondsInDay;
            break;
    }

    switch (direction)
    {
        case SCUPickerViewDirectionUp:
        case SCUPickerViewDirectionDown:
            break;
        case SCUPickerViewDirectionLeft:
        {
            NSTimeInterval sixYearsAgo = [[NSDate today] timeIntervalSince1970] - (6 * kSecondsInYear);
            
            if (self.currentEndDate > sixYearsAgo)
            {
                self.currentEndDate = self.currentEndDate - pickerOffest;
                self.currentStartDate = self.currentStartDate - pickerOffest;
            }
        }
            break;
        case SCUPickerViewDirectionRight:
        {
            NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:self.currentEndDate];

            NSTimeInterval today = [[NSDate today] timeIntervalSince1970];

            if (![endDate isToday])
            {
                self.currentEndDate = self.currentEndDate + pickerOffest;
                self.currentStartDate = self.currentStartDate + pickerOffest;
            }
            else
            {
                fetch = NO;
            }

            //-------------------------------------------------------------------
            // Don't allow selection of future dates
            //-------------------------------------------------------------------
            if (self.currentEndDate > today)
            {
                NSTimeInterval diff = self.currentEndDate - today;

                self.currentEndDate -= diff;
                self.currentStartDate -= diff;
            }
        }
            break;
    }

    if (fetch)
    {
        [self fetchCurrentData];
    }

}

#pragma mark - Climate History Model Delegate

- (void)reloadData
{
    switch (self.currentType)
    {
        case SCUHVACHistoryType_Week:
        {
            SCUClimateHistoryWeekViewController *weekViewController = (SCUClimateHistoryWeekViewController *)self.tabController.activeVC;
            [weekViewController.collectionView reloadData];
        }
            break;
        case SCUHVACHistoryType_Day:
        {
            SCUClimateHistoryDayViewController *dayViewController = (SCUClimateHistoryDayViewController *)self.tabController.activeVC;
            [dayViewController reloadData];
        }
            break;
    }
}

#pragma mark - Popover Delegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if ([popoverController.contentViewController isKindOfClass:[SCURangeViewController class]])
    {
        self.rangePicker.centerButton.selected = NO;

        SCURangeViewController *rangeVC = (SCURangeViewController *)popoverController.contentViewController;
        NSTimeInterval newEndDate = [rangeVC.endDate timeIntervalSince1970];
        NSTimeInterval newStartDate = [rangeVC.startDate timeIntervalSince1970];

        if (self.currentEndDate != newEndDate)
        {
            self.currentEndDate = newEndDate;
            self.currentStartDate = newStartDate;
            
            [self fetchCurrentData];
        }
    }
    else
    {
        self.dataFilter.selected = NO;
    }

    self.popover = nil;
}

#pragma mark - Tab Bar

- (UIImage *)tabBarIcon
{
    return [UIImage imageNamed:@"history"];
}

- (UIColor *)tabBarButtonColor
{
    return [[SCUColors shared] color01];
}

#pragma mark - SCUMainToolbarManager

- (BOOL)mainToolbarIsVisible
{
    return [UIDevice isPad];
}

@end
