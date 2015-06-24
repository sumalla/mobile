//
//  SCUAVAudioSettingsModel.m
//  SavantController
//
//  Created by Stephen Silber on 7/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVSettingsAudioModel.h"
#import "SCUAVSettingsAudioModelPrivate.h"
#import "SCUDefaultTableViewCell.h"
#import "SCUAVSettingsSliderButtonCell.h"
#import "SCUAVSettingsButtonCell.h"
#import "SCUAVSettingsStepperCell.h"
#import "SCUAVSettingsRightInfoCell.h"
#import "SCUActionSheet.h"
#import "SCUStepper.h"
#import "SCUButton.h"
#import <SavantExtensions/SAVUIKitExtensions.h>

// Allows SWITCH on an NSString --> Will refactor this later
#define CASE(str)                       if ([__s__ isEqualToString:(str)])
#define SWITCH(s)                       for (NSString *__s__ = (s); ; )
#define DEFAULT

static NSString *SCUAVSettingsModelKeyType            = @"SCUAVSettingsModelKeyType";
static NSString *SCUAVSettingsModelState              = @"SCUAVSettingsModelState";
static NSString *SCUAVSettingsModelValueKey           = @"SCUAVSettingsModelValueKey";
static NSString *SCUAVSettingsAudioActionSheetArray   = @"SCUAVSettingsAudioActionSheetArray";
static NSString *SCUAVSettingsAudioActionSheetTitle   = @"SCUAVSettingsAudioActionSheetTitle";
static NSString *SCUAVSettingsAudioActionSheetCommand = @"SCUAVSettingsAudioActionSheetCommand";

@interface SCUAVSettingsAudioModel () <StateDelegate, SCUStepperDelegate>

@property (nonatomic) SAVDISRequestGenerator *disRequestGenerator;
@property (nonatomic) SAVRoom *room;
@property (nonatomic) NSArray *states;
@property (nonatomic) NSArray *stereoServices;
@property (nonatomic) NSArray *surroundServices;
@property (nonatomic) NSMutableDictionary *currentStates;
@property (nonatomic) NSArray *stateNames;
@property (nonatomic) NSDictionary *statesToIndexPath;
@property (nonatomic) NSDictionary *indexPathToStates;
@property (nonatomic) SAVCoalescedTimer *effectsTimer;

@end

@implementation SCUAVSettingsAudioModel

- (void)dealloc
{
    [[SavantControl sharedControl] unregisterForStates:self.states forObserver:self];
}

