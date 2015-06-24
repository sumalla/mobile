//
//  SCUSecurityChartViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 5/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSecurityChartViewControllerPrivate.h"
#import "SCUSecurityChartModel.h"
#import "SCUPopoverMenu.h"
#import "SCUSensorLabel.h"

#import <SavantControl/SavantControl.h>

@interface SCUSecurityChartViewController () <SCUSecurityChartModelDelegate>

@property SCUPopoverMenu *popoverMenu;

@property UILabel *unknownLabel;
@property UILabel *criticalLabel;
@property UILabel *troubleLabel;
@property UILabel *readyLabel;
@property UILabel *allLabel;
@property SCUSensorLabel *unknownCount;
@property SCUSensorLabel *troubleCount;
@property SCUSensorLabel *criticalCount;
@property SCUSensorLabel *readyCount;

@property NSArray *allRooms;

@end

@implementation SCUSecurityChartViewController

- (instancetype)initWithService:(SAVService *)service
{
    self = [super initWithService:service];
    if (self)
    {
        self.model = [[SCUSecurityChartModel alloc] initWithService:service];
        self.model.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Security", nil);

    self.allRooms = @[NSLocalizedString(@"All", nil)];
    self.allRooms = [self.allRooms arrayByAddingObjectsFromArray:[[SavantControl sharedControl].data allRoomIds]];

    self.roomsTitle = [[UILabel alloc] init];
    self.roomsTitle.font = [UIFont fontWithName:@"Gotham" size:18];
    self.roomsTitle.textColor = [[SCUColors shared] color04];
    self.roomsTitle.text = NSLocalizedString(@"Rooms:", nil);

    self.systemSelector = [[SCUButton alloc] initWithTitle:self.model.currentSystem];
    self.systemSelector.target = self;
    self.systemSelector.releaseAction = @selector(systemSelectorTapped:);
    self.systemSelector.frame = CGRectMake(0, 0, 200, 30);
    self.systemSelector.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    self.systemSelector.selectedBackgroundColor = [[SCUColors shared] color01];
    self.systemSelector.borderWidth = [UIScreen screenPixel];
    self.systemSelector.borderColor = [[SCUColors shared] color03shade04];

    self.roomsSelector = [[SCUButton alloc] initWithTitle:[self.allRooms firstObject]];
    self.roomsSelector.target = self;
    self.roomsSelector.releaseAction = @selector(roomsSelectorTapped:);
    self.roomsSelector.selectedBackgroundColor = [[SCUColors shared] color01];
    self.roomsSelector.borderWidth = [UIScreen screenPixel];
    self.roomsSelector.borderColor = [[SCUColors shared] color03shade04];

    self.unknownCount = [[SCUSensorLabel alloc] initWithFrame:CGRectZero];
    self.unknownCount.backgroundColor = [[SCUColors shared] color03shade07];

    self.troubleCount = [[SCUSensorLabel alloc] initWithFrame:CGRectZero];
    self.troubleCount.backgroundColor = [UIColor sav_colorWithRGBValue:0xf9d700];

    self.criticalCount = [[SCUSensorLabel alloc] initWithFrame:CGRectZero];
    self.criticalCount.backgroundColor = [UIColor sav_colorWithRGBValue:0xff4200];

    self.readyCount = [[SCUSensorLabel alloc] initWithFrame:CGRectZero];
    self.readyCount.backgroundColor = [UIColor sav_colorWithRGBValue:0xafcc00];

    self.unknownLabel = [[UILabel alloc] init];
    self.unknownLabel.font = [UIFont fontWithName:@"Gotham" size:14];
    self.unknownLabel.textColor = [[SCUColors shared] color04];
    self.unknownLabel.text = NSLocalizedString(@"Unknown", nil);

    self.troubleLabel = [[UILabel alloc] init];
    self.troubleLabel.font = [UIFont fontWithName:@"Gotham" size:14];
    self.troubleLabel.textColor = [[SCUColors shared] color04];
    self.troubleLabel.text = NSLocalizedString(@"Trouble", nil);

    self.criticalLabel = [[UILabel alloc] init];
    self.criticalLabel.font = [UIFont fontWithName:@"Gotham" size:14];
    self.criticalLabel.textColor = [[SCUColors shared] color04];
    self.criticalLabel.text = NSLocalizedString(@"Critical", nil);

    self.allLabel = [[UILabel alloc] init];
    self.allLabel.font = [UIFont fontWithName:@"Gotham" size:16];
    self.allLabel.textColor = [[SCUColors shared] color04];
    self.allLabel.text = NSLocalizedString(@"All", nil);

    self.readyLabel = [[UILabel alloc] init];
    self.readyLabel.font = [UIFont fontWithName:@"Gotham" size:14];
    self.readyLabel.textColor = [[SCUColors shared] color04];
    self.readyLabel.text = NSLocalizedString(@"Ready", nil);

    self.unknownButton = [self buttonFromSensorLabel:self.unknownCount sensorTitleLabel:self.unknownLabel];
    self.troubleButton = [self buttonFromSensorLabel:self.troubleCount sensorTitleLabel:self.troubleLabel];
    self.criticalButton = [self buttonFromSensorLabel:self.criticalCount sensorTitleLabel:self.criticalLabel];
    self.readyButton = [self buttonFromSensorLabel:self.readyCount sensorTitleLabel:self.readyLabel];

    self.sensorTableViewController = [[SCUSensorTableViewController alloc] initWithModel:self.model];
    [self addChildViewController:self.sensorTableViewController];

    UIImageView *allImageView = [[UIImageView alloc] init];
    allImageView.image = [UIImage imageNamed:@"security-all"];
    allImageView.contentMode = UIViewContentModeScaleAspectFit;

    UIView *containerView = [[UIView alloc] initWithFrame:CGRectZero];
    [containerView addSubview:self.allLabel];
    [containerView addSubview:allImageView];

    [containerView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:nil
                                                                           views:@{@"all": allImageView, @"title": self.allLabel}
                                                                         formats:@[@"|[all]-(3)-[title]|",
                                                                                   @"all.centerY = super.centerY",
                                                                                   @"V:|[title]|"]]];

    self.allButton = [[SCUButton alloc] initWithCustomView:containerView];
    self.allButton.selectedBackgroundColor = nil;
    self.allButton.backgroundColor = nil;
    self.allButton.target = self;
    self.allButton.touchDownAction = @selector(filterSensorsPressed:);
    self.allButton.releaseAction = @selector(filterSensorsReleased:);

    //-------------------------------------------------------------------
    // Setup the initial state once the view loads
    //-------------------------------------------------------------------
    [self securitySystemDidChange:self.model.currentSystem];
}

