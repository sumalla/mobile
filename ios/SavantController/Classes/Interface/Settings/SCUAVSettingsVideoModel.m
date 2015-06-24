//
//  SCUAVSettingsVideoModel.m
//  SavantController
//
//  Created by Stephen Silber on 7/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVSettingsVideoModel.h"
#import "SCUAVSettingsVideoModelPrivate.h"
#import "SCUDefaultTableViewCell.h"
#import "SCUAVSettingsSliderButtonCell.h"
#import "SCUAVSettingsSelectCell.h"
#import "SCUAVSettingsRightInfoCell.h"
#import "SCUActionSheet.h"
#import "SCUSlider.h"
#import "SCUCenteredSlider.h"
#import <SavantExtensions/SAVUIKitExtensions.h>

@interface SCUAVSettingsVideoModel ()

@property (nonatomic) NSArray *states;
@property (nonatomic) NSMutableDictionary *currentStates;
@property (nonatomic) NSArray *stateNames;
@property (nonatomic) SCUAVSettingsVideoSelectModel *selectModel;
@property (nonatomic) NSArray *services;
@property (nonatomic) NSDictionary *statesToIndexPath;
@property (nonatomic) NSDictionary *indexPathToStates;
@property (nonatomic) SAVCoalescedTimer *effectsTimer;

@end

NSString *const SCUAVSettingsModelKeyType            = @"SCUAVSettingsModelKeyType";
NSString *const SCUAVSettingsVideoActionSheetArray   = @"SCUAVSettingsVideoActionSheetTitlesArray";
NSString *const SCUAVSettingsVideoActionSheetCommand = @"SCUAVSettingsVideoActionSheetCommand";
NSString *const SCUAVSettingsVideoActionSheetTitle   = @"SCUAVSettingsVideoActionSheetTitle";
NSString *const SCUAVSettingsModelState              = @"SCUAVSettingsModelState";
NSString *const SCUAVSettingsModelValueKey           = @"SCUAVSettingsModelValueKey";

@implementation SCUAVSettingsVideoModel

- (void)dealloc
{
    [[SavantControl sharedControl] unregisterForStates:self.states forObserver:self];
}

