//
//  SCUButtonCollectionViewController.m
//  SavantController
//
//  Created by Jason Wolkovitz on 4/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUButtonCollectionViewController.h"
#import "SCUButtonCollectionViewModel.h"
#import "SCUButtonCollectionViewCell.h"
#import "SCUCollectionViewFlowLayout.h"

@import Extensions;

@interface SCUButtonCollectionViewController ()

@property SCUButtonCollectionViewModel *model;

@end

@implementation SCUButtonCollectionViewController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.collectionView.delaysContentTouches = NO;
        self.collectionView.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (instancetype)initWithCommands:(NSArray *)commands
{
    self = [self init];
    if (self)
    {
        self.commands = commands;
        self.model = [[SCUButtonCollectionViewModel alloc] initWithCommands:commands];
    }
    return self;
}

#pragma mark - UICollectionViewDelegate methods

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SCUButtonCollectionViewCell *cell = (SCUButtonCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];

    cell.borderColor = [[SCUColors shared] color03shade04];
    cell.borderWidth = [UIScreen screenPixel];
    cell.textLabel.textColor = [[SCUColors shared] color04];
    cell.textLabel.font = [UIFont fontWithName:@"Gotham-Light" size:72.0f];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(tappedButton:withCommand:)])
    {
        [self.delegate tappedButton:(SCUButtonCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath] withCommand:((self.collectionViewModel.dataSource)[indexPath.row])[SCUDefaultCollectionViewCellKeyModelObject]];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];

    [self.delegate releasedButton:(SCUButtonCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath] withCommand:((self.collectionViewModel.dataSource)[indexPath.row])[SCUDefaultCollectionViewCellKeyModelObject]];
}

#pragma mark - Methods to subclass

- (UICollectionViewLayout *)preferredCollectionViewLayout
{
    SCUCollectionViewFlowLayout *flowLayout = [[SCUCollectionViewFlowLayout alloc] init];
    flowLayout.spaceBetweenItems = 2;
    
    return flowLayout;
}

- (void)registerCells
{
    [self.collectionView sav_registerClass:[SCUButtonCollectionViewCell class] forCellType:0];
}

- (SCUButtonCollectionViewModel *)collectionViewModel
{
    return self.model;
}

#pragma mark - Properties

- (void)setSquareCells:(BOOL)squareCells
{
    if (_squareCells != squareCells)
    {
        _squareCells = squareCells;
        self.collectionViewLayout.squareCells = squareCells;
        [self.collectionViewLayout invalidateLayout];
    }
}

- (void)setTintColor:(UIColor *)tintColor
{
    _tintColor = tintColor;

    [self.collectionViewLayout invalidateLayout];
}

- (void)setCommands:(NSArray *)commands
{
    _commands = commands;

    self.model.commands = commands;
    [self.collectionView reloadData];
}

@end
