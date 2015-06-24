//
//  SCUServiceSelectorModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/9/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceSelectorModel.h"
#import "SCUExpandableDataSourceModel.h"
#import "SCUDataSourceModelPrivate.h"
#import "SCUInterface.h"
#import <SavantControl/SavantControl.h>
#import "SCUServiceSelectorTableViewCell.h"
#import "SCUAnalytics.h"

static NSString *SCUServiceSelectorModelTypeKey = @"SCUServiceSelectorModelTypeKey";
static NSString *SCUServiceSelectorModelTypeExpandableModelObjectsKey = @"SCUServiceSelectorModelTypeExpandableModelObjectsKey";
static NSString *SCUServiceSelectorModelTypeExpandableModelServicesKey = @"SCUServiceSelectorModelTypeExpandableModelServicesKey";
static NSString *SCUServiceSelectorModelTypeExpandableModelExpandableCellTypeKey = @"SCUServiceSelectorModelTypeExpandableModelExpandableCellTypeKey";
static NSString *SCUServiceSelectorModelTypeGenericRequestKey = @"SCUServiceSelectorModelTypeGenericRequestKey";
static NSString *SCUServiceSelectorModelTypeIsAVKey = @"SCUServiceSelectorModelTypeIsAVKey";

typedef NS_ENUM(NSUInteger, SCUServiceModelSectionType)
{
    SCUServiceModelSectionTypeRoomOff = 1,
    SCUServiceModelSectionTypeExpandable = 2,
};

@interface SCUServiceSelectorModel () <StateDelegate, ActiveServiceObserver>

@property (nonatomic) SAVRoom *room;
@property (nonatomic) NSArray *dataSource;
@property (nonatomic) NSArray *states;
@property (nonatomic) NSArray *currentServices;
@property (nonatomic) NSArray *triggerServices;
@property (nonatomic) NSMutableDictionary *triggerStates;
@property (nonatomic) BOOL lightsAreOn;
@property (nonatomic) SAVCoalescedTimer *tableUpdateTimer;
@property (nonatomic, getter = isViewOnScreen) BOOL viewOnScreen;
@property (nonatomic) NSArray *cachedServices;
@property (nonatomic) NSUInteger startingBubbleIndex;
@property (nonatomic) NSArray *originalDataSource; /* This stores the original service order */

@end

@implementation SCUServiceSelectorModel

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self.tableUpdateTimer = [[SAVCoalescedTimer alloc] init];
        self.tableUpdateTimer.timeInverval = .1;
    }

    return self;
}

- (void)listenToSwitch:(UISwitch *)toggleSwith forIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    toggleSwith.sav_didChangeHandler = ^(BOOL on) {
        SAVStrongWeakSelf;
        [sSelf toggleService:[sSelf serviceForIndexPath:indexPath] on:on];
    };
}

- (void)listenToSwitch:(UISwitch *)toggleSwith forChildIndexPath:(NSIndexPath *)childIndexPath below:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    toggleSwith.sav_didChangeHandler = ^(BOOL on) {
        SAVStrongWeakSelf;
        [sSelf toggleService:[sSelf serviceForChildInexPath:childIndexPath belowIndexPath:indexPath] on:on];
    };
}

- (void)toggleService:(SAVService *)service on:(BOOL)on
{
    SAVServiceRequest *request = [[SAVServiceRequest alloc] initWithService:service];
    request.request = on ? @"PowerOn" : @"PowerOff";
    [[SavantControl sharedControl] sendMessage:request];
}

- (void)listenToPowerButton:(SCUButton *)powerButton forIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    [powerButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        [wSelf powerOffService:[wSelf serviceForIndexPath:indexPath]];
    }];
}

- (void)listenToPowerButton:(SCUButton *)powerButton forChildIndexPath:(NSIndexPath *)childIndexPath below:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    [powerButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        [wSelf powerOffService:[self serviceForChildInexPath:childIndexPath belowIndexPath:indexPath]];
    }];
}

