//
//  SCUServicesFirstDataModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 7/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServicesFirstDataModel.h"
#import "SCUDataSourceModelPrivate.h"
#import "SCUDefaultCollectionViewCell.h"
#import <SavantControl/SavantControl.h>
#import <SavantExtensions/SavantExtensions.h>
#import "SCUEditableButtonsCollectionViewModelPrivate.h"
#import "SCUServicesFirstCollectionViewCell.h"
#import "SCUServicesFirstClimateCollectionViewCell.h"
#import "SCUInterface.h"
#import "SCUModelTableViewController.h"
#import "SCUGenericCommandTableViewController.h"

NSString *const SCUServicesFirstCellKeyMoving = @"SCUServicesFirstCellKeyMoving";
static NSString *SCUServicesFirstDataModelKeySpan = @"SCUServicesFirstDataModelKeySpan";
static NSString *SCUServicesFirstDataModelKeyIdentifier = @"SCUServicesFirstDataModelKeyIdentifier";
static NSString *SCUServicesFirstDataModelKeyIsAV = @"SCUServicesFirstDataModelKeyIsAV";
static NSString *SCUServicesFirstDataModelKeyIsLighting = @"SCUServicesFirstDataModelKeyIsLighting";
static NSString *SCUServicesFirstDataModelKeyIsShades = @"SCUServicesFirstDataModelKeyIsShades";
static NSString *SCUServicesFirstDataModelKeyIsClimate = @"SCUServicesFirstDataModelKeyIsClimate";
static NSString *SCUServicesFirstDataModelKeyIsSecurity = @"SCUServicesFirstDataModelKeyIsSecurity";
static NSString *SCUServicesFirstDataModelKeyIsGeneric = @"SCUServicesFirstDataModelKeyIsGeneric";
static NSString *SCUServicesFirstOrderingKey = @"servicesFirst.serviceOrder";

@interface SCUServicesFirstDataModel () <ActiveServiceObserver, StateDelegate, SystemStatusDelegate>

@property (nonatomic) SAVService *service;
@property (nonatomic) NSMutableDictionary *activeServiceMapping; /* { room -> [services] } */
@property (nonatomic) NSCountedSet *serviceCounts;
@property (nonatomic) SAVCoalescedTimer *updateTimer;
@property (nonatomic, getter = isViewOnScreen) BOOL viewOnScreen;
@property (nonatomic, copy) NSArray *states;
@property (nonatomic) NSMutableDictionary *climateStates;
@property (nonatomic) NSMutableDictionary *lightStates;
@property (nonatomic) NSUInteger numberOfRoomLightsOn;
@property (nonatomic, copy) NSArray *climateValues;
@property (nonatomic) NSMutableDictionary *securityArmingStatusStates;
@property (nonatomic) NSMutableDictionary *securityStatusStates;
@property (nonatomic) NSDictionary *hvacStateToZoneMap;
@property (nonatomic) NSUInteger numberOfSecurityFaults;
@property (nonatomic) BOOL securityIsDisarmed;
@property (nonatomic) BOOL securityIsCameraOnly;
@property (nonatomic) SAVSecurityEntityStatus securityStatus;
@property (nonatomic) id orderingObserver;
@property (nonatomic) BOOL needsToReloadData;
@property NSMutableArray *mDataSource; // Actually needs to be atomic.
@property (nonatomic) dispatch_queue_t reloadQueue;
@property (nonatomic) SAVServiceGroup *serviceGroupToPresent;

@end

@implementation SCUServicesFirstDataModel

- (void)dealloc
{
    [[SavantControl sharedControl] removeSystemStatusObserver:self];
    [[SAVSettings userSettings] removeObserver:self.orderingObserver];
}

