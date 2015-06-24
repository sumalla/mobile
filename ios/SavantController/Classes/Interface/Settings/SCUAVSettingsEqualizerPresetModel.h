//
//  SCUAVSettingsEqualizerPresetTableViewModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 5/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"
#import <SavantControl/SavantControl.h>
@class SCUAVSettingsEqualizerModel;

typedef NS_ENUM(NSUInteger, SCUAVSettingsEqualizerPresetModelCellType)
{
    SCUAVSettingsEqualizerPresetModelCellTypeFixed,
    SCUAVSettingsEqualizerPresetModelCellTypeEditable
};

@protocol SCUAVSettingsEqualizerPresetModelDelegate;

@interface SCUAVSettingsEqualizerPresetModel : SCUDataSourceModel

@property (nonatomic, weak) id<SCUAVSettingsEqualizerPresetModelDelegate> delegate;

- (instancetype)initWithDefaultPresets:(NSArray *)defaultPresets
                         customPresets:(NSArray *)customPresets
                      requestGenerator:(SAVDISRequestGenerator *)disRequestGenerator
                        equalizerModel:(SCUAVSettingsEqualizerModel *)model;

- (NSArray *)swipeButtonsForIndexPath:(NSIndexPath *)indexPath;

@end

@protocol SCUAVSettingsEqualizerPresetModelDelegate <NSObject>

- (void)dismiss;

- (UITextField *)setEditing:(BOOL)editing forIndexPath:(NSIndexPath *)indexPath;

@end