- (void)powerOffService:(SAVService *)service
{
    BOOL leaveServiceScreen = YES;
    SAVServiceRequest *request = nil;

    if ([service.serviceId isEqualToString:@"SVC_ENV_LIGHTING"])
    {
        leaveServiceScreen = NO;
        request = [[SAVServiceRequest alloc] init];
        request.serviceId = @"SVC_ENV_LIGHTING";
        request.zoneName = self.room.roomId;
        request.request = @"__RoomLightsOff";
    }
    else
    {
        request = [[SAVServiceRequest alloc] initWithService:service];
        request.request = @"PowerOff";
    }

    if (request)
    {
        [[SavantControl sharedControl] sendMessage:request];

        if (![[self class] isServiceWithoutControl:service])
        {
            [[SCUInterface sharedInstance].currentDrawerViewController closeDrawerAnimated:YES completion:^{
                if (leaveServiceScreen)
                {
                    [[SCUInterface sharedInstance].currentContentViewController leaveServiceScreenAnimated:YES];
                }
            }];
        }
    }
}

#pragma mark - SCUViewModel methods

- (void)viewWillAppear
{
    [super viewWillAppear];

    SAVRoom *room = [SCUInterface sharedInstance].currentRoom;

    if (![room isEqualToRoom:self.room])
    {
        [self enumerateModelObjects:^(NSIndexPath *indexPath) {
            if ([[self expandedIndexPaths] containsObject:indexPath])
            {
                [self toggleIndexPath:indexPath];
            }
        }];

        self.room = room;
        self.originalDataSource = [self parseData];
    }

    self.dataSource = [self bubbledDataFromData:self.originalDataSource];

    [self setupStates];

    [self enumerateModelObjects:^(NSIndexPath *indexPath) {
        NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];

        if (modelObject[SCUServiceSelectorModelTypeExpandableModelServicesKey] &&
            [modelObject[SCUServiceSelectorTableViewCellKeyIsPowered] boolValue] &&
            ![[self expandedIndexPaths] containsObject:indexPath])
        {
            [self toggleIndexPath:indexPath];
        }
    }];

    [self.delegate resetTableToTop];
    [self.delegate reloadTable];
}

- (void)viewDidAppear
{
    self.viewOnScreen = YES;
}

- (void)viewWillDisappear
{
    [super viewWillDisappear];
    self.triggerStates = nil;
    [self unregisterStates];

    __block BOOL toggled = NO;

    [self enumerateModelObjects:^(NSIndexPath *indexPath) {
        if ([[self expandedIndexPaths] containsObject:indexPath])
        {
            [self toggleIndexPath:indexPath];
            toggled = YES;
        }
    }];
}

- (void)viewDidDisappear
{
    self.viewOnScreen = NO;
}

#pragma mark - SCUDataSourceModel methods

- (BOOL)isFlat
{
    return NO;
}

- (NSDictionary *)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];

    if (!modelObject[SCUDefaultTableViewCellKeyBottomLineType])
    {
        if ([[self expandedIndexPaths] containsObject:indexPath])
        {
            modelObject = [modelObject dictionaryByAddingObject:@(SCUDefaultTableViewCellBottomLineTypeNone) forKey:SCUDefaultTableViewCellKeyBottomLineType];
        }
        else
        {
            modelObject = [modelObject dictionaryByAddingObject:@(SCUDefaultTableViewCellBottomLineTypePartial) forKey:SCUDefaultTableViewCellKeyBottomLineType];
        }
    }

    return [self parsedModelObjectFromModelObject:modelObject];
}

- (id)modelObjectForChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    NSArray *dataSource = [self _modelObjectForIndexPath:indexPath][SCUServiceSelectorModelTypeExpandableModelObjectsKey];
    return [self parsedModelObjectFromModelObject:dataSource[child.row]];
}

- (NSArray *)dataSourceBelowIndexPath:(NSIndexPath *)indexPath
{
    return [self _modelObjectForIndexPath:indexPath][SCUServiceSelectorModelTypeExpandableModelObjectsKey];
}