- (instancetype)initWithStereoServices:(NSArray *)stereoServices surroundServices:(NSArray *)surroundServices
{
    self = [super init];
    
    if (self)
    {
        self.effectsTimer = [[SAVCoalescedTimer alloc] init];
        self.effectsTimer.timeInverval = 1;
        
        self.stereoServices = stereoServices;
        self.surroundServices = surroundServices;
        
        if ([self.stereoServices count])
        {
            SAVService *service = self.stereoServices.firstObject;
            self.stateNames = [[[self stateNamesToDelegateSelectors] allKeys] arrayByMappingBlock:^id(NSString *stateName) {
                return [NSString stringWithFormat:@"%@.%@.%@", service.component, service.logicalComponent, stateName];
            }];
        }

        self.currentStates = [NSMutableDictionary dictionaryWithCapacity:[self.stateNames count]];
        
        self.dataSource = @[@{SCUAVSettingsSliderButtonCellKeyTopTitle: NSLocalizedString(@"Volume:", nil),
                              SCUAVSettingsModelValueKey : SCUAVSettingsSliderButtonCellSliderValue,
                              SCUAVSettingsModelKeyType: @(SCUAVSettingsAudioCellTypeSlider),
                              SCUAVSettingsSliderButtonCellSliderType: @(SCUAVSettingsSliderTypeNormal),
                              SCUAVSettingsModelState : @"CurrentVolume",
                              SCUAVSettingsSliderCellValueRange: @{@"min": @(0.0), @"max" : @(100.0)}},
                            
                            @{SCUAVSettingsModelKeyType: @(SCUAVSettingsAudioCellTypeButtonSelect),
                              SCUAVSettingsModelValueKey : SCUAVSettingsCellValueLabel,
                              SCUAVSettingsCellValueLabel: NSLocalizedString(@"Default", nil),
                              SCUAVSettingsModelState : @"CurrentEffect",
                              SCUAVSettingsAudioActionSheetArray: @[@{SCUAVSettingsAudioActionSheetTitle: NSLocalizedString(@"Catherdral 1", nil),
                                                                      SCUAVSettingsAudioActionSheetCommand: @"SetEffectsModeCatherdral1"},
                                                                    @{SCUAVSettingsAudioActionSheetTitle: NSLocalizedString(@"Club 1", nil),
                                                                      SCUAVSettingsAudioActionSheetCommand: @"SetEffectsModeClub1"},
                                                                    @{SCUAVSettingsAudioActionSheetTitle: NSLocalizedString(@"Club 2", nil),
                                                                      SCUAVSettingsAudioActionSheetCommand: @"SetEffectsModeClub2"},
                                                                    @{SCUAVSettingsAudioActionSheetTitle: NSLocalizedString(@"Club 3", nil),
                                                                      SCUAVSettingsAudioActionSheetCommand: @"SetEffectsModeClub3"},
                                                                    @{SCUAVSettingsAudioActionSheetTitle: NSLocalizedString(@"Club 4", nil),
                                                                      SCUAVSettingsAudioActionSheetCommand: @"SetEffectsModeClub4"},
                                                                    @{SCUAVSettingsAudioActionSheetTitle: NSLocalizedString(@"Club 5", nil),
                                                                      SCUAVSettingsAudioActionSheetCommand: @"SetEffectsModeClub5"},
                                                                    @{SCUAVSettingsAudioActionSheetTitle: NSLocalizedString(@"Hall 1", nil),
                                                                      SCUAVSettingsAudioActionSheetCommand: @"SetEffectsModeHall1"},
                                                                    @{SCUAVSettingsAudioActionSheetTitle: NSLocalizedString(@"Hall 2", nil),
                                                                      SCUAVSettingsAudioActionSheetCommand: @"SetEffectsModeHall1"},
                                                                    @{SCUAVSettingsAudioActionSheetTitle: NSLocalizedString(@"Hall 3", nil),
                                                                      SCUAVSettingsAudioActionSheetCommand: @"SetEffectsModeHall2"},
                                                                    @{SCUAVSettingsAudioActionSheetTitle: NSLocalizedString(@"Hall 4", nil),
                                                                      SCUAVSettingsAudioActionSheetCommand: @"SetEffectsModeHall3"},
                                                                    @{SCUAVSettingsAudioActionSheetTitle: NSLocalizedString(@"Hall 5", nil),
                                                                      SCUAVSettingsAudioActionSheetCommand: @"SetEffectsModeHall4"},
                                                                    @{SCUAVSettingsAudioActionSheetTitle: NSLocalizedString(@"Room 1", nil),
                                                                      SCUAVSettingsAudioActionSheetCommand: @"SetEffectsModeRoom1"},
                                                                    @{SCUAVSettingsAudioActionSheetTitle: NSLocalizedString(@"Stadium 1", nil),
                                                                      SCUAVSettingsAudioActionSheetCommand: @"SetEffectsModeStadium1"},
                                                                    @{SCUAVSettingsAudioActionSheetTitle: NSLocalizedString(@"Stadium 2", nil),
                                                                      SCUAVSettingsAudioActionSheetCommand: @"SetEffectsModeStadium2"},
                                                                    @{SCUAVSettingsAudioActionSheetTitle: NSLocalizedString(@"Stadium 3", nil),
                                                                      SCUAVSettingsAudioActionSheetCommand: @"SetEffectsModeStadium3"},
                                                                    @{SCUAVSettingsAudioActionSheetTitle: NSLocalizedString(@"Stadium 4", nil),
                                                                      SCUAVSettingsAudioActionSheetCommand: @"SetEffectsModeStadium4"},
                                                                    @{SCUAVSettingsAudioActionSheetTitle: NSLocalizedString(@"Theater 1", nil),
                                                                      SCUAVSettingsAudioActionSheetCommand: @"SetEffectsModeTheater1"},
                                                                    @{SCUAVSettingsAudioActionSheetTitle: NSLocalizedString(@"Theater 2", nil),
                                                                      SCUAVSettingsAudioActionSheetCommand: @"SetEffectsModeTheater2"},
                                                                    @{SCUAVSettingsAudioActionSheetTitle: NSLocalizedString(@"None", nil),
                                                                      SCUAVSettingsAudioActionSheetCommand: @"SetEffectsModeNone"}]},

                            @{SCUAVSettingsSliderButtonCellKeyTopTitle: NSLocalizedString(@"Effect", nil),
                              SCUAVSettingsModelValueKey : SCUAVSettingsSliderButtonCellSliderValue,
                              SCUAVSettingsModelKeyType: @(SCUAVSettingsAudioCellTypeSlider),
                              SCUAVSettingsSliderButtonCellKeyBottomTitle: @"Default",
                              SCUAVSettingsSliderButtonCellSliderType: @(SCUAVSettingsSliderTypeCenter),
                              SCUAVSettingsModelState : @"CurrentEffect",
                              SCUAVSettingsSliderCellValueRange: @{@"min": @(-10.0), @"max" : @(10.0)}},
                            
                            @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Bass:", nil),
                              SCUAVSettingsModelValueKey : SCUAVSettingsCellValueLabel,
                              SCUAVSettingsModelKeyType: @(SCUAVSettingsAudioCellTypeStepper),
                              SCUAVSettingsCellValueLabel: NSLocalizedString(@"0", nil),
                              SCUAVSettingsModelState : @"CurrentBass",
                              SCUAVSettingsStepperCellValueRange: @{@"min": @(-6.0), @"max" : @(6.0)}},
                            
                            @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Treble:", nil),
                              SCUAVSettingsModelValueKey : SCUAVSettingsCellValueLabel,
                              SCUAVSettingsModelKeyType: @(SCUAVSettingsAudioCellTypeStepper),
                              SCUAVSettingsCellValueLabel: NSLocalizedString(@"0", nil),
                              SCUAVSettingsModelState : @"CurrentTreble",
                              SCUAVSettingsStepperCellValueRange: @{@"min": @(-6.0), @"max" : @(6.0)}},
                            
                            @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Balance:", nil),
                              SCUAVSettingsModelValueKey : SCUAVSettingsCellValueLabel,
                              SCUAVSettingsModelKeyType: @(SCUAVSettingsAudioCellTypeStepper),
                              SCUAVSettingsCellValueLabel: NSLocalizedString(@"0", nil),
                              SCUAVSettingsStepperCellTextArray: @[@"L", @"R"],
                              SCUAVSettingsStepperCellButtonSize: @"20",
                              SCUAVSettingsStepperCellFormattedValue: @(YES),
                              SCUAVSettingsModelState : @"CurrentBalance",
                              SCUAVSettingsStepperCellValueRange: @{@"min": @(-10.0), @"max" : @(10.0)} }];
        
        self.currentStates = [NSMutableDictionary dictionaryWithCapacity:[self.stateNames count]];

        // Commend this block out to test surround sound services
        if (![self.surroundServices count])
        {
            NSMutableArray *temporaryDataSource = [self.dataSource mutableCopy];
            [temporaryDataSource removeObjectsInRange:NSRangeFromString(@"{1,2}")];
            self.dataSource = [temporaryDataSource copy];
        }
        
        [[SavantControl sharedControl] registerForStates:self.states forObserver:self];
    }
    
    return self;
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *modelObject = [self.dataSource[indexPath.row] mutableCopy];

    if (self.currentStates[modelObject[SCUAVSettingsModelState]])
    {
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
    
    SCUAVSettingsAudioCellType type = [modelObject[SCUAVSettingsModelKeyType] unsignedIntegerValue];
    self.type = type;
    if (self.type == SCUAVSettingsAudioCellTypeButtonSelect)
    {
        NSArray *titles = [modelObject[SCUAVSettingsAudioActionSheetArray] valueForKey:SCUAVSettingsAudioActionSheetTitle];
        SAVWeakSelf;
        [self.delegate presentActionSheetFromIndexPath:indexPath withTitles:titles callback:^(NSInteger buttonIndex) {
            [wSelf handleActionSheetSelectionAtIndex:buttonIndex withTitles:titles forIndexPath:indexPath];
        }];
    }
}

