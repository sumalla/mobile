//
//  SCUClimateServiceViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUClimateServiceViewController.h"
#import "SCUClimateViewControllerPrivate.h"
#import "SCUClimateViewController.h"
#import "SCUClimateHumidityViewController.h"
#import "SCUClimateHistoryViewController.h"
#import "SCUTemperatureViewController.h"
#import "SCUToolbarButton.h"
#import "SCUSchedulingModel.h"
#import "SCUPopoverController.h"
#import "SCUScheduleTableViewController.h"
#import "SCUThemedNavigationViewController.h"
#import "SCUInterface.h"
#import "SCUIconWithTextView.h"

@interface SCUClimateServiceViewController () <SCUClimateSchedulingModelDelegate, UIPopoverControllerDelegate>

@property UILabel *scheduleLabel;
@property SCUIconWithTextView *schedulerView;
@property SCUToolbarButton *scheduleButton;
@property SCUSchedulingModel *schedulingModel;
@property SCUPopoverController *popover;
@property SAVService *climateService;

@end

@implementation SCUClimateServiceViewController

- (instancetype)initWithService:(SAVService *)service
{
    self = [super initWithService:service];
    if (self)
    {
        self.climateService = service;
        self.schedulingModel = [[SCUSchedulingModel alloc] initWithService:service];
        [self.schedulingModel addDelegate:self];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    SAVService *climateService = self.service;
    SCUClimateViewController *temperatureVC = [[DeviceClassFromClass([SCUTemperatureViewController class]) alloc] initWithService:climateService];
    SCUClimateViewController *humidityVC = [[DeviceClassFromClass([SCUClimateHumidityViewController class]) alloc] initWithService:climateService];
    SCUClimateHistoryViewController *historyVC = [[DeviceClassFromClass([SCUClimateHistoryViewController class]) alloc] initWithService:climateService];

    self.defaultVC = temperatureVC;

    NSMutableArray *viewControllers = [[NSMutableArray alloc] initWithCapacity:3];
    if (temperatureVC.hasHVACService)
    {
        [viewControllers addObject:temperatureVC];
    }
    if (humidityVC.hasHVACService)
    {
        [viewControllers addObject:humidityVC];
    }
    if (historyVC.hasHVACHistory)
    {
        [viewControllers addObject:historyVC];
    }
    
    self.viewControllers = viewControllers;
    
    temperatureVC.model.hvacPickerModel.schedulingDelegate = self.schedulingModel;
    humidityVC.model.hvacPickerModel.schedulingDelegate = self.schedulingModel;
    
    NSString *schedulerTitle = [self assignedSchduleTitle];
    
    self.schedulerView = [[SCUIconWithTextView alloc] initWithFrame:CGRectZero andImage:[UIImage sav_imageNamed:@"schedule" tintColor:[[SCUColors shared] color04]] andText:schedulerTitle];
    self.schedulerView.clipsToBounds = YES;
    
    self.scheduleButton = [[SCUToolbarButton alloc] initWithCustomView:self.schedulerView];
    self.scheduleButton.selectedColor = [[SCUColors shared] color01];
    self.scheduleButton.target = self;
    self.scheduleButton.releaseAction = @selector(presentScheduler:);
    
    self.schedulerView.selectedColor = self.scheduleButton.selectedColor;
    self.schedulerView.backgroundColor = self.scheduleButton.backgroundColor;
    self.schedulerView.color = self.scheduleButton.color;
    self.schedulerView.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h9];

    NSString *scheduleMode = [[SavantControl sharedControl].data stringPropertyForManifestKey:@"hvacMode"];

    if ([scheduleMode isEqualToString:@"classic"])
    {
        self.scheduleButton.hidden = YES;
    }
}

- (NSArray *)mainToolbarLeftItems
{
    return @[self.scheduleButton];
}

- (void)presentScheduler:(SCUButton *)sender
{
    if (self.popover.isPopoverVisible)
    {
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    }
    else
    {
        SCUScheduleTableViewController *tvc = [[SCUScheduleTableViewController alloc] initWithModel:self.schedulingModel andType:SCUScheduleTableType_Active];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:tvc];

        self.popover = [[SCUPopoverController alloc] initWithContentViewController:navController];
        self.popover.backgroundColor = [UIColor sav_colorWithRGBValue:0x333333];
        self.popover.delegate = self;
        [self.popover presentPopoverFromButton:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        sender.selected = YES;
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
    self.scheduleButton.selected = NO;
}

- (NSString *)assignedSchduleTitle
{
    NSString *zoneName = [[SAVSettings localSettings] objectForKey:[NSString stringWithFormat:@"%@.currentHVACZone", [SCUInterface sharedInstance].currentRoom.roomId]];
    BOOL hasSchedules = NO;
    
    if (zoneName)
    {
        for (SAVClimateSchedule *schedule in [self.schedulingModel.schedules allValues])
        {
            if ([schedule.zones containsObject:zoneName])
            {
                hasSchedules = YES;
                break;
            }
        }
    }
    else
    {
        hasSchedules = [[self.schedulingModel.schedules allKeys] count];
    }
    
    NSString *title = hasSchedules ? ((self.schedulingModel.assignedProfile) ? self.schedulingModel.assignedProfile : NSLocalizedString(@"Select Schedule", nil)) : @"+";
    
    return title;
}

- (void)assignedScheduleChanged:(NSString *)assignedSchedule
{
    if (assignedSchedule)
    {
        self.schedulerView.titleLabel.text = assignedSchedule;
    }
    else
    {
        self.schedulerView.titleLabel.text = [self assignedSchduleTitle];
    }
    
    [self.schedulerView invalidateIntrinsicContentSize];
    [self.schedulerView setNeedsLayout];
    [self.schedulerView layoutIfNeeded];
}

- (SAVService *)service
{
    return self.climateService;
}

@end