- (NSDictionary *)parsedModelObjectFromModelObject:(NSDictionary *)modelObject
{
    SAVService *service = modelObject[SCUDefaultTableViewCellKeyModelObject];

    if ([service.serviceId isEqualToString:@"SVC_ENV_LIGHTING"])
    {
        NSMutableDictionary *mModelObject = [modelObject mutableCopy];
        mModelObject[SCUServiceSelectorTableViewCellKeyIsPowered] = @(self.lightsAreOn);
        mModelObject[SCUServiceSelectorTableViewCellKeyShowsPowerButton] = @(self.lightsAreOn);
        modelObject = [mModelObject copy];
    }
    else
    {
        SCUServiceModelSectionType modelType = [modelObject[SCUServiceSelectorModelTypeKey] unsignedIntegerValue];

        if (modelType == SCUServiceModelSectionTypeRoomOff)
        {
            if ([self.currentServices count] || self.lightsAreOn)
            {
                modelObject = [modelObject dictionaryByAddingObject:@YES forKey:SCUServiceSelectorTableViewCellKeyIsPowered];
            }
        }
        else if (modelType == SCUServiceModelSectionTypeExpandable)
        {
            NSArray *services = modelObject[SCUServiceSelectorModelTypeExpandableModelServicesKey];

            for (SAVService *s in services)
            {
                if ([self.currentServices containsObject:s.serviceString] || [self.triggerStates[s.component] boolValue])
                {
                    modelObject = [modelObject dictionaryByAddingObject:@YES forKey:SCUServiceSelectorTableViewCellKeyIsPowered];
                    break;
                }
            }
        }
        else
        {
            if ([self.currentServices containsObject:service.serviceString] || [self.triggerStates[service.component] boolValue])
            {
                NSMutableDictionary *mModelObject = [modelObject mutableCopy];
                mModelObject[SCUServiceSelectorTableViewCellKeyIsPowered] = @(YES);

                if (modelType != SCUServiceModelSectionTypeExpandable)
                {
                    mModelObject[SCUServiceSelectorTableViewCellKeyShowsPowerButton] = @(YES);
                }

                modelObject = [mModelObject copy];
            }
        }
    }

    return modelObject;
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    SAVService *service = [self serviceForIndexPath:indexPath];

    SCUServiceSelectorModelCellType cellType = SCUServiceSelectorModelCellTypeNormal;

    if (!service)
    {
        cellType = SCUServiceSelectorModelCellTypePlaceholder;

        NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];
        SCUServiceModelSectionType modelType = [modelObject[SCUServiceSelectorModelTypeKey] unsignedIntegerValue];

        if (modelType == SCUServiceModelSectionTypeRoomOff || modelType == SCUServiceModelSectionTypeExpandable)
        {
            cellType = SCUServiceSelectorModelCellTypeNormal;
        }
    }

    return cellType;
}

- (NSUInteger)cellTypeForChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    return [[self _modelObjectForIndexPath:indexPath][SCUServiceSelectorModelTypeExpandableModelObjectsKey][child.row][SCUServiceSelectorModelTypeExpandableModelExpandableCellTypeKey] unsignedIntegerValue];
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    SCUServiceSelectorModelCellType cellType = (SCUServiceSelectorModelCellType)[self cellTypeForIndexPath:indexPath];

    switch (cellType)
    {
        case SCUServiceSelectorModelCellTypeNormal:
        {
            NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];
            SAVService *service = [self serviceForIndexPath:indexPath];

            if ([[self class] isServiceWithoutControl:service])
            {
                BOOL on = [self.triggerStates[service.component] boolValue];

                if (!on)
                {
                    [self toggleService:service on:YES];
                }
            }
            else if ([service.serviceId isEqualToString:@"SVC_GEN_GENERIC"])
            {
                SAVServiceRequest *request = modelObject[SCUServiceSelectorModelTypeGenericRequestKey];

                if (request)
                {
                    [SCUAnalytics recordEvent:@"Custom Command Executed" withKey:@"commandName" value:request.request];
                    [[SavantControl sharedControl] sendMessage:request];
                }
            }
            else if (service)
            {
                [[SCUInterface sharedInstance] presentService:service];
            }
            else
            {
                SCUServiceModelSectionType modelType = [modelObject[SCUServiceSelectorModelTypeKey] unsignedIntegerValue];

                if (modelType == SCUServiceModelSectionTypeRoomOff)
                {
                    SAVServiceRequest *request = [[SAVServiceRequest alloc] init];
                    request.request = @"PowerOff";
                    request.requestArguments = @{@"RoomOff": @YES};
                    request.zoneName = self.room.roomId;

                    [[SavantControl sharedControl] sendMessage:request];
                    [[SCUInterface sharedInstance].currentDrawerViewController closeDrawerAnimated:YES completion:NULL];

                }
                else if (modelType == SCUServiceModelSectionTypeExpandable)
                {
                    [self.delegate toggleIndexPath:indexPath];
                }
            }

            break;
        }
    }
}

