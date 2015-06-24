//
//  SCUAVSettingsEqualizerPresetTableViewModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 5/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVSettingsEqualizerPresetModel.h"
#import "SCUDataSourceModelPrivate.h"
#import "SCUDefaultTableViewCell.h"
#import "SCUAVSettingsEqualizerModel.h"
#import "SCUProgressTableViewCell.h"
#import "SCUTextFieldProgressTableViewCell.h"
#import "SCUTextFieldListener.h"
#import "SCUAlertView.h"

#import <SavantExtensions/SavantExtensions.h>

typedef NS_ENUM(NSUInteger, SCUAVSettingsEqualizerPresetTableViewModelType)
{
    SCUAVSettingsEqualizerPresetTableViewModelTypeDefault,
    SCUAVSettingsEqualizerPresetTableViewModelTypeCustom
};

static NSString *SCUAVSettingsEqualizerPresetTableViewModelKeyType = @"SCUAVSettingsEqualizerPresetTableViewModelKeyType";
static NSString *SCUAVSettingsEqualizerPresetTableViewModelKeyArray = @"SCUAVSettingsEqualizerPresetTableViewModelKeyArray";

@interface SCUAVSettingsEqualizerPresetModel () <SCUTextFieldListenerDelegate>

@property (nonatomic) NSArray *defaultPresets;
@property (nonatomic) NSArray *customPresets;
@property (nonatomic) SAVDISRequestGenerator *disRequestGenerator;
@property (nonatomic) NSArray *dataSource;
@property (nonatomic, weak) SCUAVSettingsEqualizerModel *equalizerModel;
@property (nonatomic) SCUTextFieldListener *textFieldListener;
@property (nonatomic) NSIndexPath *renamingIndexPath;

@end

@implementation SCUAVSettingsEqualizerPresetModel

- (instancetype)initWithDefaultPresets:(NSArray *)defaultPresets
                         customPresets:(NSArray *)customPresets
                      requestGenerator:(SAVDISRequestGenerator *)disRequestGenerator
                        equalizerModel:(SCUAVSettingsEqualizerModel *)model
{
    self = [super init];

    if (self)
    {
        self.equalizerModel = model;
        self.defaultPresets = [self parsePresetArray:defaultPresets];;
        self.customPresets = [self parsePresetArray:customPresets];
        self.disRequestGenerator = disRequestGenerator;

        NSMutableArray *presets = [NSMutableArray array];

        if ([self.customPresets count])
        {
            [presets addObject:@{SCUAVSettingsEqualizerPresetTableViewModelKeyType: @(SCUAVSettingsEqualizerPresetTableViewModelTypeCustom),
                                 SCUAVSettingsEqualizerPresetTableViewModelKeyArray: self.customPresets}];
        }

        if ([self.defaultPresets count])
        {
            [presets addObject:@{SCUAVSettingsEqualizerPresetTableViewModelKeyType: @(SCUAVSettingsEqualizerPresetTableViewModelTypeDefault),
                                 SCUAVSettingsEqualizerPresetTableViewModelKeyArray: self.defaultPresets}];
        }

        self.dataSource = presets;

        self.textFieldListener = [[SCUTextFieldListener alloc] init];
        self.textFieldListener.delegate = self;
    }

    return self;
}

- (NSArray *)swipeButtonsForIndexPath:(NSIndexPath *)indexPath
{
    NSArray *views = nil;

    if ([self cellTypeForIndexPath:indexPath] == SCUAVSettingsEqualizerPresetModelCellTypeEditable)
    {
        views = @[[SCUSwipeCell buttonViewWithTitle:NSLocalizedString(@"Delete", nil) font:nil color:[[SCUColors shared] color04] backgroundColor:[UIColor redColor]],
                  [SCUSwipeCell buttonViewWithTitle:NSLocalizedString(@"Rename", nil) font:nil color:[[SCUColors shared] color04] backgroundColor:[UIColor lightGrayColor]]];
    }

    return views;
}

#pragma mark - Overrides

- (BOOL)isFlat
{
    return NO;
}

