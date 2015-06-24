//
//  SCUAVSettingsEqualizerModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 5/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVSettingsEqualizerModel.h"
#import "SCUAlertView.h"
#import "SCUTextEntryAlert.h"
#import "SCUAVSettingsEqualizerPresetModel.h"
#import "SCUStateReceiver.h"
#import "SCUAVSettingsEqualizerPresetModel.h"
#import "SCUAVSettingsEqualizerSendToModel.h"

#import <SavantExtensions/SavantExtensions.h>

@interface SCUAVSettingsEqualizerModel () <StateDelegate>

@property (nonatomic) SAVDISRequestGenerator *disRequestGenerator;
@property (nonatomic) SAVRoom *room;
@property (nonatomic) NSArray *states;

@property (nonatomic) NSString *amplitude1;
@property (nonatomic) NSString *frequency1;
@property (nonatomic) NSString *amplitude2;
@property (nonatomic) NSString *frequency2;
@property (nonatomic) NSString *amplitude3;
@property (nonatomic) NSString *frequency3;
@property (nonatomic) NSString *amplitude4;
@property (nonatomic) NSString *frequency4;
@property (nonatomic) NSString *amplitude5;
@property (nonatomic) NSString *frequency5;
@property (nonatomic) NSString *amplitude6;
@property (nonatomic) NSString *frequency6;
@property (nonatomic) NSString *amplitude7;
@property (nonatomic) NSString *frequency7;
@property (nonatomic) NSString *presetName;
@property (nonatomic, getter = isResetEnabled) BOOL resetEnabled;
@property (nonatomic, getter = isAddPresetEnabled) BOOL addPresetEnabled;
@property (nonatomic) NSDictionary *currentBands;
@property (nonatomic) NSString *currentPresetID;
@property (nonatomic) SCUAVSettingsEqualizerPresetModel *presetPickerModel;
@property (nonatomic, copy) NSDictionary *zoneMapping; /* { presetID -> #{zones} } */

@end

@implementation SCUAVSettingsEqualizerModel

- (void)dealloc
{
    [[SavantControl sharedControl] unregisterForStates:self.states forObserver:self];
}

- (instancetype)initWithRoom:(SAVRoom *)room
{
    self = [super init];

    if (self)
    {
        self.disRequestGenerator = [[SAVDISRequestGenerator alloc] initWithApp:@"equalizer"];
        self.room = room;
        self.states = [self.disRequestGenerator feedbackStringsWithStateNames:[[self stateNames] allKeys]];
        [[SavantControl sharedControl] registerForStates:self.states forObserver:self];
    }

    return self;
}

- (void)registerSlider:(SCUCenteredSlider *)slider withOrder:(NSUInteger)order
{
    slider.minimumValue = -12;
    slider.maximumValue = 12;
    slider.callbackTimeInterval = .3;

    SAVWeakSelf;
    slider.callback = ^(SCUSlider *slider) {
        NSString *key = [NSString stringWithFormat:@"%lu", (unsigned long)order];

        NSMutableDictionary *bandInfo = [wSelf.currentBands[key] mutableCopy];
        bandInfo[@"Amplitude"] = @(ceilf(slider.value));

        NSDictionary *arguments = @{@"PresetID": self.currentPresetID,
                                    @"Settings": @{@"Bands": @{key: bandInfo}},
                                    @"CurrentZone": self.room.roomId};

        SAVDISRequest *request = [wSelf.disRequestGenerator request:@"ApplyPreset"
                                                      withArguments:arguments];

        [[SavantControl sharedControl] sendMessage:request];
    };
}