- (void)selectChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    NSArray *dataSource = [self dataSourceBelowIndexPath:indexPath];
    NSDictionary *modelObject = dataSource[child.row];
    SAVService *service = modelObject[SCUDefaultTableViewCellKeyModelObject];

    if (service)
    {
        if ([service.serviceId isEqualToString:@"SVC_GEN_GENERIC"])
        {
            SAVServiceRequest *request = modelObject[SCUServiceSelectorModelTypeGenericRequestKey];

            if (request)
            {
                [SCUAnalytics recordEvent:@"Custom Command Executed" withKey:@"commandName" value:request.request];
                [[SavantControl sharedControl] sendMessage:request];
            }
        }
        else if ([[self class] isServiceWithoutControl:service])
        {
            BOOL on = [self.triggerStates[service.component] boolValue];

            if (!on)
            {
                [self toggleService:service on:YES];
            }
        }
        else
        {
            [[SCUInterface sharedInstance] presentService:service];
        }
    }
}

#pragma mark - ActiveServiceObserver

- (void)room:(NSString *)roomId didUpdateActiveServiceList:(NSArray *)services
{
    if ([self.room.roomId isEqualToString:roomId])
    {
        NSArray *stringServices = [services arrayByMappingBlock:^id(SAVService *service) {
            return service.serviceString;
        }];

        if (![self.currentServices isEqualToArray:stringServices])
        {
            self.currentServices = services;
            [self scheduleTableReload];
        }
    }
}

#pragma mark - StateDelegate

- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    if ([stateUpdate.state hasSuffix:@"IsOn"])
    {
        //-------------------------------------------------------------------
        // This is a trigger state.
        //-------------------------------------------------------------------
        NSUInteger firstDot = [stateUpdate.state rangeOfString:@"."].location;

        if (firstDot != NSNotFound)
        {
            NSString *stateName = [stateUpdate.state substringToIndex:firstDot];
            self.triggerStates[stateName] = stateUpdate.value;
            [self scheduleTableReload];
        }
    }
    else if ([stateUpdate.stateName hasSuffix:@"RoomLightsAreOn"])
    {
        self.lightsAreOn = [stateUpdate.value boolValue];
        [self scheduleTableReload];
    }
}

- (void)scheduleTableReload
{
    SAVWeakSelf;
    [self.tableUpdateTimer addWorkWithKey:@"reload" work:^{
        [wSelf reloadTable];
    }];
}

- (void)reloadTable
{
    [self.delegate reloadTable];
}

#pragma mark -

- (SAVService *)serviceForIndexPath:(NSIndexPath *)indexPath
{
    return (SAVService *)[self _modelObjectForIndexPath:indexPath][SCUDefaultTableViewCellKeyModelObject];
}

- (SAVService *)serviceForChildInexPath:(NSIndexPath *)childIndexPath belowIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];
    NSArray *serviceDicts = modelObject[SCUServiceSelectorModelTypeExpandableModelObjectsKey];
    return (SAVService *)serviceDicts[childIndexPath.row][SCUDefaultTableViewCellKeyModelObject];
}

#pragma mark - Parsing

+ (BOOL)isServiceWithoutControl:(SAVService *)service
{
    static NSSet *servicesWithoutControl = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        servicesWithoutControl = [[NSSet alloc] initWithObjects:@"SVC_ENV_GENERALTRIGGERCONTROLLEDDEVICE", @"SVC_ENV_GENERALRELAYCONTROLLEDDEVICE", nil];
    });

    return [servicesWithoutControl containsObject:[service.serviceId stringByReplacingOccurrencesOfString:@"AUDIO" withString:@""]];
}

