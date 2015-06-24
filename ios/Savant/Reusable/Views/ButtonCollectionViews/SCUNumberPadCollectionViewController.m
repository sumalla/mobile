//
//  SCUNumberPadCollectionViewController.m
//  SavantController
//
//  Created by Jason Wolkovitz on 4/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUNumberPadCollectionViewController.h"
#import "SCUNumberPadCollectionViewCell.h"
#import "SCUNumberPadCollectionViewModel.h"

@interface SCUNumberPadCollectionViewController ()

@property (nonatomic) SCUNumberPadCollectionViewModel *model;

@end

@implementation SCUNumberPadCollectionViewController

- (instancetype)initWithCommands:(NSArray *)commands
{
    self = [super initWithCommands:commands];
    if (self)
    {
        self.model = [[SCUNumberPadCollectionViewModel alloc] initWithCommands:commands];
    }
    return self;
}

- (void)registerCells
{
    [self.collectionView sav_registerClass:[SCUNumberPadCollectionViewCell class] forCellType:0];
}

- (SCUNumberPadCollectionViewModel *)collectionViewModel
{
    return self.model;
}

- (SCUCollectionViewFlowLayout *)preferredCollectionViewLayout
{
    SCUCollectionViewFlowLayout *flowLayout = (SCUCollectionViewFlowLayout *)[super preferredCollectionViewLayout];

    flowLayout.numberOfColumns = 3;
    flowLayout.numberOfRows = 4;
    flowLayout.spaceBetweenItems = 2;
    
    return flowLayout;
}

#pragma mark - Properties

- (void)setLetterMapping:(BOOL)letterMapping
{
    self.model.letterMapping = letterMapping;
    [self.collectionViewLayout invalidateLayout];
}

- (BOOL)letterMapping
{
    return self.model.letterMapping;
}

@end
