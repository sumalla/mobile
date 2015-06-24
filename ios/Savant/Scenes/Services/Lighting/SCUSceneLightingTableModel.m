//
//  SCUSceneLightingTableModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 7/29/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneLightingTableModel.h"
#import "SCUDataSourceModelPrivate.h"
@import SDK;
#import "SCUDefaultTableViewCell.h"
#import "SCUSceneLightingSliderTableViewCell.h"
#import "SCUFanButtonsTableViewCell.h"
#import "SCUSlider.h"
#import "SCUButton.h"
#import "SCUToggleSwitchTableViewCell.h"

typedef NS_ENUM(NSUInteger, SCUSceneLightingModelType)
{
    SCUSceneLightingModelTypeEmptyRoomImage,
    SCUSceneLightingModelTypeRoomImage,
    SCUSceneLightingModelTypeLiveMode,
    SCUSceneLightingModelTypeLightDimmer,
    SCUSceneLightingModelTypeLightSwitch,
    SCUSceneLightingModelTypeShadeDimmer,
    SCUSceneLightingModelTypeShadeSwitch,
    SCUSceneLightingModelTypeFan
};

static NSString *SCUSceneLightingTableModelKeySectionType = @"SCUSceneLightingTableModelKeySectionType";
static NSString *SCUSceneLightingTableModelKeySectionArray = @"SCUSceneLightingTableModelKeySectionArray";

static NSString *SCUSceneLightingTableModelObjectKeyType = @"SCUSceneLightingTableModelObjectKeyType";
static NSString *SCUSceneLightingTableModelObjectKeyCellType = @"SCUSceneLightingTableModelObjectKeyCellType";
static NSString *SCUSceneLightingTableModelObjectKeyState = @"SCUSceneLightingTableModelObjectKeyState";
static NSString *SCUSceneLightingTableModelObjectKeyScope = @"SCUSceneLightingTableModelObjectKeyScope";

@interface SCUSceneLightingTableModel ()

@property (nonatomic) SAVScene *scene;
@property (nonatomic) SAVService *service;
@property (nonatomic) SAVSceneService *sceneService;
@property (nonatomic, copy) NSDictionary *sceneServices;
@property (nonatomic, copy) NSArray *dataSource;
@property (nonatomic) BOOL liveMode;
@property (nonatomic) UIImage *roomImage;
@property (nonatomic) id roomImageObserver;

@end

@implementation SCUSceneLightingTableModel

- (void)dealloc
{
    [[Savant images] removeObserver:self.roomImageObserver];
}

- (instancetype)initWithScene:(SAVScene *)scene service:(SAVService *)service sceneService:(SAVSceneService *)sceneService
{
    self = [super init];

    if (self)
    {
        self.scene = scene;
        self.service = service;
        self.sceneService = sceneService;

        NSMutableArray *dataSource = [NSMutableArray arrayWithObject:[self initialRoomImageSection]];
        self.dataSource = dataSource;

        SAVWeakSelf;
        self.roomImageObserver = [[Savant images] addObserverForKey:self.service.zoneName type:SAVImageTypeRoomImage size:SAVImageSizeMedium blurred:NO andCompletionHandler:^(UIImage *image, BOOL isDefault) {
            [wSelf handleNewRoomImage:image];
        }];
    }

    return self;
}

- (void)handleNewRoomImage:(UIImage *)image
{
    NSArray *roomImageSection = [self arrayForSection:0];
    NSMutableDictionary *modelObject = [roomImageSection firstObject];

    if (image)
    {
        modelObject[SCUSceneLightingTableModelObjectKeyType] = @(SCUSceneLightingModelTypeRoomImage);
        modelObject[SCUSceneLightingTableModelObjectKeyCellType] = @(SCUSceneLightingTableModelCellTypeRoomImage);
    }
    else
    {
        modelObject[SCUSceneLightingTableModelObjectKeyType] = @(SCUSceneLightingModelTypeEmptyRoomImage);
        modelObject[SCUSceneLightingTableModelObjectKeyCellType] = @(SCUSceneLightingTableModelCellTypeEmptyRoomImage);
    }

    self.roomImage = image;
    [self.delegate reloadData];
}

