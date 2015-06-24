//
//  SCUAVSettingsEqualizerSendToModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 5/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVSettingsEqualizerSendToModel.h"
#import "SCUAVSettingsEqualizerModel.h"
#import "SCUProgressTableViewCell.h"
#import "SCUAVSettingsRoomGroupTableModelPrivate.h"

#import <SavantExtensions/SavantExtensions.h>

@interface SCUAVSettingsEqualizerSendToModel ()

@property (nonatomic) SAVDISRequestGenerator *disRequestGenerator;

@property (nonatomic) SCUAVSettingsEqualizerModel *equalizerModel;

@end

@implementation SCUAVSettingsEqualizerSendToModel

- (instancetype)initWithDISRequestGenerator:(SAVDISRequestGenerator *)disRequestGenerator equalizerModel:(SCUAVSettingsEqualizerModel *)equalizerModel
{
    self = [super init];

    if (self)
    {
        self.disRequestGenerator = disRequestGenerator;
        self.equalizerModel = equalizerModel;

        [self parseRoomGroupsAndFilter:self.equalizerModel.room];
    }

    return self;
}

#pragma mark - Overrides

- (NSString *)title
{
    return self.equalizerModel.presetName;
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [super modelObjectForIndexPath:indexPath];
    SAVRoom *room = modelObject[SCUDefaultTableViewCellKeyModelObject];

    if ([self.equalizerModel isCurrentPresetIDAppliedInRoom:room])
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
    SAVRoom *room = modelObject[SCUDefaultTableViewCellKeyModelObject];

    BOOL isAddition = YES;

    if ([self.equalizerModel isCurrentPresetIDAppliedInRoom:room])
    {
        isAddition = NO;
    }

    NSDictionary *zones = [self.equalizerModel currentZonesToSendForPresetID:self.equalizerModel.currentPresetID
                                                                        room:room
                                                                  isAddition:isAddition];

    SAVDISRequest *request = [self.disRequestGenerator request:@"ApplyPreset" withArguments:@{@"PresetID": self.equalizerModel.currentPresetID,
                                                                                              @"Settings": @{@"Zones": zones}}];

    [[SavantControl sharedControl] sendMessage:request];
}

@end