- (void)resetCurrentPreset
{
    SCUAlertView *alertView = [[SCUAlertView alloc] initWithTitle:NSLocalizedString(@"Reset Preset", nil)
                                                          message:[NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to reset '%@' to its default state?", nil), self.presetName]
                                                     buttonTitles:@[NSLocalizedString(@"Cancel", nil), NSLocalizedString(@"Reset", nil)]];

    alertView.callback = ^(NSUInteger buttonIndex) {
        if (buttonIndex == 1)
        {
            SAVDISRequest *request = [self.disRequestGenerator request:@"ResetPreset"
                                                         withArguments:@{@"PresetID": self.currentPresetID}];

            [[SavantControl sharedControl] sendMessage:request];
        }
    };

    [alertView show];
}

- (void)addPreset
{
    SCUTextEntryAlert *alertView = [[SCUTextEntryAlert alloc] initWithTitle:NSLocalizedString(@"Create a Preset", nil)
                                                                    message:NSLocalizedString(@"Please enter a name for your new EQ preset", nil)
                                                              textEntryType:SCUTextEntryAlertFieldTypeDefault
                                                               buttonTitles:@[NSLocalizedString(@"Cancel", nil), NSLocalizedString(@"Create", nil)]];

    SAVWeakVar(alertView, sAlertView);
    alertView.callback = ^(NSUInteger buttonIndex) {
        if (buttonIndex == 1)
        {
            NSString *text = [sAlertView text];

            if ([text length] && [[text stringByReplacingOccurrencesOfString:@" " withString:@""] length])
            {
                SAVDISRequest *request = [self.disRequestGenerator request:@"CopyPreset"
                                                             withArguments:@{@"Label": text,
                                                                             @"PresetID": self.currentPresetID,
                                                                             @"Zone": self.room.roomId}];

                [[SavantControl sharedControl] sendMessage:request];
            }
        }
    };

    [alertView show];
}

- (void)pickPreset
{
    [self.delegate showPresetPickerWithModel:self.presetPickerModel];
}

- (void)sendTo
{
    [self.delegate showSendToWithModel:[self sendToModel]];
}

- (BOOL)isCurrentPresetIDAppliedInRoom:(SAVRoom *)room
{
    return [self.zoneMapping[self.currentPresetID] containsObject:room.roomId];
}

- (NSDictionary *)currentZonesToSendForPresetID:(NSString *)presetID room:(SAVRoom *)room isAddition:(BOOL)isAddition
{
    NSMutableDictionary *zonesToSend = [NSMutableDictionary dictionary];

    for (NSString *r in self.zoneMapping[presetID])
    {
        zonesToSend[r] = @[];
    }

    if (isAddition)
    {
        zonesToSend[room.roomId] = @[];
    }
    else
    {
        [zonesToSend removeObjectForKey:room.roomId];
    }

    return zonesToSend;
}

#pragma mark - SCUViewModel methods

- (void)viewDidAppear
{
    [super viewWillAppear];
    [self.delegate updateCurrentPreset];
}

#pragma mark - StateDelegate methods

- (void)didReceiveDISFeedback:(SAVDISFeedback *)feedback
{
    SEL selector = NSSelectorFromString([self stateNames][feedback.state]);
    SAVFunctionForSelector(function, self, selector, void, NSDictionary *);
    function(self, selector, feedback.value);
}

#pragma mark -

- (NSDictionary *)stateNames
{
    return @{[NSString stringWithFormat:@"%@.activePreset", self.room.roomId]: NSStringFromSelector(@selector(parseCurrentActivePreset:)),
             @"presetsList": NSStringFromSelector(@selector(parsePresetsList:)),
             @"activePresets": NSStringFromSelector(@selector(parsePresets:))};
}

- (void)parseCurrentActivePreset:(NSDictionary *)info
{
    self.presetName = info[@"Label"];
    self.resetEnabled = [info[@"Default"] boolValue];
    self.currentBands = info[@"Bands"];
    self.currentPresetID = info[@"id"];
    self.addPresetEnabled = [self.currentPresetID length] ? YES : NO;

    [self.currentBands enumerateKeysAndObjectsUsingBlock:^(NSString *band, NSDictionary *obj, BOOL *stop) {

        NSString *amp = [NSString stringWithFormat:@"%@ dB", obj[@"Amplitude"]];

        NSInteger frequency = [obj[@"Frequency"] integerValue];
        NSString *fre = nil;

        if (frequency % 1000 == 0)
        {
            fre = [NSString stringWithFormat:@"%.0fkHz", frequency / 1000.0];
        }
        else if (frequency >= 1000)
        {
            fre = [NSString stringWithFormat:@"%.1fkHz", frequency / 1000.0];
        }
        else
        {
            fre = [NSString stringWithFormat:@"%ldHz", (long)frequency];
        }

        switch ([band integerValue])
        {
            case 1:
                self.amplitude1 = amp;
                self.frequency1 = fre;
                break;
            case 2:
                self.amplitude2 = amp;
                self.frequency2 = fre;
                break;
            case 3:
                self.amplitude3 = amp;
                self.frequency3 = fre;
                break;
            case 4:
                self.amplitude4 = amp;
                self.frequency4 = fre;
                break;
            case 5:
                self.amplitude5 = amp;
                self.frequency5 = fre;
                break;
            case 6:
                self.amplitude6 = amp;
                self.frequency6 = fre;
                break;
            case 7:
                self.amplitude7 = amp;
                self.frequency7 = fre;
                break;
        }
    }];

    [self.delegate updateCurrentPreset];
}

- (void)parsePresetsList:(NSDictionary *)info
{
    NSArray *sortedPresets = [[info allValues] sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *preset1, NSDictionary *preset2) {
        NSString *label1 = preset1[@"Label"];
        NSString *label2 = preset2[@"Label"];
        return [label1 compare:label2 options:NSCaseInsensitiveNumericSearch];
    }];

    NSArray *defaultPresets = [sortedPresets filteredArrayUsingBlock:^BOOL(NSDictionary *preset) {
        return [preset[@"Default"] boolValue];
    }];

    NSArray *customPresets = [sortedPresets filteredArrayUsingBlock:^BOOL(NSDictionary *preset) {
        return ![preset[@"Default"] boolValue];
    }];

    self.presetPickerModel = [[SCUAVSettingsEqualizerPresetModel alloc] initWithDefaultPresets:defaultPresets
                                                                                 customPresets:customPresets
                                                                              requestGenerator:self.disRequestGenerator
                                                                                equalizerModel:self];

    [self.delegate updatePresetPickerModel:self.presetPickerModel];
}

- (void)parsePresets:(NSDictionary *)info
{
    NSMutableDictionary *zoneMapping = [NSMutableDictionary dictionary];

    [info enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *zones, BOOL *stop) {
        zoneMapping[key] = [NSSet setWithArray:[zones allKeys]];
    }];

    self.zoneMapping = zoneMapping;

    [self.delegate updateSentToModel:[self sendToModel]];
}

- (SCUAVSettingsEqualizerSendToModel *)sendToModel
{
    return [[SCUAVSettingsEqualizerSendToModel alloc] initWithDISRequestGenerator:self.disRequestGenerator equalizerModel:self];
}

@end