- (instancetype)initWithService:(SAVService *)service
{
    self = [super initWithService:service];

    if (self)
    {
        self.reloadQueue = dispatch_queue_create("com.savantav.Controller.ServicesFirstReloadQueue", DISPATCH_QUEUE_SERIAL);
        self.needsToReloadData = YES;
        self.appendPlusButton = NO;
        self.activeServiceMapping = [NSMutableDictionary dictionary];
        self.serviceCounts = [NSCountedSet set];
        self.updateTimer = [[SAVCoalescedTimer alloc] init];
        self.updateTimer.timeInverval = .1;
        [[SavantControl sharedControl].stateManager addActiveServiceObserver:self];
        self.climateStates = [NSMutableDictionary dictionary];
        self.lightStates = [NSMutableDictionary dictionary];
        self.climateValues = @[];
        self.securityArmingStatusStates = [NSMutableDictionary dictionary];
        self.securityStatusStates = [NSMutableDictionary dictionary];
        self.securityIsCameraOnly = YES;

        NSMutableArray *states = [NSMutableArray array];

        [[[SavantControl sharedControl].data allRooms] enumerateObjectsUsingBlock:^(SAVRoom *room, NSUInteger idx, BOOL *stop) {
            [states addObject:[NSString stringWithFormat:@"%@.RoomLightsAreOn", room.roomId]];
            [self room:room.roomId didUpdateActiveServiceList:[[SavantControl sharedControl].stateManager activeServiceListForRoom:room.roomId]];
        }];

        NSMutableDictionary *hvacStateToZoneMap = [NSMutableDictionary dictionary];
        
        SAVMutableService *dummyService = [[SAVMutableService alloc] init];
        dummyService.serviceId = @"SVC_ENV_HVAC";
        
        NSArray *climateEntities = [[SavantControl sharedControl].data HVACEntities:nil zone:nil service:dummyService];
        for (SAVHVACEntity *entity in climateEntities)
        {
            NSString *state = [entity stateFromType:SAVEntityState_CurrentTemp];
            [states addObject:state];
            hvacStateToZoneMap[state] = entity.zoneName;
        }

        self.hvacStateToZoneMap = [hvacStateToZoneMap copy];

        //-------------------------------------------------------------------
        // Fetch security arming status from entities
        //-------------------------------------------------------------------
        NSArray *securityEntities = [[SavantControl sharedControl].data securityEntities:nil zone:nil service:nil];

        for (SAVSecurityEntity *entity in securityEntities)
        {
            if (entity.type == SAVEntityType_Partition)
            {
                [states addObject:[entity stateFromType:SAVEntityState_PartitionArmingStatus]];
            }
            else
            {
                [states addObject:[entity stateFromType:SAVEntityState_SensorStatus]];
            }
        }

        if ([states count])
        {
            self.states = states;
            [[SavantControl sharedControl] registerForStates:self.states forObserver:self];
        }

        [[SavantControl sharedControl] addSystemStatusObserver:self];
    }

    return self;
}

#pragma mark - SCUDataSourceModel methods

- (void)viewWillAppear
{
    [super viewWillAppear];
    self.viewOnScreen = YES;
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    [self reloadData];
    [self registerObserver];
}

- (void)viewWillDisappear
{
    [super viewWillDisappear];
    self.viewOnScreen = NO;
}

- (void)loadButtons
{
    [self loadServicesData];
}

