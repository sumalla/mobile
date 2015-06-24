//
//  SCUNotificationCreationAddRuleTableViewController.m
//  SavantController
//
//  Created by Stephen Silber on 1/22/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationCreationAddRuleTableViewController.h"
#import "SCUNotificationCreationViewController.h"
#import "SCUNotificationCreationTableViewControllerPrivate.h"
#import "SCUNotificationAddRuleViewModel.h"
#import "SCUNotificationAddRuleCell.h"
#import "SCURangeSlider.h"
#import "SCUButton2.h"
#import <SavantControl/SAVNotification.h>

@interface SCUNotificationCreationAddRuleTableViewController () <SCUNotificationAddRuleViewDelegate>

@property (nonatomic) SCUNotificationAddRuleViewModel *model;
@property (nonatomic) SCUButton2 *saveNotification;
@property (nonatomic) SCUButton2 *deleteNotification;
@property (nonatomic) SCURangeSlider *slider;
@property (nonatomic) UILabel *headerLabel;

@end

@implementation SCUNotificationCreationAddRuleTableViewController

- (instancetype)initWithNotification:(SAVNotification *)notification
{
    self = [super initWithNotification:notification];
    
    if (self)
    {
        self.model = [[SCUNotificationAddRuleViewModel alloc] initWithNotification:notification];
        self.model.delegate = self;
        
        [self.tableView setTableHeaderView:[self tableHeaderViewForType:notification.serviceType]];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setRowHeight:60.0f];
    [self.tableView setSectionHeaderHeight:50.f];
    [self.tableView setContentInset:UIEdgeInsetsZero];
    
    [self setTitle:NSLocalizedString(@"Add Rule", nil)];
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectZero];
    
    SCUButton2 *deleteNotification = [[SCUButton2 alloc] initWithTitle:[NSLocalizedString(@"Delete", nil) uppercaseString]];
    deleteNotification.backgroundColor = [[SCUColors shared] color03shade03];
    deleteNotification.selectedBackgroundColor = [[[SCUColors shared] color03shade05] colorWithAlphaComponent:.8];
    deleteNotification.color = [[SCUColors shared] color04];
    deleteNotification.target = self;
    deleteNotification.releaseAction = @selector(deleteNotification:);
    deleteNotification.titleLabel.font = [UIFont fontWithName:@"Gotham-Medium" size:14];
    deleteNotification.disabledColor = [[SCUColors shared] color04];
    deleteNotification.disabledBackgroundColor = [[SCUColors shared] color03shade06];
    
    SCUButton2 *saveNotification = [[SCUButton2 alloc] initWithTitle:[NSLocalizedString(@"Save", nil) uppercaseString]];
    saveNotification.backgroundColor = [[SCUColors shared] color01];
    saveNotification.selectedBackgroundColor = [[[SCUColors shared] color01] colorWithAlphaComponent:.8];
    saveNotification.color = [[SCUColors shared] color04];
    saveNotification.target = self;
    saveNotification.releaseAction = @selector(saveNotification:);
    saveNotification.titleLabel.font = [UIFont fontWithName:@"Gotham-Medium" size:14];
    saveNotification.disabledColor = [[SCUColors shared] color04];
    saveNotification.disabledBackgroundColor = [[SCUColors shared] color03shade06];
    
    [footerView addSubview:saveNotification];
    
    SAVWeakSelf;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        SAVStrongWeakSelf;
        
        if (sSelf.model.notification.triggerValues.count == 2)
        {
            [sSelf.slider setLeftValue:[sSelf.model.notification.triggerValues[0] floatValue] animated:NO];
            [sSelf.slider setRightValue:[sSelf.model.notification.triggerValues[1] floatValue] animated:NO];
        }
        
        SAVWeakSelf;
        [self.slider setCallback:^(SCURangeSlider *slider) {
            [wSelf.model updateTriggerValuesWithSlider:slider];
            [wSelf updateSliderLabel];
        }];
        
        [self updateSliderLabel];
        
        if (sSelf.creationVC.isEditing)
        {
            [self setTitle:NSLocalizedString(@"Edit Rule", nil)];
            
            if (sSelf.model.notification.triggerValues.count == 2)
            {
                [sSelf.slider setLeftValue:[sSelf.model.notification.triggerValues[0] floatValue] animated:NO];
                [sSelf.slider setRightValue:[sSelf.model.notification.triggerValues[1] floatValue] animated:NO];
            }
            
            SAVWeakSelf;
            [self.slider setCallback:^(SCURangeSlider *slider) {
                [wSelf.model updateTriggerValuesWithSlider:slider];
                [wSelf updateSliderLabel];
            }];
            
            [footerView addSubview:deleteNotification];
            [footerView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:@{@"height" : @(60)}
                                                                                views:@{@"delete" : deleteNotification, @"save" : saveNotification}
                                                                              formats:@[@"|[delete][save]|",
                                                                                        @"V:|[delete]",
                                                                                        @"V:|[save]",
                                                                                        @"delete.width = save.width",
                                                                                        @"delete.height = height",
                                                                                        @"save.height = delete.height"]]];
        }
        else
        {
            [self setTitle:NSLocalizedString(@"Add Rule", nil)];
            [footerView sav_addFlushConstraintsForView:saveNotification];
        }
        
        if (sSelf.model.notification.serviceType == SAVNotificationServiceTypeTemperature ||
            sSelf.model.notification.serviceType == SAVNotificationServiceTypeHumidity)
        {
            [sSelf updateSliderLabel];
        }
        sSelf.passthroughVC.footerView = footerView;
        sSelf.passthroughVC.footerHeight = 60;
    });

    self.saveNotification = saveNotification;
    self.saveNotification.enabled = [self saveEnabled];
    self.deleteNotification = deleteNotification;
    self.deleteNotification.enabled = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView reloadData];
    self.saveNotification.enabled = [self saveEnabled];
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUNotificationAddRuleCell class] forCellType:0];
}