- (void)handleActionSheetSelectionAtIndex:(NSInteger)index withTitles:(NSArray *)titles forIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];
    NSArray *commands = [modelObject[SCUAVSettingsAudioActionSheetArray] valueForKey:SCUAVSettingsAudioActionSheetCommand];
    
    if (index != -1)
    {
        NSString *command = commands[index];
        NSString *title = titles[index];

        self.currentStates[@"CurrentEffect"] = title;

        [self sendCommand:command withArguments:nil];
        [self.delegate reloadIndexPath:indexPath];
    }
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    return [[self modelObjectForIndexPath:indexPath][SCUAVSettingsModelKeyType] unsignedIntegerValue];
}

- (void)listenToStepper:(SCUStepper *)stepper atIndexPath:(NSIndexPath *)indexPath
{
    stepper.delegate = self;

    SAVWeakSelf;
    [stepper setCallback:^(SCUStepper *stepper){
        [wSelf handleStepper:stepper forIndexPath:indexPath];
    }];
}

- (void)listenToDefaultButton:(SCUButton *)defaultButton atIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];

    SAVWeakSelf;
    [defaultButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        [wSelf sendDefaultCommandFromStateName:modelObject[SCUAVSettingsModelState] atIndexPath:indexPath];
    }];
}

- (void)listenToAddButton:(SCUButton *)addButton minusButton:(SCUButton *)minusButton slider:(SCUSlider *)slider centerSlider:(SCUCenteredSlider *)centerSlider atIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];
    
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
        
        [wSelf sendCommandFromStateName:modelObject[SCUAVSettingsModelState] withValue:slider.value];
        
        // Make UI changes to reflect the slider
        [wSelf.delegate updateSliderValueLabel:slider.value atIndexPath:indexPath];
    }];

    [minusButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        // Easier to just send a decremented value
        slider.value -= 1;
        centerSlider.value -= 1;
        
        [wSelf sendCommandFromStateName:modelObject[SCUAVSettingsModelState] withValue:slider.value];
        
        // Make UI changes to reflect the slider
        [wSelf.delegate updateSliderValueLabel:slider.value atIndexPath:indexPath];
    }];
}