+ (BOOL)shouldHideService:(SAVService *)service
{
    static NSSet *servicesToHide = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        servicesToHide = [[NSSet alloc] initWithObjects:@"SVC_GEN_GENERIC", nil];
    });

    BOOL shouldHide = [servicesToHide containsObject:service.serviceId];

    if (!shouldHide)
    {
        shouldHide = [service.serviceId sav_containsString:@"SVC_SETTINGS" options:NSCaseInsensitiveSearch];
    }

    if (!shouldHide)
    {
        shouldHide = [service.serviceId sav_containsString:@"SVC_INFO" options:NSCaseInsensitiveSearch];
    }

    return shouldHide;
}

- (NSDictionary *)groupServicesByServiceDisplayName:(NSArray *)services
{
    //-------------------------------------------------------------------
    // Split up the services by service ID/component
    //-------------------------------------------------------------------
    NSMutableDictionary *serviceToIDDict = [NSMutableDictionary dictionary];

    for (SAVService *service in services)
    {
        NSMutableDictionary *dict = serviceToIDDict[service.displayName];

        if (!dict)
        {
            dict = [NSMutableDictionary dictionary];
            serviceToIDDict[service.displayName] = dict;
        }

        NSMutableArray *array = dict[service.component];

        if (!array)
        {
            array = [NSMutableArray array];
            dict[service.component] = array;
        }

        [array addObject:service];
    }

    return [serviceToIDDict copy];
}

- (NSDictionary *)flattenedServicesFromGroupedServices:(NSDictionary *)groupedServices
{
    NSMutableDictionary *flattenedServices = [NSMutableDictionary dictionaryWithCapacity:[groupedServices count]];

    [groupedServices enumerateKeysAndObjectsUsingBlock:^(NSString *displayName, NSDictionary *services, BOOL *stop) {

        NSMutableArray *flattenedAVServices = [NSMutableArray array];

        for (NSArray *avServices in [services sav_valuesForSortedStringKeys])
        {
            [flattenedAVServices addObjectsFromArray:avServices];
        }

        flattenedServices[displayName] = [flattenedAVServices copy];
    }];

    return [flattenedServices copy];
}

- (NSArray *)parsedServicesFromFlattenedServices:(NSDictionary *)flattenedServices
{
    NSMutableArray *parsedServices = [NSMutableArray array];

    for (NSArray *services in [flattenedServices sav_valuesForSortedStringKeys])
    {
        if ([services count] == 1)
        {
            SAVService *service = [services firstObject];
            [parsedServices addObject:@[@{SCUDefaultTableViewCellKeyTitle: service.alias ? [service.alias uppercaseString] : @"Unknown",
                                          SCUServiceSelectorTableViewCellKeyServiceIconName: service.iconName,
                                          SCUDefaultTableViewCellKeyModelObject: service,
                                          SCUServiceSelectorModelTypeIsAVKey: @YES}]];
        }
        else
        {
            NSUInteger arrayMax = [services count] - 1;

            NSArray *expandableServices = [services arrayByMappingIndexBlock:^id(SAVService *service, NSUInteger idx, BOOL *stop) {
                return @{SCUDefaultTableViewCellKeyTitle: service.alias ? service.alias : @"Unknown",
                         SCUDefaultTableViewCellKeyModelObject: service,
                         SCUServiceSelectorModelTypeExpandableModelExpandableCellTypeKey: @(SCUServiceSelectorModelCellTypeNormal),
                         SCUServiceSelectorTableViewCellKeyExpandableImage: @(idx == arrayMax ? SCUServiceSelectorTableViewCellExpandableImageTypeLast: SCUServiceSelectorTableViewCellExpandableImageTypeFirstAndMiddle),
                         SCUDefaultTableViewCellKeyBottomLineType: @(idx == arrayMax ? SCUDefaultTableViewCellBottomLineTypePartial : SCUDefaultTableViewCellBottomLineTypeNone)};
            }];

            SAVService *defaultService = [services firstObject];
            [parsedServices addObject:@[@{SCUDefaultTableViewCellKeyTitle: [defaultService.displayName uppercaseString],
                                          SCUServiceSelectorTableViewCellKeyServiceIconName: defaultService.iconName,
                                          SCUServiceSelectorModelTypeExpandableModelObjectsKey: expandableServices,
                                          SCUServiceSelectorModelTypeKey: @(SCUServiceModelSectionTypeExpandable),
                                          SCUServiceSelectorModelTypeExpandableModelServicesKey: services,
                                          SCUServiceSelectorModelTypeIsAVKey: @YES}]];
        }
    }

    return [parsedServices copy];
}

