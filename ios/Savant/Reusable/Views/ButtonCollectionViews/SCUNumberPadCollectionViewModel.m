//
//  SCUNumberPadCollectionViewModel.m
//  SavantController
//
//  Created by Jason Wolkovitz on 4/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUNumberPadCollectionViewModel.h"
#import "SCUNumberPadCollectionViewCell.h"

@import Extensions;

@interface SCUNumberPadCollectionViewModel ()

@property (nonatomic) NSArray *commands;

@end

@implementation SCUNumberPadCollectionViewModel

- (instancetype)initWithCommands:(NSArray *)commands
{
    self = [super init];
    if (self)
    {
        self.commands = commands;
    }
    return self;
}

- (NSDictionary *)modelObjectWithCommand:(NSString *)command position:(NSNumber *)position
{
    return [self modelObjectWithTitle:(command) ? SCULocalizedServiceCommand(command) : nil
                             subtitle:nil
                            imageName:[self imageNameForCommandString:command]
                              command:command
                       preferredOrder:position];
}

- (NSMutableDictionary *)modelObjectWithTitle:(NSString *)title subtitle:(NSString *)subtitle imageName:(NSString *)imageName command:(NSString *)command preferredOrder:(NSNumber *)order
{
    NSMutableDictionary *modelObject = [self modelObjectWithTitle:title imageName:imageName command:command preferredOrder:order];
    
    if (subtitle && self.letterMapping)
    {
//        modelObject[SCUNumberPadCollectionViewCellSubTitleKey] = subtitle;
    }
    
    return modelObject;
}

- (void)setCommands:(NSArray *)commands
{
    [super setCommands:commands];

    self.dataSource = [self prepareData];
}

- (NSArray *)prepareData
{
    NSString *rightBottomCommand = nil;
    NSString *leftBottomCommand = nil;

    NSArray *rightBottomCommands = [self.commands filteredArrayUsingBlock:^BOOL(NSString *command) {
        BOOL keep = NO;

        if ([command containsString:@"Enter"] ||
            [command containsString:@"Pound"])
        {
            keep = YES;
        }

        return keep;
    }];

    if ([rightBottomCommands count])
    {
        rightBottomCommand = [rightBottomCommands firstObject];
    }

    NSArray *leftBottomCommands = [self.commands filteredArrayUsingBlock:^BOOL(NSString *command) {
        BOOL keep = NO;

        if ([command containsString:@"Dash"] ||
            [command containsString:@"Dot"] ||
            [command containsString:@"Point"] ||
            [command containsString:@"PlusTen"] ||
            [command containsString:@"Asterix"])
        {
            keep = YES;
        }

        return keep;
    }];

    if (leftBottomCommands)
    {
        leftBottomCommand = [leftBottomCommands firstObject];
    }

    return @[[self modelObjectWithTitle:NSLocalizedString(@"1", nil) subtitle:NSLocalizedString(@" ", nil)   imageName:nil command:@"NumberOne" preferredOrder:@1],
             [self modelObjectWithTitle:NSLocalizedString(@"2", nil) subtitle:NSLocalizedString(@"ABC", nil) imageName:nil command:@"NumberTwo" preferredOrder:@2],
             [self modelObjectWithTitle:NSLocalizedString(@"3", nil) subtitle:NSLocalizedString(@"DEF", nil) imageName:nil command:@"NumberThree" preferredOrder:@3],
             [self modelObjectWithTitle:NSLocalizedString(@"4", nil) subtitle:NSLocalizedString(@"GHI", nil) imageName:nil command:@"NumberFour" preferredOrder:@4],
             [self modelObjectWithTitle:NSLocalizedString(@"5", nil) subtitle:NSLocalizedString(@"JKL", nil) imageName:nil command:@"NumberFive" preferredOrder:@5],
             [self modelObjectWithTitle:NSLocalizedString(@"6", nil) subtitle:NSLocalizedString(@"MNO", nil) imageName:nil command:@"NumberSix" preferredOrder:@6],
             [self modelObjectWithTitle:NSLocalizedString(@"7", nil) subtitle:NSLocalizedString(@"PQRS", nil)imageName:nil command:@"NumberSeven" preferredOrder:@7],
             [self modelObjectWithTitle:NSLocalizedString(@"8", nil) subtitle:NSLocalizedString(@"TUV", nil) imageName:nil command:@"NumberEight" preferredOrder:@8],
             [self modelObjectWithTitle:NSLocalizedString(@"9", nil) subtitle:NSLocalizedString(@"WXYZ", nil) imageName:nil command:@"NumberNine" preferredOrder:@9],
             [self modelObjectWithCommand:leftBottomCommand position:@10],
             [self modelObjectWithTitle:NSLocalizedString(@"0", nil) subtitle:NSLocalizedString(@"", nil) imageName:@"" command:@"NumberZero" preferredOrder:@11],
             [self modelObjectWithCommand:rightBottomCommand position:@12]];
}

- (NSString *)imageNameForCommandString:(NSString *)command
{
    if ([command containsString:@"Dot"] || [command containsString:@"Point"])
    {
        return @"dot";
    }
    else if ([command containsString:@"Dash"])
    {
        return @"dash";
    }
    else
    {
        return [super imageNameForCommandString:command];
    }
}

- (void)setLetterMapping:(BOOL)letterMapping
{
    _letterMapping = letterMapping;
    self.dataSource = [self prepareData];
}

@end