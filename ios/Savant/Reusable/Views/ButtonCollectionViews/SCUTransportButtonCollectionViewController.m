//
//  SCUTransportButtonCollectionViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 5/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUTransportButtonCollectionViewController.h"
#import "SCUButtonCollectionViewModel.h"
#import "SCUButtonCollectionViewCell.h"

@interface SCUTransportButtonCollectionViewController ()

@property SCUButtonCollectionViewModel *model;
@property NSArray *genericCommands;
@property NSArray *backCommands;
@property NSArray *forwardCommands;

@end

@implementation SCUTransportButtonCollectionViewController

- (instancetype)initWithGenericCommands:(NSArray *)commands backCommands:(NSArray *)backCommands forwardCommands:(NSArray *)forwardCommands
{
    self = [super initWithCommands:nil];
    if (self)
    {
        self.genericCommands = commands;
        self.backCommands = backCommands;
        self.forwardCommands = forwardCommands;

        [self prepareCommands];
    }
    return self;
}

- (void)configureLayout:(UICollectionViewLayout *)layout withOrientation:(UIInterfaceOrientation)orientation
{
    SCUCollectionViewFlowLayout *flowLayout = (SCUCollectionViewFlowLayout *)layout;
    flowLayout.numberOfRows = self.numberOfRows;
    flowLayout.numberOfColumns = [self numberOfColumns];

    [flowLayout invalidateLayout];
}

