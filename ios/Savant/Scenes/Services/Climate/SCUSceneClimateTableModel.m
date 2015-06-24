//
//  SCUSceneClimateTableModel.m
//  SavantController
//
//  Created by Stephen Silber on 8/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneClimatePickerCell.h"
#import "SCUSceneClimateTableModel.h"
#import "SCUDefaultTableViewCell.h"
#import "SCUDataSourceModelPrivate.h"
@import SDK;
@import Extensions;

typedef NS_ENUM(NSUInteger, SCUSceneClimateModelType)
{
    SCUSceneClimateModelTypeThermostatCoolPoint,
    SCUSceneClimateModelTypeThermostatHeatPoint,
    SCUSceneClimateModelTypeThermostatFanOptions,
    SCUSceneClimateModelTypeThermostatModeOptions,
    SCUSceneClimateModelTypeHumidity,
    SCUSceneClimateModelTypeHumidify,
    SCUSceneClimateModelTypeDehumidify
};

typedef NS_ENUM(NSUInteger, SCUSceneClimateModeType)
{
    SCUSceneClimateModeTypeAuto,
    SCUSceneClimateModeTypeHeat,
    SCUSceneClimateModeTypeCool,
    SCUSceneClimateModeTypeOff
};


static NSString *SCUSceneClimateTableModelKeySectionType   = @"SCUSceneClimateTableModelKeySectionType";
static NSString *SCUSceneClimateTableModelKeySectionArray  = @"SCUSceneClimateTableModelKeySectionArray";
static NSString *SCUSceneClimateTableModelKeySectionTitle  = @"SCUSceneClimateTableModelKeySectionTitle";
static NSString *SCUSceneClimateTableModelKeyCellType      = @"SCUSceneClimateTableModelKeyCellType";
static NSString *SCUSceneClimateTableModelKeyChildCellType = @"SCUSceneClimateTableModelKeyChildCellType";
static NSString *SCUSceneClimateModelTypeKey               = @"SCUSceneClimateModelTypeKey";
static NSString *SCUSceneClimateModeTypeKey                = @"SCUSceneClimateModeTypeKey";
static NSString *SCUSceneClimateTableModelObjectKeyScope   = @"SCUSceneClimateTableModelObjectKeyScope";
static NSString *SCUSceneClimateTableModelKeyCellChildren  = @"SCUSceneClimateTableModelKeyCellChildren";
static NSString *SCUClimateTableViewCellKeyValue           = @"SCUClimateTableViewCellKeyValue";

@interface SCUSceneClimateTableModel ()

@property (nonatomic) SAVScene *scene;
@property (nonatomic) SAVService *service;
@property (nonatomic, copy) NSArray *sceneServices;
@property (nonatomic, copy) NSArray *dataSource;
@property (nonatomic, copy) NSArray *climateCommands;
@property (nonatomic, copy) NSDictionary *childrenDataSource;
@property (nonatomic) NSMutableDictionary *roomImages;
@property (nonatomic) NSArray *observers;
@property NSDictionary *entityForDevice;
@property (nonatomic) BOOL temperatureOptionsShow;
@property (nonatomic) NSArray *entities;

@property NSString *coolPoint, *heatPoint;
@property NSInteger minCoolPoint, minHeatPoint;

@end

@implementation SCUSceneClimateTableModel

- (instancetype)initWithScene:(SAVScene *)scene service:(SAVService *)service sceneService:(SAVSceneService *)sceneService
{
    self = [super init];
    
    if (self)
    {
        self.scene = scene;
        self.service = service;
        
        SAVData *data = [Savant data];
        self.entities = [data HVACEntities:nil zone:self.service.zoneName service:nil];
        
        [self buildChildrenDataSource];
    }
    
    return self;
}

- (void)loadDataIfNecessary
{
    if (!self.dataSource)
    {
        [self buildDataSource];
    }
    
    if (self.observers)
    {
        return;
    }
    
    if (!self.roomImages)
    {
        self.roomImages = [NSMutableDictionary dictionary];
    }
    
    NSMutableArray *observers = [NSMutableArray array];
    NSDictionary *zoneToRooms = [[Savant data] HVACRoomsInZones];
    
    for (NSString *room in zoneToRooms[self.service.zoneName])
    {
        SAVWeakSelf;
        id observer = [[Savant images] addObserverForKey:room type:SAVImageTypeRoomImage size:SAVImageSizeMedium blurred:NO andCompletionHandler:^(UIImage *image, BOOL isDefault) {
            if (image)
            {
                wSelf.roomImages[room] = image;
            }
            
            [self.delegate reloadTableHeader];
        }];
        
        [observers addObject:observer];
    }
}

#pragma mark - Helpers

- (BOOL)entityContainsCommand:(NSString *)command
{
    return [self.entity.service.commands containsObject:command];
}

- (NSArray *)modesAvailableForService:(SAVService *)service
{
    NSMutableArray *modes = [NSMutableArray array];
    
    if ([self entity].heatSetPoint && [self entityContainsCommand:@"SetHVACModeHeat"])
    {
        [modes addObject:@(SCUSceneClimateModeTypeHeat)];
    }
    if ([self entity].coolSetPoint && [self entityContainsCommand:@"SetHVACModeCool"])
    {
        [modes addObject:@(SCUSceneClimateModeTypeCool)];
    }
    if ([self entityContainsCommand:@"SetHVACModeAuto"]  && [self entity].autoMode)
    {
        [modes addObject:@(SCUSceneClimateModeTypeAuto)];
    }
    if ([self entityContainsCommand:@"SetHVACModeOff"])
    {
        [modes addObject:@(SCUSceneClimateModeTypeOff)];
    }

    return [modes copy];
}

