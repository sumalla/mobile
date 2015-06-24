//
//  SCUButtonViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 5/9/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUButtonViewController.h"
#import "SCUGradientView.h"
#import "SCUButton.h"
#import "SCUButtonCollectionViewController.h"

@import Extensions;

@interface SCUButtonViewController ()

@property (nonatomic) SCUButtonCollectionViewController *collectionViewController;

@end

@implementation SCUButtonViewController

- (instancetype)initWithCommands:(NSArray *)commands
{
    self = [super init];
    if (self)
    {
        self.collectionViewController = [[SCUButtonCollectionViewController alloc] initWithCommands:commands];
        self.collectionViewController.collectionViewLayout.numberOfRows = 1;
        self.collectionViewController.collectionViewLayout.numberOfColumns = [commands count];
        self.tintColor = [[SCUColors shared] color01];
    }
    return self;
}

- (instancetype)initWithCollectionViewController:(SCUButtonCollectionViewController *)collectionViewController
{
    self = [super init];
    if (self)
    {
        self.collectionViewController = collectionViewController;
        self.tintColor = [[SCUColors shared] color01];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [[SCUColors shared] color03];
    self.view.borderColor = [[SCUColors shared] color03shade02];
    self.view.borderWidth = [UIScreen screenPixel];
    self.collectionViewController.view.backgroundColor = [UIColor clearColor];

    [self sav_addChildViewController:self.collectionViewController];

    if (self.needsFlushConstraints)
    {
        [self.view sav_addConstraintsForView:self.collectionViewController.view withEdgeInsets:UIEdgeInsetsMake(8, 8, 8, 8)];
    }
}

- (BOOL)needsFlushConstraints
{
    return YES;
}

#pragma mark - Properties

- (void)setSquareCells:(BOOL)squareCells
{
    if (_squareCells != squareCells)
    {
        _squareCells = squareCells;
        self.collectionViewController.squareCells = squareCells;
    }
}

- (void)setNumberOfColumns:(NSUInteger)numberOfColumns
{
    self.collectionViewController.collectionViewLayout.numberOfColumns = numberOfColumns;

    [self.collectionViewController.collectionViewLayout invalidateLayout];
}

- (NSUInteger)numberOfColumns
{
    return self.collectionViewController.collectionViewLayout.numberOfColumns;
}

- (void)setNumberOfRows:(NSUInteger)numberOfRows
{
    self.collectionViewController.collectionViewLayout.numberOfRows = numberOfRows;

    [self.collectionViewController.collectionViewLayout invalidateLayout];
}

- (NSUInteger)numberOfRows
{
    return self.collectionViewController.collectionViewLayout.numberOfRows;
}

- (void)setMaxNumberOfRows:(NSUInteger)maxNumberOfRows
{
    self.collectionViewController.collectionViewLayout.maxNumberOfRows = maxNumberOfRows;

    [self.collectionViewController.collectionViewLayout invalidateLayout];
}

- (NSUInteger)maxNumberOfRows
{
    return self.collectionViewController.collectionViewLayout.maxNumberOfRows;
}

- (void)setMinNumberOfRows:(NSUInteger)minNumberOfRows
{
    self.collectionViewController.collectionViewLayout.minNumberOfRows = minNumberOfRows;

    [self.collectionViewController.collectionViewLayout invalidateLayout];
}

- (NSUInteger)minNumberOfRows
{
    return self.collectionViewController.collectionViewLayout.minNumberOfRows;
}

- (void)setSpaceBetweenItems:(CGFloat)spaceBetweenItems
{
    self.collectionViewController.collectionViewLayout.spaceBetweenItems = spaceBetweenItems;

    [self.collectionViewController.collectionViewLayout invalidateLayout];
}

- (CGFloat)spaceBetweenItems
{
    return self.collectionViewController.collectionViewLayout.spaceBetweenItems;
}

- (void)setDelegate:(id<SCUButtonCollectionViewControllerDelegate>)delegate
{
    self.collectionViewController.delegate = delegate;
}

- (id<SCUButtonCollectionViewControllerDelegate>)delegate
{
    return self.collectionViewController.delegate;
}

- (void)setTintColor:(UIColor *)tintColor
{
    self.collectionViewController.tintColor = tintColor;

    [[SCUButton appearanceWhenContainedIn:[self class], nil] setSelectedBackgroundColor:tintColor];
}

- (UIColor *)tintColor
{
    return self.collectionViewController.tintColor;
}

- (void)setCommands:(NSArray *)commands
{
    self.collectionViewController.commands = commands;
}

- (NSArray *)commands
{
    return self.collectionViewController.commands;
}

@end