- (NSArray *)parsedAVServices
{
    NSArray *services = [[self allServices] filteredArrayUsingBlock:^BOOL(SAVService *service) {
        return ![[self class] shouldHideService:service];
    }];

    self.triggerServices = [services filteredArrayUsingBlock:^BOOL(SAVService *service) {
        return [[self class] isServiceWithoutControl:service];
    }];

    NSArray *avServices = [services filteredArrayUsingBlock:^BOOL(SAVService *service) {
        return [service.serviceId hasPrefix:@"SVC_AV"] || [[self class] isServiceWithoutControl:service];
    }];

    avServices = [avServices sortedArrayUsingComparator:^NSComparisonResult(SAVService *service1, SAVService *service2) {
        return [service1.alias compare:service2.alias options:NSCaseInsensitiveNumericSearch];
    }];

    NSDictionary *groupedServices = [self groupServicesByServiceDisplayName:avServices];
    NSDictionary *flattedServices = [self flattenedServicesFromGroupedServices:groupedServices];
    return [self parsedServicesFromFlattenedServices:flattedServices];
}

- (NSArray *)parseData
{
    self.cachedServices = nil;
    self.startingBubbleIndex = 0;

    NSMutableArray *dataSource = [NSMutableArray array];

    if (self.room.hasLighting || self.room.hasFans)
    {
        NSArray *lightingServices = [self serviceFilteredWithServiceIDs:[NSSet setWithObjects:@"SVC_ENV_LIGHTING", nil]];

        if ([lightingServices count])
        {
            self.startingBubbleIndex++;
            SAVService *lightingService = [lightingServices firstObject];
            NSString *cellTitle;
            if (self.room.hasLighting && self.room.hasFans)
            {
                cellTitle = NSLocalizedString(@"LIGHTING AND FANS", nil);
            }
            else if (self.room.hasLighting)
            {
                cellTitle = NSLocalizedString(@"LIGHTING", nil);
            }
            else
            {
                 cellTitle = NSLocalizedString(@"FANS", nil);
            }
            
            [dataSource addObject:@[@{SCUDefaultTableViewCellKeyTitle: cellTitle,
                                      SCUServiceSelectorTableViewCellKeyIsPowered: @YES,
                                      SCUDefaultTableViewCellKeyModelObject: lightingService,
                                      SCUServiceSelectorTableViewCellKeyServiceIconName: lightingService.iconName ? lightingService.iconName : @""}]];
        }
    }

    if (self.room.hasShades)
    {
        NSArray *shadeServices = [self serviceFilteredWithServiceIDs:[NSSet setWithObjects:@"SVC_ENV_SHADE", nil]];

        if ([shadeServices count])
        {
            self.startingBubbleIndex++;
            SAVService *shadeService = [shadeServices firstObject];

            [dataSource addObject:@[@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"SHADES", nil),
                                      SCUServiceSelectorTableViewCellKeyIsPowered: @YES,
                                      SCUDefaultTableViewCellKeyModelObject: shadeService,
                                      SCUServiceSelectorTableViewCellKeyServiceIconName: shadeService.iconName ? shadeService.iconName : @""}]];
        }
    }



    if (self.room.hasHVAC)
    {
        NSArray *hvacServices = [self serviceFilteredWithServiceIDs:[NSSet setWithObject:@"SVC_ENV_HVAC"]];

        if ([hvacServices count])
        {
            self.startingBubbleIndex++;
            SAVService *hvacService = [hvacServices firstObject];

            [dataSource addObject:@[@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"CLIMATE", nil),
                                      SCUServiceSelectorTableViewCellKeyIsPowered: @YES,
                                      SCUDefaultTableViewCellKeyModelObject: hvacService,
                                      SCUServiceSelectorTableViewCellKeyServiceIconName: hvacService.iconName ? hvacService.iconName : @""}]];
        }
    }

    if (self.room.hasSecurity || self.room.hasCameras)
    {
        NSArray *securityServices = [self serviceFilteredWithServiceIDs:[NSSet setWithObjects:@"SVC_ENV_SECURITYSYSTEM", @"SVC_ENV_SECURITYCAMERA", @"SVC_ENV_USERLOGIN_SECURITYSYSTEM", nil]];

        if ([securityServices count])
        {
            self.startingBubbleIndex++;
            SAVService *securityService = [securityServices firstObject];

            [dataSource addObject:@[@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"SECURITY", nil),
                                      SCUServiceSelectorTableViewCellKeyIsPowered: @YES,
                                      SCUDefaultTableViewCellKeyModelObject: securityService,
                                      SCUServiceSelectorTableViewCellKeyServiceIconName: securityService.iconName ? securityService.iconName : @""}]];
        }
    }

    NSArray *poolAndSpaServices = [self serviceFilteredWithServiceIDs:[NSSet setWithObject:@"SVC_ENV_POOLANDSPA"]];

    if ([poolAndSpaServices count])
    {
        self.startingBubbleIndex++;
        SAVService *poolAndSpa = [poolAndSpaServices firstObject];

        [dataSource addObject:@[@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"POOL AND SPA", nil),
                                  SCUServiceSelectorTableViewCellKeyIsPowered: @YES,
                                  SCUDefaultTableViewCellKeyModelObject: poolAndSpa,
                                  SCUServiceSelectorTableViewCellKeyServiceIconName: poolAndSpa.iconName ? poolAndSpa.iconName : @""}]];
    }

    //-------------------------------------------------------------------
    // Attempt to find generic commands.
    //-------------------------------------------------------------------
    {
        SAVMutableService *service = [[SAVMutableService alloc] init];
        service.serviceId = @"SVC_GEN_GENERIC";
        service.zoneName = self.room.roomId;

        NSArray *requests = [[SavantControl sharedControl].data requests:service onlyVisible:YES];

        if ([requests count])
        {
            self.startingBubbleIndex++;

            if ([requests count] == 1)
            {
                SAVServiceRequest *request = [requests firstObject];

                [dataSource addObject:@[@{SCUDefaultTableViewCellKeyTitle: [request.request ? request.request : @"" uppercaseString],
                                          SCUServiceSelectorTableViewCellKeyIsPowered: @YES,
                                          SCUServiceSelectorTableViewCellKeyServiceIconName: service.iconName,
                                          SCUDefaultTableViewCellKeyModelObject: service,
                                          SCUServiceSelectorModelTypeGenericRequestKey: request}]];
            }
            else
            {
                NSUInteger arrayMax = [requests count] - 1;

                NSArray *expandableServices = [requests arrayByMappingIndexBlock:^id(SAVServiceRequest *request, NSUInteger idx, BOOL *stop) {
                    return @{SCUDefaultTableViewCellKeyTitle: request.request ? request.request : @"",
                             SCUServiceSelectorTableViewCellKeyIsPowered: @YES,
                             SCUDefaultTableViewCellKeyModelObject: service,
                             SCUServiceSelectorModelTypeGenericRequestKey: request,
                             SCUServiceSelectorModelTypeExpandableModelExpandableCellTypeKey: @(SCUServiceSelectorModelCellTypeNormal),
                             SCUServiceSelectorTableViewCellKeyExpandableImage: @(idx == arrayMax ? SCUServiceSelectorTableViewCellExpandableImageTypeLast: SCUServiceSelectorTableViewCellExpandableImageTypeFirstAndMiddle),
                             SCUDefaultTableViewCellKeyBottomLineType: @(idx == arrayMax ? SCUDefaultTableViewCellBottomLineTypePartial : SCUDefaultTableViewCellBottomLineTypeNone)};
                }];

                [dataSource addObject:@[@{SCUDefaultTableViewCellKeyTitle: [service.displayName uppercaseString],
                                          SCUServiceSelectorTableViewCellKeyIsPowered: @YES,
                                          SCUServiceSelectorTableViewCellKeyServiceIconName: service.iconName,
                                          SCUServiceSelectorModelTypeExpandableModelObjectsKey: expandableServices,
                                          SCUServiceSelectorModelTypeKey: @(SCUServiceModelSectionTypeExpandable)}]];
            }
        }
    }

    [dataSource addObjectsFromArray:[self parsedAVServices]];

    if ([dataSource count])
    {
        self.startingBubbleIndex++;
        [dataSource insertObject:@[@{SCUDefaultTableViewCellKeyTitle: [NSString stringWithFormat:NSLocalizedString(@"%@ OFF", nil), [self.room.roomId uppercaseString]],
                                     SCUServiceSelectorModelTypeKey: @(SCUServiceModelSectionTypeRoomOff),
                                     SCUServiceSelectorTableViewCellKeyServiceIconName: @"Power",
                                     SCUDefaultTableViewCellKeyBottomLineType: @(SCUDefaultTableViewCellBottomLineTypeFull)}]
                         atIndex:0];
    }
    else
    {
        [dataSource addObject:@[@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"No Services Available", nil)}]];
    }

    self.cachedServices = nil;
    return [dataSource copy];
}

