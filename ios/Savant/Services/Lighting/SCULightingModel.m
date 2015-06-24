//
//  SCULightingModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 8/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCULightingModel.h"
#import "SCUDataSourceModelPrivate.h"
#import "SCULightingModelPrivate.h"
#import "SCUDefaultTableViewCell.h"
#import "SCUToggleSwitchTableViewCell.h"
#import "SCUSceneLightingSliderTableViewCell.h"
#import "SCULightingSceneButtonTableViewCell.h"
#import "SCUFanButtonsTableViewCell.h"
#import "SCUShadesModel.h"

NSString *const SCULightingSectionKey = @"SCULightingSectionKey";
NSString *const SCULightingArrayKey = @"SCULightingArrayKey";
NSString *const SCULightingStateKey = @"SCULightingStateKey";
NSString *const SCULightingModelType = @"SCULightingModelType";
NSString *const SCULightingCellType = @"SCULightingCellType";

@interface SCULightingModel () <StateDelegate>

@property (nonatomic) SAVService *service;
@property (nonatomic, copy) NSArray *dataSource;
@property (nonatomic, copy) NSArray *lights;
@property (nonatomic, copy) NSArray *allStates;
@property (nonatomic, copy) NSArray *allScopes;
@property (nonatomic) NSMutableDictionary *states;
@property (nonatomic) NSMutableDictionary *dirtyLieStates;
@property (nonatomic) NSMutableDictionary *dirtyLieTimers;
@property (nonatomic) SAVCoalescedTimer *stateUpdateTimer;
@property (nonatomic) id roomImageObserver;
@property (nonatomic) UIImage *roomImage;
@property (nonatomic, weak) NSTimer *repeatTimer;

@end

@implementation SCULightingModel

- (instancetype)initWithService:(SAVService *)service
{
    self = [super init];

    if (self)
    {
        self.service = service;
        self.states = [NSMutableDictionary dictionary];
        self.dirtyLieStates = [NSMutableDictionary dictionary];
        self.dirtyLieTimers = [NSMutableDictionary dictionary];
        self.stateUpdateTimer = [[SAVCoalescedTimer alloc] init];
        self.stateUpdateTimer.timeInverval = .3;
    }

    return self;
}

- (void)listenToToggleSwitch:(UISwitch *)toggleSwitch forIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    toggleSwitch.sav_didChangeHandler = ^(BOOL on) {
        [wSelf switchDidToggleOn:on forIndexPath:indexPath];
    };
}

- (void)listenToSlider:(SCUSlider *)slider forParentIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    slider.callback = ^(SCUSlider *slider) {
        [wSelf sliderDidUpdateToValue:slider.value forParentIndexPath:indexPath];
    };
}

- (void)listenToCloseButton:(SCUButton *)closeButton openButton:(SCUButton *)openButton forParentIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    [closeButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        [wSelf handleShadeCloseForIndexPath:indexPath isSlider:YES];
    }];

    [openButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        [wSelf handleShadeOpenForIndexPath:indexPath isSlider:YES];
    }];
}

- (void)listenToCloseButton:(SCUButton *)closeButton stopButton:(SCUButton *)stopButton openButton:(SCUButton *)openButton forParentIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    [closeButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        [wSelf handleShadeCloseForIndexPath:indexPath isSlider:NO];
    }];

    [stopButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        [wSelf handleShadeStopForIndexPath:indexPath];
    }];

    [openButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        [wSelf handleShadeOpenForIndexPath:indexPath isSlider:NO];
    }];
}

- (void)listenToOffButton:(SCUButton *)offButton lowButton:(SCUButton *)lowButton medButton:(SCUButton *)medButton highButton:(SCUButton *)highButton forParentIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    [offButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        [wSelf handleFanValue:SCUFanButtonsTableViewCellSelectedButtonOff forIndexPath:indexPath];
    }];
    
    [lowButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        [wSelf handleFanValue:SCUFanButtonsTableViewCellSelectedButtonLow forIndexPath:indexPath];
    }];
    
    [medButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        [wSelf handleFanValue:SCUFanButtonsTableViewCellSelectedButtonMed forIndexPath:indexPath];
    }];
    
    [highButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        [wSelf handleFanValue:SCUFanButtonsTableViewCellSelectedButtonHigh forIndexPath:indexPath];
    }];
}