- (void)loadServicesData
{
    if ([self.mDataSource count] && !self.needsToReloadData)
    {
        return;
    }

    self.needsToReloadData = NO;
    self.modelObjects = @[];
    [self reloadData];
    [self.delegate setSpinnerVisible:YES];

    dispatch_async(self.reloadQueue, ^{
        NSArray *serviceGroups = [[SavantControl sharedControl].data allServiceGroups];
        NSMutableArray *dataSource = [NSMutableArray array];
        
        BOOL addedLighting = NO;
        BOOL addedShades = NO;
        BOOL addedClimate = NO;
        BOOL addedSecurity = NO;
        BOOL addedEnvironmentalService = NO;

        for (SAVServiceGroup *serviceGroup in serviceGroups)
        {
            if (([serviceGroup.serviceId hasPrefix:@"SVC_SETTINGS"] ||
                 [serviceGroup.serviceId hasPrefix:@"SVC_ENV"] ||
                 [serviceGroup.serviceId hasPrefix:@"SVC_COMM"] ||
                 [serviceGroup.serviceId hasPrefix:@"SVC_INFO"]) &&
                ![serviceGroup.serviceId isEqualToString:@"SVC_ENV_LIGHTING"] &&
                ![serviceGroup.serviceId isEqualToString:@"SVC_ENV_SHADE"] &&
                ![serviceGroup.serviceId isEqualToString:@"SVC_ENV_HVAC"] &&
                ![SAVService serviceID:serviceGroup.serviceId
                     matchesServiceIDs:@[@"SVC_ENV_SECURITYSYSTEM",
                                         @"SVC_ENV_USERLOGIN_SECURITYSYSTEM",
                                         @"SVC_ENV_SECURITYCAMERA"]
                  includeAudioVariants:NO])
            {
                continue;
            }

            if ([serviceGroup.serviceId isEqualToString:@"SVC_ENV_LIGHTING"])
            {
                if (addedLighting)
                {
                    continue;
                }
                else
                {
                    addedLighting = YES;
                    addedEnvironmentalService = YES;
                    serviceGroup.serviceId = @"SVC_ENV_LIGHTING";
                }
            }

            if ([serviceGroup.serviceId isEqualToString:@"SVC_ENV_SHADE"])
            {
                if (addedShades)
                {
                    continue;
                }
                else
                {
                    addedShades = YES;
                    addedEnvironmentalService = YES;
                    serviceGroup.serviceId = @"SVC_ENV_SHADE";
                }
            }

            if ([serviceGroup.serviceId isEqualToString:@"SVC_ENV_HVAC"])
            {
                if (addedClimate)
                {
                    continue;
                }
                else
                {
                    addedClimate = YES;
                    addedEnvironmentalService = YES;
                }
            }

            if ([SAVService serviceID:serviceGroup.serviceId
                    matchesServiceIDs:@[@"SVC_ENV_SECURITYSYSTEM",
                                        @"SVC_ENV_USERLOGIN_SECURITYSYSTEM",
                                        @"SVC_ENV_SECURITYCAMERA"]
                 includeAudioVariants:NO])
            {
                if ([serviceGroup.serviceId isEqualToString:@"SVC_ENV_SECURITYSYSTEM"] || [serviceGroup.serviceId isEqualToString:@"SVC_ENV_USERLOGIN_SECURITYSYSTEM"])
                {
                    self.securityIsCameraOnly = NO;
                }

                if (addedSecurity)
                {
                    continue;
                }
                else
                {
                    serviceGroup.serviceId = @"SVC_ENV_SECURITYSYSTEM";
                    addedSecurity = YES;
                    addedEnvironmentalService = YES;
                }
            }

            NSMutableDictionary *serviceData = [@{SCUDefaultCollectionViewCellKeyTitle: serviceGroup.alias ? serviceGroup.alias : serviceGroup.displayName,
                                                  SCUDefaultCollectionViewCellKeyModelObject: serviceGroup,
                                                  } mutableCopy];

            if (serviceGroup.iconName)
            {
                if ([UIDevice isPad] && [serviceGroup.serviceId hasPrefix:@"SVC_ENV"])
                {
                    serviceData[SCUDefaultCollectionViewCellKeyImage] = serviceGroup.iconName;
                }
                else
                {
                    serviceData[SCUDefaultCollectionViewCellKeyImage] = serviceGroup.iconName;
                }
            }

            NSUInteger width = 1;
            NSUInteger height = 1;

            if ([serviceGroup.serviceId hasPrefix:@"SVC_ENV"])
            {
                width = 2;
                height = 2;
                serviceData[SCUDefaultCollectionViewCellKeyTitle] = serviceGroup.displayName;

                if ([serviceGroup.serviceId isEqualToString:@"SVC_ENV_LIGHTING"])
                {
                    serviceData[SCUServicesFirstDataModelKeyIsLighting] = @YES;
                }
                else  if ([serviceGroup.serviceId isEqualToString:@"SVC_ENV_SHADE"])
                {
                    serviceData[SCUServicesFirstDataModelKeyIsShades] = @YES;
                }
                else if ([serviceGroup.serviceId isEqualToString:@"SVC_ENV_HVAC"])
                {
                    serviceData[SCUServicesFirstDataModelKeyIsClimate] = @YES;
                }
                else if ([serviceGroup.serviceId isEqualToString:@"SVC_ENV_SECURITYSYSTEM"])
                {
                    serviceData[SCUServicesFirstDataModelKeyIsSecurity] = @YES;
                }
                
                serviceData[SCUServicesFirstDataModelKeyIdentifier] = serviceGroup.serviceId;

                [dataSource insertObject:serviceData atIndex:0];
            }
            else
            {
                serviceData[SCUServicesFirstDataModelKeyIsAV] = @YES;
                [dataSource addObject:serviceData];
                serviceData[SCUServicesFirstDataModelKeyIdentifier] = serviceGroup.identifier;
            }

            SCUReorderableTileLayoutSpan *span = [SCUReorderableTileLayoutSpan spanWithWidth:width height:height];
            serviceData[SCUServicesFirstDataModelKeySpan] = span;
        }
        
        SAVMutableService *genericService = [[SAVMutableService alloc] init];
        genericService.serviceId = @"SVC_GEN_GENERIC";

        NSArray *requests = [[SavantControl sharedControl].data requests:genericService onlyVisible:YES];

        if ([requests count])
        {
            if ([requests count])
            {
                NSMutableDictionary *serviceData = [NSMutableDictionary dictionary];

                serviceData[SCUServicesFirstCollectionViewCellCycleValuesKey] = [requests arrayByMappingBlock:^id(SAVServiceRequest *serviceRequest) {
                    NSString *name = serviceRequest.request;

                    if (name)
                    {
                        return @{SCUServicesFirstCollectionViewCellSubordinateTextColorKey: [[SCUColors shared] color03shade07],
                                 SCUServicesFirstCollectionViewCellSubordinateTextKey: name,
                                 SCUDefaultTableViewCellKeyModelObject: serviceRequest,
                                 SCUDefaultTableViewCellKeyTitle: name};
                    }
                    else
                    {
                        return nil;
                    }
                }];

                serviceData[SCUDefaultCollectionViewCellKeyTitle] = NSLocalizedString(genericService.displayName, nil);
                serviceData[SCUDefaultCollectionViewCellKeyImage] = genericService.displayName;
                serviceData[SCUServicesFirstDataModelKeyIsGeneric] = @YES;
                serviceData[SCUServicesFirstDataModelKeyIdentifier] = @"SVC_GEN_GENERIC";
                serviceData[SCUServicesFirstDataModelKeySpan] = [SCUReorderableTileLayoutSpan spanWithWidth:1 height:1];
                
                [dataSource addObject:serviceData];
            }
        }
        
        if (!addedEnvironmentalService)
        {
            [self.delegate setAllItemsAre1x1:YES];
        }

        [self orderServices:dataSource];

        dispatch_async_main(^{
            [self.delegate setSpinnerVisible:NO];
            self.modelObjects = dataSource;
            self.mDataSource = dataSource;
            [self reloadData];
        });
    });
}