- (NSArray *)bubbledDataFromData:(NSArray *)originalDataSource
{
    NSArray *activeServices = [[SavantControl sharedControl].stateManager activeServiceListForRoom:self.room.roomId];

    NSMutableArray *dataSource = [NSMutableArray array];
    NSUInteger insertIndex = self.startingBubbleIndex;

    for (NSArray *array in originalDataSource)
    {
        BOOL addObjectLast = YES;

        NSDictionary *modelObject = [array firstObject];

        if ([modelObject[SCUServiceSelectorModelTypeIsAVKey] boolValue])
        {
            SAVService *service = modelObject[SCUDefaultTableViewCellKeyModelObject];
            NSArray *services = nil;

            if (service)
            {
                services = @[service];
            }
            else
            {
                services = modelObject[SCUServiceSelectorModelTypeExpandableModelServicesKey];
            }

            for (SAVService *activeService in activeServices)
            {
                if ([services containsObject:activeService])
                {
                    [dataSource insertObject:array atIndex:insertIndex];
                    insertIndex++;
                    addObjectLast = NO;
                    break;
                }
            }
        }

        if (addObjectLast)
        {
            [dataSource addObject:array];
        }
    }

    return [dataSource copy];
}

- (NSArray *)allServices
{
    if (!self.cachedServices)
    {
        SAVMutableService *service = [[SAVMutableService alloc] init];
        service.zoneName = self.room.roomId;
        self.cachedServices = [[SavantControl sharedControl].data servicesFilteredByService:service];
    }

    return self.cachedServices;
}