- (void)listenToSceneHold:(UILongPressGestureRecognizer *)holdGesture forIndexPath:(NSIndexPath *)indexPath
{
    SAVEntity *entity = [self _modelObjectForIndexPath:indexPath][SCUDefaultTableViewCellKeyModelObject];

    if ([self requestForEvent:SAVEntityEvent_Hold value:0 entity:entity])
    {
        holdGesture.minimumPressDuration = .2;
        SAVWeakSelf;
        holdGesture.sav_handler = ^(UIGestureRecognizerState state, CGPoint location) {

            SAVStrongWeakSelf;
            switch (state)
            {
                case UIGestureRecognizerStateBegan:
                {
                    [sSelf handleTouchDown:indexPath];

                    [sSelf.repeatTimer invalidate];
                    sSelf.repeatTimer = [NSTimer sav_scheduledTimerWithTimeInterval:.2 repeats:YES block:^{
                        [wSelf handleHoldDown:indexPath];
                    }];

                    [sSelf.repeatTimer fire];

                    break;
                }
                case UIGestureRecognizerStateEnded:
                case UIGestureRecognizerStateFailed:
                case UIGestureRecognizerStateCancelled:
                    [sSelf handleTouchUp:indexPath];
                    break;
            }
        };
    }
}

- (void)setRoomImageInTable:(BOOL)roomImageInTable
{
    if (_roomImageInTable != roomImageInTable)
    {
        _roomImageInTable = roomImageInTable;
        [self roomImageDidUpdate:self.roomImage];
    }
}

#pragma mark - SCUExpandableDataSourceModel methods

- (void)loadDataIfNecessary
{
    if (!self.dataSource)
    {
        [self loadLightingData];
        [self.delegate reloadData];

        if (!self.service.zoneName)
        {
            [self roomImageDidUpdate:[UIImage imageNamed:@"whole-home"]];
        }
    }
}

- (void)viewDidDisappear
{
    [[Savant states] unregisterForStates:self.allStates forObserver:self];
    [[Savant images] removeObserver:self.roomImageObserver];

    //-------------------------------------------------------------------
    // Clean up lie states.
    //-------------------------------------------------------------------
    [self.dirtyLieStates removeAllObjects];

    for (NSTimer *timer in [self.dirtyLieTimers allValues])
    {
        [timer invalidate];
    }

    [self.dirtyLieTimers removeAllObjects];
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    SCULightingModelCellType cellType = [[self _modelObjectForIndexPath:indexPath][SCULightingCellType] unsignedIntegerValue];

    if ([self isKindOfClass:[SCUShadesModel class]] && cellType == SCULightingModelCellTypeToggleSwitch)
    {
        cellType = SCULightingModelCellTypePlain;
    }

    return cellType;
}

- (SCULightingEntityType)modelTypeForIndexPath:(NSIndexPath *)indexPath
{
    return [[self _modelObjectForIndexPath:indexPath][SCULightingModelType] unsignedIntegerValue];
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    SCULightingEntityType type = [self.dataSource[section][SCULightingSectionKey] unsignedIntegerValue];

    NSString *title = nil;

    switch (type)
    {
        case SCULightingEntityTypeLightingDimmer:
            title = NSLocalizedString(@"Dimmers", nil);
            break;
        case SCULightingEntityTypeLightingSwitch:
            title = NSLocalizedString(@"Switches", nil);
            break;
        case SCULightingEntityTypeShadeDimmer:
        case SCULightingEntityTypeShadeSwitch:
            title = NSLocalizedString(@"Shades", nil);
            break;
        case SCULightingEntityTypeFan:
            title = NSLocalizedString(@"Fans", nil);
            break;
    }

    return title;
}

- (NSInteger)numberOfChildrenBelowIndexPath:(NSIndexPath *)indexPath
{
    return 1;
}