- (instancetype)initWithServices:(NSArray *)services
{
    self = [super init];
    
    if (self)
    {
        self.services = services;
        self.effectsTimer = [[SAVCoalescedTimer alloc] init];
        self.effectsTimer.timeInverval = 0.1;

        if ([self.services count])
        {
            SAVService *service = self.services.firstObject;
            self.stateNames = [[[self stateNamesToDelegateSelectors] allKeys] arrayByMappingBlock:^id(NSString *stateName) {
                return [NSString stringWithFormat:@"%@.%@.%@", service.component, service.logicalComponent, stateName];
            }];
        }
        
        self.currentStates = [NSMutableDictionary dictionary];


        self.dataSource = @[@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Input", nil),
                              SCUAVSettingsModelValueKey : SCUAVSettingsRightInfoCellRightTitle,
                              SCUAVSettingsModelKeyType: @(SCUAVSettingsVideoCellTypeRightInfo),
                              SCUAVSettingsRightInfoCellRightTitle: NSLocalizedString(@"1080p", nil),
                              SCUAVSettingsModelState : @"CurrentVideoInputFormat"},
                            
                            @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Output", nil),
                              SCUAVSettingsModelValueKey : SCUAVSettingsRightInfoCellRightTitle,
                              SCUAVSettingsModelKeyType: @(SCUAVSettingsVideoCellTypeRightInfo),
                              SCUAVSettingsRightInfoCellRightTitle: NSLocalizedString(@"1080p", nil),
                              SCUAVSettingsModelState : @"CurrentVideoOutputFormat"},
                            
                            @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"3D", nil),
                              SCUAVSettingsModelValueKey : SCUAVSettingsCellLeftValueLabel,
                              SCUAVSettingsModelKeyType: @(SCUAVSettingsVideoCellTypeMenuSelect),
                              SCUAVSettingsCellLeftValueLabel: NSLocalizedString(@"Off", nil),
                              SCUAVSettingsVideoActionSheetArray: @[@{SCUAVSettingsVideoActionSheetTitle: NSLocalizedString(@"Top and Bottom", nil),
                                                                            SCUAVSettingsVideoActionSheetCommand: @"Set3DTopBottom"},
                                                                          @{SCUAVSettingsVideoActionSheetTitle: NSLocalizedString(@"Side by Side", nil),
                                                                            SCUAVSettingsVideoActionSheetCommand: @"Set3DSideBySide"},
                                                                          @{SCUAVSettingsVideoActionSheetTitle: NSLocalizedString(@"Off", nil),
                                                                            SCUAVSettingsVideoActionSheetCommand: @"Set3DOff"}],
                              SCUAVSettingsModelState : @"Current3D"},
                            
                            @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Aspect Ratio", nil),
                              SCUAVSettingsModelKeyType: @(SCUAVSettingsVideoCellTypeMenuSelect),
                              SCUAVSettingsModelValueKey : SCUAVSettingsCellLeftValueLabel,
                              SCUAVSettingsCellLeftValueLabel: NSLocalizedString(@"Default", nil),
                              SCUAVSettingsVideoActionSheetArray: @[@{SCUAVSettingsVideoActionSheetTitle: NSLocalizedString(@"Anamorphic", nil),
                                                                            SCUAVSettingsVideoActionSheetCommand: @"SetAspectRatioAnamorphic"},
                                                                          @{SCUAVSettingsVideoActionSheetTitle: NSLocalizedString(@"Stretch", nil),
                                                                            SCUAVSettingsVideoActionSheetCommand: @"SetAspectRatioStretch"},
                                                                          @{SCUAVSettingsVideoActionSheetTitle: NSLocalizedString(@"Vertical Stretch", nil),
                                                                            SCUAVSettingsVideoActionSheetCommand: @"SetAspectRatioVerticalStretch"},
                                                                          @{SCUAVSettingsVideoActionSheetTitle: NSLocalizedString(@"Zoom", nil),
                                                                            SCUAVSettingsVideoActionSheetCommand: @"SetAspectRatioZoom"},
                                                                          @{SCUAVSettingsVideoActionSheetTitle: NSLocalizedString(@"Pillar Box", nil),
                                                                            SCUAVSettingsVideoActionSheetCommand: @"SetAspectRatioPillarBox"},
                                                                          @{SCUAVSettingsVideoActionSheetTitle: NSLocalizedString(@"Panoramic", nil),
                                                                            SCUAVSettingsVideoActionSheetCommand: @"SetAspectRatioPanoramic"},
                                                                          @{SCUAVSettingsVideoActionSheetTitle: NSLocalizedString(@"Panoramic Stretch", nil),
                                                                            SCUAVSettingsVideoActionSheetCommand: @"SetAspectRatioPanoramicStretch"},
                                                                    ],
                              SCUAVSettingsModelState : @"CurrentAspectRatio"},
                            
                            @{SCUAVSettingsSliderButtonCellKeyTopTitle: NSLocalizedString(@"Contrast:", nil),
                              SCUAVSettingsModelValueKey : SCUAVSettingsSliderButtonCellSliderValue,
                              SCUAVSettingsModelKeyType: @(SCUAVSettingsVideoCellTypeSlider),
                              SCUAVSettingsSliderButtonCellSliderType: @(SCUAVSettingsSliderTypeCenter),
                              SCUAVSettingsModelState : @"CurrentContrast",
                              SCUAVSettingsSliderCellValueRange: @{@"min": @(-50.0), @"max" : @(50.0)}},
                            
                            @{SCUAVSettingsSliderButtonCellKeyTopTitle: NSLocalizedString(@"Brightness:", nil),
                              SCUAVSettingsModelValueKey : SCUAVSettingsSliderButtonCellSliderValue,
                              SCUAVSettingsModelKeyType: @(SCUAVSettingsVideoCellTypeSlider),
                              SCUAVSettingsSliderButtonCellSliderType: @(SCUAVSettingsSliderTypeCenter),
                              SCUAVSettingsModelState : @"CurrentBrightness",
                              SCUAVSettingsSliderCellValueRange: @{@"min": @(-50.0), @"max" : @(50.0)}},
                            
                            @{SCUAVSettingsSliderButtonCellKeyTopTitle: NSLocalizedString(@"Saturation:", nil),
                              SCUAVSettingsModelValueKey : SCUAVSettingsSliderButtonCellSliderValue,
                              SCUAVSettingsModelKeyType: @(SCUAVSettingsVideoCellTypeSlider),
                              SCUAVSettingsSliderButtonCellSliderType: @(SCUAVSettingsSliderTypeCenter),
                              SCUAVSettingsModelState : @"CurrentSaturation",
                              SCUAVSettingsSliderCellValueRange: @{@"min": @(-50.0), @"max" : @(50.0)}},
                            
                            @{SCUAVSettingsSliderButtonCellKeyTopTitle: NSLocalizedString(@"Hue:", nil),
                              SCUAVSettingsModelValueKey : SCUAVSettingsSliderButtonCellSliderValue,
                              SCUAVSettingsModelKeyType: @(SCUAVSettingsVideoCellTypeSlider),
                              SCUAVSettingsSliderButtonCellSliderType: @(SCUAVSettingsSliderTypeCenter),
                              SCUAVSettingsModelState : @"CurrentHue",
                              SCUAVSettingsSliderCellValueRange: @{@"min": @(-50.0), @"max" : @(50.0)}},
                            
                            @{SCUAVSettingsSliderButtonCellKeyTopTitle: NSLocalizedString(@"Detail Enhancement:", nil),
                              SCUAVSettingsModelValueKey : SCUAVSettingsSliderButtonCellSliderValue,
                              SCUAVSettingsModelKeyType: @(SCUAVSettingsVideoCellTypeSlider),
                              SCUAVSettingsSliderButtonCellSliderType: @(SCUAVSettingsSliderTypeNormal),
                              SCUAVSettingsModelState : @"CurrentDetailEnhancementLevel",
                              SCUAVSettingsSliderCellValueRange: @{@"min": @(0.0), @"max" : @(31.0)}},
                            
                            @{SCUAVSettingsSliderButtonCellKeyTopTitle: NSLocalizedString(@"Noise Level:", nil),
                              SCUAVSettingsModelValueKey : SCUAVSettingsSliderButtonCellSliderValue,
                              SCUAVSettingsModelKeyType: @(SCUAVSettingsVideoCellTypeSlider),
                              SCUAVSettingsSliderButtonCellSliderType: @(SCUAVSettingsSliderTypeNormal),
                              SCUAVSettingsModelState : @"CurrentNoiseReduction",
                              SCUAVSettingsSliderCellValueRange: @{@"min": @(0.0), @"max" : @(100.0)}}];
        
        [[SavantControl sharedControl] registerForStates:self.states forObserver:self];
    }
    
    return self;
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *modelObject = [self.dataSource[indexPath.row] mutableCopy];

    if (self.currentStates[modelObject[SCUAVSettingsModelState]])
    {
        // Changes which value in the cell to set based on the data source
        NSString *key = modelObject[SCUAVSettingsModelValueKey];
        modelObject[key] = self.currentStates[modelObject[SCUAVSettingsModelState]];
    }
    return [modelObject copy];
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (NSInteger)numberOfSections
{
    return 1;
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];
    SCUAVSettingsVideoCellType type = [modelObject[SCUAVSettingsModelKeyType] unsignedIntegerValue];
    self.type = type;

    if (self.type == SCUAVSettingsVideoCellTypeMenuSelect)
    {
        NSArray *titles = [modelObject[SCUAVSettingsVideoActionSheetArray] valueForKey:SCUAVSettingsVideoActionSheetTitle];
        SAVWeakSelf;
        [self.delegate presentActionSheetFromIndexPath:indexPath withTitles:titles callback:^(NSInteger buttonIndex) {
            [wSelf handleActionSheetSelectionAtIndex:buttonIndex withTitles:titles forIndexPath:indexPath];
        }];
    }
}