- (void)orderServices:(NSMutableArray *)services
{
    NSArray *userOrder = [[SAVSettings userSettings] objectForKey:SCUServicesFirstOrderingKey];

    if (userOrder)
    {
        [services sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
            NSComparisonResult result = NSOrderedAscending;

            NSInteger position1 = [userOrder indexOfObject:obj1[SCUServicesFirstDataModelKeyIdentifier]];
            NSInteger position2 = [userOrder indexOfObject:obj2[SCUServicesFirstDataModelKeyIdentifier]];

            result = position1 < position2 ? NSOrderedAscending : NSOrderedDescending;

            return result;
        }];
    }
    else
    {
        [services sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
            NSComparisonResult result = NSOrderedAscending;

            SAVService *service1 = obj1[SCUDefaultCollectionViewCellKeyModelObject];
            SAVService *service2 = obj2[SCUDefaultCollectionViewCellKeyModelObject];

            if ([service1.serviceId hasPrefix:@"SVC_ENV"])
            {
                result = NSOrderedAscending;
            }
            else
            {
                result = [[service1 alias] compare:[service2 alias] options:NSCaseInsensitiveNumericSearch];
            }
            
            return result;
        }];
    }
}

- (void)itemAtIndexPathTapped:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];
    SAVServiceGroup *serviceGroup = modelObject[SCUDefaultCollectionViewCellKeyModelObject];
    BOOL isGeneric = [modelObject[SCUServicesFirstDataModelKeyIsGeneric] boolValue];

    if (serviceGroup || isGeneric)
    {
        if ([serviceGroup.serviceId hasPrefix:@"SVC_AV"])
        {
            BOOL isActive = NO;

            if ([self.serviceCounts countForObject:serviceGroup.identifier])
            {
                isActive = YES;
            }

            BOOL presentService = NO;
            BOOL delay = NO;

            NSMutableSet *availableRooms = [NSMutableSet set];

            for (SAVService *service in serviceGroup.services)
            {
                if (service.zoneName)
                {
                    [availableRooms addObject:service.zoneName];
                }
            }

            if (isActive && [[SCUInterface sharedInstance] hasViewControllerForSerivce:serviceGroup.wildCardedService])
            {
                presentService = YES;
            }
            else if ([availableRooms count] == 1)
            {
                SAVService *service = [serviceGroup.services firstObject];
                SAVServiceRequest *request = [[SAVServiceRequest alloc] initWithService:service];
                request.request = @"PowerOn";
                [[SavantControl sharedControl] sendMessage:request];
                delay = YES;
                presentService = YES;
            }

            if (isActive && ![[SCUInterface sharedInstance] hasViewControllerForSerivce:serviceGroup.wildCardedService])
            {
                presentService = NO;
            }

            if (![[SCUInterface sharedInstance] hasViewControllerForSerivce:serviceGroup.wildCardedService])
            {
                presentService = NO;
            }

            if (presentService)
            {
                if (delay)
                {
                    self.serviceGroupToPresent = serviceGroup;
                }
                else
                {
                    [[SCUInterface sharedInstance] presentServicesFirstServiceGroup:serviceGroup animated:YES];
                }
            }
            else
            {
                [[SCUInterface sharedInstance] presentRoomsDistributionForServiceGroup:serviceGroup];
            }
        }
        else if ([serviceGroup.serviceId isEqualToString:@"SVC_ENV_SECURITYSYSTEM"] ||
                 [serviceGroup.serviceId isEqualToString:@"SVC_ENV_LIGHTING"] ||
                 [serviceGroup.serviceId isEqualToString:@"SVC_ENV_SHADE"] ||
                 [serviceGroup.serviceId isEqualToString:@"SVC_ENV_HVAC"])
        {
            [[SCUInterface sharedInstance] presentServicesFirstServiceGroup:serviceGroup animated:YES];
        }
        else if (isGeneric)
        {
            NSArray *commands = modelObject[SCUServicesFirstCollectionViewCellCycleValuesKey];
            SCUGenericCommandTableViewController *viewController = [[SCUGenericCommandTableViewController alloc] initWithCommands:commands];
            [self.delegate presentViewController:viewController];
        }
    }
}