- (void)prepareCommands
{
    NSMutableArray *commands = [NSMutableArray array];

    //-------------------------------------------------------------------
    // If we have a single row of commands, we just display
    // [back][generic][forward]
    //-------------------------------------------------------------------
    if (self.singleRow)
    {
        [commands addObjectsFromArray:self.backCommands];
        [commands addObjectsFromArray:self.genericCommands];
        [commands addObjectsFromArray:self.forwardCommands];
    }
    //-------------------------------------------------------------------
    // iPhone, keep generics commands on the outer edges as possible
    // This is always 3 columns. Number of rows varies based on available commands
    //-------------------------------------------------------------------
    else if ([self numberOfColumns] == 4)
    {
        NSMutableArray *genericCommands = [NSMutableArray arrayWithArray:self.genericCommands];
        NSMutableArray *backCommands = [NSMutableArray arrayWithArray:self.backCommands];
        NSMutableArray *forwardCommands = [NSMutableArray arrayWithArray:self.forwardCommands];
        
        NSUInteger buttonCount = (genericCommands.count + backCommands.count + forwardCommands.count);
        
        NSInteger column = 0;
        
        while (buttonCount > 0)
        {
            switch (column)
            {
                case 0:
                    if (backCommands.count)
                    {
                        [commands addObject:[backCommands firstObject]];
                        [backCommands removeObjectAtIndex:0];
                    }
                    else if (genericCommands.count)
                    {
                        [commands addObject:[genericCommands firstObject]];
                        [genericCommands removeObjectAtIndex:0];
                    }
                    else if (forwardCommands.count)
                    {
                        [commands addObject:[forwardCommands firstObject]];
                        [forwardCommands removeObjectAtIndex:0];
                    }
                    buttonCount--;
                    column++;
                    break;
                case 1:
                    if (backCommands.count > genericCommands.count)
                    {
                        [commands addObject:[backCommands firstObject]];
                        [backCommands removeObjectAtIndex:0];
                    }
                    else if (genericCommands.count)
                    {
                        [commands addObject:[genericCommands firstObject]];
                        [genericCommands removeObjectAtIndex:0];
                    }
                    else if (forwardCommands.count)
                    {
                        [commands addObject:[forwardCommands firstObject]];
                        [forwardCommands removeObjectAtIndex:0];
                    }
                    buttonCount--;
                    column++;
                    break;
                case 2:
                    if (forwardCommands.count > genericCommands.count || forwardCommands.count > 1)
                    {
                        [commands addObject:[forwardCommands firstObject]];
                        [forwardCommands removeObjectAtIndex:0];
                    }
                    else if (genericCommands.count)
                    {
                        [commands addObject:[genericCommands firstObject]];
                        [genericCommands removeObjectAtIndex:0];
                    }
                    else if (backCommands.count)
                    {
                        [commands addObject:[backCommands firstObject]];
                        [backCommands removeObjectAtIndex:0];
                    }
                    buttonCount--;
                    column++;
                    break;
                case 3:
                    if (forwardCommands.count)
                    {
                        [commands addObject:[forwardCommands firstObject]];
                        [forwardCommands removeObjectAtIndex:0];
                    }
                    else if (genericCommands.count)
                    {
                        [commands addObject:[genericCommands firstObject]];
                        [genericCommands removeObjectAtIndex:0];
                    }
                    else if (backCommands.count)
                    {
                        [commands addObject:[backCommands firstObject]];
                        [backCommands removeObjectAtIndex:0];
                    }
                    buttonCount--;
                    column = 0;
                    break;
            }
        }

    }
    else if ([self numberOfColumns] == 2)
    {
        NSMutableArray *genericCommands = [NSMutableArray arrayWithArray:self.genericCommands];
        NSMutableArray *backCommands = [NSMutableArray arrayWithArray:self.backCommands];
        NSMutableArray *forwardCommands = [NSMutableArray arrayWithArray:self.forwardCommands];
        
        for (NSInteger i = 0; i < self.numberOfRows; i++)
        {
            if (backCommands.count && forwardCommands.count)
            {
                [commands addObject:[backCommands firstObject]];
                [backCommands removeObjectAtIndex:0];
                
                [commands addObject:[forwardCommands firstObject]];
                [forwardCommands removeObjectAtIndex:0];
            }
            else if (backCommands.count && genericCommands.count)
            {
                [commands addObject:[backCommands firstObject]];
                [backCommands removeObjectAtIndex:0];
                
                [commands addObject:[genericCommands firstObject]];
                [genericCommands removeObjectAtIndex:0];
            }
            else if (forwardCommands.count && genericCommands.count)
            {
                
                [commands addObject:[genericCommands firstObject]];
                [genericCommands removeObjectAtIndex:0];
                
                [commands addObject:[forwardCommands firstObject]];
                [forwardCommands removeObjectAtIndex:0];
                
            }
            else
            {
                while (genericCommands.count)
                {
                    [commands addObject:[genericCommands firstObject]];
                    [genericCommands removeObjectAtIndex:0];
                }
            }
        }
    }
    else
    {
        NSMutableArray *genericCommands = [NSMutableArray arrayWithArray:self.genericCommands];
        NSMutableArray *backCommands = [NSMutableArray arrayWithArray:self.backCommands];
        NSMutableArray *forwardCommands = [NSMutableArray arrayWithArray:self.forwardCommands];
        
        for (NSInteger i = 0; i < self.numberOfRows; i++)
        {
            //-------------------------------------------------------------------
            // Add the first item, prefering back, then generic, then forward
            //-------------------------------------------------------------------
            if ([backCommands count])
            {
                [commands addObject:[backCommands lastObject]];
                [backCommands removeLastObject];
            }
            else if ([genericCommands count])
            {
                [commands addObject:[genericCommands firstObject]];
                [genericCommands removeObjectAtIndex:0];
            }
            else if ([forwardCommands count])
            {
                [commands addObject:[forwardCommands firstObject]];
                [forwardCommands removeObjectAtIndex:0];
            }
            else
            {
                break;
            }
            
            //-------------------------------------------------------------------
            // Add the second item, prefering generic, then back, then forward
            //-------------------------------------------------------------------
            if ([genericCommands count])
            {
                [commands addObject:[genericCommands firstObject]];
                [genericCommands removeObjectAtIndex:0];
            }
            else if ([backCommands count])
            {
                [commands addObject:[backCommands lastObject]];
                [backCommands removeLastObject];
            }
            else if ([forwardCommands count])
            {
                [commands addObject:[forwardCommands firstObject]];
                [forwardCommands removeObjectAtIndex:0];
            }
            else
            {
                break;
            }
            
            //-------------------------------------------------------------------
            // Add the last item, prefering forward, then generic, then back
            //-------------------------------------------------------------------
            if ([forwardCommands count])
            {
                [commands addObject:[forwardCommands firstObject]];
                [forwardCommands removeObjectAtIndex:0];
            }
            else if ([genericCommands count])
            {
                [commands addObject:[genericCommands firstObject]];
                [genericCommands removeObjectAtIndex:0];
            }
            else if ([backCommands count])
            {
                [commands addObject:[backCommands lastObject]];
                [backCommands removeLastObject];
            }
            else
            {
                break;
            }
        }
    }

    self.model.commands = [commands copy];

    [self configureLayout:self.collectionViewLayout withOrientation:[UIDevice interfaceOrientation]];
}

