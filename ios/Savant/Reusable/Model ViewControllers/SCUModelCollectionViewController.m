//
//  SCUModelCollectionViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 4/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelCollectionViewController.h"

@interface SCUModelCollectionViewController ()

@property BOOL hasInitialLayout;
@property UIInterfaceOrientation previousOrientation;

@end

@implementation SCUModelCollectionViewController

- (instancetype)init
{
    UICollectionViewLayout *layout = [self preferredCollectionViewLayout];
    self = [super initWithCollectionViewLayout:layout];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // TODO: Handle drawer gesture compatibility

    [self.collectionView sav_registerClass:[SCUDefaultCollectionViewCell class] forCellType:0];

    if ([self respondsToSelector:@selector(registerCells)])
    {
        [self registerCells];
    }

    self.view.backgroundColor = [[SCUColors shared] color03shade01];
    self.collectionView.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (!self.hasInitialLayout || (self.previousOrientation != [UIDevice interfaceOrientation]))
    {
        [self configureLayout:self.collectionViewLayout withOrientation:[UIDevice interfaceOrientation]];

        self.hasInitialLayout = YES;
    }

    if ([[self collectionViewModel] respondsToSelector:@selector(loadDataIfNecessary)])
    {
        [[self collectionViewModel] loadDataIfNecessary];
    }

    if ([[self collectionViewModel] respondsToSelector:@selector(viewWillAppear)])
    {
        [[self collectionViewModel] viewWillAppear];
    }

    if ([self.collectionViewModel respondsToSelector:@selector(willBegingDisplayingItemAtIndexPath:)])
    {
        for (NSIndexPath *indexPath in self.collectionView.indexPathsForVisibleItems)
        {

            [[self collectionViewModel] willBegingDisplayingItemAtIndexPath:indexPath];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([[self collectionViewModel] respondsToSelector:@selector(viewDidAppear)])
    {
        [[self collectionViewModel] viewDidAppear];
    }

    if ([self.collectionViewModel respondsToSelector:@selector(didBegingDisplayingItemAtIndexPath:)])
    {
        for (NSIndexPath *indexPath in self.collectionView.indexPathsForVisibleItems)
        {
            [[self collectionViewModel] didBegingDisplayingItemAtIndexPath:indexPath];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    self.previousOrientation = [UIDevice interfaceOrientation];
    
    if ([[self collectionViewModel] respondsToSelector:@selector(viewWillDisappear)])
    {
        [[self collectionViewModel] viewWillDisappear];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if ([[self collectionViewModel] respondsToSelector:@selector(viewDidDisappear)])
    {
        [[self collectionViewModel] viewDidDisappear];
    }
}

#pragma mark - Methods to subclass

- (UICollectionViewLayout *)preferredCollectionViewLayout
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)configureLayout:(UICollectionViewLayout *)layout withOrientation:(UIInterfaceOrientation)orientation
{
    ;
}

- (id<SCUDataSourceModel>)collectionViewModel
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma mark - UICollectionViewDataSource methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [[self collectionViewModel] numberOfSections];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[self collectionViewModel] numberOfItemsInSection:section];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger type = [[self collectionViewModel] cellTypeForIndexPath:indexPath];

    NSString *identifier = [NSString stringWithFormat:@"%lu", (unsigned long)type];

    SCUDefaultCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];

    [cell configureWithInfo:[[self collectionViewModel] modelObjectForIndexPath:indexPath]];

    if ([self respondsToSelector:@selector(configureCell:withType:indexPath:)])
    {
        [self configureCell:cell withType:type indexPath:indexPath];
    }

    if ([[self collectionViewModel] respondsToSelector:@selector(configureCell:withType:indexPath:)])
    {
        [[self collectionViewModel] configureCell:cell withType:type indexPath:indexPath];
    }

    if ([self.collectionViewModel respondsToSelector:@selector(willBegingDisplayingItemAtIndexPath:)])
    {
        [[self collectionViewModel] willBegingDisplayingItemAtIndexPath:indexPath];
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self.collectionViewModel respondsToSelector:@selector(didBegingDisplayingItemAtIndexPath:)])
        {
            [[self collectionViewModel] didBegingDisplayingItemAtIndexPath:indexPath];
        }
    });

    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger type = [[self collectionViewModel] cellTypeForIndexPath:indexPath];

    NSString *identifier = [NSString stringWithFormat:@"%@%lu", kind, (unsigned long)type];

    SCUDefaultCollectionViewCell *cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:identifier forIndexPath:indexPath];

    if ([self respondsToSelector:@selector(configureSupplementaryCell:withType:indexPath:)])
    {
        [self configureSupplementaryCell:cell withType:type indexPath:indexPath];
    }

    [cell configureWithInfo:[[self collectionViewModel] modelObjectForSection:indexPath.section]];

    return cell;
}

#pragma mark - UICollectionViewDelegate methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    if ([self.collectionViewModel respondsToSelector:@selector(selectItemAtIndexPath:)])
    {
        [[self collectionViewModel] selectItemAtIndexPath:indexPath];
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.collectionViewModel respondsToSelector:@selector(didEndDisplayingItemAtIndexPath:)])
    {
        [[self collectionViewModel] didEndDisplayingItemAtIndexPath:indexPath];
    }
}

#pragma mark - Rotation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    if ([UIDevice isPad])
    {
        [self animateInterfaceRotationChangeWithCoordinator:coordinator block:^(UIInterfaceOrientation orientation) {
            [self configureLayout:self.collectionViewLayout withOrientation:orientation];
        }];
    }
}

@end