- (NSString *)fanStateFromIntegerValue:(SCUFanButtonsTableViewCellSelectedButton)value
{
    switch (value)
    {
        case SCUFanButtonsTableViewCellSelectedButtonOff:
            return @"Off";
        case SCUFanButtonsTableViewCellSelectedButtonLow:
            return @"Low";
        case SCUFanButtonsTableViewCellSelectedButtonMed:
            return @"Med";
        case SCUFanButtonsTableViewCellSelectedButtonHigh:
            return @"High";
    }
    
    return nil;
}

- (void)listenToOffButton:(SCUButton *)offButton lowButton:(SCUButton *)lowButton medButton:(SCUButton *)medButton highButton:(SCUButton *)highButton forIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    [offButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        [wSelf setStringValue:[self fanStateFromIntegerValue:SCUFanButtonsTableViewCellSelectedButtonOff] forIndexPath:indexPath];
        [wSelf.delegate reloadChildrenBelowIndexPath:indexPath];
    }];
    
    [lowButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        [wSelf setStringValue:[self fanStateFromIntegerValue:SCUFanButtonsTableViewCellSelectedButtonLow] forIndexPath:indexPath];
        [wSelf.delegate reloadChildrenBelowIndexPath:indexPath];
    }];
    
    [medButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        [wSelf setStringValue:[self fanStateFromIntegerValue:SCUFanButtonsTableViewCellSelectedButtonMed] forIndexPath:indexPath];
        [wSelf.delegate reloadChildrenBelowIndexPath:indexPath];
    }];
    
    [highButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        [wSelf setStringValue:[self fanStateFromIntegerValue:SCUFanButtonsTableViewCellSelectedButtonHigh] forIndexPath:indexPath];
        [wSelf.delegate reloadChildrenBelowIndexPath:indexPath];
    }];
}

- (void)listenToToggleSwitch:(UISwitch *)toggleSwitch forIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;

    if ([self modelTypeForIndexPath:indexPath] == SCUSceneLightingModelTypeLiveMode)
    {
        toggleSwitch.sav_didChangeHandler = ^(BOOL on) {
            wSelf.liveMode = on;
        };
    }
    else
    {
        toggleSwitch.sav_didChangeHandler = ^(BOOL on) {
            [wSelf toggleIndexPath:indexPath on:on];
        };
    }
}

- (void)listenToSlider:(SCUSlider *)slider forParentIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    slider.callback = ^(SCUSlider *slider) {
        [wSelf sliderValueDidChangeTo:slider.value forParentIndexPath:indexPath];
    };
}

- (void)commit
{
    for (SAVSceneService *sceneService in [self.sceneServices allValues])
    {
        [sceneService commit];
    }
}

- (void)rollback
{
    for (SAVSceneService *sceneService in [self.sceneServices allValues])
    {
        [sceneService rollback];
    }
}

#pragma mark - SCUExpandableDataSourceModel methods

- (void)viewWillAppear
{
    [super viewWillAppear];

    NSArray *lights = [self lightingData];

    if ([lights count])
    {
        NSMutableArray *dataSource = [self.dataSource mutableCopy];
        [dataSource addObjectsFromArray:lights];
        self.dataSource = dataSource;
    }

    [self.dataSource enumerateObjectsUsingBlock:^(NSDictionary *modelObject, NSUInteger section, BOOL *stop) {

        SCUSceneLightingModelType modelType = [modelObject[SCUSceneLightingTableModelKeySectionType] unsignedIntegerValue];

        switch (modelType)
        {
            case SCUSceneLightingModelTypeLightDimmer:
            case SCUSceneLightingModelTypeShadeDimmer:
            {
                NSArray *dimmers = [self arrayForSection:section];

                for (NSUInteger row = 0; row < [dimmers count]; row++)
                {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];

                    if ([[self valueForIndexPath:indexPath] integerValue] > 0)
                    {
                        [self toggleIndexPath:indexPath];
                    }
                }
            }
            case SCUSceneLightingModelTypeFan:
            {
                NSArray *fans = [self arrayForSection:section];
                
                for (NSUInteger row = 0; row < [fans count]; row++)
                {
                    [self toggleIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
                }
            }
        }

    }];
}

- (BOOL)isFlat
{
    return NO;
}

