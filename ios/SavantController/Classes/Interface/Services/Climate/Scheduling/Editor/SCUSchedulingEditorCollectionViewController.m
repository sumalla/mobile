//
//  SCUSchedulingEditor.m
//  SavantController
//
//  Created by Nathan Trapp on 7/14/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSchedulingEditorCollectionViewController.h"
#import "SCUSchedulingEditorModel.h"
#import "SCUSchedulingEditingViewController.h"
#import "SCUSchedulingCell.h"
#import <SavantControl/SAVClimateSchedule.h>

@interface SCUSchedulingEditorCollectionViewController ()

@property SCUSchedulingEditorModel *model;
@property NSIndexPath *selectedIndex;
@property NSMutableDictionary *editingViewControllers;

@end

@implementation SCUSchedulingEditorCollectionViewController

- (instancetype)initWithSchedule:(SAVClimateSchedule *)schedule
{
    self = [super init];
    if (self)
    {
        if (!schedule)
        {
            schedule = [[SAVClimateSchedule alloc] init];
            schedule.days = @[@(SAVClimateScheduleDay_Sunday),
                              @(SAVClimateScheduleDay_Monday),
                              @(SAVClimateScheduleDay_Tuesday),
                              @(SAVClimateScheduleDay_Wednesday),
                              @(SAVClimateScheduleDay_Thursday),
                              @(SAVClimateScheduleDay_Friday),
                              @(SAVClimateScheduleDay_Saturday)];
        }

        self.model = [[SCUSchedulingEditorModel alloc] initWithSchedule:[schedule copy]];
        self.editingViewControllers = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.allowsMultipleSelection = NO;
    
    self.selectedIndex = [NSIndexPath indexPathForItem:0 inSection:0];

    //TODO: Fix this hack - should be replaced once we rebuild SCUActionSheet to support iPhone/iPad
    if ([UIDevice isPhone])
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.selectedIndex = [NSIndexPath indexPathForItem:0 inSection:0];
            [self.collectionView reloadItemsAtIndexPaths:@[self.selectedIndex]];
            [self.collectionView selectItemAtIndexPath:self.selectedIndex animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        });
    }
    else
    {
        [self.collectionView reloadItemsAtIndexPaths:@[self.selectedIndex]];
        [self.collectionView selectItemAtIndexPath:self.selectedIndex animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
    
}

#pragma mark - Methods to subclass

- (void)configureCell:(SCUDefaultCollectionViewCell *)c withType:(NSUInteger)t indexPath:(NSIndexPath *)indexPath
{
    SCUSchedulingCell *cell = (SCUSchedulingCell *)c;

    cell.editingViewController = [self editingViewControllerForIndexPath:indexPath];

    [self.collectionView selectItemAtIndexPath:self.selectedIndex animated:NO scrollPosition:UICollectionViewScrollPositionNone];
}

- (SCUSchedulingEditingViewController *)editingViewControllerForIndexPath:(NSIndexPath *)indexPath
{
    SCUSchedulingEditingViewController *editingViewController = nil;

    if (indexPath)
    {
        NSDictionary *info = [self.model modelObjectForIndexPath:indexPath];

        if (info[SCUDefaultCollectionViewCellKeyModelObject])
        {
            SCUSchedulingEditorType type = [info[@"type"] integerValue];

            if ([self.editingViewControllers[indexPath] isKindOfClass:[SCUSchedulingEditingViewController classForType:type]])
            {
                editingViewController = self.editingViewControllers[indexPath];
            }
            else
            {
                editingViewController = [SCUSchedulingEditingViewController editingViewControllerForType:type andSchedule:info[SCUDefaultCollectionViewCellKeyModelObject]];
                self.editingViewControllers[indexPath] = editingViewController;
            }
        }
    }

    return editingViewController;
}

- (id<SCUDataSourceModel>)collectionViewModel
{
    return self.model;
}

- (UICollectionViewLayout *)preferredCollectionViewLayout
{
    return [[SCUCollectionViewFlowLayout alloc] init];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.collectionViewModel respondsToSelector:@selector(selectItemAtIndexPath:)])
    {
        [[self collectionViewModel] selectItemAtIndexPath:indexPath];
    }

    [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    self.selectedIndex = indexPath;
}

@end