/**
 *  Fetch a random entity for shared methods
 *
 *  @return entity
 */
- (SAVHVACEntity *)entity
{
    return self.entities.count ? [self.entities firstObject] : nil;
}

/**
 *  Fetch the raw state name for a type
 *
 *  @param type SCUSceneClimateModelType
 *
 *  @return stateName
 */
- (NSString *)stateNameForType:(SCUSceneClimateModelType)type
{
    NSString *stateName = nil;
    
    switch (type)
    {
        case SCUSceneClimateModelTypeThermostatCoolPoint:
            stateName = [self.entity nameFromState:[self.entity stateFromType:SAVEntityState_CoolPoint]];
            break;
        case SCUSceneClimateModelTypeThermostatHeatPoint:
            stateName = [self.entity nameFromState:[self.entity stateFromType:SAVEntityState_HeatPoint]];
            break;
        case SCUSceneClimateModelTypeHumidity:
            stateName = [self.entity nameFromState:[self.entity stateFromType:SAVEntityState_HumidityPoint]];
            break;
        case SCUSceneClimateModelTypeHumidify:
            stateName = [self.entity nameFromState:[self.entity stateFromType:SAVEntityState_HumidifyPoint]];
            break;
        case SCUSceneClimateModelTypeDehumidify:
            stateName = [self.entity nameFromState:[self.entity stateFromType:SAVEntityState_DehumidifyPoint]];
            break;
        case SCUSceneClimateModelTypeThermostatFanOptions:
            stateName = [self.entity nameFromState:[self.entity stateFromType:SAVEntityState_Fanmode]];
            break;
        case SCUSceneClimateModelTypeThermostatModeOptions:
            stateName = [self.entity nameFromState:[self.entity stateFromType:SAVEntityState_Mode]];
            break;
    }
    
    return stateName;
}

/**
 *  Return toe mode type from the string value
 *
 *  @param mode NSString
 *
 *  @return SCUSceneClimateModeType
 */
- (SCUSceneClimateModeType)modeTypeFromString:(NSString *)mode
{
    if ([mode isEqualToString:NSLocalizedString(@"Auto", nil)])
    {
        return  SCUSceneClimateModeTypeAuto;
    }
    if ([mode isEqualToString:NSLocalizedString(@"Heat", nil)])
    {
        return SCUSceneClimateModeTypeHeat;
    }
    if ([mode isEqualToString:NSLocalizedString(@"Cool", nil)])
    {
        return SCUSceneClimateModeTypeCool;
    }
    if ([mode isEqualToString:NSLocalizedString(@"Off", nil)])
    {
        return SCUSceneClimateModeTypeOff;
    }
    
    return SCUSceneClimateModeTypeAuto;
}

/**
 *  Return mode string from SCUSceneClimateModeType
 *
 *  @param type SCUSceneClimateModeType
 *
 *  @return mode string
 */
- (NSString *)modeStringFromType:(SCUSceneClimateModeType)type
{
    switch (type)
    {
        case SCUSceneClimateModeTypeAuto:
            return NSLocalizedString(@"Auto", nil);
        case SCUSceneClimateModeTypeHeat:
            return NSLocalizedString(@"Heat", nil);
        case SCUSceneClimateModeTypeCool:
            return NSLocalizedString(@"Cool", nil);
        case SCUSceneClimateModeTypeOff:
            return NSLocalizedString(@"Off", nil);
    }
    
    return nil;
}

- (NSSet *)temperatureModeOptions
{
    NSMutableSet *setPoints = [NSMutableSet set];

    if (self.entity.heatSetPoint && [self entityContainsCommand:@"SetHVACModeHeat"])
    {
        [setPoints addObject:@(SCUSceneClimateModeTypeHeat)];
    }
    if (self.entity.coolSetPoint && [self entityContainsCommand:@"SetHVACModeCool"])
    {
        [setPoints addObject:@(SCUSceneClimateModeTypeCool)];
    }
    if ([self entityContainsCommand:@"SetHVACModeAuto"]  && self.entity.autoMode)
    {
        [setPoints addObject:@(SCUSceneClimateModeTypeAuto)];
    }
    if ([self entityContainsCommand:@"SetHVACModeOff"])
    {
        [setPoints addObject:@(SCUSceneClimateModeTypeOff)];
    }
    return [setPoints copy];
}

/**
 *  Fetch the value for a given type from the scene service
 *
 *  @param type SCUSceneClimateModelType
 *
 *  @return value
 */
- (NSString *)valueForType:(SCUSceneClimateModelType)type
{
    return [self valueForStateName:[self stateNameForType:type]];
}