- (NSUInteger)cellTypeForChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    SCULightingModelCellType cellType = SCULightingModelCellTypeSlider;

    switch ([self modelTypeForIndexPath:indexPath])
    {
        case SCULightingEntityTypeShadeDimmer:
        case SCULightingEntityTypeLightingDimmer:
            cellType = SCULightingModelCellTypeSlider;
            break;
        case SCULightingEntityTypeShadeSwitch:
            cellType = SCULightingModelCellTypeShadesRelative;
            break;
        case SCULightingEntityTypeFan:
            cellType = SCULightingModelCellTypeFan;
            break;
    }

    return cellType;
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];

    switch ([self cellTypeForIndexPath:indexPath])
    {
        case SCULightingModelCellTypeToggleSwitch:
        {
            modelObject = [modelObject dictionaryByAddingObject:@([self valueForIndexPath:indexPath])
                                                         forKey:SCUToggleSwitchTableViewCellKeyValue];
            
            SCUDefaultTableViewCellBottomLineType bottomLine = [self.expandedIndexPaths containsObject:indexPath] ? SCUDefaultTableViewCellBottomLineTypeNone :  SCUDefaultTableViewCellBottomLineTypeFull;
            
            modelObject = [modelObject dictionaryByAddingObject:@(bottomLine)
                                                         forKey:SCUDefaultTableViewCellKeyBottomLineType];

            break;
        }
        case SCULightingModelCellTypeScene:
        {
            modelObject = [modelObject dictionaryByAddingObject:@([self valueForIndexPath:indexPath])
                                                         forKey:SCULightingSceneButtonTableViewCellKeyEnabled];

            break;
        }
        case SCULightingModelCellTypePlain:
        {
            if ([self isKindOfClass:[SCUShadesModel class]])
            {
                SCUDefaultTableViewCellBottomLineType bottomLine = [self.expandedIndexPaths containsObject:indexPath] ? SCUDefaultTableViewCellBottomLineTypeNone :  SCUDefaultTableViewCellBottomLineTypeFull;

                modelObject = [modelObject dictionaryByAddingObject:@(bottomLine)
                                                             forKey:SCUDefaultTableViewCellKeyBottomLineType];
            }

            break;
        }
        case SCULightingModelCellTypeRoomImage:
            modelObject = [modelObject dictionaryByAddingObject:self.service.zoneName ? self.service.zoneName : NSLocalizedString(@"Home", nil)
                                                         forKey:SCUDefaultTableViewCellKeyTitle];
            break;
    }

    return modelObject;
}

- (id)modelObjectForChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];

    switch ([self modelTypeForIndexPath:indexPath])
    {
        case SCULightingEntityTypeLightingDimmer:
        case SCULightingEntityTypeShadeDimmer:
        {
            modelObject = [modelObject dictionaryByAddingObject:@([self valueForIndexPath:indexPath])
                                                         forKey:SCUSliderMinMaxCellKeyValue];
            break;
        }
        case SCULightingEntityTypeFan:
            modelObject = [modelObject dictionaryByAddingObject:@([self selectedFanButtonForIndexPath:indexPath])
                                                         forKey:SCUFanButtonsTableViewCellKeySelectedButton];
            break;
    }

    return modelObject;
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self cellTypeForIndexPath:indexPath] == SCULightingModelCellTypeScene)
    {
        [self handleTouchDown:indexPath];
        [self handleTouchUp:indexPath];
    }
}

#pragma mark - StateDelegate methods

- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    if (stateUpdate.state && stateUpdate.value)
    {
        if ([stateUpdate.value isKindOfClass:[NSString class]])
        {
            if ([stateUpdate.value hasPrefix:@"Switch"])
            {
                if ([stateUpdate.value isEqualToString:@"SwitchOn"])
                {
                    self.states[stateUpdate.state] = @YES;
                }
                else if ([stateUpdate.value isEqualToString:@"SwitchOff"])
                {
                    self.states[stateUpdate.state] = @NO;
                }
            }
            else
            {
                self.states[stateUpdate.state] = stateUpdate.value;
            }
        }
        else
        {
            self.states[stateUpdate.state] = stateUpdate.value;
        }

        [self reloadData];
    }
}

- (void)reloadData
{
    SAVWeakSelf;
    [self.stateUpdateTimer addWorkWithKey:@"refresh" work:^{
        [wSelf.delegate reloadData];
    }];
}

#pragma mark - Private

- (BOOL)isFlat
{
    return NO;
}

- (NSArray *)arrayForSection:(NSInteger)section
{
    return self.dataSource[section][SCULightingArrayKey];
}

- (SCULightingEntityType)lightingTypes
{
    return SCULightingEntityTypeScene |
    SCULightingEntityTypeLightingDimmer |
    SCULightingEntityTypeLightingSwitch |
    SCULightingEntityTypeFan;
}