- (NSDictionary *)modelObjectForIndexPath:(NSIndexPath *)indexPath isInEditMode:(BOOL)isInEditMode isMoving:(BOOL)isMoving
{
    NSDictionary *modelObject = [super modelObjectForIndexPath:indexPath isInEditMode:isInEditMode isMoving:isMoving];
    BOOL isAV = [modelObject[SCUServicesFirstDataModelKeyIsAV] boolValue];
    BOOL isLighting = [modelObject[SCUServicesFirstDataModelKeyIsLighting] boolValue];
    BOOL isSecurity = [modelObject[SCUServicesFirstDataModelKeyIsSecurity] boolValue];
    BOOL isClimate = [modelObject[SCUServicesFirstDataModelKeyIsClimate] boolValue];

    if (isAV || isLighting)
    {
        NSMutableDictionary *mModelObject = [modelObject mutableCopy];
        NSUInteger count = 0;

        if (isAV)
        {
            count += [self.serviceCounts countForObject:modelObject[SCUServicesFirstDataModelKeyIdentifier]];
        }
        else
        {
            count = self.numberOfRoomLightsOn;
        }

        if (count == 0)
        {
            mModelObject[SCUServicesFirstCollectionViewCellSubordinateTextKey] = NSLocalizedString(@"OFF", nil);
            mModelObject[SCUServicesFirstCollectionViewCellSubordinateTextColorKey] = [[SCUColors shared] color03shade07];

        }
        else if (count == 1)
        {
            mModelObject[SCUServicesFirstCollectionViewCellSubordinateTextKey] = [NSString stringWithFormat:NSLocalizedString(@"%lu ROOM", nil), count];
            mModelObject[SCUServicesFirstCollectionViewCellSubordinateTextColorKey] = [[SCUColors shared] color01];
        }
        else
        {
            mModelObject[SCUServicesFirstCollectionViewCellSubordinateTextKey] = [NSString stringWithFormat:NSLocalizedString(@"%lu ROOMS", nil), count];
            mModelObject[SCUServicesFirstCollectionViewCellSubordinateTextColorKey] = [[SCUColors shared] color01];
        }

        modelObject = [mModelObject copy];
    }
    else if (isClimate)
    {
        modelObject = [modelObject dictionaryByAddingObject:self.climateValues forKey:SCUServicesFirstCollectionViewCellCycleValuesKey];
    }
    else if (isSecurity)
    {
        NSMutableDictionary *mModelObject = [modelObject mutableCopy];

        if (self.securityStatus >= SAVSecurityEntityStatus_Ready)
        {
            mModelObject[SCUServicesFirstCollectionViewCellSubordinateTextColorKey] = [[SCUColors shared] color01];
        }
        else
        {
            mModelObject[SCUServicesFirstCollectionViewCellSubordinateTextColorKey] = [[SCUColors shared] color03shade07];
        }

        NSString *securityStatus = nil;

        switch (self.securityStatus)
        {
            case SAVSecurityEntityStatus_Trouble:
                securityStatus = [NSLocalizedString(@"Trouble", nil) uppercaseString];
                break;
            case SAVSecurityEntityStatus_Critical:
                securityStatus = [NSLocalizedString(@"Critical", nil) uppercaseString];
                break;
            default:
                securityStatus = [NSLocalizedString(@"Ready", nil) uppercaseString];
                break;
        }

        NSString *imageKey = @"Security";

        if (self.securityIsDisarmed)
        {
            imageKey = @"SecurityUnlocked";
        }
        
        if (self.securityIsCameraOnly)
        {
            imageKey = @"SecurityCamera";
        }

        if ([UIDevice isPad])
        {
            mModelObject[SCUDefaultCollectionViewCellKeyImage] = imageKey;
        }
        else
        {
            mModelObject[SCUDefaultCollectionViewCellKeyImage] = imageKey;
        }

        mModelObject[SCUServicesFirstCollectionViewCellSubordinateTextKey] = securityStatus;
        mModelObject[SCUServicesFirstCollectionViewCellSupplimentaryTextKey] = [@(self.numberOfSecurityFaults) stringValue];
        mModelObject[SCUServicesFirstCollectionViewCellSupplimentaryTextColorKey] = [[SCUColors shared] color01];

        modelObject = [mModelObject copy];
    }

    return modelObject;
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger cellType = [super cellTypeForIndexPath:indexPath];

    if (cellType == SCUEditableButtonCollectionViewCellTypeNormal && [[self _modelObjectForIndexPath:indexPath][SCUServicesFirstDataModelKeyIsClimate] boolValue])
    {
        cellType = SCUServicesFirstCollectionViewCellTypeClimate;
    }
    else if (cellType == SCUEditableButtonCollectionViewCellTypeNormal && ([[self _modelObjectForIndexPath:indexPath][SCUServicesFirstDataModelKeyIsLighting] boolValue] || [[self _modelObjectForIndexPath:indexPath][SCUServicesFirstDataModelKeyIsShades] boolValue]))
    {
        cellType = SCUServicesFirstCollectionViewCellTypeLarge;
    }
    else if (cellType == SCUEditableButtonCollectionViewCellTypeNormal && [[self _modelObjectForIndexPath:indexPath][SCUServicesFirstDataModelKeyIsSecurity] boolValue])
    {
        cellType = SCUServicesFirstCollectionViewCellTypeSecurity;
    }

    return cellType;
}

