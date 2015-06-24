//
//  SCUGenericCommandTableModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 10/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUGenericCommandTableModel.h"
#import "SCUDefaultCollectionViewCell.h"
#import <SavantControl/SavantControl.h>
#import "SCUAnalytics.h"

@interface SCUGenericCommandTableModel ()

@property (nonatomic, copy) NSArray *dataSource;

@end

@implementation SCUGenericCommandTableModel

- (instancetype)initWithCommands:(NSArray *)commands
{
    self = [super init];

    if (self)
    {
        self.dataSource = commands;
    }

    return self;
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    SAVServiceRequest *request = [self modelObjectForIndexPath:indexPath][SCUDefaultCollectionViewCellKeyModelObject];

    if (request)
    {
        [SCUAnalytics recordEvent:@"Custom Command Executed" withKey:@"commandName" value:request.request];
        [[SavantControl sharedControl] sendMessage:request];
    }
}

@end