- (void)roomImageDidUpdate:(UIImage *)image
{
    self.roomImage = image;

    if (self.isRoomImageInTable)
    {
        NSArray *roomImageSection = [self arrayForSection:0];
        NSMutableDictionary *modelObject = [roomImageSection firstObject];

        if (image)
        {
            modelObject[SCULightingCellType] = @(SCULightingModelCellTypeRoomImage);
        }
        else
        {
            modelObject[SCULightingCellType] = @(SCULightingModelCellTypeEmptyRoomImage);
        }

        [self.delegate reloadData];
    }
    else
    {
        NSArray *roomImageSection = [self arrayForSection:0];
        NSMutableDictionary *modelObject = [roomImageSection firstObject];

        if ([modelObject[SCULightingCellType] unsignedIntegerValue] == SCULightingModelCellTypeRoomImage)
        {
            modelObject[SCULightingCellType] = @(SCULightingModelCellTypeEmptyRoomImage);
            [self.delegate reloadData];
        }
    }

    [self.roomImageDelegate roomImageDidUpdate:image];
}

- (void)didLoadLightingData
{
    [[Savant states] registerForStates:self.allStates forObserver:self];

    NSMutableDictionary *fakeRoomImage = [@{SCULightingModelType: @(SCULightingEntityTypeRoomImage),
                                            SCULightingCellType: @(SCULightingModelCellTypeEmptyRoomImage)} mutableCopy];

    NSDictionary *roomImageSection = @{SCULightingSectionKey: @(SCULightingEntityTypeRoomImage),
                                       SCULightingArrayKey: @[fakeRoomImage]};

    NSMutableArray *dataSource = [NSMutableArray arrayWithObject:roomImageSection];
    [dataSource addObjectsFromArray:self.lights];
    self.dataSource = dataSource;

    SAVWeakSelf;
    self.roomImageObserver = [[Savant images] addObserverForKey:self.service.zoneName type:SAVImageTypeRoomImage size:SAVImageSizeMedium blurred:NO andCompletionHandler:^(UIImage *image, BOOL isDefault) {
        [wSelf roomImageDidUpdate:image];
    }];

    [self enumerateModelObjects:^(NSIndexPath *indexPath) {
        switch ([self modelTypeForIndexPath:indexPath])
        {
            case SCULightingEntityTypeLightingDimmer:
            case SCULightingEntityTypeShadeDimmer:
            case SCULightingEntityTypeShadeSwitch:
            case SCULightingEntityTypeFan:
                [self toggleIndexPath:indexPath];
                break;
        }
    }];
}

- (void)switchDidToggleOn:(BOOL)on forIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];
    SAVServiceRequest *request = nil;
    SAVEntity *entity = modelObject[SCUDefaultTableViewCellKeyModelObject];
    NSString *state = modelObject[SCULightingStateKey];
    NSNumber *newValue = nil;

    switch ([self modelTypeForIndexPath:indexPath])
    {
        case SCULightingEntityTypeScene:
        {
            break;
        }
        case SCULightingEntityTypeLightingDimmer:
        {
            if (on)
            {
                request = [self requestForEvent:SAVEntityEvent_SwitchOn value:0 entity:entity];
                newValue = @100;
            }
            else
            {
                request = [self requestForEvent:SAVEntityEvent_SwitchOff value:0 entity:entity];
                newValue = @0;
            }

            break;
        }
        case SCULightingEntityTypeLightingSwitch:
        {
            if (on)
            {
                request = [self requestForEvent:SAVEntityEvent_SwitchOn value:0 entity:entity];
            }
            else
            {
                request = [self requestForEvent:SAVEntityEvent_SwitchOff value:0 entity:entity];
            }

            break;
        }
        case SCULightingEntityTypeShadeDimmer:
        {
            if (on)
            {
                request = [self requestForEvent:SAVEntityEvent_ShadeUp value:0 entity:entity];
            }
            else
            {
                request = [self requestForEvent:SAVEntityEvent_ShadeDown value:0 entity:entity];
            }

            break;
        }
    }

    if (request)
    {
        [[Savant control] sendMessage:request];
    }

    if (state && newValue)
    {
        self.states[state] = newValue;
        NSIndexPath *absoluteIndexPath = [self absoluteIndexPathForRelativeIndexPath:indexPath];
        [self.delegate reloadIndexPath:[NSIndexPath indexPathForItem:absoluteIndexPath.item + 1 inSection:absoluteIndexPath.section]];
    }
}