- (NSArray *)arrayForSection:(NSInteger)section
{
    if ([self.dataSource count] > (NSUInteger)section)
    {
        return self.dataSource[section][SCUSceneLightingTableModelKeySectionArray];
    }
    else
    {
        return nil;
    }
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    SCUSceneLightingTableModelCellType type = [[self _modelObjectForIndexPath:indexPath][SCUSceneLightingTableModelObjectKeyCellType] unsignedIntegerValue];
    
    if (self.editMode)
    {
        if (type == SCUSceneLightingTableModelCellTypeToggleSwitch || type == SCUSceneLightingTableModelCellTypeSlider || type == SCUSceneLightingTableModelCellTypeToggleLabel)
        {
            return SCUSceneLightingTableModelCellTypeEdit;
        }
    }
    else
    {
        if (![self entityIncludedAtIndexPath:indexPath] && type != SCUSceneLightingTableModelCellTypeRoomImage && type != SCUSceneLightingTableModelCellTypeEmptyRoomImage)
        {
            return SCUSceneLightingTableModelCellTypeExcluded;
        }
    }	

    return type;
}

- (NSUInteger)cellTypeForChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    switch ([self cellTypeForIndexPath:indexPath])
    {
        case SCUSceneLightingTableModelCellTypePlain:
            return SCUSceneLightingTableModelCellTypeFan;
        default:
            return SCUSceneLightingTableModelCellTypeSlider;
    }
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;
    SCUSceneLightingModelType modelType = [self.dataSource[section][SCUSceneLightingTableModelKeySectionType] unsignedIntegerValue];

    switch (modelType)
    {
        case SCUSceneLightingModelTypeLightDimmer:
            title = NSLocalizedString(@"Dimmers", nil);
            break;
        case SCUSceneLightingModelTypeLightSwitch:
            title = NSLocalizedString(@"Switches", nil);
            break;
        case SCUSceneLightingModelTypeShadeDimmer:
        case SCUSceneLightingModelTypeShadeSwitch:
            title = NSLocalizedString(@"Shades", nil);
            break;
        case SCUSceneLightingModelTypeFan:
            title = NSLocalizedString(@"Fans", nil);
            break;
    }

    return title;
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];
    SCUSceneLightingModelType type = [self cellTypeForIndexPath:indexPath];
    
    if ([self cellTypeForIndexPath:indexPath] == SCUSceneLightingTableModelCellTypeToggleSwitch)
    {
        NSInteger value = [[self valueForIndexPath:indexPath] integerValue];
        modelObject = [modelObject dictionaryByAddingObject:@(value > 0 ? YES : NO) forKey:SCUToggleSwitchTableViewCellKeyValue];
        
        SCUDefaultTableViewCellBottomLineType bottomLine = [self.expandedIndexPaths containsObject:indexPath] ? SCUDefaultTableViewCellBottomLineTypeNone :  SCUDefaultTableViewCellBottomLineTypeFull;
        
        modelObject = [modelObject dictionaryByAddingObject:@(bottomLine)
                                                     forKey:SCUDefaultTableViewCellKeyBottomLineType];
    }
    
    
    if (type == SCUSceneLightingTableModelCellTypeEdit)
    {
        if (self.editMode)
        {
            UITableViewCellAccessoryType accessory = ([self entityIncludedAtIndexPath:indexPath]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            modelObject = [modelObject dictionaryByAddingObject:@(accessory) forKey:SCUDefaultTableViewCellKeyAccessoryType];
        }
        else
        {
            modelObject = [modelObject dictionaryByAddingObject:NSLocalizedString(@"Excluded", nil) forKey:SCUDefaultTableViewCellKeyDetailTitle];
            modelObject = [modelObject dictionaryByAddingObject:@(UITableViewCellAccessoryNone) forKey:SCUDefaultTableViewCellKeyAccessoryType];
        }

    }
    
    return modelObject;
}

- (NSInteger)numberOfChildrenBelowIndexPath:(NSIndexPath *)indexPath
{
    return 1;
}

- (NSArray *)dataSourceBelowIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];

    SCUSceneLightingModelType modelType = (SCUSceneLightingModelType)[modelObject[SCUSceneLightingTableModelObjectKeyType] unsignedIntegerValue];

    NSDictionary *newModelObject = nil;

    switch (modelType)
    {
        case SCUSceneLightingModelTypeLightDimmer:
        case SCUSceneLightingModelTypeShadeDimmer:
        {
            NSInteger value = [[self valueForIndexPath:indexPath] integerValue];
            newModelObject = @{SCUSliderMinMaxCellKeyValue: @(value)};
            break;
        }
        case SCUSceneLightingModelTypeFan:
        {
            NSString *value = [self stringValueForIndexPath:indexPath];
            if ([value isKindOfClass:[NSString class]])
            {
                NSInteger selectedButton = [self selectedValueForString:value];
                newModelObject = @{SCUFanButtonsTableViewCellKeySelectedButton: @(selectedButton)};
            }
            break;
        }
    }

    return newModelObject ? @[newModelObject] : nil;
}