#pragma mark - SCUReorderableTileLayoutDelegate methods

- (SCUReorderableTileLayoutSpan *)layout:(SCUReorderableTileLayout *)layout spanForIndexPath:(NSIndexPath *)indexPath
{
    return [self _modelObjectForIndexPath:indexPath][SCUServicesFirstDataModelKeySpan];
}

- (void)layoutDidEndEditingMode:(SCUReorderableTileLayout *)layout
{
    NSMutableArray *identifierOrder = [NSMutableArray array];

    for (NSDictionary *modelObject in self.dataSource)
    {
        NSString *identifier = modelObject[SCUServicesFirstDataModelKeyIdentifier];
        if (identifier)
        {
            [identifierOrder addObject:identifier];
        }
    }

    if (![[[SAVSettings userSettings] objectForKey:SCUServicesFirstOrderingKey] isEqualToArray:identifierOrder])
    {
        [[SAVSettings userSettings] setObject:identifierOrder forKey:SCUServicesFirstOrderingKey];
        [[SAVSettings userSettings] synchronize];
    }
}

#pragma mark - ActiveServiceObserver methods

- (void)room:(NSString *)roomId didUpdateActiveServiceList:(NSArray *)services
{
    NSMutableArray *serviceIdentifiers = [NSMutableArray array];

    if (self.serviceGroupToPresent)
    {
        SAVService *service = [self.serviceGroupToPresent.services firstObject];

        for (SAVService *newService in services)
        {
            if ([service isEqualToService:newService])
            {
                [[SCUInterface sharedInstance] presentServicesFirstServiceGroup:self.serviceGroupToPresent animated:YES];
                self.serviceGroupToPresent = nil;
                break;
            }
        }
    }

    for (SAVService *service in services)
    {
        SAVMutableService *s = [service mutableCopy];
        s.zoneName = nil;
        s.variantId = nil;

        [serviceIdentifiers addObject:s.identifier];
    }

    self.activeServiceMapping[roomId] = serviceIdentifiers;

    SAVWeakSelf;
    [self.updateTimer addWorkWithKey:@"service" work:^{
        [wSelf updateActiveServiceStatus];
    }];
}