- (NSArray *)shownTypesForModeType:(SCUSceneClimateModeType)type
{
    NSMutableArray *types = [NSMutableArray array];
    
    // Check if commands are available, then add them to the array
    switch (type)
    {
        case SCUSceneClimateModeTypeAuto:
            if ([self.climateCommands containsObject:@(SCUSceneClimateModeTypeCool)])
            {
                [types addObject:@(SCUSceneClimateModeTypeCool)];
            }
            if ([self.climateCommands containsObject:@(SCUSceneClimateModeTypeHeat)])
            {
                [types addObject:@(SCUSceneClimateModeTypeHeat)];
            }
            break;
        case SCUSceneClimateModeTypeHeat:
            if ([self.climateCommands containsObject:@(SCUSceneClimateModeTypeHeat)])
            {
                [types addObject:@(SCUSceneClimateModeTypeHeat)];
            }
            break;
        case SCUSceneClimateModeTypeCool:
            if ([self.climateCommands containsObject:@(SCUSceneClimateModeTypeCool)])
            {
                [types addObject:@(SCUSceneClimateModeTypeCool)];
            }
            break;
    }
    
    return [types copy];
}

- (NSIndexPath *)heatInsertionIndexPathForSelectedMode:(NSString *)selectedMode
{
    NSInteger row = 0;
    if ([selectedMode isEqualToString:[self modeStringFromType:SCUSceneClimateModeTypeAuto]])
    {
        if ([self.climateCommands containsObject:@(SCUSceneClimateModeTypeCool)])
        {
            row = 1;
        }
    }
    
    return [NSIndexPath indexPathForRow:row inSection:0];
}

- (NSIndexPath *)indexPathForModeType:(SCUSceneClimateModeType)type andSelectedMode:(NSString *)selectedMode
{
    NSInteger row = 0;
    for (NSDictionary *cell in self.dataSource[0][SCUSceneClimateTableModelKeySectionArray])
    {
        if ([cell[SCUSceneClimateModeTypeKey] integerValue] == type)
        {
            return [NSIndexPath indexPathForRow:row inSection:0];
        }
        row++;
    }
    
    if (type == SCUSceneClimateModeTypeCool && [self.climateCommands containsObject:@(SCUSceneClimateModeTypeCool)])
    {
        return [NSIndexPath indexPathForRow:0 inSection:0];
    }
    
    if (type == SCUSceneClimateModeTypeHeat && [self.climateCommands containsObject:@(SCUSceneClimateModeTypeHeat)])
    {
        return [self heatInsertionIndexPathForSelectedMode:selectedMode];
    }
    
    return nil;
}

/**
 *  Toggle HVAC modes. Update the desired temperature to the correct state.
 *
 *  @param selectedMode mode
 */
- (void)changeModes:(NSString *)selectedMode fromIndexPath:(NSIndexPath *)modeIndexPath
{
    NSString *heatState = [self stateNameForType:SCUSceneClimateModelTypeThermostatHeatPoint];
    NSString *coolState = [self stateNameForType:SCUSceneClimateModelTypeThermostatCoolPoint];
    
    NSString *currentMode = [self valueForStateName:[self stateNameForType:SCUSceneClimateModelTypeThermostatModeOptions]];
    
    if ([currentMode isEqualToString:selectedMode])
    {
        return;
    }
    
    [self setValue:selectedMode forStateName:[self stateNameForType:SCUSceneClimateModelTypeThermostatModeOptions]];
    [self.delegate reloadIndexPath:modeIndexPath];
    [self.delegate reloadChildrenBelowIndexPath:modeIndexPath animated:NO];

    SCUSceneClimateModeType currentType = [self modeTypeFromString:currentMode];
    SCUSceneClimateModeType selectedType = [self modeTypeFromString:selectedMode];
    
    NSSet *selectedOptions = [NSSet setWithArray:[self shownTypesForModeType:selectedType]];
    NSSet *currentOptions = [NSSet setWithArray:[self shownTypesForModeType:currentType]];
    
    NSMutableArray *indexPathsToRemove = [NSMutableArray array];
    NSMutableArray *indexPathsToInsert = [NSMutableArray array];
    
    for (id type in [[currentOptions sav_minusSet:selectedOptions] allObjects])
    {
        SCUSceneClimateModeType modeType = [type integerValue];
        NSIndexPath *indexPath = [self indexPathForModeType:modeType andSelectedMode:selectedMode];
        if (indexPath)
        {
            [indexPathsToRemove addObject:indexPath];
        }
    }
    
    for (id type in [[selectedOptions sav_minusSet:currentOptions] allObjects])
    {
        SCUSceneClimateModeType modeType = [type integerValue];
        NSIndexPath *indexPath = [self indexPathForModeType:modeType andSelectedMode:selectedMode];
        if (indexPath)
        {
            [indexPathsToInsert addObject:indexPath];
        }
    }
    
    if ([selectedMode isEqualToString:@"Auto"])
    {
        [self setValue:self.coolPoint forStateName:coolState];
        [self setValue:self.heatPoint forStateName:heatState];
    }
    else if ([selectedMode isEqualToString:@"Heat"])
    {
        [self setValue:nil forStateName:coolState];
        [self setValue:self.heatPoint forStateName:heatState];
    }
    else if ([selectedMode isEqualToString:@"Cool"])
    {
        [self setValue:nil forStateName:heatState];
        [self setValue:self.coolPoint forStateName:coolState];
    }
    else if([selectedMode isEqualToString:@"Off"])
    {
        [self setValue:nil forStateName:heatState];
        [self setValue:nil forStateName:coolState];
    }

    [self buildDataSource];
    
    // If we are just changing out a single cell, we do not want to remove the cell (animated) and then add another one in (animated)
    if (indexPathsToRemove.count == indexPathsToInsert.count && indexPathsToInsert.count)
    {
        for (NSInteger i = 0; i < (long)indexPathsToInsert.count; i++)
        {
            if ([indexPathsToRemove[i] isEqual:indexPathsToInsert[i]])
            {
                [self.delegate reloadData];
                return;
            }
        }
    }
    
    // Indexpaths need to be sorted to avoid crash when looping through and updating expanded indexes
    if (indexPathsToRemove.count)
    {
        [indexPathsToRemove sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSInteger r1 = [obj1 row];
            NSInteger r2 = [obj2 row];
            if (r1 < r2)
            {
                return (NSComparisonResult)NSOrderedDescending;
            }
            if (r1 > r2)
            {
                return (NSComparisonResult)NSOrderedAscending;
            }
            return (NSComparisonResult)NSOrderedSame;
        }];
        [self.delegate removeRowsAtIndexPaths:indexPathsToRemove];
    }
    
    if (indexPathsToInsert.count)
    {
        [indexPathsToInsert sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSInteger r1 = [obj1 row];
            NSInteger r2 = [obj2 row];
            if (r1 > r2)
            {
                return (NSComparisonResult)NSOrderedDescending;
            }
            if (r1 < r2)
            {
                return (NSComparisonResult)NSOrderedAscending;
            }
            return (NSComparisonResult)NSOrderedSame;
        }];
        [self.delegate addRowsAtIndexPaths:indexPathsToInsert];
        [self.delegate reconfigureIndexPaths:indexPathsToInsert];
    }
}

