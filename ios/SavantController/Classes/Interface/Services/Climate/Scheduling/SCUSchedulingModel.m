//
//  SCUSchedulingModel.m
//  SavantController
//
//  Created by Nathan Trapp on 7/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSchedulingModel.h"
#import "SCUInterface.h"
#import "SCUClimateScheduleSwitchCell.h"

#import <SavantControl/SAVClimateSchedule.h>
#import <SavantControl/SavantControl.h>

@interface SCUSchedulingModel () <StateDelegate>

@property SAVDISRequestGenerator *disRequestGenerator;
@property NSArray *states;
@property NSMutableDictionary *schedules;
@property NSMutableDictionary *activeSchedules;
@property NSDictionary *schedulerSettings;
@property NSString *assignedProfile;
@property NSHashTable *delegates;
@property NSString *zoneName;
@property NSArray *orderedSchedules, *orderedActiveSchedules;

@end

@implementation SCUSchedulingModel

- (instancetype)initWithService:(SAVService *)service
{
    self = [super init];
    if (self)
    {
        if ([SCUInterface sharedInstance].currentRoom)
        {
            self.zoneName = [[SAVSettings localSettings] objectForKey:[NSString stringWithFormat:@"%@.currentHVACZone", [SCUInterface sharedInstance].currentRoom.roomId]];
            
            if (!self.zoneName)
            {
                self.zoneName = [[[[SavantControl sharedControl].data zonesForRoom:[SCUInterface sharedInstance].currentRoom filteredByService:service] firstObject] zoneName];
            }
        }
        else if (service.zoneName)
        {
            self.zoneName = service.zoneName;
        }
        
        self.disRequestGenerator = [[SAVDISRequestGenerator alloc] initWithApp:@"hvacSchedule"];
        self.states = [self.disRequestGenerator feedbackStringsWithStateNames:[[self stateNames] allKeys]];
        [[SavantControl sharedControl] registerForStates:self.states forObserver:self];
        self.schedules = [NSMutableDictionary dictionary];
        self.activeSchedules = [NSMutableDictionary dictionary];
        self.delegates = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)dealloc
{
    [[SavantControl sharedControl] unregisterForStates:self.states forObserver:self];
}

- (void)listenToSwitch:(UISwitch *)toggleSwitch atIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    toggleSwitch.sav_didChangeHandler = ^(BOOL on){
        SAVStrongWeakSelf;
        SAVClimateSchedule *schedule = [sSelf scheduleForIndexPath:indexPath];
        schedule.active = on;
        SAVDISRequest *activateRequest = [sSelf activateScheduleRequest:schedule];
        
        [[SavantControl sharedControl] sendMessage:activateRequest];
        
        if (self.type == SCUScheduleTableType_Active)
        {
            for (id <SCUClimateSchedulingModelDelegate> delegate in self.delegates)
            {
                if ([delegate respondsToSelector:@selector(removeObjectAtIndexPath:)])
                {
                    [delegate removeObjectAtIndexPath:indexPath];
                }
            }
        }
    };
}

- (void)addDelegate:(id <SCUClimateSchedulingModelDelegate>)delegate
{
    [self.delegates addObject:delegate];
}

- (void)removeDelegate:(id <SCUClimateSchedulingModelDelegate>)delegate
{
    [self.delegates removeObject:delegate];
}

- (void)removeScheduleAtIndexPath:(NSIndexPath *)indexPath
{
    SAVClimateSchedule *schedule = [self scheduleForIndexPath:indexPath];
    
    if (schedule)
    {
        [self.activeSchedules removeObjectForKey:schedule.name];
        [self.schedules removeObjectForKey:schedule.name];
        
        [self sortSchedules];
        
        SAVDISRequest *deleteRequest = [self removeScheduleRequest:schedule];
        [[SavantControl sharedControl] sendMessage:deleteRequest];
        
        for (id <SCUClimateSchedulingModelDelegate> delegate in self.delegates)
        {
            if ([delegate respondsToSelector:@selector(removeObjectAtIndexPath:)])
            {
                [delegate removeObjectAtIndexPath:indexPath];
            }
        }
    }
}

- (void)saveSchedule:(SAVClimateSchedule *)schedule
{
    if (schedule)
    {
        SAVDISRequest *saveSchedule = nil;
        
        saveSchedule = [self saveScheduleSettingsRequest:schedule];
        
        [[SavantControl sharedControl] sendMessage:saveSchedule];
    }
}

#pragma mark - Data Source

- (SAVClimateSchedule *)scheduleForIndexPath:(NSIndexPath *)indexPath
{
    SAVClimateSchedule *schedule = nil;
    
    switch (self.type)
    {
        case SCUScheduleTableType_Active:
            if (indexPath.row < (NSInteger)[self.activeSchedules count])
            {
                schedule = self.activeSchedules[self.orderedActiveSchedules[indexPath.row]];
            }
            break;
        case SCUScheduleTableType_AllSchedules:
            if (indexPath.row < (NSInteger)[self.schedules count])
            {
                schedule = self.schedules[self.orderedSchedules[indexPath.row]];
            }
            break;
    }
    
    return schedule;
}