#pragma mark - StateDelegate methods

- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    if (stateUpdate.state && stateUpdate.value)
    {
        NSArray *components = [stateUpdate.state componentsSeparatedByString:@"."];
        NSString *stateName = [components lastObject];
        NSString *room = [components firstObject];

        if ([stateName isEqualToString:@"RoomLightsAreOn"])
        {
            self.lightStates[room] = @([stateUpdate.value boolValue]);

            SAVWeakSelf;
            [self.updateTimer addWorkWithKey:@"lights" work:^{
                [wSelf updateLightingStatus];
            }];
        }
        else if ([stateName hasPrefix:@"ThermostatCurrentTemperature"])
        {
            NSString *zoneName = self.hvacStateToZoneMap[stateUpdate.state];
            if (zoneName)
            {
                self.climateStates[zoneName] = @([stateUpdate.value integerValue]);
            }

            SAVWeakSelf;
            [self.updateTimer addWorkWithKey:@"climate" work:^{
                [wSelf updateClimateStatus];
            }];
        }
        else if ([stateName hasPrefix:@"CurrentPartitionArmingStatus"])
        {
            self.securityArmingStatusStates[stateUpdate.state] = @([SAVSecurityEntity armingStatusForString:stateUpdate.value]);

            SAVWeakSelf;
            [self.updateTimer addWorkWithKey:@"security" work:^{
                [wSelf updateSecurityStatus];
            }];
        }
        else if ([stateName hasPrefix:@"ZoneSummary"])
        {
            self.securityStatusStates[stateUpdate.state] = @([stateUpdate.value integerValue]);

            SAVWeakSelf;
            [self.updateTimer addWorkWithKey:@"security" work:^{
                [wSelf updateSecurityStatus];
            }];
        }
    }
}

#pragma mark -

- (void)updateActiveServiceStatus
{
    NSCountedSet *serviceCounts = [NSCountedSet set];

    [self.activeServiceMapping enumerateKeysAndObjectsUsingBlock:^(NSString *room, NSArray *serviceIdentifiers, BOOL *stop) {
        for (NSString *serviceIdentifier in serviceIdentifiers)
        {
            [serviceCounts addObject:serviceIdentifier];
        }
    }];

    self.serviceCounts = serviceCounts;

    //-------------------------------------------------------------------
    // Reload all the visible index paths that are AV.
    //-------------------------------------------------------------------
    NSMutableArray *visibleIndexPaths = [[self.delegate visibleIndexPaths] mutableCopy];

    NSUInteger lightingIndex = [self indexForServiceIdentifier:@"SVC_ENV_LIGHTING"];

    if (lightingIndex != NSNotFound)
    {
        [visibleIndexPaths removeObject:[NSIndexPath indexPathForItem:lightingIndex inSection:0]];
    }

    NSUInteger climateIndex = [self indexForServiceIdentifier:@"SVC_ENV_HVAC"];

    if (climateIndex != NSNotFound)
    {
        [visibleIndexPaths removeObject:[NSIndexPath indexPathForItem:climateIndex inSection:0]];
    }

    NSUInteger securityIndex = [self indexForServiceIdentifier:@"SVC_ENV_SECURITYSYSTEM"];

    if (securityIndex != NSNotFound)
    {
        [visibleIndexPaths removeObject:[NSIndexPath indexPathForItem:securityIndex inSection:0]];
    }

    [self reloadIndexPaths:visibleIndexPaths];
}

- (void)updateLightingStatus
{
    NSUInteger numberOfRoomLightsOn = 0;

    for (NSNumber *on in [self.lightStates allValues])
    {
        if ([on boolValue])
        {
            numberOfRoomLightsOn++;
        }
    }

    self.numberOfRoomLightsOn = numberOfRoomLightsOn;

    NSUInteger lightingIndex = [self indexForServiceIdentifier:@"SVC_ENV_LIGHTING"];

    if (lightingIndex != NSNotFound)
    {
        [self reloadIndexPaths:@[[NSIndexPath indexPathForItem:lightingIndex inSection:0]]];
    }
}