- (void)listenToPickerView:(SCUClimatePicker *)pickerView forParentIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    [pickerView setCallback:^(SCUClimatePicker *pickerView, NSInteger row, NSInteger component) {
        [wSelf updatePickerView:pickerView forParentIndexPath:indexPath withRow:row];
    }];
}

- (void)validateNewPickerValuesForPickerView:(SCUClimatePicker *)pickerView andIndexPath:(NSIndexPath *)indexPath andRow:(NSInteger)row
{
    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];
    
    if ([modelObject[SCUSceneClimateModelTypeKey] unsignedIntegerValue] == SCUSceneClimateModelTypeThermostatHeatPoint)
    {
        NSInteger value = row + pickerView.minimumValue;
        self.heatPoint = value >= self.minHeatPoint ? [NSString stringWithFormat:@"%li", (long)value] : nil;

        if (row) // not default
        {
            NSInteger coolValue = [[self valueForType:SCUSceneClimateModelTypeThermostatCoolPoint] integerValue];
            if ((coolValue - 5) <= value)
            {
                NSString *newValue = [NSString stringWithFormat:@"%li", (long)(value + 5)];
                self.coolPoint = [newValue integerValue] >= self.minCoolPoint ? newValue : nil;
                [self setValue:newValue forStateName:[self stateNameForType:SCUSceneClimateModelTypeThermostatCoolPoint]];
            }
        }
    }
    if ([modelObject[SCUSceneClimateModelTypeKey] unsignedIntegerValue] == SCUSceneClimateModelTypeThermostatCoolPoint)
    {
        NSInteger value = row + pickerView.minimumValue;
        self.coolPoint = value >= self.minCoolPoint ? [NSString stringWithFormat:@"%li", (long)value] : nil;

        if (row) // not default
        {
            NSInteger heatValue = [[self valueForType:SCUSceneClimateModelTypeThermostatHeatPoint] integerValue];

            if ((heatValue + 5) >= value)
            {
                NSString *newValue = [NSString stringWithFormat:@"%li", (long)(value - 5)];
                self.heatPoint = [newValue integerValue] >= self.minHeatPoint ? newValue : nil;
                [self setValue:newValue forStateName:[self stateNameForType:SCUSceneClimateModelTypeThermostatHeatPoint]];
            }
        }
    }
    if ([modelObject[SCUSceneClimateModelTypeKey] unsignedIntegerValue] == SCUSceneClimateModelTypeHumidify)
    {
        NSInteger value = row + pickerView.minimumValue;

        if (row)
        {
            NSInteger dehumidifyValue = [[self valueForType:SCUSceneClimateModelTypeDehumidify] integerValue];
            if ((dehumidifyValue - 5) <= value)
            {
                NSString *newValue = [NSString stringWithFormat:@"%li", (long)(value + 5)];
                [self setValue:newValue forStateName:[self stateNameForType:SCUSceneClimateModelTypeDehumidify]];
            }
        }
    }
    if ([modelObject[SCUSceneClimateModelTypeKey] unsignedIntegerValue] == SCUSceneClimateModelTypeDehumidify)
    {
        NSInteger value = row + pickerView.minimumValue;

        if (row)
        {
            NSInteger humidifyValue = [[self valueForType:SCUSceneClimateModelTypeHumidify] integerValue];
            if ((humidifyValue + 5) <= value)
            {
                NSString *newValue = [NSString stringWithFormat:@"%li", (long)(value - 5)];
                [self setValue:newValue forStateName:[self stateNameForType:SCUSceneClimateModelTypeDehumidify]];
            }
        }
    }
}