- (SCUButton *)buttonFromSensorLabel:(SCUSensorLabel *)sensorLabel sensorTitleLabel:(UILabel *)titleLabel
{
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectZero];
    [containerView addSubview:sensorLabel];
    [containerView addSubview:titleLabel];

    [containerView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:nil
                                                                           views:@{@"sensor": sensorLabel, @"title": titleLabel}
                                                                         formats:@[@"|[sensor(23)]-(3)-[title]|",
                                                                                   @"sensor.centerY = super.centerY",
                                                                                   @"sensor.height = 23",
                                                                                   @"V:|[title]|"]]];

    SCUButton *sensorButton = [[SCUButton alloc] initWithCustomView:containerView];
    sensorButton.selectedBackgroundColor = nil;
    sensorButton.backgroundColor = nil;
    sensorButton.target = self;
    sensorButton.touchDownAction = @selector(filterSensorsPressed:);
    sensorButton.releaseAction = @selector(filterSensorsReleased:);

    return sensorButton;
}

- (void)filterSensorsPressed:(SCUButton *)button
{
    if (button == self.readyButton)
    {
        self.readyLabel.textColor = [[SCUColors shared] color01];
    }
    else if (button == self.troubleButton)
    {
        self.troubleLabel.textColor = [[SCUColors shared] color01];
    }
    else if (button == self.criticalButton)
    {
        self.criticalLabel.textColor = [[SCUColors shared] color01];
    }
    else if (button == self.unknownButton)
    {
        self.unknownLabel.textColor = [[SCUColors shared] color01];
    }
    else if (button == self.allButton)
    {
        self.allLabel.textColor = [[SCUColors shared] color01];
    }
}

