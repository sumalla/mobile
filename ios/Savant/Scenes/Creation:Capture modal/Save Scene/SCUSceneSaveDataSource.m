//
//  SCUSceneSaveDataSource.m
//  SavantController
//
//  Created by Nathan Trapp on 7/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneSaveDataSource.h"
#import "SCUSceneCreationDataSourcePrivate.h"
#import "SCUDefaultTableViewCell.h"
#import "SCUSecondsPickerView.h"

@implementation SCUSceneSaveDataSource

- (NSInteger)numberOfSections
{
    return 2;
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section ? 1 : 0;
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    return section ? 2 : 1;
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *modelObject = [NSMutableDictionary dictionary];

    if (indexPath.section == 0)
    {
        modelObject[SCUDefaultTableViewCellKeyModelObject] = self.scene;

        if (self.scene.name)
        {
            modelObject[SCUDefaultTableViewCellKeyTitle] = self.scene.name;
        }
    }
    else
    {
        switch (indexPath.row)
        {
            case 0:
            {
                NSString *title = nil;
                NSString *description = nil;

                if (self.scene.isScheduled)
                {
                    switch (self.scene.scheduleType)
                    {
                        case SAVSceneScheduleType_Celestial:
                            title = NSLocalizedString(@"Celestial", nil);
                            if (self.scene.time > 0)
                            {
                                description = [NSString stringWithFormat:@"%@ After %@", [SCUSecondsPickerView stringForValue:self.scene.time], self.scene.celestialTypeString];
                            }
                            else if (self.scene.time < 0)
                            {
                                description = [NSString stringWithFormat:@"%@ Before %@", [SCUSecondsPickerView stringForValue:ABS(self.scene.time)], self.scene.celestialTypeString];
                            }
                            else
                            {
                                description = [NSLocalizedString(@"At ", nil) stringByAppendingString:self.scene.celestialTypeString];
                            }

                            description = [description stringByAppendingFormat:@", %@, %@", self.scene.dateString, self.scene.dayString];
                            break;
                        case SAVSceneScheduleType_Countdown:
                            title = NSLocalizedString(@"Countdown", nil);
                            description = [SCUSecondsPickerView stringForValue:self.scene.time];
                            break;
                        case SAVSceneScheduleType_Normal:
                            title = NSLocalizedString(@"Schedule", nil);
                            description = [NSString stringWithFormat:@"%@, %@, %@", self.scene.timeString, self.scene.dateString, self.scene.dayString];
                            break;
                    }
                }

                modelObject[SCUDefaultTableViewCellKeyTitle] = title ? title : NSLocalizedString(@"Schedule Scene", nil);
                modelObject[SCUDefaultTableViewCellKeyAccessoryType] = @(UITableViewCellAccessoryDisclosureIndicator);
                
                if (description)
                {
                    modelObject[SCUDefaultTableViewCellKeyDetailTitle] = description;
                }
            }
                break;

            case 1:
            {
                modelObject[SCUDefaultTableViewCellKeyTitle] = self.scene.fadeTime ? NSLocalizedString(@"Fade Time", nil) : NSLocalizedString(@"Add Fade Time", nil);;
                modelObject[SCUDefaultTableViewCellKeyAccessoryType] = @(UITableViewCellAccessoryDisclosureIndicator);

                if (self.scene.fadeTime)
                {
                    modelObject[SCUDefaultTableViewCellKeyDetailTitle] = [SCUSecondsPickerView stringForValue:self.scene.fadeTime];
                }
            }
                break;
        }

        modelObject[SCUDefaultTableViewCellKeyDetailTitleColor] = [[SCUColors shared] color03shade07];
    }

    return modelObject;
}

@end
