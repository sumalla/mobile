//
//  SCUSecurityChartModel.m
//  SavantController
//
//  Created by Nathan Trapp on 5/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSecurityChartModel.h"
#import "SCUSecurityModelPrivate.h"
#import "SCUSecuritySensorCell.h"

#import <SavantControl/SavantControl.h>

@interface SCUSecurityChartModel ()

@property NSMutableDictionary *sensorStatus;

@property SCUSecurityEntityStatusFilter statusFilter;
@property NSArray *filteredEntities;
@property NSArray *dataSource;

@end

@implementation SCUSecurityChartModel

- (instancetype)initWithService:(SAVService *)service
{
    self = [super initWithService:service];
    if (self)
    {
        self.sensorStatus = [NSMutableDictionary dictionary];
        self.statusFilter = SCUSecurityEntityStatusFilter_All;
    }
    return self;
}

- (void)selectSecuritySystem:(NSString *)componentName
{
    [super selectSecuritySystem:componentName];

    [self.sensorStatus removeAllObjects];

    for (SAVSecurityEntity *sensor in self.sensors)
    {
        self.sensorStatus[@(sensor.identifier)] = [NSMutableDictionary dictionaryWithObjectsAndKeys:sensor.label, SCUDefaultTableViewCellKeyTitle, @(-1), SCUSecuritySensorCellKeyStatus, @(sensor.identifier), SCUSecuritySensorCellKeyIdentifier, @(sensor.hasBypass), SCUSecuritySensorCellKeyHasBypass, nil];
    }

    [self reloadTableAfterDelay];
}

- (void)viewDidAppear
{
    [self reloadTableAfterDelay];
}

- (void)filterByStatus:(SCUSecurityEntityStatusFilter)status
{
    self.statusFilter = status;

    [self reloadTableAfterDelay];
}

- (void)filterByRoomId:(NSString *)roomId
{
    if (roomId)
    {
        self.filteredEntities = [[SavantControl sharedControl].data securityEntities:roomId zone:nil service:nil];
    }
    else
    {
        self.filteredEntities = nil;
    }

    [self reloadTableAfterDelay];
}

- (void)bypassPressedForRow:(NSInteger)row bypass:(BOOL)bypass
{
    SAVSecurityEntity *entity = [self sensorForIdentifier:[self.dataSource[row][SCUSecuritySensorCellKeyIdentifier] integerValue]];

    SAVServiceRequest *request = [entity requestForEvent:bypass ? SAVEntityEvent_Bypass : SAVEntityEvent_Unbypass value:nil];

    if (request)
    {
        [self sendServiceRequest:request];
    }
}

#pragma mark - SCUStateReceiver

- (NSArray *)statesToRegister
{
    NSMutableArray *sensorStates = [NSMutableArray array];

    //-------------------------------------------------------------------
    // Register for all sensor bypass states
    //-------------------------------------------------------------------
    for (SAVSecurityEntity *entity in self.sensors)
    {
        [sensorStates addObjectsFromArray:entity.states];
    }

    return sensorStates;
}

- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    [super didReceiveStateUpdate:stateUpdate];

    SAVSecurityEntity *sensor = [self sensorForSensorNumber:[[[self.sensors firstObject] addressesFromState:stateUpdate.state] firstObject]];

    SAVEntityState state = [sensor typeFromState:stateUpdate.state];

    switch (state)
    {
        case SAVEntityState_SensorBypassToggle:
            [self sensor:sensor updateBypass:[stateUpdate.value boolValue]];
            break;
        case SAVEntityState_SensorDetailedStatus:
            [self sensor:sensor updateDetailedStatus:stateUpdate.value];
            break;
        case SAVEntityState_SensorStatus:
            [self sensor:sensor updateStatus:[stateUpdate.value integerValue]];
            break;
        default:
            break;
    }
}

#pragma mark - Sensor Status Management

- (void)buildDataSource
{
    self.dataSource = [self _dataSource];
}

