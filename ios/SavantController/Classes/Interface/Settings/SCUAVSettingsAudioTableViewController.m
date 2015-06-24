//
//  SCUAVAudioSettingsViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/30/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUStepper.h"
#import "SCUAVSettingsVideoModel.h"
#import "SCUAVSettingsSelectCell.h"
#import "SCUAVSettingsSliderButtonCell.h"
#import "SCUAVSettingsStepperCell.h"
#import "SCUAVSettingsButtonCell.h"
#import "SCUAVSettingsAudioTableViewController.h"
#import "SCUAVSettingsAudioModel.h"

@interface SCUAVSettingsAudioTableViewController () <SCUAVSettingsAudioModelDelegate, SCUStepperDelegate>

@property (nonatomic) SCUAVSettingsAudioModel *model;
@property (nonatomic) SCUActionSheet *actionSheet;

@end

@implementation SCUAVSettingsAudioTableViewController

- (instancetype)initWithModel:(SCUAVSettingsAudioModel *)model
{
    self = [super init];
    if (self)
    {
        self.tableView.separatorColor = [UIColor colorWithRed:0.5451 green:0.5490 blue:0.5686 alpha:1.0];
        self.model = model;
        self.model.delegate = self;
    }
    
    return self;
    
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUAVSettingsSliderButtonCell class] forCellType:SCUAVSettingsAudioCellTypeSlider];
    [self.tableView sav_registerClass:[SCUAVSettingsStepperCell class] forCellType:SCUAVSettingsAudioCellTypeStepper];
    [self.tableView sav_registerClass:[SCUAVSettingsButtonCell class] forCellType:SCUAVSettingsAudioCellTypeButtonSelect];
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)t indexPath:(NSIndexPath *)indexPath
{
    SCUAVSettingsVideoCellType type = t;
    switch (type)
    {
        case SCUAVSettingsAudioCellTypeSlider:
        {
            SCUAVSettingsSliderButtonCell *cell = (SCUAVSettingsSliderButtonCell *)c;
            [self.model listenToAddButton:cell.addButton minusButton:cell.minusButton slider:cell.slider centerSlider:cell.centerSlider atIndexPath:indexPath];
            break;
        }
        case SCUAVSettingsAudioCellTypeStepper:
        {
            SCUAVSettingsStepperCell *cell = (SCUAVSettingsStepperCell *)c;
            [self.model listenToStepper:cell.stepper atIndexPath:indexPath];
            [self.model listenToDefaultButton:cell.defaultButton atIndexPath:indexPath];
            break;
        }
        case SCUAVSettingsAudioCellTypeButtonSelect:
        {
            SCUAVSettingsButtonCell *cell = (SCUAVSettingsButtonCell *)c;
            [self.model listenToDefaultButton:cell.rightButton atIndexPath:indexPath];
            break;
        }
    };
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Audio Settings", nil);
    
}

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCUAVSettingsAudioCellType type = [self.model cellTypeForIndexPath:indexPath];
    switch (type)
    {
        case SCUAVSettingsAudioCellTypeStepper:
            return 50.0f;
        case SCUAVSettingsAudioCellTypeSlider:
            return 100.0f;
        case SCUAVSettingsAudioCellTypeBalance:
            return 50.0f;
        case SCUAVSettingsAudioCellTypeButtonSelect:
            return 50.0f;
    }
}

- (void)presentActionSheetFromIndexPath:(NSIndexPath *)indexPath withTitles:(NSArray *)titles callback:(SCUActionSheetCallback)callback
{
    self.actionSheet = [[SCUActionSheet alloc] initWithButtonTitles:titles];
    self.actionSheet.callback = callback;
    [self.actionSheet showInView:self.view];
}

- (SCUAVSettingsSliderButtonCell *)sliderButtonCellForStateName:(NSString *)stateName
{
    NSIndexPath *indexPath = self.model.currentStates[stateName];
    return (SCUAVSettingsSliderButtonCell *)[self.tableView cellForRowAtIndexPath:indexPath];
}

- (SCUAVSettingsStepperCell *)stepperCellForStateName:(NSString *)stateName
{
    NSIndexPath *indexPath = self.model.currentStates[stateName];
    return (SCUAVSettingsStepperCell *)[self.tableView cellForRowAtIndexPath:indexPath];
}

#pragma mark - SCUAVSettingsAudioModelDelegate implementation

- (void)updateSliderValueLabel:(float)value atIndexPath:(NSIndexPath *)indexPath
{
    SCUAVSettingsSliderButtonCell *cell = (SCUAVSettingsSliderButtonCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell sliderUpdatedValue:value];
}

- (void)reloadIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)currentVolumeDidUpdateWithValue:(NSString *)value
{
    SCUAVSettingsSliderButtonCell *cell = (SCUAVSettingsSliderButtonCell *)[self.tableView cellForRowAtIndexPath:[self.model indexPathFromStateName:@"CurrentVolume"]];
    [cell setSliderValue:[value floatValue]];
}

- (void)currentBassDidUpdateWithValue:(NSString *)value
{
    SCUAVSettingsStepperCell *cell = (SCUAVSettingsStepperCell *)[self.tableView cellForRowAtIndexPath:[self.model indexPathFromStateName:@"CurrentBass"]];
    [cell updateStepper:[value floatValue]];
}

- (void)currentTrebleDidUpdateWithValue:(NSString *)value
{
    SCUAVSettingsStepperCell *cell = (SCUAVSettingsStepperCell *)[self.tableView cellForRowAtIndexPath:[self.model indexPathFromStateName:@"CurrentTreble"]];
    [cell updateStepper:[value floatValue]];
}

- (void)currentBalanceDidUpdateWithValue:(NSString *)value
{
    SCUAVSettingsStepperCell *cell = (SCUAVSettingsStepperCell *)[self.tableView cellForRowAtIndexPath:[self.model indexPathFromStateName:@"CurrentBalance"]];
    [cell updateStepperFromFormattedValue:value];
}

- (void)currentAudioEffectsLevelDidUpdateWithValue:(NSString *)value
{
    SCUAVSettingsSliderButtonCell *cell = (SCUAVSettingsSliderButtonCell *)[self.tableView cellForRowAtIndexPath:[self.model indexPathFromStateName:@"CurrentAudioEffectsLevel"]];
    [cell setSliderValue:[value floatValue]];
}

- (void)isMutedDidUpdateWithValue:(NSString *)value
{
    SCUAVSettingsSliderButtonCell *cell = (SCUAVSettingsSliderButtonCell *)[self.tableView cellForRowAtIndexPath:[self.model indexPathFromStateName:@"CurrentVolume"]];
    if ([value isEqualToString:@"0"])
    {
        [cell setSliderValue:0];
    }


}

@end