- (void)handleStepper:(SCUStepper *)stepper forIndexPath:(NSIndexPath *)indexPath
{
    [self sendCommandFromStateName:self.dataSource[indexPath.row][SCUAVSettingsModelState] withValue:stepper.value];
}

- (void)handleSlider:(SCUSlider *)slider forIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate updateSliderValueLabel:slider.value atIndexPath:indexPath];
    [self sendCommandFromStateName:self.dataSource[indexPath.row][SCUAVSettingsModelState] withValue:slider.value];
}

- (void)sendDefaultCommandFromStateName:(NSString *)stateName atIndexPath:(NSIndexPath *)indexPath
{
    SWITCH(stateName)
    {
        CASE (@"CurrentEffect")
        {
            [self sendCommand:@"SetEffectsModeNone"];
            break;
        }
        CASE (@"CurrentBass")
        {
            [self sendCommand:@"SetBass" withArguments:@{@"BassValue": @"0"}];
            self.currentStates[stateName] = @(0);
            break;
        }
        CASE (@"CurrentTreble")
        {
            [self sendCommand:@"SetTreble" withArguments:@{@"TrebleValue": @"0"}];
            self.currentStates[stateName] = @(0);
            break;
        }
        CASE (@"CurrentBalance")
        {
            [self sendCommand:@"SetBalance" withArguments:@{@"BalanceBias": @"0"}];
            self.currentStates[stateName] = @(0);
            break;
        }
        DEFAULT
        {
            break;
        }
    }
}