- (void)updateClimateStatus
{
    NSMutableArray *climateValues = [NSMutableArray array];

    for (NSString *room in [self.climateStates sav_sortedStringKeys])
    {
        NSString *temp = [SAVHVACEntity addDegreeSuffix:[NSString stringWithFormat:@"%lu", (unsigned long)[self.climateStates[room] unsignedIntegerValue]]];

        [climateValues addObject:@{SCUServicesFirstCollectionViewCellSubordinateTextKey: [room uppercaseString],
                                   SCUServicesFirstCollectionViewCellSubordinateTextColorKey: [[SCUColors shared] color01],
                                   SCUServicesFirstCollectionViewCellSupplimentaryTextKey: temp,
                                   SCUServicesFirstCollectionViewCellSupplimentaryTextColorKey: [[SCUColors shared] color04]}];
    }

    self.climateValues = climateValues;

    NSUInteger climateIndex = [self indexForServiceIdentifier:@"SVC_ENV_HVAC"];

    if (climateIndex != NSNotFound)
    {
        [self reloadIndexPaths:@[[NSIndexPath indexPathForItem:climateIndex inSection:0]]];
    }
}

- (void)updateSecurityStatus
{
    NSUInteger numberOfSecurityFaults = 0;
    SAVSecurityEntityStatus worstStatus = SAVSecurityEntityStatus_Unknown;

    for (NSNumber *value in [self.securityStatusStates allValues])
    {
        SAVSecurityEntityStatus status = [value integerValue];

        if (status > worstStatus)
        {
            worstStatus = status;
        }

        switch (status)
        {
            case SAVSecurityEntityStatus_Trouble:
            case SAVSecurityEntityStatus_Critical:
                numberOfSecurityFaults++;
                break;
            default:
                break;
        }
    }

    self.securityStatus = worstStatus;
    self.numberOfSecurityFaults = numberOfSecurityFaults;

    //-------------------------------------------------------------------
    // Calculate security arming status
    //-------------------------------------------------------------------
    BOOL isDisarmed = NO;

    for (NSNumber *value in [self.securityArmingStatusStates allValues])
    {
        if ([value integerValue] == SAVSecurityEntityArmingStatus_Disarmed)
        {
            isDisarmed = YES;
            break;
        }
    }

    self.securityIsDisarmed = isDisarmed;

    NSUInteger securityIndex = [self indexForServiceIdentifier:@"SVC_ENV_SECURITYSYSTEM"];

    if (securityIndex != NSNotFound)
    {
        [self reloadIndexPaths:@[[NSIndexPath indexPathForItem:securityIndex inSection:0]]];
    }
}

#pragma mark - System Status Delegate

- (void)connectionIsReady
{
    self.needsToReloadData = YES;
    [self registerObserver];
}

- (void)registerObserver
{
    if ([SavantControl sharedControl].isConnectedToSystem && !self.orderingObserver)
    {
        SAVWeakSelf;
        self.orderingObserver = [[SAVSettings userSettings] addObserverForKey:SCUServicesFirstOrderingKey
                                                                   usingBlock:^(NSString *key, id setting) {
                                                                       SAVStrongWeakSelf;
                                                                       dispatch_async(sSelf.reloadQueue, ^{
                                                                           [sSelf orderServices:sSelf.mDataSource];
                                                                           sSelf.modelObjects = sSelf.mDataSource;

                                                                           dispatch_async_main(^{
                                                                               [sSelf reloadData];
                                                                           });
                                                                       });
                                                                   }];
    }
}

#pragma mark -

- (NSUInteger)indexForServiceIdentifier:(NSString *)serviceIdentifier
{
    __block NSUInteger index = NSNotFound;

    [self.dataSource enumerateObjectsUsingBlock:^(NSDictionary *modelObject, NSUInteger idx, BOOL *stop) {
        NSString *sID = modelObject[SCUServicesFirstDataModelKeyIdentifier];
        if ([sID isEqualToString:serviceIdentifier])
        {
            index = idx;

            if (stop)
            {
                *stop = YES;
            }
        }
    }];

    return index;
}

- (void)reloadIndexPaths:(NSArray *)indexPaths
{
    if (self.viewOnScreen && [indexPaths count])
    {
        [self.delegate reloadIndexPaths:indexPaths];
    }
}

@end