- (NSArray *)serviceFilteredWithServiceIDs:(NSSet *)serviceIDs
{
    return [[self allServices] filteredArrayUsingBlock:^BOOL(SAVService *service) {
        if ([serviceIDs containsObject:service.serviceId])
        {
            return YES;
        }
        else
        {
            return NO;
        }
    }];
}

#pragma mark -

- (void)setupStates
{
    self.lightsAreOn = NO;
    self.triggerStates = [NSMutableDictionary dictionary];

    [[SavantControl sharedControl].stateManager addActiveServiceObserver:self];
    self.currentServices = [[[SavantControl sharedControl].stateManager activeServiceListForRoom:self.room.roomId] arrayByMappingBlock:^id(SAVService *service) {
        return service.serviceString;
    }];

    [self scheduleTableReload];

    NSMutableArray *states = [NSMutableArray array];

    [states addObjectsFromArray:[self.triggerServices arrayByMappingBlock:^id(SAVService *service) {
        return [NSString stringWithFormat:@"%@.%@.IsOn", service.component, service.logicalComponent];
    }]];
    
    [states addObject:[NSString stringWithFormat:@"%@.RoomLightsAreOn", self.room.roomId]];
    
    self.states = [states copy];
    [[SavantControl sharedControl] registerForStates:self.states forObserver:self];
}

- (void)unregisterStates
{
    [[SavantControl sharedControl] unregisterForStates:self.states forObserver:self];
    [[SavantControl sharedControl].stateManager removeActiveServiceObserver:self];
}

@end