- (NSUInteger)numberOfItems
{
    return self.numberOfBackForwardItems + [self.genericCommands count];
}

- (NSUInteger)numberOfBackForwardItems
{
    return [self.backCommands count] + [self.forwardCommands count];
}

- (NSUInteger)numberOfGenericItems
{
    return [self.genericCommands count];
}

//-------------------------------------------------------------------
// Calculate the number of columns to try and keep directional commands together
//-------------------------------------------------------------------
- (NSUInteger)numberOfColumns
{
    if (self.columns)
    {
        return self.columns;
    }
    
    NSUInteger numberOfColumns = 0;
    NSInteger difference = [self numberOfGenericItems] - [self numberOfBackForwardItems];
    NSUInteger modifier = 0;

    //-------------------------------------------------------------------
    // if the difference between generic transport controls and directional controls
    // is greater than 2, offset the number of columns to keep items grouped
    //-------------------------------------------------------------------
    if (difference >= 2)
    {
        modifier = ceilf(difference / 2.0);
    }

    //-------------------------------------------------------------------
    // Set the base number of columns based on the type that has more items,
    // so when things reflow to the left, they remain grouped
    //-------------------------------------------------------------------
    if (self.numberOfBackForwardItems > self.numberOfGenericItems)
    {
        numberOfColumns = self.numberOfBackForwardItems - modifier;
    }
    else
    {
        numberOfColumns = self.numberOfGenericItems - modifier;
    }

    //-------------------------------------------------------------------
    // If the difference is odd and we have at least two items,
    // add an extra column to preserve grouping
    //-------------------------------------------------------------------
    if (numberOfColumns > 1 && !(difference % 2) && difference)
    {
        numberOfColumns++;
    }
    
    //-------------------------------------------------------------------
    // Make sure we’re providing enough columns to split across two rows
    //-------------------------------------------------------------------
    NSUInteger minNumberOfColums = ceilf(self.numberOfItems / 2.0);

    if (minNumberOfColums > numberOfColumns)
    {
        numberOfColumns = minNumberOfColums;
    }

    return numberOfColumns;
}

- (NSInteger)numberOfRows
{
    return ceil((CGFloat)self.numberOfItems / 3);
}

- (void)setColumns:(NSInteger)columns
{
    _columns = columns;
    [self prepareCommands];
}

- (SCUCollectionViewFlowLayout *)preferredCollectionViewLayout
{
    SCUCollectionViewFlowLayout *flowLayout = (SCUCollectionViewFlowLayout *)[super preferredCollectionViewLayout];

    flowLayout.spaceBetweenItems = 2;

    return flowLayout;
}

- (void)setSingleRow:(BOOL)singleRow
{
    _singleRow = singleRow;

    [self prepareCommands];
}

@end