- (void)updatePickerView:(SCUClimatePicker *)pickerView forParentIndexPath:(NSIndexPath *)indexPath withRow:(NSInteger)row
{
    [self validateNewPickerValuesForPickerView:pickerView andIndexPath:indexPath andRow:row];
    
    NSString *value = [NSString stringWithFormat:@"%ld", (long)(row + pickerView.minimumValue)];
    if (row == 0)
    {
        value = nil;
    }
    
    SCUSceneClimateModelType modelType = (SCUSceneClimateModelType)[self modelTypeFromIndexPath:indexPath];
    
    if (modelType == SCUSceneClimateModelTypeThermostatHeatPoint || modelType == SCUSceneClimateModelTypeThermostatCoolPoint)
    {
        //-------------------------------------------------------------------
        // Set default modes to Auto
        //-------------------------------------------------------------------
        if (![self valueForType:SCUSceneClimateModelTypeThermostatModeOptions])
        {
            [self setValue:@"Auto" forStateName:[self stateNameForType:SCUSceneClimateModelTypeThermostatModeOptions]];
        }
    }
    
    [self setValue:value forStateName:[self stateNameForType:modelType]];
    
    [self.delegate reloadData];
}

- (void)convertSceneServiceZonesToRooms
{
    NSDictionary *HVACs = [[Savant data] HVACRoomsInZones];
    for (SAVSceneService *sceneService in self.sceneServices)
    {
        NSMutableArray *rooms = [NSMutableArray array];
        for (NSDictionary *zone in sceneService.zones)
        {
            [rooms addObjectsFromArray:HVACs[zone]];
            sceneService.rooms = [rooms mutableCopy];
        }
    }
}

- (SCUSceneClimateModelType)modelTypeFromIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];
    SCUSceneClimateModelType type = (SCUSceneClimateModelType)[modelObject[SCUSceneClimateModelTypeKey] unsignedIntegerValue];
    return type;
}

- (void)commit
{
    [self convertSceneServiceZonesToRooms];
    
    //-------------------------------------------------------------------
    // Clear fan/mode states if temp is default
    //-------------------------------------------------------------------
    if (![self valueForType:SCUSceneClimateModelTypeThermostatCoolPoint] && ![self valueForType:SCUSceneClimateModelTypeThermostatHeatPoint])
    {
        [self setValue:nil forStateName:[self stateNameForType:SCUSceneClimateModelTypeThermostatModeOptions]];
    }
    
    for (SAVSceneService *sceneService in self.sceneServices)
    {
        [sceneService commit];

        if (![sceneService.zones count] || ![sceneService.states count])
        {
            [sceneService.zones removeAllObjects];
            [sceneService.rooms removeAllObjects];
        }
    }
}

- (void)rollback
{
    for (SAVSceneService *sceneService in self.sceneServices)
    {
        [sceneService rollback];
    }
}

#pragma mark - Value Handling

- (NSString *)detailValueForType:(SCUSceneClimateModelType)type
{
    NSString *stateName = [self stateNameForType:type];
    NSString *value = [self valueForStateName:stateName];
    
    return value ? value : NSLocalizedString(@"Default", nil);
}

- (NSString *)valueForStateName:(NSString *)stateName
{
    NSString *value = nil;
    
    for (SAVSceneService *sceneService in self.sceneServices)
    {
        SAVHVACEntity *entity = self.entityForDevice[sceneService.scope];
        NSString *state = [[entity stateFromStateName:stateName] stringByReplacingOccurrencesOfString:entity.stateScope withString:@""];
        
        if (sceneService.combinedStates[state])
        {
            value = sceneService.combinedStates[state];
            break;
        }
    }
    
    return value;
}

- (void)setValue:(NSString *)value forStateName:(NSString *)stateName
{
    for (SAVSceneService *sceneService in self.sceneServices)
    {
        SAVHVACEntity *entity = self.entityForDevice[sceneService.scope];
        NSString *state = [[entity stateFromStateName:stateName] stringByReplacingOccurrencesOfString:entity.stateScope withString:@""];
        
        [sceneService applyValue:value forSetting:state immediately:YES];
    }
}

#pragma mark - SCUExpandableDataSourceModel methods

- (BOOL)isFlat
{
    return NO;
}

- (NSArray *)arrayForSection:(NSInteger)section
{
    return self.dataSource[section][SCUSceneClimateTableModelKeySectionArray];
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    return [[self modelObjectForIndexPath:indexPath][SCUSceneClimateTableModelKeyCellType] unsignedIntegerValue];
}

- (NSUInteger)cellTypeForChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self modelObjectForChild:child belowIndexPath:indexPath];
    SCUSceneClimateTableModelCellType cellType = (SCUSceneClimateTableModelCellType)[modelObject[SCUSceneClimateTableModelKeyCellType] unsignedIntegerValue];
    
    switch (cellType)
    {
        case SCUSceneClimateTableModelCellTypePicker:
            return SCUSceneClimateTableModelCellTypePicker;
        default:
            return SCUSceneClimateTableModelCellTypeChild;
    }
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    return self.dataSource[section][SCUSceneClimateTableModelKeySectionTitle];
}

- (NSInteger)numberOfChildrenBelowIndexPath:(NSIndexPath *)indexPath
{
    return [[self dataSourceBelowIndexPath:indexPath] count];
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate toggleIndex:indexPath];
}