- (NSInteger)createNewScheduleRow
{
    return [self.schedules count] ? [self.activeSchedules count] + 1 : 0;
}

- (NSInteger)viewAllSchedulesRow
{
    return [self.schedules count] ? [self.activeSchedules count] : NSNotFound;
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    NSInteger numberOfItems = 0;
    
    switch (self.type)
    {
        case SCUScheduleTableType_Active:
            numberOfItems = [self.schedules count] ? [self.activeSchedules count] + 2 : 1;
            break;
        case SCUScheduleTableType_AllSchedules:
            numberOfItems = [self.schedules count];
            break;
    }
    
    return numberOfItems;
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    return [self scheduleForIndexPath:indexPath] ? SCUScheduleCellType_Toggle : SCUScheduleCellType_Default;
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.type == SCUScheduleTableType_Active)
    {
        if (indexPath.row == [self createNewScheduleRow])
        {
            for (id <SCUClimateSchedulingModelDelegate> delegate in [self.delegates copy])
            {
                if ([delegate respondsToSelector:@selector(editSchedule:)])
                {
                    [delegate newSchedule:self.schedulerSettings];
                }
            }
        }
        else if (indexPath.row == [self viewAllSchedulesRow])
        {
            for (id <SCUClimateSchedulingModelDelegate> delegate in [self.delegates copy])
            {
                if ([delegate respondsToSelector:@selector(viewAllSchedules)])
                {
                    [delegate viewAllSchedules];
                }
            }
        }
    }
    else
    {
        for (id <SCUClimateSchedulingModelDelegate> delegate in [self.delegates copy])
        {
            if ([delegate respondsToSelector:@selector(editSchedule:)])
            {
                [delegate editSchedule:self.schedules[self.orderedSchedules[indexPath.row]]];
            }
        }
    }
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    id modelObject = nil;
    
    switch (self.type)
    {
        case SCUScheduleTableType_Active:
        {
            if (indexPath.row < (NSInteger)[self.activeSchedules count])
            {
                SAVClimateSchedule *schedule = self.activeSchedules[self.orderedActiveSchedules[indexPath.row]];
                modelObject = @{SCUDefaultTableViewCellKeyTitle: schedule.name,
                                SCUDefaultTableViewCellKeyModelObject: schedule,
                                SCUToggleSwitchTableViewCellKeyValue: @(schedule.isActive)};
            }
            else
            {
                if (indexPath.row == [self viewAllSchedulesRow])
                {
                    modelObject = @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"View All Schedules", nil)};
                }
                else if (indexPath.row == [self createNewScheduleRow])
                {
                    modelObject = @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Create A New Schedule", nil)};
                }
            }
        }
            break;
        case SCUScheduleTableType_AllSchedules:
        {
            SAVClimateSchedule *schedule = self.schedules[self.orderedSchedules[indexPath.row]];
            modelObject = @{SCUDefaultTableViewCellKeyTitle: schedule.name,
                            SCUDefaultTableViewCellKeyModelObject: schedule,
                            SCUToggleSwitchTableViewCellKeyValue: @(schedule.isActive)};
        }
            break;
    }
    
    return modelObject;
}

- (void)sortSchedules
{
    NSArray *schedules = [[self.schedules allKeys] sortedArrayUsingSelector:@selector(compare:)];
    self.orderedSchedules = schedules;
    
    NSArray *activeSchedules = [[self.activeSchedules allKeys] sortedArrayUsingSelector:@selector(compare:)];
    self.orderedActiveSchedules = activeSchedules;
}

- (void)hvacPickerChangedZone:(NSString *)zone
{
    [[SavantControl sharedControl] unregisterForStates:self.states forObserver:self];
    
    self.zoneName = zone;
    self.states = [self.disRequestGenerator feedbackStringsWithStateNames:[[self stateNames] allKeys]];

    [[SavantControl sharedControl] registerForStates:self.states forObserver:self];
}

#pragma mark - Requests

- (SAVDISRequest *)addScheduleRequest:(SAVClimateSchedule *)schedule
{
    return [self.disRequestGenerator request:@"NewProfile"
                               withArguments:[schedule dictionaryRepresentation]];
}

- (SAVDISRequest *)removeScheduleRequest:(SAVClimateSchedule *)schedule
{
    return [self.disRequestGenerator request:@"DeleteProfile"
                               withArguments:@{SAVClimateScheduleNameKey: schedule.name}];
}

- (SAVDISRequest *)activateScheduleRequest:(SAVClimateSchedule *)schedule
{
    if (schedule.active)
    {
        self.activeSchedules[schedule.name] = schedule;
    }
    else
    {
        [self.activeSchedules removeObjectForKey:schedule.name];
    }
    
    [self sortSchedules];
    
    return [self.disRequestGenerator request:@"ActivateProfile"
                               withArguments:@{SAVClimateScheduleNameKey: schedule.name,
                                               SAVClimateScheduleActiveKey: @(schedule.isActive)}];
}

