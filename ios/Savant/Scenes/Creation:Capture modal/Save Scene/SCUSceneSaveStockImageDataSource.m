//
//  SCUSceneSaveStockImageDataSource.m
//  SavantController
//
//  Created by Stephen Silber on 10/13/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneSaveStockImageDataSource.h"
#import "SCUSceneSaveStockImageCell.h"

@interface SCUSceneSaveStockImageDataSource ()

@property (nonatomic) NSArray *dataSource;
@property (nonatomic) NSIndexPath *selectedIndexPath;
@property (nonatomic) SAVScene *scene;

@end

@implementation SCUSceneSaveStockImageDataSource

- (instancetype)initWithScene:(SAVScene *)scene
{
    self = [super init];
    if (self)
    {
        self.scene = scene;

        [self buildDataSource];
        [self.delegate reloadData];
    }
    
    return self;
}

- (void)buildDataSource
{
    NSMutableArray *dataSource = [NSMutableArray array];
    [dataSource addObject:@{SCUSceneSaveStockImageCellKeyImage: @"Scene-Date Night"}];
    [dataSource addObject:@{SCUSceneSaveStockImageCellKeyImage: @"Scene-Daytime"}];
    [dataSource addObject:@{SCUSceneSaveStockImageCellKeyImage: @"Scene-Dinner"}];
    [dataSource addObject:@{SCUSceneSaveStockImageCellKeyImage: @"Scene-Goodnight"}];
    [dataSource addObject:@{SCUSceneSaveStockImageCellKeyImage: @"Scene-Movie Night"}];
    [dataSource addObject:@{SCUSceneSaveStockImageCellKeyImage: @"Scene-Play Time"}];
    [dataSource addObject:@{SCUSceneSaveStockImageCellKeyImage: @"Scene-Relax"}];
    [dataSource addObject:@{SCUSceneSaveStockImageCellKeyImage: @"Scene-Shades"}];
    [dataSource addObject:@{SCUSceneSaveStockImageCellKeyImage: @"Scene-Vacation"}];
    [dataSource addObject:@{SCUSceneSaveStockImageCellKeyImage: @"Scene-Wake Up"}];
    [dataSource addObject:@{SCUSceneSaveStockImageCellKeyImage: @"Scene-Away"}];
    [dataSource addObject:@{SCUSceneSaveStockImageCellKeyImage: @"Scene-Bathroom"}];
    [dataSource addObject:@{SCUSceneSaveStockImageCellKeyImage: @"Scene-Kitchen"}];
    [dataSource addObject:@{SCUSceneSaveStockImageCellKeyImage: @"Scene-Outdoor"}];
    [dataSource addObject:@{SCUSceneSaveStockImageCellKeyImage: @"Scene-Pool"}];

    self.dataSource = [dataSource copy];
}

- (void)saveSelectedImage
{
    if (self.selectedIndexPath)
    {
        self.scene.image = [self selectedImage];
        self.scene.hasCustomImage = NO;
        self.scene.imageKey = self.dataSource[self.selectedIndexPath.row][SCUSceneSaveStockImageCellKeyImage];
        
    }
}

- (UIImage *)selectedImage
{
    NSString *imageName = self.dataSource[self.selectedIndexPath.row][SCUSceneSaveStockImageCellKeyImage];
    return [UIImage imageNamed:imageName];
}

- (NSInteger)numberOfSections
{
    return 1;
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    return 0;
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedIndexPath = indexPath;
    [self.delegate reloadData];
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath isEqual:self.selectedIndexPath])
    {
        NSDictionary *modelObject = self.dataSource[indexPath.row];
        return [modelObject dictionaryByAddingObject:@YES forKey:SCUSceneSaveStockImageCellKeySelected];
    }
    
    return self.dataSource[indexPath.row];
}

@end