- (NSIndexPath *)indexPathFromStateName:(NSString *)stateName
{
    NSInteger index = 0;
    for (NSDictionary *cellData in self.dataSource)
    {
        if ([cellData[SCUAVSettingsModelState] isEqualToString:stateName])
        {
            return [NSIndexPath indexPathForRow:index inSection:0];
        }
        
        index++;
    }
    
    return nil;
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    return [[self modelObjectForIndexPath:indexPath][SCUAVSettingsModelKeyType] unsignedIntegerValue];
}

- (void)listenToAddButton:(SCUButton *)addButton minusButton:(SCUButton *)minusButton slider:(SCUSlider *)slider centerSlider:(SCUCenteredSlider *)centerSlider atIndexPath:(NSIndexPath *)indexPath
{
    centerSlider.callbackTimeInterval = 0.75;
    slider.callbackTimeInterval   = 0.75;
    
    SAVWeakSelf;
    
    [centerSlider setCallback:^(SCUSlider *slider){
        [wSelf handleSlider:slider forIndexPath:indexPath];
    }];
    
    [slider setCallback:^(SCUSlider *slider){
        [wSelf handleSlider:slider forIndexPath:indexPath];
    }];
    
    [addButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        // Easier to just send a decremented value
        slider.value += 1;
        centerSlider.value += 1;
        
        [wSelf sendCommandFromSliderAtIndexPath:indexPath withValue:slider.value];
        
        // Make UI changes to reflect the slider
        [wSelf.delegate updateSliderValueLabel:slider.value atIndexPath:indexPath];
    }];
    
    [minusButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        // Easier to just send a decremented value
        slider.value -= 1;
        centerSlider.value -= 1;
        
        [wSelf sendCommandFromSliderAtIndexPath:indexPath withValue:slider.value];
        
        // Make UI changes to reflect the slider
        [wSelf.delegate updateSliderValueLabel:slider.value atIndexPath:indexPath];
    }];
}