- (void)filterSensorsReleased:(SCUButton *)button
{
    if (button == self.readyButton)
    {
        self.readyLabel.textColor = [[SCUColors shared] color04];
        [self.model filterByStatus:SCUSecurityEntityStatusFilter_Ready];
    }
    else if (button == self.troubleButton)
    {
        self.troubleLabel.textColor = [[SCUColors shared] color04];
        [self.model filterByStatus:SCUSecurityEntityStatusFilter_Trouble];
    }
    else if (button == self.criticalButton)
    {
        self.criticalLabel.textColor = [[SCUColors shared] color04];
        [self.model filterByStatus:SCUSecurityEntityStatusFilter_Critical];
    }
    else if (button == self.unknownButton)
    {
        self.unknownLabel.textColor = [[SCUColors shared] color04];
        [self.model filterByStatus:SCUSecurityEntityStatusFilter_Unknown];
    }
    else if (button == self.allButton)
    {
        self.allLabel.textColor = [[SCUColors shared] color04];
        [self.model filterByStatus:SCUSecurityEntityStatusFilter_All];
    }
}

- (void)systemSelectorTapped:(SCUButton *)button
{
    self.popoverMenu = [[SCUPopoverMenu alloc] initWithButtonTitles:self.model.systems];
    SAVWeakSelf;
    self.popoverMenu.selectedIndex = [self.model.systems indexOfObject:self.model.currentSystem];
    self.popoverMenu.callback = ^(NSInteger buttonIndex) {
        if ((buttonIndex != -1) && (buttonIndex != wSelf.popoverMenu.selectedIndex))
        {
            [wSelf.model selectSecuritySystem:wSelf.model.systems[buttonIndex]];
            [wSelf reloadTable];
        }
    };
    [self.popoverMenu showFromButton:button animated:YES];
}

- (void)roomsSelectorTapped:(SCUButton *)button
{
    self.popoverMenu = [[SCUPopoverMenu alloc] initWithButtonTitles:self.allRooms];
    self.popoverMenu.selectedIndex = [self.allRooms indexOfObject:self.roomsSelector.title];
    SAVWeakSelf;
    self.popoverMenu.callback = ^(NSInteger buttonIndex) {
        if (buttonIndex != -1)
        {
            if (buttonIndex == 0)
            {
                [wSelf.model filterByRoomId:nil];
            }
            else
            {
                [wSelf.model filterByRoomId:wSelf.allRooms[buttonIndex]];
            }
            
            wSelf.roomsSelector.title = wSelf.allRooms[buttonIndex];
        }
    };
    [self.popoverMenu showFromButton:button animated:YES];
}

#pragma mark - SCUSecurityModel Delegate

- (void)securitySystemDidChange:(NSString *)componentName
{
    self.systemSelector.title = componentName;
}

- (void)reloadTable
{
    [self.sensorTableViewController.tableView reloadData];
}

- (void)securitySystemSensorCountDidChange:(NSString *)componentName
{
    self.unknownCount.text = [NSString stringWithFormat:@"%ld", (unsigned long)self.model.unknownSensors];
    self.troubleCount.text = [NSString stringWithFormat:@"%ld", (unsigned long)self.model.troubleSensors];
    self.criticalCount.text = [NSString stringWithFormat:@"%ld", (unsigned long)self.model.criticalSensors];
    self.readyCount.text = [NSString stringWithFormat:@"%ld", (unsigned long)self.model.readySensors];
}

#pragma mark - Tab Bar Controller

- (UIImage *)tabBarIcon
{
    return [UIImage imageNamed:@"security-list"];
}

- (UIColor *)tabBarButtonColor
{
    return [[SCUColors shared] color01];
}

@end
