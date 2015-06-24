//
//  SCUAddDynamicButtonViewModel.m
//  SavantController
//
//  Created by Jason Wolkovitz on 5/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAddDynamicButtonViewModel.h"
#import "SCUDefaultTableViewCell.h"
#import "SCUDynamicButtonsCollectionViewModel.h"
#import "SCUStandardCollectionViewCell.h"
@import SDK;

@interface SCUAddDynamicButtonViewModel ()

@property NSArray *dataSource;

@end

@implementation SCUAddDynamicButtonViewModel

- (instancetype)initWithCommands:(NSArray *)commands
{
    self = [super init];
    if (self)
    {
        [self loadCommands:commands];
    }
    return self;
}

- (void)loadCommands:(NSArray *)commands
{
    if (![commands isKindOfClass:[NSArray class]])
    {
        return;
    }

    commands = [commands sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    self.dataSource = [commands arrayByMappingBlock:^id(NSString *command) {
        NSString *localizedCommand = [SCUDynamicButtonsCollectionViewModel localizedCommand:command];

        NSMutableDictionary *newCommand = [NSMutableDictionary dictionary];

        newCommand[SCUDefaultCollectionViewCellKeyTitle] = localizedCommand;
        newCommand[SCUDefaultCollectionViewCellKeyModelObject] = command;

        return [newCommand copy];
    }];
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = self.dataSource[indexPath.row];
    NSMutableArray *newDataSource = [self.dataSource mutableCopy];
    [newDataSource removeObjectAtIndex:indexPath.row];

    self.dataSource = [newDataSource copy];

    [self.delegate addButton:modelObject];
}

@end