- (void)sendCommandFromStateName:(NSString *)stateName withValue:(float)value
{
    NSString *valueString = [NSString stringWithFormat:@"%.0f", value];
    SWITCH(stateName)
    {
        CASE (@"CurrentVolume")
        {
            [self sendCommand:@"SetVolume" withArguments:@{@"VolumeValue": valueString}];
            break;
        }
        CASE (@"CurrentEffects")
        {
            [self sendCommand:@"SetEffectsLevel" withArguments:@{@"EffectsValue": valueString}];
        }
        CASE (@"CurrentBass")
        {
            [self sendCommand:@"SetBass" withArguments:@{@"BassValue": valueString}];
            break;
        }
        CASE (@"CurrentTreble")
        {
            [self sendCommand:@"SetTreble" withArguments:@{@"TrebleValue": valueString}];
            break;
        }
        CASE (@"CurrentBalance")
        {
            [self sendCommand:@"SetBalance" withArguments:@{@"BalanceBias": valueString}];
            break;
        }
        DEFAULT
        {
            break;
        }
    }
}

- (NSIndexPath *)indexPathFromStateName:(NSString *)stateName
{
    NSInteger index = 0;
    for (NSDictionary *modelObject in self.dataSource)
    {
        if ([modelObject[SCUAVSettingsModelState] isEqualToString:stateName])
        {
            return [NSIndexPath indexPathForRow:index inSection:0];
        }
        
        index++;
    }
    
    return nil;
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

- (void)currentAudioEffectDidUpdateWithValue:(NSString *)value
{
    SAVWeakSelf;
    [self.effectsTimer addWorkWithKey:@"effectsTimer" work:^{
        [wSelf updateCurrentAudioEffect:value];
    }];
}

- (void)updateCurrentAudioEffect:(NSString *)value
{
    // TODO: How do you just turn off any changes?
    // Check which effect state is now active
    for (NSString *state in [[self statesForAudioEffects] allKeys])
    {
        if ([self.currentStates[state] isEqualToString:@"1"])
        {
            self.currentStates[@"CurrentEffect"] = [self statesForAudioEffects][state];
            NSIndexPath *indexPath = [self indexPathFromStateName:@"CurrentEffect"];
            [self.delegate reloadIndexPath:indexPath];
        }
    }
}

// Values 0 and 1 are too common and possibly integer values, so
// we only want to scan through possible aspect ratio states
- (NSDictionary *)statesForAudioEffects
{
    return @{@"AudioEffectsModeIsCathedral1" : @"Cathedral 1",
             @"AudioEffectsModeIsClub1"  : @"Club 1",
             @"AudioEffectsModeIsClub2"  : @"Club 2",
             @"AudioEffectsModeIsClub3"  : @"Club 3",
             @"AudioEffectsModeIsClub4"  : @"Club 4",
             @"AudioEffectsModeIsClub5"  : @"Club 5",
             @"AudioEffectsModeIsHall1" : @"Hall 1",
             @"AudioEffectsModeIsHall2" : @"Hall 2",
             @"AudioEffectsModeIsHall3" : @"Hall 3",
             @"AudioEffectsModeIsHall4" : @"Hall 4",
             @"AudioEffectsModeIsHall5" : @"Hall 5",
             @"AudioEffectsModeIsRoom1"  : @"Room 1",
             @"AudioEffectsModeIsStadium1"    : @"Stadium 1",
             @"AudioEffectsModeIsStadium2"    : @"Stadium 2",
             @"AudioEffectsModeIsStadium3"    : @"Stadium 3",
             @"AudioEffectsModeIsStadium4"    : @"Stadium 4",
             @"AudioEffectsModeIsTheater1"  : @"Theater 1",
             @"AudioEffectsModeIsTheater2"  : @"Theater 2"};
}

- (NSDictionary *)stateNamesToDelegateSelectors
{
    return @{@"CurrentVolume": NSStringFromSelector(@selector(currentVolumeDidUpdateWithValue:)),
             @"CurrentBass": NSStringFromSelector(@selector(currentBassDidUpdateWithValue:)),
             @"CurrentTreble": NSStringFromSelector(@selector(currentTrebleDidUpdateWithValue:)),
             @"CurrentBalance": NSStringFromSelector(@selector(currentBalanceDidUpdateWithValue:)),
             @"AudioEffectsModeIsCathedral1": NSStringFromSelector(@selector(currentAudioEffectDidUpdateWithValue:)),
             @"AudioEffectsModeIsClub1": NSStringFromSelector(@selector(currentAudioEffectDidUpdateWithValue:)),
             @"AudioEffectsModeIsClub2": NSStringFromSelector(@selector(currentAudioEffectDidUpdateWithValue:)),
             @"AudioEffectsModeIsClub3": NSStringFromSelector(@selector(currentAudioEffectDidUpdateWithValue:)),
             @"AudioEffectsModeIsClub4": NSStringFromSelector(@selector(currentAudioEffectDidUpdateWithValue:)),
             @"AudioEffectsModeIsClub5": NSStringFromSelector(@selector(currentAudioEffectDidUpdateWithValue:)),
             @"AudioEffectsModeIsHall1": NSStringFromSelector(@selector(currentAudioEffectDidUpdateWithValue:)),
             @"AudioEffectsModeIsHall2": NSStringFromSelector(@selector(currentAudioEffectDidUpdateWithValue:)),
             @"AudioEffectsModeIsHall3": NSStringFromSelector(@selector(currentAudioEffectDidUpdateWithValue:)),
             @"AudioEffectsModeIsHall4": NSStringFromSelector(@selector(currentAudioEffectDidUpdateWithValue:)),
             @"AudioEffectsModeIsHall5": NSStringFromSelector(@selector(currentAudioEffectDidUpdateWithValue:)),
             @"AudioEffectsModeIsRoom1": NSStringFromSelector(@selector(currentAudioEffectDidUpdateWithValue:)),
             @"AudioEffectsModeIsStadium1": NSStringFromSelector(@selector(currentAudioEffectDidUpdateWithValue:)),
             @"AudioEffectsModeIsStadium2": NSStringFromSelector(@selector(currentAudioEffectDidUpdateWithValue:)),
             @"AudioEffectsModeIsStadium3": NSStringFromSelector(@selector(currentAudioEffectDidUpdateWithValue:)),
             @"AudioEffectsModeIsStadium4": NSStringFromSelector(@selector(currentAudioEffectDidUpdateWithValue:)),
             @"AudioEffectsModeIsTheater1": NSStringFromSelector(@selector(currentAudioEffectDidUpdateWithValue:)),
             @"AudioEffectsModeIsTheater2": NSStringFromSelector(@selector(currentAudioEffectDidUpdateWithValue:)),
             @"IsMuted": NSStringFromSelector(@selector(isMutedDidUpdateWithValue:)),
             @"CurrentAudioEffectsLevel": NSStringFromSelector(@selector(currentAudioEffectsLevelDidUpdateWithValue:)),
             };
}

#pragma mark - SCUViewModel methods

- (void)viewDidAppear
{
    [super viewWillAppear];
}

- (void)sendCommand:(NSString *)command withArguments:(NSDictionary *)arguments
{
    NSArray *services = [self.stereoServices arrayByAddingObjectsFromArray:self.surroundServices];
    NSArray *requests = [services arrayByMappingBlock:^id(SAVService *service) {
        SAVServiceRequest *request = [[SAVServiceRequest alloc] initWithService:service];
        request.request = command;
        request.requestArguments = arguments;
        return request;
    }];
    
    [[SavantControl sharedControl] sendMessages:requests];
}

@end
