//
//  SCUAVVideoSettingsViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/30/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVSettingsVideoTableViewController.h"
#import "SCUAVSettingsSliderButtonCell.h"
#import "SCUAVSettingsSelectCell.h"
#import "SCUActionSheet.h"
#import "SCUAVSettingsRightInfoCell.h"
#import "SCUThemedNavigationViewController.h"
#import <SavantExtensions/SavantExtensions.h>

@interface SCUAVSettingsVideoTableViewController () <SCUAVSettingsVideoModelDelegate>

@property (nonatomic) SCUAVSettingsVideoModel *model;
@property (nonatomic) UIPopoverController *popController;
@property (nonatomic) SCUActionSheet *actionSheet;
@property (nonatomic) CGFloat currentContrast;

@end

@implementation SCUAVSettingsVideoTableViewController

- (instancetype)initWithModel:(SCUAVSettingsVideoModel *)model
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
    [self.tableView sav_registerClass:[SCUAVSettingsRightInfoCell class] forCellType:SCUAVSettingsVideoCellTypeRightInfo];
    [self.tableView sav_registerClass:[SCUAVSettingsSelectCell class] forCellType:SCUAVSettingsVideoCellTypeMenuSelect];
    [self.tableView sav_registerClass:[SCUAVSettingsSliderButtonCell class] forCellType:SCUAVSettingsVideoCellTypeSlider];
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)t indexPath:(NSIndexPath *)indexPath
{
    SCUAVSettingsVideoCellType type = t;
    switch (type)
    {
        case SCUAVSettingsVideoCellTypeSlider:
        {
            SCUAVSettingsSliderButtonCell *cell = (SCUAVSettingsSliderButtonCell *)c;
            [self.model listenToAddButton:cell.addButton minusButton:cell.minusButton slider:cell.slider centerSlider:cell.centerSlider atIndexPath:indexPath];
            break;
        }
    };
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Video Settings", nil);
}

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ([self.model cellTypeForIndexPath:indexPath] == SCUAVSettingsVideoCellTypeSlider) ? 100 : 55;
}

#pragma mark - SCUAVSettingsVideoModelDelegate

- (void)reloadIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (UITableViewCell *)tableViewCellForIndexPath:(NSIndexPath *)indexPath
{
    return [self.tableView cellForRowAtIndexPath:indexPath];
}

- (void)presentActionSheetFromIndexPath:(NSIndexPath *)indexPath withTitles:(NSArray *)titles callback:(SCUActionSheetCallback)callback
{
    self.actionSheet = [[SCUActionSheet alloc] initWithButtonTitles:titles];
    self.actionSheet.callback = callback;
    [self.actionSheet showInView:self.view];
}

- (SCUAVSettingsSliderButtonCell *)sliderButtonCellForStateName:(NSString *)stateName
{
    NSIndexPath *indexPath = self.model.statesToIndexPath[stateName];
    return (SCUAVSettingsSliderButtonCell *)[self.tableView cellForRowAtIndexPath:indexPath];
}

- (void)updateSliderValueLabel:(float)value atIndexPath:(NSIndexPath *)indexPath
{
    SCUAVSettingsSliderButtonCell *cell = (SCUAVSettingsSliderButtonCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell sliderUpdatedValue:value];
}

//------------------------------------
// Reloading indexPath caused layout issues,
// especially with SCUCenteredSlider
//------------------------------------
- (void)currentBrightnessDidUpdateWithValue:(NSString *)value
{
    SCUAVSettingsSliderButtonCell *cell = (SCUAVSettingsSliderButtonCell *)[self.tableView cellForRowAtIndexPath:[self.model indexPathFromStateName:@"CurrentBrightness"]];
    [cell setSliderValue:[value floatValue]];
}

- (void)currentSaturationDidUpdateWithValue:(NSString *)value
{
    SCUAVSettingsSliderButtonCell *cell = (SCUAVSettingsSliderButtonCell *)[self.tableView cellForRowAtIndexPath:[self.model indexPathFromStateName:@"CurrentSaturation"]];
    [cell setSliderValue:[value floatValue]];}

- (void)currentContrastDidUpdateWithValue:(NSString *)value
{
    SCUAVSettingsSliderButtonCell *cell = (SCUAVSettingsSliderButtonCell *)[self.tableView cellForRowAtIndexPath:[self.model indexPathFromStateName:@"CurrentContrast"]];
    [cell setSliderValue:[value floatValue]];
}

- (void)currentNoiseReductionDidUpdateWithValue:(NSString *)value
{
    SCUAVSettingsSliderButtonCell *cell = (SCUAVSettingsSliderButtonCell *)[self.tableView cellForRowAtIndexPath:[self.model indexPathFromStateName:@"CurrentNoiseReduction"]];
    [cell setSliderValue:[value floatValue]];
}

- (void)currentHueDidUpdateWithValue:(NSString *)value
{
    SCUAVSettingsSliderButtonCell *cell = (SCUAVSettingsSliderButtonCell *)[self.tableView cellForRowAtIndexPath:[self.model indexPathFromStateName:@"CurrentHue"]];
    [cell setSliderValue:[value floatValue]];
}

- (void)currentDetailEnhancementDidUpdateWithValue:(NSString *)value
{
    SCUAVSettingsSliderButtonCell *cell = (SCUAVSettingsSliderButtonCell *)[self.tableView cellForRowAtIndexPath:[self.model indexPathFromStateName:@"CurrentDetailEnhancementLevel"]];
    [cell setSliderValue:[value floatValue]];
}

- (void)currentInputVideoFormatDidUpdateWithValue:(NSString *)value
{
    [self reloadIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

- (void)currentOutputVideoFormatDidUpdateWithValue:(NSString *)value
{
    [self reloadIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
}

@end