- (void)handleActionSheetSelectionAtIndex:(NSInteger)index withTitles:(NSArray *)titles forIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];
    NSArray *commands = [modelObject[SCUAVSettingsVideoActionSheetArray] valueForKey:SCUAVSettingsVideoActionSheetCommand];
    
    if (index != -1)
    {
        NSString *command = commands[index];
        NSString *title = titles[index];
        
        self.currentStates[modelObject[SCUAVSettingsModelState]] = title;
        
        [self sendCommand:command withArguments:nil];
        [self.delegate reloadIndexPath:indexPath];
    }
}

- (void)handleSlider:(SCUSlider *)slider forIndexPath:(NSIndexPath *)indexPath
{
    [self sendCommandFromSliderAtIndexPath:indexPath withValue:slider.value];
}

- (void)sendCommandFromSliderAtIndexPath:(NSIndexPath *)indexPath withValue:(float)value
{
    [self.delegate updateSliderValueLabel:value atIndexPath:indexPath];
    
    NSString *valueString = [NSString stringWithFormat:@"%.1f", value];
    switch (indexPath.row)
    {
        case 4:
            [self sendCommand:@"SetContrast" withArguments:@{@"ContrastValue": valueString}];
            break;
        case 5:
            [self sendCommand:@"SetBrightness" withArguments:@{@"BrightnessValue": valueString}];
            break;
        case 6:
            [self sendCommand:@"SetSaturation" withArguments:@{@"SaturationValue": valueString}];
            break;
        case 7:
            [self sendCommand:@"SetHue" withArguments:@{@"HueValue": valueString}];
            break;
        case 8:
            [self sendCommand:@"SetDetailEnhancementLevel" withArguments:@{@"DetailEnhancementLevelValue": valueString}];
            break;
        case 9:
            [self sendCommand:@"SetNoiseReduction" withArguments:@{@"NoiseReductionValue": valueString}];
            break;
        default:
            break;
    }
}

#pragma mark - SCUStateReceiver methods

- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    NSString *stateName = [stateUpdate stateName];

    self.currentStates[stateName] = stateUpdate.value;
    if ([stateName length])
    {
        SEL selector = NSSelectorFromString([self stateNamesToDelegateSelectors][stateName]);
        
        if ([self respondsToSelector:selector])
        {
            SAVFunctionForSelector(function, (id)self, selector, void, id);
            function(self, selector, stateUpdate.value);
        }
        else if ([self.delegate respondsToSelector:selector])
        {
            SAVFunctionForSelector(function, (id)self.delegate, selector, void, id);
            function(self.delegate, selector, stateUpdate.value);
        }
    }
}

#pragma mark -

- (NSArray *)statesToRegister
{
    return self.stateNames;
}

- (void)current3DDidUpdateWithValue:(NSString *)value
{
    SAVWeakSelf;
    [self.effectsTimer addWorkWithKey:@"3DTimer" work:^{
        [wSelf update3D:value];
    }];
}

- (void)currentAspectRatioDidUpdateWithValue:(NSString *)value
{
    SAVWeakSelf;
    [self.effectsTimer addWorkWithKey:@"aspectRatioTimer" work:^{
        [wSelf updateCurrentAspectRatioEffect:value];
    }];
}

- (void)update3D:(NSString *)value
{
    // TODO: How do you just turn off any changes?
    // Check which effect state is now active
    for (NSString *state in [[self statesFor3D] allKeys])
    {
        if ([self.currentStates[state] isEqualToString:@"1"])
        {
            self.currentStates[@"Current3D"] = [self statesFor3D][state];
            NSIndexPath *indexPath = [self indexPathFromStateName:@"Current3D"];
            [self.delegate reloadIndexPath:indexPath];
        }
    }
}

- (void)updateCurrentAspectRatioEffect:(NSString *)value
{
    // TODO: How do you just turn off any changes?
    // Check which effect state is now active
    for (NSString *state in [[self statesForAspectRatios] allKeys])
    {
        if ([self.currentStates[state] isEqualToString:@"1"])
        {
            self.currentStates[@"CurrentAspectRatio"] = [self statesForAspectRatios][state];
            NSIndexPath *indexPath = [self indexPathFromStateName:@"CurrentAspectRatio"];
            [self.delegate reloadIndexPath:indexPath];
        }
    }
}