- (NSArray *)arrayForSection:(NSInteger)section
{
    return self.dataSource[section][SCUAVSettingsEqualizerPresetTableViewModelKeyArray];
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    SCUAVSettingsEqualizerPresetTableViewModelType modelType = (SCUAVSettingsEqualizerPresetTableViewModelType)[self.dataSource[indexPath.section][SCUAVSettingsEqualizerPresetTableViewModelKeyType] unsignedIntegerValue];

    SCUAVSettingsEqualizerPresetModelCellType cellType = SCUAVSettingsEqualizerPresetModelCellTypeFixed;

    switch (modelType)
    {
        case SCUAVSettingsEqualizerPresetTableViewModelTypeDefault:
            cellType = SCUAVSettingsEqualizerPresetModelCellTypeFixed;
            break;
        case SCUAVSettingsEqualizerPresetTableViewModelTypeCustom:
            cellType = SCUAVSettingsEqualizerPresetModelCellTypeEditable;
            break;
    }

    return cellType;
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;

    SCUAVSettingsEqualizerPresetTableViewModelType type = (SCUAVSettingsEqualizerPresetTableViewModelType)[self.dataSource[section][SCUAVSettingsEqualizerPresetTableViewModelKeyType] unsignedIntegerValue];

    switch (type)
    {
        case SCUAVSettingsEqualizerPresetTableViewModelTypeDefault:
            title = NSLocalizedString(@"System Presets", nil);
            break;
        case SCUAVSettingsEqualizerPresetTableViewModelTypeCustom:
            title = NSLocalizedString(@"Custom Presets", nil);
            break;
    }

    return title;
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [super modelObjectForIndexPath:indexPath];

    if ([modelObject[@"id"] isEqualToString:self.equalizerModel.currentPresetID])
    {
        NSMutableDictionary *mModelObject = [modelObject mutableCopy];
        mModelObject[SCUProgressTableViewCellKeyAccessoryType] = @(SCUProgressTableViewCellAccessoryTypeCheckmark);
        modelObject = [mModelObject copy];
    }

    return modelObject;
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];
    NSString *presetID = modelObject[@"id"];

    NSDictionary *zones = [self.equalizerModel currentZonesToSendForPresetID:presetID
                                                                        room:self.equalizerModel.room
                                                                  isAddition:YES];

    SAVDISRequest *request = [self.disRequestGenerator request:@"ApplyPreset" withArguments:@{@"PresetID": presetID,
                                                                                              @"Settings": @{@"Zones": zones}}];

    [[SavantControl sharedControl] sendMessage:request];

    [self.delegate dismiss];
}

- (BOOL)shouldAllowSwipingForIndexPath:(NSIndexPath *)indexPath
{
    BOOL allow = YES;

    if (self.renamingIndexPath)
    {
        allow = NO;
    }

    return allow;
}

- (void)buttonWasTappedAtIndex:(NSUInteger)index atIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];

    NSString *presetName = modelObject[SCUDefaultTableViewCellKeyTitle];
    NSString *presetID = modelObject[@"id"];

    if (index == 0)
    {
        //-------------------------------------------------------------------
        // Handle delete
        //-------------------------------------------------------------------
        SCUAlertView *alertView = [[SCUAlertView alloc] initWithTitle:NSLocalizedString(@"Delete Preset", nil)
                                                              message:[NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to delete the '%@' preset?", nil), presetName]
                                                         buttonTitles:@[NSLocalizedString(@"Cancel", nil), NSLocalizedString(@"Delete", nil)]];

        alertView.callback = ^(NSUInteger i) {
            if (i == 1)
            {
                SAVDISRequest *request = [self.disRequestGenerator request:@"RemovePreset" withArguments:@{@"PresetID": presetID}];
                [[SavantControl sharedControl] sendMessage:request];
            }
        };

        [alertView show];
    }
    else
    {
        //-------------------------------------------------------------------
        // Handle rename
        //-------------------------------------------------------------------
        self.renamingIndexPath = indexPath;
        UITextField *textField = [self.delegate setEditing:YES forIndexPath:indexPath];
        [self.textFieldListener listenToTextField:textField withTag:indexPath.row];
    }
}

#pragma mark - SCUTextFieldListenerDelegate methods

- (void)textFieldListener:(SCUTextFieldListener *)listener textFieldDidReturnWithTag:(NSInteger)tag finalText:(NSString *)text
{
    NSString *trimmedText = [text stringByReplacingOccurrencesOfString:@" " withString:@""];

    if ([trimmedText length])
    {
        NSDictionary *modelObject = [self modelObjectForIndexPath:self.renamingIndexPath];
        NSString *presetID = modelObject[@"id"];
        SAVDISRequest *request = [self.disRequestGenerator request:@"RenamePresets" withArguments:@{presetID: text}];
        [[SavantControl sharedControl] sendMessage:request];
    }
}

- (void)textFieldListener:(SCUTextFieldListener *)listener textFieldDidEndEditingWithTag:(NSInteger)tag
{
    [self.delegate setEditing:NO forIndexPath:self.renamingIndexPath];
    self.renamingIndexPath = nil;
}

#pragma mark -

- (NSArray *)parsePresetArray:(NSArray *)presetArray
{
    return [presetArray arrayByMappingBlock:^id(NSDictionary *preset) {
        NSString *label = preset[@"Label"];
        NSMutableDictionary *mPreset = [preset mutableCopy];
        mPreset[SCUDefaultTableViewCellKeyTitle] = label;
        mPreset[SCUTextFieldProgressTableViewCellKeyEditableText] = label;
        mPreset[SCUTextFieldProgressTableViewCellKeyPlaceholderText] = label;
        return [mPreset copy];
    }];
}

@end