- (void)sliderDidUpdateToValue:(CGFloat)value forParentIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];
    SAVServiceRequest *request = nil;
    SAVLightEntity *entity = modelObject[SCUDefaultTableViewCellKeyModelObject];

    if (entity.stateName)
    {
        [self updateLieTimerForState:entity.stateName lieValue:(NSInteger)value indexPath:nil];
    }

    switch ([self modelTypeForIndexPath:indexPath])
    {
        case SCULightingEntityTypeLightingDimmer:
        {
            request = [self requestForEvent:SAVEntityEvent_Dimmer value:@((NSInteger)value) entity:entity];

            if (value == 0)
            {
                [self.delegate toggleSwitchForIndexPath:indexPath];
            }

            break;
        }
        case SCULightingEntityTypeShadeDimmer:
        {
            request = [self requestForEvent:SAVEntityEvent_ShadeSet value:@((NSInteger)value) entity:entity];
            break;
        }
    }

    if (request)
    {
        [[Savant control] sendMessage:request];
    }
}

#pragma mark - Handle scene buttons

- (void)handleTouchDown:(NSIndexPath *)indexPath
{
    SAVLightEntity *entity = [self _modelObjectForIndexPath:indexPath][SCUDefaultTableViewCellKeyModelObject];

    if ([entity isKindOfClass:[SAVShadeEntity class]] && (entity.type == SAVEntityType_Button))
    {
        //-------------------------------------------------------------------
        // Do nothing for now.
        //-------------------------------------------------------------------
    }
    else if ([entity.stateName length])
    {
        NSInteger value = [self valueForIndexPath:indexPath];
        NSInteger lieValue = 0;

        if (value > 0)
        {
            //-------------------------------------------------------------------
            // Lie about turning it off.
            //-------------------------------------------------------------------
            lieValue = 0;
        }
        else
        {
            //-------------------------------------------------------------------
            // Lie about turning it on.
            //-------------------------------------------------------------------
            lieValue = 100;
        }

        [self updateLieTimerForState:entity.stateName lieValue:lieValue indexPath:indexPath];
    }

    SAVServiceRequest *request = nil;

    if ([self trueValueForIndexPath:indexPath])
    {
        request = [self requestForEvent:SAVEntityEvent_TogglePress value:0 entity:entity];
    }
    else
    {
        request = [self requestForEvent:SAVEntityEvent_Press value:0 entity:entity];
    }

    if (request)
    {
        [[Savant control] sendMessage:request];
    }
}

- (void)handleHoldDown:(NSIndexPath *)indexPath
{
    SAVEntity *entity = [self _modelObjectForIndexPath:indexPath][SCUDefaultTableViewCellKeyModelObject];

    SAVServiceRequest *request = nil;

    if ([self trueValueForIndexPath:indexPath])
    {
        request = [self requestForEvent:SAVEntityEvent_ToggleHold value:0 entity:entity];
    }
    else
    {
        request = [self requestForEvent:SAVEntityEvent_Hold value:0 entity:entity];
    }

    if (request)
    {
        [[Savant control] sendMessage:request];
    }
}

- (void)handleTouchUp:(NSIndexPath *)indexPath
{
    [self.repeatTimer invalidate];
    self.repeatTimer = nil;

    SAVEntity *entity = [self _modelObjectForIndexPath:indexPath][SCUDefaultTableViewCellKeyModelObject];

    SAVServiceRequest *request = nil;

    if ([self trueValueForIndexPath:indexPath])
    {
        request = [self requestForEvent:SAVEntityEvent_ToggleRelease value:0 entity:entity];
    }
    else
    {
        request = [self requestForEvent:SAVEntityEvent_Release value:0 entity:entity];
    }

    if (request)
    {
        [[Savant control] sendMessage:request];
    }
}

#pragma mark - Handle fans