- (void)saveNotification:(SCUButton2 *)sender
{
    self.saveNotification.enabled = NO;
    self.deleteNotification.enabled = NO;
    
    [self.model updateTriggerValuesWithSlider:self.slider];
    self.saveNotification.enabled = NO;
    [self.model saveNotificationWithEditing:self.creationVC.isEditing];
}

- (void)deleteNotification:(SCUButton2 *)sender
{
    self.saveNotification.enabled = NO;
    self.deleteNotification.enabled = NO;

    [self.model deleteNotification];
}

- (BOOL)saveEnabled
{
    BOOL saveEnabled = NO;
    
    if (self.model.notification.triggerValues.count &&
//        self.creationVC.isNotificationDirty &&
        (self.model.notification.pushDeliveryEnabled || self.model.notification.emailDeliveryEnabled))
    {
        saveEnabled = YES;
    }
    
    return saveEnabled;
}

- (UIView *)tableHeaderViewForType:(SAVNotificationServiceType)type
{
    UIView *header = [[UIView alloc] initWithFrame:CGRectZero];
    
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    textLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h8];
    textLabel.textColor = [[SCUColors shared] color03shade07];
    textLabel.numberOfLines = 0;

    [header addSubview:textLabel];

    switch (type)
    {
        case SAVNotificationServiceTypeLighting:
        case SAVNotificationServiceTypeEntertainment:
        {
            textLabel.text = [self.model headerTextForType:type];
            
            header.frame = CGRectMake(0, 0, CGRectGetWidth(header.frame), 50.0f);
            [header sav_pinView:textLabel withOptions:SAVViewPinningOptionsToLeft withSpace:[[SCUDimens dimens] regular].globalMargin1];
            [header sav_pinView:textLabel withOptions:SAVViewPinningOptionsToRight withSpace:33.0f];
            [header sav_pinView:textLabel withOptions:SAVViewPinningOptionsToBottom withSpace:10.f];
            break;
        }
        case SAVNotificationServiceTypeHumidity:
        case SAVNotificationServiceTypeTemperature:
        {
            UILabel *leftLabel  = [[UILabel alloc] initWithFrame:CGRectZero];
            UILabel *rightLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            
            leftLabel.textColor = [[SCUColors shared] color03shade08];
            leftLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h12];
            
            rightLabel.textColor = [[SCUColors shared] color03shade08];
            rightLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h12];
            
            [header addSubview:leftLabel];
            [header addSubview:rightLabel];
            
            header.frame = CGRectMake(0, 0, CGRectGetWidth(header.frame), 140.0f);
            
            SCURangeSliderStyle style = (type == SAVNotificationServiceTypeHumidity) ? SCURangeSliderStyleHumidity : SCURangeSliderStyleClimate;
            self.slider = [[SCURangeSlider alloc] initWithStyle:style withOffsetPercentage:0.3 andFrame:CGRectZero];
            
            [header addSubview:self.slider];
            
            [header sav_pinView:textLabel withOptions:SAVViewPinningOptionsToLeft withSpace:[[SCUDimens dimens] regular].globalMargin1];
            [header sav_pinView:textLabel withOptions:SAVViewPinningOptionsToRight withSpace:20.0f];
            [header sav_pinView:textLabel withOptions:SAVViewPinningOptionsToTop withSpace:20];
            
            leftLabel.text = [NSString stringWithFormat:@"%.0f%@", self.slider.minimumValue, self.slider.modifierCharacter];
            rightLabel.text = [NSString stringWithFormat:@"%.0f%@", self.slider.maximumValue, self.slider.modifierCharacter];
            
            [header sav_pinView:self.slider withOptions:SAVViewPinningOptionsToBottom];
            [header sav_pinView:self.slider withOptions:SAVViewPinningOptionsHorizontally withSpace:40];
            [header sav_pinView:leftLabel withOptions:SAVViewPinningOptionsToLeft|SAVViewPinningOptionsCenterY ofView:self.slider withSpace:10];
            [header sav_pinView:rightLabel withOptions:SAVViewPinningOptionsToRight|SAVViewPinningOptionsCenterY ofView:self.slider withSpace:10];
            
            [self updateSliderLabel];
            
            break;
        }
    }
    
    self.headerLabel = textLabel;
    return header;
}