- (void)selectChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    SCUSceneClimateModelType type = [self modelTypeFromIndexPath:indexPath];
    NSString *value = [self modelObjectForChild:child belowIndexPath:indexPath][SCUClimateTableViewCellKeyValue];
    
    if (type == SCUSceneClimateModelTypeThermostatModeOptions)
    {
        [self changeModes:value fromIndexPath:indexPath];
    }
    else
    {
        [self.delegate reloadData];
    }
}

- (SCUSceneClimateTableModelCellType)cellTypeFromModelType:(SCUSceneClimateModelType)modelType
{
    SCUSceneClimateTableModelCellType cellType = SCUSceneClimateTableModelCellTypeDefault;
    
    switch (modelType)
    {
        case SCUSceneClimateModelTypeDehumidify:
        case SCUSceneClimateModelTypeHumidify:
        case SCUSceneClimateModelTypeHumidity:
        case SCUSceneClimateModelTypeThermostatCoolPoint:
        case SCUSceneClimateModelTypeThermostatHeatPoint:
        case SCUSceneClimateModelTypeThermostatModeOptions:
            cellType = SCUSceneClimateTableModelCellTypeDefault;
    }
    
    return cellType;
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *modelObject = [[self _modelObjectForIndexPath:indexPath] mutableCopy];
    
    SCUSceneClimateModelType modelType = (SCUSceneClimateModelType)[modelObject[SCUSceneClimateModelTypeKey] unsignedIntegerValue];
    
    NSString *detailValue = [self detailValueForType:modelType];
    NSString *value = [self valueForType:modelType];
    
    switch (modelType)
    {
        case SCUSceneClimateModelTypeThermostatCoolPoint:
        case SCUSceneClimateModelTypeThermostatHeatPoint:
        case SCUSceneClimateModelTypeDehumidify:
        case SCUSceneClimateModelTypeHumidify:
        case SCUSceneClimateModelTypeHumidity:
            modelObject[SCUDefaultTableViewCellKeyDetailTitle] = detailValue;
            modelObject[SCUScenesClimatePickerCellKeyCurrentValue] = detailValue;
            break;
        case SCUSceneClimateModelTypeThermostatModeOptions:
            modelObject[SCUDefaultTableViewCellKeyDetailTitle] = detailValue;
    }
    
    if ([detailValue isEqualToString:value])
    {
        modelObject[SCUDefaultTableViewCellKeyDetailTitleColor] = [[SCUColors shared] color03shade07];
    }
    
    return [modelObject copy];
}

- (NSArray *)dataSourceBelowIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];
    SCUSceneClimateModelType modelType = [modelObject[SCUSceneClimateModelTypeKey] unsignedIntegerValue];
    
    return self.childrenDataSource[@(modelType)];
}

- (id)modelObjectForChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *modelObject = [[super modelObjectForChild:child belowIndexPath:indexPath] mutableCopy];
    
    SCUSceneClimateModelType type = [self modelTypeFromIndexPath:indexPath];
    NSString *currentValue = ([self valueForType:type]) ? [self valueForType:type] : @"";
    
    if (type == SCUSceneClimateModelTypeThermostatModeOptions)
    {
        modelObject[SCUDefaultTableViewCellKeyAccessoryType] = [currentValue isEqualToString:modelObject[SCUClimateTableViewCellKeyValue]] ? @(UITableViewCellAccessoryCheckmark) : @(UITableViewCellAccessoryNone);
    }
    else
    {
        modelObject[SCUScenesClimatePickerCellKeyCurrentValue] = currentValue;
    }
    
    return [modelObject copy];
}

- (BOOL)isCelsius
{
    SAVEntity *entity = [self.entities firstObject];
    SAVService *service = [entity service];
    NSString *celsiusKey = [NSString stringWithFormat:@"%@.%@.isCelsius", service.component, service.logicalComponent];

    return [[[SAVSettings globalSettings] objectForKey:celsiusKey] boolValue];
}