- (void)handleFanValue:(SCUFanButtonsTableViewCellSelectedButton)value forIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];
    SAVLightEntity *entity = modelObject[SCUDefaultTableViewCellKeyModelObject];
    SAVServiceRequest *request = nil;
	
	if (entity.stateName)
	{
		NSIndexPath *absoluteIndexPath = [self absoluteIndexPathForRelativeIndexPath:indexPath];
		NSIndexPath *realIndexPath = [NSIndexPath indexPathForRow:absoluteIndexPath.row + 1 inSection:absoluteIndexPath.section];
		[self updateLieTimerForState:entity.stateName lieValue:(NSInteger)value indexPath:realIndexPath];
	}
	
    SAVEntityEvent event = SAVEntityEvent_FanOff;
    
    switch (value)
    {
        case SCUFanButtonsTableViewCellSelectedButtonLow:
            event = SAVEntityEvent_FanLow;
            break;
        case SCUFanButtonsTableViewCellSelectedButtonMed:
            event = SAVEntityEvent_FanMedium;
            break;
        case SCUFanButtonsTableViewCellSelectedButtonHigh:
            event = SAVEntityEvent_FanHigh;
            break;
    }
    
    request = [self requestForEvent:event value:@(value) entity:entity];
    
    if (request)
    {
        [[Savant control] sendMessage:request];
    }
}

#pragma mark - Handle relative shades

- (void)handleShadeCloseForIndexPath:(NSIndexPath *)indexPath isSlider:(BOOL)isSlider
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];
    SAVEntity *entity = modelObject[SCUDefaultTableViewCellKeyModelObject];
    SAVServiceRequest *request = nil;

    if (isSlider)
    {
        request = [self requestForEvent:SAVEntityEvent_ShadeSet value:@"0" entity:entity];
    }
    else
    {
        request = [self requestForEvent:SAVEntityEvent_ShadeDown value:0 entity:entity];
    }

    if (request)
    {
        [[Savant control] sendMessage:request];
    }
}

- (void)handleShadeStopForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];
    SAVEntity *entity = modelObject[SCUDefaultTableViewCellKeyModelObject];
    SAVServiceRequest *request = [self requestForEvent:SAVEntityEvent_ShadeStop value:0 entity:entity];

    if (request)
    {
        [[Savant control] sendMessage:request];
    }
}

- (void)handleShadeOpenForIndexPath:(NSIndexPath *)indexPath isSlider:(BOOL)isSlider
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];
    SAVEntity *entity = modelObject[SCUDefaultTableViewCellKeyModelObject];
    SAVServiceRequest *request = nil;

    if (isSlider)
    {
        request = [self requestForEvent:SAVEntityEvent_ShadeSet value:@"100" entity:entity];
    }
    else
    {
        request = [self requestForEvent:SAVEntityEvent_ShadeUp value:0 entity:entity];
    }

    if (request)
    {
        [[Savant control] sendMessage:request];
    }
}

- (SCUFanButtonsTableViewCellSelectedButton)selectedFanButtonForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];
    NSString *state = modelObject[SCULightingStateKey];
    
    NSString *stateValue = self.states[state];
	
	NSNumber *lieValue = self.dirtyLieStates[state];
	if (lieValue)
	{
		return (SCUFanButtonsTableViewCellSelectedButton)[lieValue integerValue];
	}
	
    if ([stateValue isEqualToString:@"Off"])
    {
        return SCUFanButtonsTableViewCellSelectedButtonOff;
    }
    else if ([stateValue isEqualToString:@"Low"])
    {
        return SCUFanButtonsTableViewCellSelectedButtonLow;
    }
    else if ([stateValue isEqualToString:@"Medium"])
    {
        return SCUFanButtonsTableViewCellSelectedButtonMed;
    }
    else if ([stateValue isEqualToString:@"High"])
    {
        return SCUFanButtonsTableViewCellSelectedButtonHigh;
    }
    
    return SCUFanButtonsTableViewCellSelectedButtonNone;
}

- (NSInteger)valueForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];
    NSString *state = modelObject[SCULightingStateKey];

    NSNumber *lieValue = self.dirtyLieStates[state];

    if (lieValue)
    {
        return [lieValue integerValue];
    }
    else
    {
        return [self.states[state] integerValue];
    }
}

- (NSInteger)trueValueForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];
    NSString *state = modelObject[SCULightingStateKey];
    return [self.states[state] integerValue];
}

- (NSInteger)valueForChildBelowIndexPath:(NSIndexPath *)indexPath
{
    return [self valueForIndexPath:indexPath];
}

