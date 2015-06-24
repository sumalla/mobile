//
//  SCUSecurityPanelModel.m
//  SavantController
//
//  Created by Nathan Trapp on 5/27/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSecurityPanelModel.h"
#import "SCUSecurityModelPrivate.h"
#import "SCUStateReceiver.h"

#import <SavantControl/SavantControl.h>
#import <SavantExtensions/SavantExtensions.h>

@interface SCUSecurityPanelModel ()

@property SAVSecurityEntity *currentPartition;
@property NSString *armingStatus;
@property SAVSecurityEntityArmingStatus armingState;

@end

@implementation SCUSecurityPanelModel

#pragma mark - SCUStateReceiver

- (void)selectSecuritySystem:(NSString *)componentName
{
    if (componentName == self.currentSystem)
    {
        return;
    }

    [super selectSecuritySystem:componentName];

    [self selectSecurityPartition:[self.partitions firstObject]];
}

- (void)selectSecurityPartition:(SAVSecurityEntity *)partition
{
    NSAssert([self.partitions containsObject:partition], @"Partition is not a valid selection");

    if (partition == self.currentPartition)
    {
        return;
    }

    if (self.currentPartition)
    {
        [[SavantControl sharedControl] unregisterForStates:self.statesToRegister forObserver:self];
    }

    [self cleanup];

    self.currentPartition = partition;

    if ([self.delegate respondsToSelector:@selector(securityPartitionDidChange:)])
    {
        [self.delegate securityPartitionDidChange:self.currentPartition];
    }

    if (self.currentSystem && self.isOnScreen)
    {
        [[SavantControl sharedControl] registerForStates:self.statesToRegister forObserver:self];
    }
}

- (void)updateArmingStatus
{
    NSString *armingStatus = nil;

    switch (self.armingState)
    {
        case SAVSecurityEntityArmingStatus_Disarmed:
            armingStatus = NSLocalizedString(@"Disarmed", nil);
            break;
        case SAVSecurityEntityArmingStatus_Away:
            armingStatus = NSLocalizedString(@"Away", nil);
            break;
        case SAVSecurityEntityArmingStatus_Stay:
            armingStatus = NSLocalizedString(@"Stay", nil);
            break;
        case SAVSecurityEntityArmingStatus_Instant:
            armingStatus = NSLocalizedString(@"Instant", nil);
            break;
        case SAVSecurityEntityArmingStatus_Vaction:
            armingStatus = NSLocalizedString(@"Vacation", nil);
            break;
        case SAVSecurityEntityArmingStatus_NightStay:
            armingStatus = NSLocalizedString(@"Night Stay", nil);
            break;
        case SAVSecurityEntityArmingStatus_Unknown:
            break;
    }

    if (armingStatus)
    {
        self.armingStatus = armingStatus;

        if ([self.delegate respondsToSelector:@selector(securityPartition:armingStatusDidChange:)])
        {
            [self.delegate securityPartition:self.currentPartition armingStatusDidChange:self.armingStatus];
        }
    }
}

- (NSArray *)statesToRegister
{
    return [[super statesToRegister] arrayByAddingObjectsFromArray:self.currentPartition.states];
}

- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    [super didReceiveStateUpdate:stateUpdate];

    if ([self.currentPartition.states containsObject:stateUpdate.state])
    {
        SAVEntityState state = [self.currentPartition typeFromState:stateUpdate.state];

        switch (state)
        {
            case SAVEntityState_PartitionStatus:
                [self.delegate securityPartition:self.currentPartition statusDidChange:stateUpdate.value];
                break;
            case SAVEntityState_PartitionArmingStatus:
                self.armingState = [SAVSecurityEntity armingStatusForString:stateUpdate.value];
                [self updateArmingStatus];
                break;
            case SAVEntityState_PartitionMenuLine1:
                [self.delegate securityPartition:self.currentPartition line1DidChange:stateUpdate.value];
                break;
            case SAVEntityState_PartitionMenuLine2:
                [self.delegate securityPartition:self.currentPartition line2DidChange:stateUpdate.value];
                break;
            case SAVEntityState_PartitionUserAccessCode:
                [self.delegate securityPartition:self.currentPartition accessCodeDidChange:stateUpdate.value];
                break;
            case SAVEntityState_PartitionUserNumber:
                [self.delegate securityPartition:self.currentPartition userNumberDidChange:[stateUpdate.value integerValue]];
                break;
            default:
                break;
        }
    }
}

- (NSArray *)systems
{
    return [[super systems] filteredArrayUsingBlock:^BOOL(NSString *system) {
        return [self.securityEntities[system][SCUSecurityKeyPartition] count];
    }];
}

@end