#pragma mark -

- (NSArray *)lightingData
{
    SAVData *data = [Savant data];

    NSMutableArray *dataSource = [NSMutableArray array];
    NSMutableDictionary *sceneServices = [NSMutableDictionary dictionary];
    
    BOOL setDefaultStates = [self.delegate isFirstPass];
    
    SAVArrayMappingBlock mappingBlock = ^id(SAVEntity *entity) {

        if ([entity respondsToSelector:@selector(isSceneable)])
        {
            SAVLightEntity *lightEntity = (SAVLightEntity *)entity;
            if (!lightEntity.isSceneable)
            {
                return nil;
            }
        }

        NSString *state = [entity.states firstObject];
        NSString *stateName = nil;
        NSMutableDictionary *dict = nil;

        NSUInteger lastDot = [state rangeOfString:@"." options:NSBackwardsSearch].location;

        if (lastDot != NSNotFound)
        {
            stateName = [state substringFromIndex:lastDot + 1];
        }

        if (stateName)
        {
            dict = [NSMutableDictionary dictionary];
            dict[SCUSceneLightingTableModelObjectKeyState] = stateName;

            NSString *scope = [NSString stringWithFormat:@"%@.%@", entity.service.component, entity.service.logicalComponent];
            dict[SCUSceneLightingTableModelObjectKeyScope] = scope;

            SCUSceneLightingModelType modelType = [self modelTypeFromEntity:entity];
            SCUSceneLightingTableModelCellType cellType = [self cellTypeFromModelType:modelType];
            dict[SCUSceneLightingTableModelObjectKeyType] = @(modelType);
            dict[SCUSceneLightingTableModelObjectKeyCellType] = @(cellType);
            dict[SCUDefaultTableViewCellKeyTitle] = entity.label;
            dict[SCUDefaultTableViewCellKeyModelObject] = entity;

            SAVSceneService *sceneService = sceneServices[scope];

            if (!sceneService)
            {
                SAVMutableService *service = [[SAVMutableService alloc] init];
                NSArray *comps = [scope componentsSeparatedByString:@"."];
                service.component = comps[0];
                service.logicalComponent = comps[1];
                service.serviceId = self.service.serviceId;
                sceneService = [self.scene sceneServiceForService:service];
                sceneService.rooms = self.sceneService.rooms;
                sceneServices[scope] = sceneService;
            }
            
            if (setDefaultStates && !(sceneService.combinedStates)[stateName])
            {
                [sceneService applyValue:@0 forSetting:stateName immediately:NO];
            }
        }

        return dict;
    };

    if ([self.service.serviceId isEqualToString:@"SVC_ENV_LIGHTING"])
    {
        NSArray *allLights = [data lightEntitiesForRoom:self.service.zoneName];

        {
            //-------------------------------------------------------------------
            // Light dimmers
            //-------------------------------------------------------------------
            NSArray *lightDimmers = [allLights filteredArrayUsingBlock:^BOOL(SAVEntity *entity) {
                return entity.type == SAVEntityType_Dimmer;
            }];

            NSArray *filteredLightDimmers = [lightDimmers arrayByMappingBlock:mappingBlock];

            if ([filteredLightDimmers count])
            {
                [dataSource addObject:@{SCUSceneLightingTableModelKeySectionType: @(SCUSceneLightingModelTypeLightDimmer),
                                        SCUSceneLightingTableModelKeySectionArray: filteredLightDimmers}];
            }
        }

        {
            //-------------------------------------------------------------------
            // Light switches
            //-------------------------------------------------------------------
            NSArray *lightSwitches = [allLights filteredArrayUsingBlock:^BOOL(SAVEntity *entity) {
                return entity.type == SAVEntityType_Switch || entity.type == SAVEntityType_Hue;
            }];

            NSArray *filteredLightSwitches = [lightSwitches arrayByMappingBlock:mappingBlock];

            if ([filteredLightSwitches count])
            {
                [dataSource addObject:@{SCUSceneLightingTableModelKeySectionType: @(SCUSceneLightingModelTypeLightSwitch),
                                        SCUSceneLightingTableModelKeySectionArray: filteredLightSwitches}];
            }
        }
        
        {
            //-------------------------------------------------------------------
            // Fans
            //-------------------------------------------------------------------
            NSArray *fans = [allLights filteredArrayUsingBlock:^BOOL(SAVEntity *entity) {
                return entity.type == SAVEntityType_Fan;
            }];
            
            NSArray *filteredFans = [fans arrayByMappingBlock:mappingBlock];
            
            if ([filteredFans count])
            {
                [dataSource addObject:@{SCUSceneLightingTableModelKeySectionType: @(SCUSceneLightingModelTypeFan),
                                        SCUSceneLightingTableModelKeySectionArray: filteredFans}];
            }
        }
    }

    if ([self.service.serviceId isEqualToString:@"SVC_ENV_SHADE"])
    {
        //-------------------------------------------------------------------
        // Shades
        //-------------------------------------------------------------------
        NSArray *allShades = [data shadeEntitiesForRoom:self.service.zoneName];

        NSArray *shades = [allShades filteredArrayUsingBlock:^BOOL(SAVEntity *entity) {
            return entity.type == SAVEntityType_Shade || entity.type == SAVEntityType_Variable;
        }];

        NSArray *filteredShades = [shades arrayByMappingBlock:mappingBlock];

        if ([filteredShades count])
        {
            [dataSource addObject:@{SCUSceneLightingTableModelKeySectionType: @(SCUSceneLightingModelTypeShadeDimmer),
                                    SCUSceneLightingTableModelKeySectionArray: filteredShades}];
        }
    }

    self.sceneServices = sceneServices;

    return [dataSource copy];
}