#pragma mark -

- (BOOL)lightsAreWanted
{
    BOOL lightsAreWanted = NO;

    SCULightingEntityType lightingTypes = [self lightingTypes];

    if (lightingTypes & SCULightingEntityTypeScene || lightingTypes & SCULightingEntityTypeLightingDimmer || lightingTypes & SCULightingEntityTypeLightingSwitch)
    {
        lightsAreWanted = YES;
    }

    return lightsAreWanted;
}

- (BOOL)fansAreWanted
{
    BOOL fansAreWanted = NO;
    
    SCULightingEntityType lightingTypes = [self lightingTypes];
    
    if (lightingTypes & SCULightingEntityTypeScene || lightingTypes & SCULightingEntityTypeFan)
    {
        fansAreWanted = YES;
    }
    
    return fansAreWanted;
}

- (BOOL)shadesAreWanted
{
    BOOL shadesAreWanted = NO;

    SCULightingEntityType lightingTypes = [self lightingTypes];

    if (lightingTypes & SCULightingEntityTypeShadeDimmer || lightingTypes & SCULightingEntityTypeShadeSwitch)
    {
        shadesAreWanted = YES;
    }

    return shadesAreWanted;
}

- (void)loadLightingData
{
    SAVData *data = [Savant data];

    NSMutableArray *dataSource = [NSMutableArray array];
    NSMutableSet *allStates = [NSMutableSet set];

    SAVArrayMappingBlock mappingBlock = ^id(SAVEntity *entity) {
        NSString *state = [entity.states firstObject];
        NSMutableDictionary *dict = nil;

        SCULightingEntityType modelType = [self modelTypeFromEntityType:entity.type];

        if ([state length] || modelType == SCULightingEntityTypeShadeSwitch || modelType == SCULightingEntityTypeScene)
        {
            dict = [NSMutableDictionary dictionary];

            if ([state length])
            {
                [allStates addObject:state];
                dict[SCULightingStateKey] = state;
            }

            dict[SCULightingModelType] = @(modelType);
            SCULightingModelCellType cellType = [self cellTypeFromModelType:modelType];
            dict[SCULightingCellType] = @(cellType);
            dict[SCUDefaultTableViewCellKeyTitle] = entity.label;
            dict[SCUDefaultTableViewCellKeyModelObject] = entity;
        }

        return dict;
    };

    if ([self lightsAreWanted] || [self fansAreWanted])
    {
        NSArray *allLights = [data lightEntitiesForRoom:self.service.zoneName];

        if ([self lightingTypes] & SCULightingEntityTypeScene)
        {
            NSArray *lightScenes = [allLights filteredArrayUsingBlock:^BOOL(SAVEntity *entity) {
                return entity.type == SAVEntityType_Scene || entity.type == SAVEntityType_Button;
            }];

            NSArray *filteredScenes = [lightScenes arrayByMappingBlock:mappingBlock];

            if ([filteredScenes count])
            {
                [dataSource addObject:@{SCULightingSectionKey: @(SCULightingEntityTypeScene),
                                        SCULightingArrayKey: filteredScenes}];
            }
        }

        if ([self lightingTypes] & SCULightingEntityTypeLightingDimmer)
        {
            NSArray *lightDimmers = [allLights filteredArrayUsingBlock:^BOOL(SAVEntity *entity) {
                return entity.type == SAVEntityType_Dimmer;
            }];

            NSArray *filteredLightDimmers = [lightDimmers arrayByMappingBlock:mappingBlock];

            if ([filteredLightDimmers count])
            {
                [dataSource addObject:@{SCULightingSectionKey: @(SCULightingEntityTypeLightingDimmer),
                                        SCULightingArrayKey: filteredLightDimmers}];
            }
        }

        if ([self lightingTypes] & SCULightingEntityTypeLightingSwitch)
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
                [dataSource addObject:@{SCULightingSectionKey: @(SCULightingEntityTypeLightingSwitch),
                                        SCULightingArrayKey: filteredLightSwitches}];
            }
        }
        
        if ([self lightingTypes] & SCULightingEntityTypeFan)
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
                [dataSource addObject:@{SCULightingSectionKey: @(SCULightingEntityTypeFan),
                                        SCULightingArrayKey: filteredFans}];
            }
        }
    }

    if ([self shadesAreWanted])
    {
        NSArray *allShades = [data shadeEntitiesForRoom:self.service.zoneName];

        NSArray *shades = [allShades filteredArrayUsingBlock:^BOOL(SAVEntity *entity) {

            if (entity.type == SAVEntityType_Variable && [self lightingTypes] & SCULightingEntityTypeShadeDimmer)
            {
                return YES;
            }
            else if (entity.type == SAVEntityType_Shade && [self lightingTypes] & SCULightingEntityTypeShadeSwitch)
            {
                return YES;
            }
            else if (entity.type == SAVEntityType_Button)
            {
                return YES;
            }
            else
            {
                return NO;
            }

        }];

        NSArray *filteredShades = [shades arrayByMappingBlock:mappingBlock];

        if ([filteredShades count])
        {
            [dataSource addObject:@{SCULightingSectionKey: @(SCULightingEntityTypeShadeDimmer),
                                    SCULightingArrayKey: filteredShades}];
        }
    }

    self.lights = dataSource;
    self.dataSource = dataSource;

    self.allStates = [allStates allObjects];

    NSMutableSet *allScopes = [NSMutableSet set];

    for (NSString *state in self.allStates)
    {
        NSArray *components = [state componentsSeparatedByString:@"."];

        if ([components count] == 3)
        {
            [allScopes addObject:[[components subarrayWithRange:NSMakeRange(0, 2)] componentsJoinedByString:@"."]];
        }
    }

    self.allScopes = [allScopes allObjects];

    [self didLoadLightingData];
}

