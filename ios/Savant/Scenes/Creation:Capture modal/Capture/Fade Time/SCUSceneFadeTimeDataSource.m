//
//  SCUSceneFadeTimeDataSource.m
//  SavantController
//
//  Created by Nathan Trapp on 8/19/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneFadeTimeDataSource.h"
#import "SCUSecondsPickerView.h"
#import "SCUSecondsPickerCell.h"
#import "SCUSceneCreationDataSourcePrivate.h"

@implementation SCUSceneFadeTimeDataSource

- (instancetype)initWithScene:(SAVScene *)scene andService:(SAVService *)service
{
    self = [super initWithScene:scene andService:service];
    if (self)
    {
        [self prepareData];
    }
    return self;
}

- (void)prepareData
{
    NSMutableArray *dataSource = [NSMutableArray array];

    [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Fade Time", nil),
                            SCUDefaultTableViewCellKeyDetailTitle: [SCUSecondsPickerView stringForValue:self.scene.fadeTime],
                            SCUDefaultTableViewCellKeyDetailTitleColor: [[SCUColors shared] color03shade07]}];

    [dataSource addObject:@{SCUPickerCellKeyValue: @(self.scene.time),
                           SCUPickerCellKeyValues: @[@0, @1, @2, @3, @4, @5, @6, @7, @8, @9, @10, @15, @20, @25, @30, @60, @300, @600, @900]}];

    self.dataSource = dataSource;
}

- (NSInteger)numberOfSections
{
    return 1;
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    return 2;
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.row;
}

@end