- (NSArray *)_dataSource
{
    NSArray *allData = [self.sensorStatus allValues];

    //-------------------------------------------------------------------
    // Filter the table based on user input
    //-------------------------------------------------------------------
    if (self.statusFilter != SCUSecurityEntityStatusFilter_All || self.filteredEntities)
    {
        allData = [allData filteredArrayUsingBlock:^BOOL(NSDictionary *sensorDict) {
            SAVSecurityEntity *sensor = [self sensorForIdentifier:[sensorDict[SCUSecuritySensorCellKeyIdentifier] integerValue]];

            BOOL remove = NO;

            if (self.filteredEntities)
            {
                remove = ![[self.filteredEntities filteredArrayUsingBlock:^BOOL(SAVSecurityEntity *entity) {
                    BOOL keep = NO;

                    if (entity.identifier == sensor.identifier)
                    {
                        keep = YES;
                    }

                    return keep;
                }] count];
            }

            if (!remove)
            {
                switch (self.statusFilter)
                {
                    case SCUSecurityEntityStatusFilter_Unknown:
                        remove = ![self.unknownSensorsTable containsObject:sensor];
                        break;
                    case SCUSecurityEntityStatusFilter_Ready:
                        remove = ![self.readySensorsTable containsObject:sensor];
                        break;
                    case SCUSecurityEntityStatusFilter_Trouble:
                        remove = ![self.troubleSensorsTable containsObject:sensor];
                        break;
                    case SCUSecurityEntityStatusFilter_Critical:
                        remove = ![self.criticalSensorsTable containsObject:sensor];
                        break;
                }
            }

            return !remove;
        }];
    }

    return [allData sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *sensorDict1, NSDictionary *sensorDict2) {
        return [sensorDict1[SCUDefaultTableViewCellKeyTitle] compare:sensorDict2[SCUDefaultTableViewCellKeyTitle] options:NSCaseInsensitiveNumericSearch];
    }];
}

- (void)reloadTableAfterDelay
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadTable) object:nil];
    [self performSelector:@selector(reloadTable) withObject:nil afterDelay:.02];
}

- (void)reloadTable
{
    [self buildDataSource];
    [self.delegate reloadTable];
}

- (void)sensor:(SAVSecurityEntity *)sensor updateBypass:(BOOL)isBypassed
{
    NSMutableDictionary *sensorDict = self.sensorStatus[@(sensor.identifier)];

    if ([sensorDict[SCUSecuritySensorCellKeyIsBypassed] boolValue] != isBypassed)
    {
        sensorDict[SCUSecuritySensorCellKeyIsBypassed] = @(isBypassed);

        [self reloadTableAfterDelay];
    }
}

- (void)sensor:(SAVSecurityEntity *)sensor updateDetailedStatus:(NSString *)detailedStatus
{
    NSMutableDictionary *sensorDict = self.sensorStatus[@(sensor.identifier)];

    if (![sensorDict[SCUSecuritySensorCellKeyDetailedStatus] isEqualToString:detailedStatus])
    {
        sensorDict[SCUSecuritySensorCellKeyDetailedStatus] = detailedStatus;

        [self reloadTableAfterDelay];
    }
}

- (void)sensor:(SAVSecurityEntity *)sensor updateStatus:(SAVSecurityEntityStatus)status
{
    NSMutableDictionary *sensorDict = self.sensorStatus[@(sensor.identifier)];

    if ([sensorDict[SCUSecuritySensorCellKeyStatus] integerValue] != status)
    {
        sensorDict[SCUSecuritySensorCellKeyStatus] = @(status);

        [self reloadTableAfterDelay];
    }
}

- (NSArray *)systems
{
    return [[super systems] filteredArrayUsingBlock:^BOOL(NSString *system) {
        return [self.securityEntities[system][SCUSecurityKeySensor] count];
    }];
}

#pragma mark - TableViewModel

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    return self.dataSource[indexPath.row];
}

- (NSUInteger)headerTypeForSection:(NSInteger)section
{
    return 0;
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    return 0;
}

- (NSInteger)numberOfSections
{
    return 1;
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    return [self.dataSource count];
}

@end