- (SCULightingEntityType)modelTypeFromEntityType:(SAVEntityType)entityType
{
    SCULightingEntityType modelType = SCULightingEntityTypeScene;

    switch (entityType)
    {
        case SAVEntityType_Button:
        case SAVEntityType_Scene:
            modelType = SCULightingEntityTypeScene;
            break;
        case SAVEntityType_Dimmer:
        case SAVEntityType_Hue:
            modelType = SCULightingEntityTypeLightingDimmer;
            break;
        case SAVEntityType_Switch:
            modelType = SCULightingEntityTypeLightingSwitch;
            break;
        case SAVEntityType_Variable:
            modelType = SCULightingEntityTypeShadeDimmer;
            break;
        case SAVEntityType_Shade:
            modelType = SCULightingEntityTypeShadeSwitch;
            break;
        case SAVEntityType_Fan:
            modelType = SCULightingEntityTypeFan;
            break;
    }

    return modelType;
}

- (SCULightingModelCellType)cellTypeFromModelType:(SCULightingEntityType)modelType
{
    SCULightingModelCellType cellType = 0;

    switch (modelType)
    {
        case SCULightingEntityTypeLightingDimmer:
        case SCULightingEntityTypeShadeDimmer:
        case SCULightingEntityTypeLightingSwitch:
            cellType = SCULightingModelCellTypeToggleSwitch;
            break;
        case SCULightingEntityTypeFan:
        case SCULightingEntityTypeShadeSwitch:
            cellType = SCULightingModelCellTypePlain;
            break;
        case SCULightingEntityTypeScene:
            cellType = SCULightingModelCellTypeScene;
            break;
    }
    
    return cellType;
}

- (SAVServiceRequest *)requestForEvent:(SAVEntityEvent)event value:(id)value entity:(SAVEntity *)entity
{
    SAVServiceRequest *request = [entity requestForEvent:event value:value];
    request.zoneName = self.service.zoneName;
    return request;
}

- (void)updateLieTimerForState:(NSString *)stateName lieValue:(NSInteger)lieValue indexPath:(NSIndexPath *)indexPath
{
    self.dirtyLieStates[stateName] = @(lieValue);
    NSTimer *lieTimer = self.dirtyLieTimers[stateName];
    [lieTimer invalidate];
    lieTimer = nil;

    if (indexPath)
    {
        [self.delegate reloadIndexPath:indexPath];
    }

    SAVWeakSelf;
    lieTimer = [NSTimer sav_scheduledBlockWithDelay:3 block:^{
        SAVStrongWeakSelf;
        [sSelf.dirtyLieStates removeObjectForKey:stateName];
        [sSelf reloadData];
    }];

    self.dirtyLieTimers[stateName] = lieTimer;
}

@end