- (SCUSceneLightingModelType)modelTypeFromEntity:(SAVEntity *)entity
{
    SCUSceneLightingModelType modelType = SCUSceneLightingModelTypeLightDimmer;

    switch (entity.type)
    {
        case SAVEntityType_Dimmer:
        case SAVEntityType_Hue:
            modelType = SCUSceneLightingModelTypeLightDimmer;
            break;
        case SAVEntityType_Switch:
            modelType = SCUSceneLightingModelTypeLightSwitch;
            break;
        case SAVEntityType_Shade:
            modelType = SCUSceneLightingModelTypeShadeSwitch;
            break;
        case SAVEntityType_Variable:
            modelType = SCUSceneLightingModelTypeShadeDimmer;
            break;
        case SAVEntityType_Fan:
            modelType = SCUSceneLightingModelTypeFan;
            break;
    }

    return modelType;
}

- (BOOL)canToggleAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self modelTypeForIndexPath:indexPath] == SCUSceneLightingModelTypeFan)
    {
        return NO;
    }
    
    return YES;
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editMode && [self canToggleAtIndexPath:indexPath])
    {
        [self toggleIncludedForIndexPath:indexPath];
    }
}

- (BOOL)entityIncludedAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self valueForIndexPath:indexPath])
    {
        return YES;
    }
    
    return NO;
}

- (void)toggleIncludedForIndexPath:(NSIndexPath *)indexPath
{
    if ([self valueForIndexPath:indexPath])
    {
        [self setValue:nil forIndexPath:indexPath];
    }
    else
    {
        [self setValue:@0 forIndexPath:indexPath];
    }
    
    [self.delegate reloadIndexPath:indexPath];
}

- (SCUSceneLightingTableModelCellType)cellTypeFromModelType:(SCUSceneLightingModelType)modelType
{
    SCUSceneLightingTableModelCellType cellType = SCUSceneLightingTableModelCellTypeToggleSwitch;

    switch (modelType)
    {
        case SCUSceneLightingModelTypeLightDimmer:
        case SCUSceneLightingModelTypeLightSwitch:
        case SCUSceneLightingModelTypeShadeDimmer:
            cellType = SCUSceneLightingTableModelCellTypeToggleSwitch;
            break;
        case SCUSceneLightingModelTypeShadeSwitch:
            cellType = SCUSceneLightingTableModelCellTypeToggleLabel;
            break;
        case SCUSceneLightingModelTypeFan:
            cellType = SCUSceneLightingTableModelCellTypePlain;
            break;
    }

    return cellType;
}

- (SAVSceneService *)sceneServiceForModelObject:(NSDictionary *)modelObject
{
    return self.sceneServices[modelObject[SCUSceneLightingTableModelObjectKeyScope]];
}