// Values 0 and 1 are too common and possibly integer values, so
// we only want to scan through possible aspect ratio states
- (NSDictionary *)statesForAspectRatios
{
    return @{@"CurrentAspectRatioIsAnamorphic" : @"Anamorphic",
             @"CurrentAspectRatioIsPanoramic"  : @"Panoramic",
             @"CurrentAspectRatioIsPanoramicStretch" : @"Panoramic Stretch",
             @"CurrentAspectRatioIsPillarBox"  : @"Pillar Box",
             @"CurrentAspectRatioIsStretch"    : @"Stretch",
             @"CurrentAspectRatioIsVerticalStretch"  : @"Vertical Stretch",
             @"CurrentAspectRatioIsZoom"       : @"Zoom"};
}

// Values 0 and 1 are too common and possibly integer values, so
// we only want to scan through possible 3D states
- (NSDictionary *)statesFor3D
{
    return @{@"Current3DOff" : @"Off",
             @"Current3DSideBySide": @"Side by Side",
             @"Current3DTopBottom" : @"Top Bottom"};
}

/*
 * Anything that isn't receiving a state update here could be due to the stateNames.
 * These are all from a wiki: https://github.com/SavantSystems/Android-Software/wiki/Service-Info-SVC_SETTINGS_VIDEO
 */
- (NSDictionary *)stateNamesToDelegateSelectors
{
    return @{@"CurrentBrightness": NSStringFromSelector(@selector(currentBrightnessDidUpdateWithValue:)),
             @"CurrentContrast": NSStringFromSelector(@selector(currentContrastDidUpdateWithValue:)),
             @"CurrentDetailEnhancementLevel": NSStringFromSelector(@selector(currentDetailEnhancementDidUpdateWithValue:)),
             @"CurrentHue": NSStringFromSelector(@selector(currentHueDidUpdateWithValue:)),
             @"CurrentVideoInputFormat": NSStringFromSelector(@selector(currentInputVideoFormatDidUpdateWithValue:)),
             @"CurrentNoiseReduction": NSStringFromSelector(@selector(currentNoiseReductionDidUpdateWithValue:)),
             @"CurrentVideoOutputFormat": NSStringFromSelector(@selector(currentOutputVideoFormatDidUpdateWithValue:)),
             @"CurrentSaturation": NSStringFromSelector(@selector(currentSaturationDidUpdateWithValue:)),
             @"Current3DOff": NSStringFromSelector(@selector(current3DDidUpdateWithValue:)),
             @"Current3DSideBySide": NSStringFromSelector(@selector(current3DDidUpdateWithValue:)),
             @"Current3DTopBottom": NSStringFromSelector(@selector(current3DDidUpdateWithValue:)),
             @"CurrentAspectRatioIsAnamorphic": NSStringFromSelector(@selector(currentAspectRatioDidUpdateWithValue:)),
             @"CurrentAspectRatioIsPanoramic": NSStringFromSelector(@selector(currentAspectRatioDidUpdateWithValue:)),
             @"CurrentAspectRatioIsPanoramicStretch": NSStringFromSelector(@selector(currentAspectRatioDidUpdateWithValue:)),
             @"CurrentAspectRatioIsPillarBox": NSStringFromSelector(@selector(currentAspectRatioDidUpdateWithValue:)),
             @"CurrentAspectRatioIsStretch": NSStringFromSelector(@selector(currentAspectRatioDidUpdateWithValue:)),
             @"CurrentAspectRatioIsVerticalStretch": NSStringFromSelector(@selector(currentAspectRatioDidUpdateWithValue:)),
             @"CurrentAspectRatioIsZoom": NSStringFromSelector(@selector(currentAspectRatioDidUpdateWithValue:)) };
}

#pragma mark - SCUViewModel methods

- (void)viewDidAppear
{
    [super viewWillAppear];
}

- (void)sendCommand:(NSString *)command withArguments:(NSDictionary *)arguments
{
    NSArray *requests = [self.services arrayByMappingBlock:^id(SAVService *service) {
        SAVServiceRequest *request = [[SAVServiceRequest alloc] initWithService:service];
        request.request = command;
        request.requestArguments = arguments;
        return request;
    }];
    
    [[SavantControl sharedControl] sendMessages:requests];
}

@end