- (void)updateSliderLabel
{
    if ((self.model.notification.serviceType == SAVNotificationServiceTypeHumidity) || (self.model.notification.serviceType == SAVNotificationServiceTypeTemperature))
    {
        NSString *leftValue = [NSString stringWithFormat:@"%.0f%@", self.slider.leftValue, self.slider.modifierCharacter];
        NSString *rightValue = [NSString stringWithFormat:@"%.0f%@", self.slider.rightValue, self.slider.modifierCharacter];
        NSString *climateType = self.model.notification.serviceType == SAVNotificationServiceTypeHumidity ? NSLocalizedString(@"humidity", nil) : NSLocalizedString(@"temperature", nil);
        NSString *normalString = [NSString stringWithFormat:@"If the %@ is below %@ or above %@...", climateType, leftValue, rightValue];
        
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:normalString];
        
        [attributedString addAttribute:NSForegroundColorAttributeName value:[[SCUColors shared] color04] range:[normalString rangeOfString:leftValue]];
        [attributedString addAttribute:NSForegroundColorAttributeName value:[[SCUColors shared] color04] range:[normalString rangeOfString:rightValue]];
        
        [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Gotham-Medium" size:[[SCUDimens dimens] regular].h8] range:[normalString rangeOfString:leftValue]];
        [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Gotham-Medium" size:[[SCUDimens dimens] regular].h8] range:[normalString rangeOfString:rightValue]];
        
        self.headerLabel.attributedText = attributedString;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 1)
    {
        return [self.model displaysScheduleTime] ? 86 : 60;
    }
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect frame = CGRectMake(0, 0, 0, 50);
    
    UIView *view = [[UIView alloc] initWithFrame:frame];
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    
    label.text = [self tableView:tableView titleForHeaderInSection:section];
    label.textColor = [[SCUColors shared] color03shade07];
    label.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h8];
    
    [view addSubview:label];
    [view sav_addConstraintsForView:label withEdgeInsets:UIEdgeInsetsMake(11.f, [[SCUDimens dimens] regular].globalMargin1, 0, 0)];
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
    if (section == 1)
    {
        return 50.f;
    }
    else
    {
        return 0.f;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    //JRL: this sucks, 0.f doesn't work
    return 0.0001f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCUNotificationsAddServiceRuleType type = [self.model ruleTypeForIndexPath:indexPath];
    
    switch (type)
    {
        case SCUNotificationsAddServiceRuleType_Where:
            if ((self.model.notification.serviceType == SAVNotificationServiceTypeTemperature) || (self.model.notification.serviceType == SAVNotificationServiceTypeHumidity))
            {
                self.creationVC.activeState = SCUNotificationCreationState_SetZones;
            }
            else
            {
                self.creationVC.activeState = SCUNotificationCreationState_SetRooms;
            }
            break;
        case SCUNotificationsAddServiceRuleType_When:
            self.creationVC.activeState = SCUNotificationCreationState_SetWhen;
            break;
        case SCUNotificationsAddServiceRuleType_Send:
            self.creationVC.activeState = SCUNotificationCreationState_SetSend;
            break;
    }
}

- (BOOL)editingNotification
{
    return self.creationVC.isEditing;
}

@end