- (SAVDISRequest *)fetchScheduleSettingsRequest:(SAVClimateSchedule *)schedule
{
    return [self.disRequestGenerator request:@"FetchProfileProperties"
                               withArguments:@{SAVClimateScheduleNameKey: schedule.name}];
}

- (SAVDISRequest *)saveScheduleSettingsRequest:(SAVClimateSchedule *)schedule
{
    return [self.disRequestGenerator request:@"SaveProfileProperties"
                               withArguments:[schedule dictionaryRepresentation]];
}

#pragma mark - States

- (void)receivedProfiles:(NSDictionary *)profiles
{
    NSMutableArray *currentProfiles = [[self.schedules allKeys] mutableCopy];
    self.activeSchedules = [NSMutableDictionary dictionary];
    
    NSArray *profileNames = [profiles[@"ProfileNamesAndDates"] allKeys];
    NSDictionary *profileData = profiles[@"ProfileNamesAndDates"];

    for (NSString *profile in profileNames)
    {
        SAVClimateSchedule *schedule = self.schedules[profile];

        
        if (!schedule)
        {
            schedule = [[SAVClimateSchedule alloc] initWithName:profile];

            self.schedules[profile] = schedule;
        }
        
        [schedule setActive:[profileData[profile][@"Active"] boolValue]];
        [schedule setDateRange:profileData[profile][@"DateRange"]];
        [schedule setDays:profileData[profile][@"ProfileDays"]];
        
        if (schedule.isActive)
        {
            self.activeSchedules[schedule.name] = schedule;
        }
        
        if (self.schedulerSettings)
        {
            [schedule applyGlobalSettings:self.schedulerSettings];
        }
        
        SAVDISRequest *fetchRequest = [self fetchScheduleSettingsRequest:schedule];
        [[SavantControl sharedControl] sendMessage:fetchRequest];
        
        [currentProfiles removeObject:profile];
    }
    
    for (NSString *removedProfile in currentProfiles)
    {
        [self.schedules removeObjectForKey:removedProfile];
        
    }
    
    [self sortSchedules];
    
    for (id <SCUClimateSchedulingModelDelegate> delegate in self.delegates)
    {
        if ([delegate respondsToSelector:@selector(reloadData)])
        {
            [delegate reloadData];
        }
    }}

- (void)receivedProfileProperties:(NSDictionary *)profileProperties
{
    SAVClimateSchedule *schedule = self.schedules[profileProperties[SAVClimateScheduleNameKey]];
    
    if (schedule)
    {
        [schedule applySettings:profileProperties];
    }
    
    [self sortSchedules];
    
    for (id <SCUClimateSchedulingModelDelegate> delegate in self.delegates)
    {
        if ([delegate respondsToSelector:@selector(reloadData)])
        {
            [delegate reloadData];
        }
    }
}

- (void)receivedSchedulerSettings:(NSDictionary *)schedulerSettings
{
    schedulerSettings = (schedulerSettings[@"ProfileProperties"]) ? schedulerSettings[@"ProfileProperties"] : schedulerSettings;
    for (SAVClimateSchedule *schedule in [self.schedules allValues])
    {
        [schedule applyGlobalSettings:schedulerSettings];
    }
    
    self.schedulerSettings = schedulerSettings;
}

- (void)receivedAssignedSchedule:(NSDictionary *)scheduleInfo
{
    self.assignedProfile = scheduleInfo[@"ProfileName"];
    
    for (id <SCUClimateSchedulingModelDelegate> delegate in self.delegates)
    {
        if ([delegate respondsToSelector:@selector(assignedScheduleChanged:)])
        {
            [delegate assignedScheduleChanged:self.assignedProfile];
        }
    }
}

- (NSDictionary *)stateNames
{
    NSMutableDictionary *dict = [@{@"ProfileNamesAndDates": NSStringFromSelector(@selector(receivedProfiles:)),
//                                   @"ProfileNames": NSStringFromSelector(@selector(receivedProfiles:)),
                                   @"FetchProfileProperties": NSStringFromSelector(@selector(receivedProfileProperties:)),
                                   @"SchedulerSettings": NSStringFromSelector(@selector(receivedSchedulerSettings:))} mutableCopy];
    
    if (self.zoneName)
    {
        dict[[self.zoneName stringByAppendingString:@".AssignedSchedule"]] = NSStringFromSelector(@selector(receivedAssignedSchedule:));
    }
    
    return dict;
}

- (void)didReceiveDISFeedback:(SAVDISFeedback *)feedback
{
    SEL selector = NSSelectorFromString([self stateNames][feedback.state]);
    
    if (selector)
    {
        SAVFunctionForSelector(function, self, selector, void, NSDictionary *);
        function(self, selector, feedback.value);
    }
}

@end
