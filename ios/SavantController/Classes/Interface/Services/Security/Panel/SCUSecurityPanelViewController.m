//
//  SCUSecurityPanelViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 5/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSecurityPanelViewControllerPrivate.h"
#import "SCUPopoverMenu.h"
#import "SCUAlertView.h"
#import <SavantControl/SavantControl.h>

@interface SCUSecurityPanelViewController () <SCUButtonCollectionViewControllerDelegate, SCUSecurityPanelModelDelegate, SCUPickerViewDelegate>

@property SCUPopoverMenu *popoverMenu;
@property NSArray *panicCommands;
@property UILabel *userNumberTitle;

@end

@implementation SCUSecurityPanelViewController

- (instancetype)initWithService:(SAVService *)service
{
    self = [super initWithService:service];
    if (self)
    {
        self.model = [[SCUSecurityPanelModel alloc] initWithService:service];
        self.model.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Security", nil);

    self.numberPad = [[SCUNumberPadViewController alloc] initWithCommands:self.model.numberPadCommands];
    self.numberPad.delegate = self;
    self.numberPad.tintColor = [[SCUColors shared] color01];
    self.numberPad.alwaysShowClearButton = YES;
    self.numberPad.hideInfoBox = NO;
    self.numberPad.squareCells = NO;
    [self addChildViewController:self.numberPad];

    self.disarmButtons = [[SCUButtonViewController alloc] initWithCommands:@[SAVSecurityEntityCommandDisarm, SAVSecurityEntityCommandAway, SAVSecurityEntityCommandStay]];
    self.disarmButtons.delegate = self;
    self.disarmButtons.tintColor = [[SCUColors shared] color01];
    [self addChildViewController:self.disarmButtons];

    self.panicButtons = [[SCUButtonViewController alloc] initWithCommands:nil];
    self.panicButtons.delegate = self;
    self.panicButtons.tintColor = [[SCUColors shared] color01];
    [self addChildViewController:self.panicButtons];

    self.menuPicker = [[SCUPickerView alloc] initWithConfiguration:SCUPickerViewConfigurationTwoArrowsHorizontal];
    self.menuPicker.delegate = self;
    self.menuPicker.title = NSLocalizedString(@"Menu", nil);
    [self.menuPicker.centerButton defaultStyle];
    self.menuPicker.centerButton.selectedBackgroundColor = [[SCUColors shared] color01];
    self.menuPicker.centerButton.target = self;
    self.menuPicker.centerButton.touchDownAction = @selector(menuButtonTapped:);
    self.menuPicker.centerButton.releaseAction = @selector(menuButtonReleased:);
    self.menuPicker.centerButton.borderWidth = [UIScreen screenPixel];
    self.menuPicker.centerButton.borderColor = [[SCUColors shared] color03shade04];
    self.menuPicker.selectedTintColor = [[SCUColors shared] color01];

    self.userPicker = [[SCUPickerView alloc] initWithConfiguration:SCUPickerViewConfigurationTwoArrowsHorizontal];
    self.userPicker.delegate = self;
    self.userPicker.selectedTintColor = [[SCUColors shared] color01];

    self.pickerViews = [[UIView alloc] initWithFrame:CGRectZero];

    self.label1 = [[UILabel alloc] init];
    self.label1.font = [UIFont fontWithName:@"Gotham-Light" size:16];
    self.label1.textColor = [[SCUColors shared] color04];

    self.label2 = [[UILabel alloc] init];
    self.label2.font = [UIFont fontWithName:@"Gotham-Light" size:16];
    self.label2.textColor = [[SCUColors shared] color04];

    self.label3 = [[UILabel alloc] init];
    self.label3.font = [UIFont fontWithName:@"Gotham-Light" size:16];
    self.label3.textColor = [[SCUColors shared] color04];

    self.partitionTitle = [[UILabel alloc] init];
    self.partitionTitle.font = [UIFont fontWithName:@"Gotham-Light" size:18];
    self.partitionTitle.textColor = [UIColor sav_colorWithRGBValue:0xcccccc];
    self.partitionTitle.text = NSLocalizedString(@"PARTITION", nil);

    self.userNumberTitle = [[UILabel alloc] init];
    self.userNumberTitle.font = [UIFont fontWithName:@"Gotham-Light" size:18];
    self.userNumberTitle.textColor = [UIColor sav_colorWithRGBValue:0xcccccc];
    self.userNumberTitle.text = NSLocalizedString(@"USER", nil);

    self.armingStatusTitle = [[UILabel alloc] init];
    self.armingStatusTitle.font = [UIFont fontWithName:@"Gotham-Light" size:18];
    self.armingStatusTitle.textColor = [UIColor sav_colorWithRGBValue:0xcccccc];
    self.armingStatusTitle.text = NSLocalizedString(@"STATUS", nil);

    self.systemSelector = [[SCUButton alloc] initWithTitle:self.model.currentSystem];
    self.systemSelector.target = self;
    self.systemSelector.releaseAction = @selector(systemSelectorTapped:);
    self.systemSelector.frame = CGRectMake(0, 0, 200, 30);
    self.systemSelector.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    self.systemSelector.selectedBackgroundColor = [[SCUColors shared] color01];
    self.systemSelector.borderWidth = [UIScreen screenPixel];
    self.systemSelector.borderColor = [[SCUColors shared] color03shade04];

    self.partitionSelector = [[SCUButton alloc] initWithTitle:self.model.currentPartition.label];
    self.partitionSelector.target = self;
    self.partitionSelector.releaseAction = @selector(partionSelectorTapped:);
    self.partitionSelector.selectedBackgroundColor = [[SCUColors shared] color01];
    self.partitionSelector.borderWidth = [UIScreen screenPixel];
    self.partitionSelector.borderColor = [[SCUColors shared] color03shade04];

    self.armingSelector = [[SCUButton alloc] initWithTitle:self.model.armingStatus];
    self.armingSelector.target = self;
    self.armingSelector.releaseAction = @selector(armSelectorTapped:);
    self.armingSelector.selectedBackgroundColor = [[SCUColors shared] color01];
    self.armingSelector.borderWidth = [UIScreen screenPixel];
    self.armingSelector.borderColor = [[SCUColors shared] color03shade04];

    self.unknownCount = [[SCUSensorLabel alloc] initWithFrame:CGRectMake(0, 0, 23, 23)];
    self.unknownCount.backgroundColor = [[SCUColors shared] color03shade07];

    self.troubleCount = [[SCUSensorLabel alloc] initWithFrame:CGRectMake(0, 0, 23, 23)];
    self.troubleCount.backgroundColor = [UIColor sav_colorWithRGBValue:0xf9d700];

    self.criticalCount = [[SCUSensorLabel alloc] initWithFrame:CGRectMake(0, 0, 23, 23)];
    self.criticalCount.backgroundColor = [UIColor sav_colorWithRGBValue:0xff4200];

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

    //-------------------------------------------------------------------
    // Setup the initial state once the view loads
    //-------------------------------------------------------------------
    [self securitySystemDidChange:self.model.currentSystem];
    [self securityPartitionDidChange:self.model.currentPartition];
}

- (void)menuButtonTapped:(SCUButton *)button
{
    [self sendRequestForEvent:SAVEntityEvent_Menu];
}

- (void)menuButtonReleased:(SCUButton *)button
{
    [self sendRequestForEvent:SAVEntityEvent_Release];
}

- (void)systemSelectorTapped:(SCUButton *)button
{
    self.popoverMenu = [[SCUPopoverMenu alloc] initWithButtonTitles:self.model.systems];
    self.popoverMenu.selectedIndex = [self.model.systems indexOfObject:self.model.currentSystem];
    SAVWeakSelf;
    self.popoverMenu.callback = ^(NSInteger buttonIndex) {
        if (buttonIndex != -1)
        {
            [wSelf.model selectSecuritySystem:wSelf.model.systems[buttonIndex]];
        }
    };
    [self.popoverMenu showFromButton:button animated:YES];
}

- (void)partionSelectorTapped:(SCUButton *)button
{
    NSArray *partionNames = [self.model.partitions arrayByMappingBlock:^id(SAVSecurityEntity *entity) {
        return entity.label;
    }];
    self.popoverMenu = [[SCUPopoverMenu alloc] initWithButtonTitles:partionNames];
    self.popoverMenu.selectedIndex = [partionNames indexOfObject:self.model.currentPartition.label];
    SAVWeakSelf;
    self.popoverMenu.callback = ^(NSInteger buttonIndex) {
        if (buttonIndex != -1)
        {
            [wSelf.model selectSecurityPartition:wSelf.model.partitions[buttonIndex]];
        }
    };
    [self.popoverMenu showFromButton:button animated:YES];
}

- (void)armSelectorTapped:(SCUButton *)button
{
    NSArray *armingCommands = @[SAVSecurityEntityCommandDisarm, SAVSecurityEntityCommandAway, SAVSecurityEntityCommandStay];
    NSArray *armingNames = [armingCommands arrayByMappingBlock:^id(NSString *command) {
        return NSLocalizedStringWithDefaultValue([command stringByAppendingString:@"-Command"], @"Command", [NSBundle mainBundle], command, @"Localized Service Command");
    }];
    self.popoverMenu = [[SCUPopoverMenu alloc] initWithButtonTitles:armingNames];
    self.popoverMenu.selectedIndex = [armingNames indexOfObject:self.model.armingStatus];
    SAVWeakSelf;
    self.popoverMenu.callback = ^(NSInteger buttonIndex) {
        if (buttonIndex != -1)
        {
            [wSelf sendRequestForEvent:[wSelf.model.currentPartition eventForCommand:armingCommands[buttonIndex]]];
            [wSelf sendRequestForEvent:SAVEntityEvent_Release];
        }
    };
    [self.popoverMenu showFromButton:button animated:YES];
}

- (void)sendRequestForEvent:(SAVEntityEvent)event
{
    SAVServiceRequest *request = [self.model.currentPartition requestForEvent:event value:nil];

    if (request)
    {
        [self.model sendServiceRequest:request];
    }
}

#pragma mark - SCUSecurityPanelModel Delegate

- (void)securitySystemDidChange:(NSString *)componentName
{
    self.systemSelector.title = componentName;

    if (self.pickerViews)
    {
        [[self.pickerViews subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

        if (self.model.isUserSecurity)
        {
            [self.pickerViews addSubview:self.userPicker];

            if ([UIDevice isPad])
            {
                [self.pickerViews addSubview:self.userNumberTitle];
                [self.pickerViews addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:nil
                                                                                          views:@{@"picker": self.userPicker, @"title": self.userNumberTitle}
                                                                                        formats:@[@"|[picker]|",
                                                                                                  @"|[title]|",
                                                                                                  @"V:|[title][picker]|"]]];
            }
            else
            {
                [self.pickerViews sav_addFlushConstraintsForView:self.userPicker];
            }
        }
        else
        {
            [self.pickerViews addSubview:self.menuPicker];
            if ([UIDevice isPad])
            {
                [self.pickerViews sav_addConstraintsForView:self.menuPicker withEdgeInsets:UIEdgeInsetsMake(18, 0, 0, 0)];
            }
            else
            {
                [self.pickerViews sav_addFlushConstraintsForView:self.menuPicker];
            }
        }
    }

    NSMutableArray *panicCommands = [NSMutableArray array];
    for (NSString *command in  @[SAVSecurityEntityCommandPolice, SAVSecurityEntityCommandMedical, SAVSecurityEntityCommandFire, SAVSecurityEntityCommandPanic])
    {
        if ([self.model.serviceCommands containsObject:command])
        {
            [panicCommands addObject:command];
        }
    }

    self.panicCommands = panicCommands;
    self.panicButtons.commands = self.panicCommands;

    self.numberPad.commands = self.model.numberPadCommands;
}

- (void)securityPartitionDidChange:(SAVSecurityEntity *)partition
{
    self.label1.text = @"";
    self.label2.text = @"";
    self.label3.text = @"";

    self.partitionSelector.title = partition.label;
}

- (void)securityPartition:(SAVSecurityEntity *)partition armingStatusDidChange:(NSString *)armingStatus
{
    self.armingSelector.title = armingStatus;
}

- (void)securitySystemSensorCountDidChange:(NSString *)componentName
{
    self.unknownCount.text = [NSString stringWithFormat:@"%ld", (unsigned long)self.model.unknownSensors];
    self.troubleCount.text = [NSString stringWithFormat:@"%ld", (unsigned long)self.model.troubleSensors];
    self.criticalCount.text = [NSString stringWithFormat:@"%ld", (unsigned long)self.model.criticalSensors];
}

- (void)securityPartition:(SAVSecurityEntity *)partition userNumberDidChange:(NSUInteger)userNumber
{
    self.userPicker.title = [NSString stringWithFormat:@"%ld", (unsigned long)userNumber];
}

- (void)securityPartition:(SAVSecurityEntity *)partition statusDidChange:(NSString *)status
{
    self.label1.text = status;
}

- (void)securityPartition:(SAVSecurityEntity *)partition line1DidChange:(NSString *)line1
{
    self.label2.text = line1;
}

- (void)securityPartition:(SAVSecurityEntity *)partition line2DidChange:(NSString *)line2
{
    self.label3.text = line2;
}

- (void)securityPartition:(SAVSecurityEntity *)partition accessCodeDidChange:(NSString *)accessCode
{
    self.label2.text = accessCode;
}

#pragma mark - SCUPickerView Delegate

- (void)pickerView:(SCUPickerView *)pickerView didTapArrowWithDirection:(SCUPickerViewDirection)direction
{
    if (self.model.isUserSecurity)
    {
        switch (direction)
        {
            case SCUPickerViewDirectionLeft:
                [self sendRequestForEvent:SAVEntityEvent_UserDown];
                break;
            case SCUPickerViewDirectionRight:
                [self sendRequestForEvent:SAVEntityEvent_UserUp];
                break;
            default:
                break;
        }
    }
    else
    {
        switch (direction)
        {
            case SCUPickerViewDirectionLeft:
                [self sendRequestForEvent:SAVEntityEvent_Left];
                break;
            case SCUPickerViewDirectionRight:
                [self sendRequestForEvent:SAVEntityEvent_Right];
                break;
            default:
                break;
        }
    }
}

- (void)pickerView:(SCUPickerView *)pickerView didSelectArrowWithDirection:(SCUPickerViewDirection)direction
{
    [self sendRequestForEvent:SAVEntityEvent_Release];
}

#pragma mark - SCUButtonCollectionViewController Delegate

- (void)tappedButton:(SCUButtonCollectionViewCell *)button withCommand:(NSString *)command
{
    if ([self.panicCommands containsObject:command])
    {
        SAVEntityEvent event = [self.model.currentPartition eventForCommand:command];

        NSString *messageString = nil;
        NSString *boldText = nil;
        NSString *okText = nil;

        switch (event)
        {
            case SAVEntityEvent_Panic:
                boldText = NSLocalizedString(@"panic alert", nil);
                messageString = [NSString stringWithFormat:NSLocalizedString(@"Confirm %@?", nil), boldText];
                okText = NSLocalizedString(@"Panic Alert", nil);
                break;
            case SAVEntityEvent_Fire:
                boldText = NSLocalizedString(@"alert the fire department", nil);
                messageString = [NSString stringWithFormat:NSLocalizedString(@"Do you wish to %@?", nil), boldText];
                okText = NSLocalizedString(@"Alert Fire Dept", nil);
                break;
            case SAVEntityEvent_Medical:
                boldText = NSLocalizedString(@"call for an ambulance", nil);
                messageString = [NSString stringWithFormat:NSLocalizedString(@"Do you wish to %@?", nil), boldText];
                okText = NSLocalizedString(@"Call Ambulance", nil);
                break;
            case SAVEntityEvent_Police:
                boldText = NSLocalizedString(@"alert the police", nil);
                messageString = [NSString stringWithFormat:NSLocalizedString(@"Do you wish to %@?", nil), boldText];
                okText = NSLocalizedString(@"Alert Police", nil);
                break;
            default:
                boldText = NSLocalizedString(@"send this alert", nil);
                messageString = [NSString stringWithFormat:NSLocalizedString(@"Do you wish to %@?", nil), boldText];
                okText = NSLocalizedString(@"Send Alert", nil);
                break;
        }

        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:messageString attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16]}];
        [attributedString setAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:16]}
                                  range:[messageString rangeOfString:boldText]];

        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.attributedText = attributedString;

        UIView *labelContainer = [[UIView alloc] initWithFrame:CGRectZero];
        [labelContainer addSubview:messageLabel];
        [labelContainer sav_addConstraintsForView:messageLabel withEdgeInsets:UIEdgeInsetsMake(15, 5, 15, 5)];

        SCUAlertView *alertView = [[SCUAlertView alloc] initWithTitle:nil
                                                          contentView:labelContainer
                                                         buttonTitles:@[NSLocalizedString(@"Cancel", nil),
                                                                        okText]];
        alertView.tapToDismiss = NO;

        SAVWeakSelf;
        alertView.callback = ^(NSUInteger buttonIndex){
            if (buttonIndex == 1)
            {
                SAVStrongWeakSelf;
                [sSelf sendRequestForEvent:[self.model.currentPartition eventForCommand:command]];
                [sSelf sendRequestForEvent:SAVEntityEvent_Release];
            }
        };
        alertView.primaryButtons = [NSIndexSet indexSetWithIndex:1];
        [alertView show];
    }
    else
    {
        [self sendRequestForEvent:[self.model.currentPartition eventForCommand:command]];
    }
}

- (void)releasedButton:(SCUButtonCollectionViewCell *)button withCommand:(NSString *)command
{
    if ([command isEqualToString:kClearNumbersInternalAppCommand])
    {
        [self sendRequestForEvent:SAVEntityEvent_Clear];
    }

    if (![self.panicCommands containsObject:command])
    {
        [self sendRequestForEvent:SAVEntityEvent_Release];
    }
}

#pragma mark - Tab Bar Controller

- (UIImage *)tabBarIcon
{
    return [UIImage imageNamed:@"numberpad"];
}

- (UIColor *)tabBarButtonColor
{
    return [[SCUColors shared] color01];
}

@end