- (void)buildChildrenDataSource
{
    NSMutableDictionary *childDataSource = [NSMutableDictionary dictionary];
    NSMutableSet *modeSet = [NSMutableSet set];
    
    for (SAVHVACEntity *entity in self.entities)
    {
        [modeSet addObjectsFromArray:[self modesAvailableForService:entity.service]];
    }
    
    self.climateCommands    = [modeSet allObjects];
    NSMutableArray *dataSource  = [NSMutableArray array];
    NSString *currentValue      = ([self valueForType:SCUSceneClimateModelTypeThermostatModeOptions]) ? [self valueForType:SCUSceneClimateModelTypeThermostatModeOptions] : nil;
    
    if (!currentValue)
    {
        // Loop through and set the top mode as the default value
        if ([self.climateCommands containsObject:@(SCUSceneClimateModeTypeAuto)])
        {
            currentValue = NSLocalizedString(@"Auto", nil);
        }
        else if ([self.climateCommands containsObject:@(SCUSceneClimateModeTypeHeat)])
        {
            currentValue = NSLocalizedString(@"Heat", nil);
        }
        else if ([self.climateCommands containsObject:@(SCUSceneClimateModeTypeCool)])
        {
            currentValue = NSLocalizedString(@"Cool", nil);
        }
        else
        {
            currentValue = @"";
        }
    }
    
    [self setValue:currentValue forStateName:[self stateNameForType:SCUSceneClimateModelTypeThermostatModeOptions]];
    
    if ([self.climateCommands containsObject:@(SCUSceneClimateModeTypeAuto)])
    {
        [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle : NSLocalizedString(@"Auto", nil),
                                SCUClimateTableViewCellKeyValue: @"Auto",
                                SCUSceneClimateTableModelKeyChildCellType: @(SCUSceneClimateModeTypeAuto),
                                SCUDefaultTableViewCellKeyAccessoryType: [currentValue isEqualToString:@"Auto"] ? @(UITableViewCellAccessoryCheckmark) : @(UITableViewCellAccessoryNone)}];
    }
    if ([self.climateCommands containsObject:@(SCUSceneClimateModeTypeHeat)])
    {
        [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle : NSLocalizedString(@"Heat", nil),
                                SCUClimateTableViewCellKeyValue: @"Heat",
                                SCUSceneClimateTableModelKeyChildCellType: @(SCUSceneClimateModeTypeHeat),
                                SCUDefaultTableViewCellKeyAccessoryType: [currentValue isEqualToString:@"Heat"] ? @(UITableViewCellAccessoryCheckmark) : @(UITableViewCellAccessoryNone)}];
    }
    if ([self.climateCommands containsObject:@(SCUSceneClimateModeTypeCool)])
    {
        [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle : NSLocalizedString(@"Cool", nil),
                                SCUClimateTableViewCellKeyValue: @"Cool",
                                SCUSceneClimateTableModelKeyChildCellType: @(SCUSceneClimateModeTypeCool),
                                SCUDefaultTableViewCellKeyAccessoryType: [currentValue isEqualToString:@"Cool"] ? @(UITableViewCellAccessoryCheckmark) : @(UITableViewCellAccessoryNone)}];
    }
    if ([self.climateCommands containsObject:@(SCUSceneClimateModeTypeOff)])
    {
        [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle : NSLocalizedString(@"Off", nil),
                                SCUClimateTableViewCellKeyValue: @"Off",
                                SCUSceneClimateTableModelKeyChildCellType: @(SCUSceneClimateModeTypeOff),
                                SCUDefaultTableViewCellKeyAccessoryType: [currentValue isEqualToString:@"Off"] ? @(UITableViewCellAccessoryCheckmark) : @(UITableViewCellAccessoryNone)}];
    }
    
    childDataSource[@(SCUSceneClimateModelTypeThermostatModeOptions)] = [dataSource copy];

    NSInteger min = 45;
    NSInteger max = 85;

    if ([self isCelsius])
    {
        min = 5;
        max = 30;
    }

    self.minHeatPoint = min;

    childDataSource[@(SCUSceneClimateModelTypeThermostatHeatPoint)] = @[@{SCUScenesClimatePickerCellKeyMinimumValue: @(min),
                                                                          SCUScenesClimatePickerCellKeyMaximumValue: @(max),
                                                                          SCUSceneClimateTableModelKeyCellType : @(SCUSceneClimateTableModelCellTypePicker),
                                                                          SCUScenesClimatePickerCellKeyCurrentValue: currentValue}];

    min = 50;
    max = 90;

    if ([self isCelsius])
    {
        min = 10;
        max = 35;
    }

    self.minCoolPoint = min;

    childDataSource[@(SCUSceneClimateModelTypeThermostatCoolPoint)] = @[@{SCUScenesClimatePickerCellKeyMinimumValue: @(min),
                                                                          SCUScenesClimatePickerCellKeyMaximumValue: @(max),
                                                                          SCUSceneClimateTableModelKeyCellType : @(SCUSceneClimateTableModelCellTypePicker),
                                                                          SCUScenesClimatePickerCellKeyCurrentValue: currentValue}];
    
    min = 20;
    max = 80;
    childDataSource[@(SCUSceneClimateModelTypeHumidity)] = @[@{SCUScenesClimatePickerCellKeyMinimumValue: @(min),
                                                             SCUScenesClimatePickerCellKeyMaximumValue: @(max),
                                                             SCUSceneClimateTableModelKeyCellType : @(SCUSceneClimateTableModelCellTypePicker),
                                                               SCUScenesClimatePickerCellKeyCurrentValue: currentValue}];
    
    childDataSource[@(SCUSceneClimateModelTypeHumidify)] = @[@{SCUScenesClimatePickerCellKeyMinimumValue: @(min),
                                                                SCUScenesClimatePickerCellKeyMaximumValue: @(max),
                                                                SCUSceneClimateTableModelKeyCellType : @(SCUSceneClimateTableModelCellTypePicker),
                                                                SCUScenesClimatePickerCellKeyCurrentValue: currentValue}];
    
    childDataSource[@(SCUSceneClimateModelTypeDehumidify)] = @[@{SCUScenesClimatePickerCellKeyMinimumValue: @(min),
                                                                 SCUScenesClimatePickerCellKeyMaximumValue: @(max),
                                                                 SCUSceneClimateTableModelKeyCellType : @(SCUSceneClimateTableModelCellTypePicker),
                                                                 SCUScenesClimatePickerCellKeyCurrentValue: currentValue}];

    self.childrenDataSource = [childDataSource copy];
}