- (void)toggleIndexPath:(NSIndexPath *)indexPath on:(BOOL)on
{
    SCUSceneLightingModelType modelType = [self modelTypeForIndexPath:indexPath];

    if (modelType == SCUSceneLightingModelTypeLightDimmer || modelType == SCUSceneLightingModelTypeShadeDimmer)
    {
        [self setValue:on ? @100 : @0 forIndexPath:indexPath];

        if (on && [[self expandedIndexPaths] containsObject:indexPath])
        {
            NSIndexPath *absoluteIndexPath = [self absoluteIndexPathForRelativeIndexPath:indexPath];

            [self.delegate reloadIndexPath:[NSIndexPath indexPathForRow:absoluteIndexPath.row + 1 inSection:absoluteIndexPath.section]];
        }
        else
        {
            [self.delegate toggleIndexPath:indexPath];
        }
    }
    else if (modelType == SCUSceneLightingModelTypeLightSwitch)
    {
        [self setValue:on ? @1 : @0 forIndexPath:indexPath];
    }
}

- (void)sliderValueDidChangeTo:(CGFloat)value forParentIndexPath:(NSIndexPath *)indexPath
{
    NSInteger oldValue = [[self valueForIndexPath:indexPath] integerValue];
    [self setValue:@((NSInteger)value) forIndexPath:indexPath];

    if ((oldValue == 0 && value > 0) || (value == 0 && oldValue > 0))
    {
        [self.delegate toggleSwitchForIndexPath:indexPath];
    }
}

- (NSInteger)selectedValueForString:(NSString *)string
{
    if ([string isEqualToString:@"Off"])
    {
        return SCUFanButtonsTableViewCellSelectedButtonOff;
    }
    else if ([string isEqualToString:@"Low"])
    {
        return SCUFanButtonsTableViewCellSelectedButtonLow;
    }
    else if ([string isEqualToString:@"Med"])
    {
        return SCUFanButtonsTableViewCellSelectedButtonMed;
    }
    else if ([string isEqualToString:@"High"])
    {
        return SCUFanButtonsTableViewCellSelectedButtonHigh;
    }
    
    return SCUFanButtonsTableViewCellSelectedButtonNone;
}

- (void)setStringValue:(NSString *)value forIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];
    SAVSceneService *sceneService = [self sceneServiceForModelObject:modelObject];
    [sceneService applyValue:value forSetting:modelObject[SCUSceneLightingTableModelObjectKeyState] immediately:NO];

}

- (void)setValue:(NSNumber *)value forIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];
    SAVSceneService *sceneService = [self sceneServiceForModelObject:modelObject];
    [sceneService applyValue:value forSetting:modelObject[SCUSceneLightingTableModelObjectKeyState] immediately:NO];

    if (self.liveMode)
    {
        //-------------------------------------------------------------------
        // CBP TODO: Send service requests.
        //-------------------------------------------------------------------
    }
}

- (NSString *)stringValueForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];
    SAVSceneService *sceneService = [self sceneServiceForModelObject:modelObject];
    return sceneService.combinedStates[modelObject[SCUSceneLightingTableModelObjectKeyState]];
}

- (NSNumber *)valueForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];
    SAVSceneService *sceneService = [self sceneServiceForModelObject:modelObject];
    return sceneService.combinedStates[modelObject[SCUSceneLightingTableModelObjectKeyState]];
}

- (SCUSceneLightingModelType)modelTypeForIndexPath:(NSIndexPath *)indexPath
{
    return [[self _modelObjectForIndexPath:indexPath][SCUSceneLightingTableModelObjectKeyType] unsignedIntegerValue];
}

- (NSDictionary *)initialRoomImageSection
{
    NSMutableDictionary *fakeRoomImage = [@{SCUSceneLightingTableModelObjectKeyType: @(SCUSceneLightingModelTypeEmptyRoomImage),
                                            SCUSceneLightingTableModelObjectKeyCellType: @(SCUSceneLightingTableModelCellTypeEmptyRoomImage)} mutableCopy];

//    NSDictionary *liveMode = @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Live Mode", nil),
//                               SCUSceneLightingTableModelObjectKeyCellType: @(SCUSceneLightingTableModelCellTypeToggleSwitch)};

    return @{SCUSceneLightingTableModelKeySectionType: @(SCUSceneLightingModelTypeLiveMode),
             SCUSceneLightingTableModelKeySectionArray: [NSMutableArray arrayWithObjects:fakeRoomImage/*, liveMode*/, nil]};
}

@end
