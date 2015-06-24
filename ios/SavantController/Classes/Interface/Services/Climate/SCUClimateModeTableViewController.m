//
//  SCUClimateModeTableViewController.m
//  SavantController
//
//  Created by David Fairweather on 5/19/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUClimateModeTableViewController.h"
#import "SCUButton.h"

#import <SavantExtensions/SavantExtensions.h>

#define kSCUClimateModeTablePickerTagOffset 48932
#define kSCUClimateSectionMultiplier 1000 //allows each section to have 1000 options (this is over kill)

@interface SCUClimateModeTableViewController ()

@property (nonatomic) SCUSettingsConainerViewModel *model;
@property (nonatomic) NSUInteger settingsIndex;

@end

@implementation SCUClimateModeTableViewController

- (instancetype)initWithStyle:(UITableViewStyle)style withSettingsModel:(SCUSettingsConainerViewModel *)model settingsIndex:(NSUInteger)index
{
    self = [super initWithStyle:style];
    if (self)
    {
        self.settingsIndex = index;
        self.model = model;
        self.tableView.rowHeight = 44.0;
        self.tableView.sectionHeaderHeight = 44.0;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = [[SCUColors shared] color03];
    self.tableView.scrollEnabled = NO;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGSize)tabelViewSize
{
    CGFloat padingWidth = 100;
    CGFloat height = 0;
    NSUInteger numberOfSectionsInTabel = [self.model numberOfSectionForSettingsIndex:self.settingsIndex];
    CGFloat width = 110.0f;
    
    for (NSUInteger section = 0; section < numberOfSectionsInTabel; section++)
    {
        NSUInteger numberOfItemsSection = [self.model numberOfOptionsForSettingsIndex:self.settingsIndex section:section];
        height += (self.tableView.rowHeight * numberOfItemsSection);
        width = MAX(width, [self longestLocalizeStringLengthInArrayOrNestedArray:[self.model getSettingsOptionsArrayForSettingIndex:self.settingsIndex subsectionIndex:section] withFont:nil] + padingWidth);
        NSString *headerTitle = [self.model titleForSection:section forSettingsIndex:self.settingsIndex];
        if (headerTitle)
        {
            height += self.tableView.sectionHeaderHeight;
            width = MAX(width, [self longestLocalizeStringLengthInArrayOrNestedArray:@[headerTitle] withFont:nil] + padingWidth);
        }
    }
    return CGSizeMake(width, height);
}

- (CGFloat)longestLocalizeStringLengthInArrayOrNestedArray:(NSArray *)stringsArray withFont:(UIFont *)font
{
    if (!font)
    {
        font = [[SCUButton alloc] initWithTitle:@"XXTESTXX"].titleLabel.font;
    }
    UILabel *aLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [aLabel setFont:font];
    CGFloat longest = 0;
    for (NSObject *arrayObject in stringsArray)
    {
        if ([arrayObject isKindOfClass:[NSString class]])
        {
            NSString *aString = (NSString *)arrayObject;
            [aLabel setText:NSLocalizedString(aString, nil)];
            [aLabel sizeToFit];
            longest = MAX(longest, aLabel.frame.size.width);
        }
        else if ([arrayObject isKindOfClass:[NSArray class]])
        {
            NSArray *subArray = (NSArray *)arrayObject;
            longest = MAX(longest, [self longestLocalizeStringLengthInArrayOrNestedArray:subArray withFont:font]);
        }
        else if ([arrayObject isKindOfClass:[NSNumber class]])
        {
            NSString *aString = [self.model labelsForState:[(NSNumber *)arrayObject integerValue]];
            if (aString)
            {
                [aLabel setText:NSLocalizedString(aString, nil)];
                [aLabel sizeToFit];
                longest = MAX(longest, aLabel.frame.size.width);
            }
        }
    }
    return longest;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.model numberOfSectionForSettingsIndex:self.settingsIndex];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.model numberOfOptionsForSettingsIndex:self.settingsIndex section:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    // This will create a "invisible" footer
    return 0.01f;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.model titleForSection:section forSettingsIndex:self.settingsIndex];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    
    cell.backgroundColor = self.view.backgroundColor;
    NSObject *titleOrImage = [self.model imageOrTitleForSettingIndex:self.settingsIndex atIndexPath:indexPath];
    SCUButton *cellButton;
    
    if ([titleOrImage isKindOfClass:[UIImage class]])
    {
        cellButton = [[SCUButton alloc] initWithImage:(UIImage *)titleOrImage];
    }
    else if ([titleOrImage isKindOfClass:[NSString class]])
    {
        cellButton = [[SCUButton alloc] initWithTitle:NSLocalizedString((NSString *)titleOrImage, nil)];
    }
    else
    {
        cellButton = [[SCUButton alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"unKnowOption %d", nil), indexPath.row]];
    }
    if ([self.model settingsIndex:self.settingsIndex ModeIsSelected:indexPath])
    {
        [cellButton setSelected:YES];
    }

    cellButton.color = [[SCUColors shared] color03shade06];
    cellButton.selectedColor = [[SCUColors shared] color01];
    cellButton.selectedBackgroundColor = [UIColor sav_colorWithRGBValue:0xc4c4c4 alpha:.8];
    cellButton.frame = CGRectZero;
    cellButton.clipsToBounds = YES;
    cellButton.tag = kSCUClimateModeTablePickerTagOffset + indexPath.row + indexPath.section * kSCUClimateSectionMultiplier;
    [cellButton setTarget:self];
    [cellButton setReleaseAction:@selector(modeButtonPressed:)];
    [cell.contentView addSubview:cellButton];
    [cell.contentView sav_addFlushConstraintsForView:cellButton];
   
    return cell;
}

- (void)modeButtonPressed:(UIButton *)settingsSelected
{
    NSUInteger buttonTag = settingsSelected.tag - kSCUClimateModeTablePickerTagOffset;
    NSIndexPath *settingsIndexPath = [NSIndexPath indexPathForRow:buttonTag % kSCUClimateSectionMultiplier inSection:buttonTag / kSCUClimateSectionMultiplier];
    [self.model settingsModeSelectedAtIndexPath:settingsIndexPath forSettingIndex:self.settingsIndex];
    BOOL shouldDismissTable = [self.model shouldDismissPopUpAfterSingleSelection:self.settingsIndex];
    if ([self.delegate respondsToSelector:@selector(settingsUpdatedWithIndexPath:settingsIndex:shouldDismissTable:)])
    {
        [self.delegate settingsUpdatedWithIndexPath:settingsIndexPath settingsIndex:self.settingsIndex shouldDismissTable:shouldDismissTable];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.model settingsModeSelectedAtIndexPath:indexPath forSettingIndex:self.settingsIndex];
}

@end