- (void)buildDataSource
{

    NSMutableArray *sceneServices = [NSMutableArray array];
    NSMutableDictionary *entityForDevice = [NSMutableDictionary dictionary];
    
    BOOL dehumidifyPresent      = NO;
    BOOL humidifyPresent        = NO;
//    BOOL autoModePresent        = NO;
    BOOL humidityPresent        = NO;
    BOOL temperaturePresent     = NO;
    BOOL coolPointPresent       = NO;
    BOOL heatPointPresent       = NO;
    BOOL temperatureModePresent = NO;
    
    // Check which controls we should display to the user
    for (SAVHVACEntity *entity in self.entities)
    {
        NSArray *modes = [self modesAvailableForService:entity.service];
        if (modes.count)
        {
            temperatureModePresent = YES;
        }
        if (entity.humidifySetPoint)
        {
            humidifyPresent = YES;
        }
        if (entity.dehumidifySetPoint)
        {
            dehumidifyPresent = YES;
        }
        if ([entity.service.commands containsObject:@"SetHumiditySetPoint"] && !humidifyPresent && !dehumidifyPresent && entity.humiditySPCount > 0)
        {
            humidityPresent = YES;
        }
        if (entity.tempSPCount > 0)
        {
            temperaturePresent = YES;
        }
        if (entity.coolSetPoint)
        {
            coolPointPresent = YES;
        }
        if (entity.heatSetPoint)
        {
            heatPointPresent = YES;
        }
        if (entity.autoMode)
        {
//            autoModePresent = YES;
        }
        
        //-------------------------------------------------------------------
        // Store entities based on entity service
        //-------------------------------------------------------------------
        NSString *scope = [NSString stringWithFormat:@"%@.%@", entity.service.component, entity.service.logicalComponent];
        
        entityForDevice[scope] = entity;
        
        [sceneServices addObject:[self.scene sceneServiceForService:entity.service]];
    }
    self.sceneServices = sceneServices;
    self.entityForDevice = entityForDevice;
    
    // Build data source since we know which sections to add
    NSMutableArray *dataSource       = [NSMutableArray array];
    NSMutableDictionary *temperature = [NSMutableDictionary dictionary];
    NSString *mode = [self valueForStateName:[self stateNameForType:SCUSceneClimateModelTypeThermostatModeOptions]];
    mode = mode ? mode : NSLocalizedString(@"Auto", nil);

    SCUSceneClimateModeType modeType = [self modeTypeFromString:mode];
    
    if (temperaturePresent)
    {
        NSMutableArray *temperatureCells = [NSMutableArray array];
        if (coolPointPresent)
        {
            if ((modeType == SCUSceneClimateModeTypeCool || modeType == SCUSceneClimateModeTypeAuto) && modeType != SCUSceneClimateModeTypeOff)
            {
                [temperatureCells addObject:@{SCUSceneClimateModelTypeKey: @(SCUSceneClimateModelTypeThermostatCoolPoint),
                                              SCUSceneClimateModeTypeKey: @(SCUSceneClimateModeTypeCool),
                                              SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Cool Point", nil)}];

                NSString *coolValue = [self valueForStateName:[self stateNameForType:SCUSceneClimateModelTypeThermostatCoolPoint]];
                self.coolPoint = [coolValue integerValue] >= self.minCoolPoint ? coolValue : nil;
            }
        }
        if (heatPointPresent)
        {
            if ((modeType == SCUSceneClimateModeTypeHeat || modeType == SCUSceneClimateModeTypeAuto) && modeType != SCUSceneClimateModeTypeOff)
            {
                [temperatureCells addObject:@{SCUSceneClimateModelTypeKey: @(SCUSceneClimateModelTypeThermostatHeatPoint),
                                              SCUSceneClimateModeTypeKey: @(SCUSceneClimateModeTypeHeat),
                                              SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Heat Point", nil)}];

                NSString *heatValue = [self valueForStateName:[self stateNameForType:SCUSceneClimateModelTypeThermostatHeatPoint]];
                self.heatPoint = [heatValue integerValue] >= self.minHeatPoint ? heatValue : nil;
            }
        }
        if (temperatureModePresent)
        {
            [temperatureCells addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Mode", nil),
                                          SCUSceneClimateModelTypeKey : @(SCUSceneClimateModelTypeThermostatModeOptions),
                                          SCUClimateTableViewCellKeyValue: mode}];
        }
        
        temperature[SCUSceneClimateTableModelKeySectionTitle] = NSLocalizedString(@"Temperature", nil);
        temperature[SCUSceneClimateTableModelKeySectionArray] = temperatureCells;
        [dataSource addObject:temperature];
    }
    

    NSMutableArray *humidityCells = [NSMutableArray array];
    
    if (humidifyPresent)
    {
        [humidityCells addObject:@{SCUSceneClimateModelTypeKey: @(SCUSceneClimateModelTypeHumidify),
                                   SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Humidify Set Point", nil)}];
    }
    if (dehumidifyPresent)
    {
        [humidityCells addObject:@{SCUSceneClimateModelTypeKey: @(SCUSceneClimateModelTypeDehumidify),
                                   SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Dehumidify Set Point", nil)}];
    }
    if (humidityPresent)
    {
        [humidityCells addObject:@{SCUSceneClimateModelTypeKey: @(SCUSceneClimateModelTypeHumidity),
                                   SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Humidity Set Point", nil)}];
    }
    if ([humidityCells count])
    {
        // Build Humidity Section
        [dataSource addObject: @{SCUSceneClimateTableModelKeySectionTitle: NSLocalizedString(@"Humidity", nil),
                                 SCUSceneClimateTableModelKeySectionArray:humidityCells}];
    }

    
    
    self.dataSource = [dataSource copy];
}

@end
