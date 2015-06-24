//
//  SCUButtonCollectionViewModel.m
//  SavantController
//
//  Created by Jason Wolkovitz on 4/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUButtonCollectionViewModel.h"
#import "SCUButtonCollectionViewCell.h"
#import "SCUDataSourceModelPrivate.h"

@import Extensions;

@implementation SCUButtonCollectionViewModel

- (instancetype)initWithCommands:(NSArray *)commands
{
    self = [super init];
    
    if (self)
    {
        self.commands = commands;
    }
    
    return self;
}

- (void)setCommands:(NSArray *)commands
{
    _commands = commands;

    self.dataSource = [self modelObjectsForServiceCommands:commands];
}

- (NSMutableDictionary *)modelObjectWithTitle:(NSString *)title imageName:(NSString *)imageName command:(NSString *)command preferredOrder:(NSNumber *)order
{
    NSMutableDictionary *modelObject = [NSMutableDictionary dictionary];

    if (title)
    {
        modelObject[SCUDefaultCollectionViewCellKeyTitle] = title;
    }

    if (imageName)
    {
        modelObject[SCUCollectionViewCellImageNameKey] = imageName;
    }

    if (order)
    {
        modelObject[SCUCollectionViewCellPreferredOrderKey] = order;
    }
    
    if (command)
    {
        modelObject[SCUDefaultCollectionViewCellKeyModelObject] = command;
    }

    return modelObject;
}

- (NSMutableDictionary *)modelObjectWithTitle:(NSString *)title imageName:(NSString *)imageName command:(NSUInteger)command
{
    NSMutableDictionary *modelObject = [NSMutableDictionary dictionary];
    
    if (title)
    {
        modelObject[SCUDefaultCollectionViewCellKeyTitle] = title;
    }
    
    if (imageName)
    {
        modelObject[SCUCollectionViewCellImageNameKey] = imageName;
    }
    
    modelObject[SCUDefaultCollectionViewCellKeyModelObject] = @(command);
    
    return modelObject;
}

- (NSArray *)modelObjectsForServiceCommands:(NSArray *)commands
{
    return [commands arrayByMappingBlock:^id(NSString *command) {
        return [self modelObjectForServiceCommand:command];
    }];
}

- (void)title:(out NSString *__autoreleasing*)outTitle imageName:(out NSString *__autoreleasing*)outImageName preferredOrder:(out NSNumber *__autoreleasing*)position serviceCommand:(out NSString*)serviceCommand
{
    NSString *imageName = [self imageNameForCommandString:serviceCommand];
    if (imageName)
    {
        *outImageName = imageName;
    }
    else
    {
        *outTitle = SCULocalizedServiceCommand(serviceCommand);
    }
    NSNumber *order = [self preferredOrderForCommand:serviceCommand];
    if (order && [order integerValue] > 0)
    {
        *position = order;
    }
}

#pragma mark - Methods to subclass

- (NSString *)imageNameForCommandString:(NSString *)command
{
    NSString *imageName = nil;
    if ([command hasSuffix:@".jpg"] || [command hasSuffix:@".png"] || [command hasSuffix:@".gif"])
    {
        imageName = command;
    }
    //-------------------------------------------------------------------
    // We only override specific commands to images here, as we don't want
    // to arbitrarily assign images from the asset catalog to commands
    // accidentally
    //-------------------------------------------------------------------
    else if ([command isEqualToString:@"Rewind"] ||
        [command isEqualToString:@"ScanDown"] ||
        [command isEqualToString:@"FastPlayReverse"])
    {
        imageName = @"Rewind";
    }
    else if ([command isEqualToString:@"FastForward"] ||
             [command isEqualToString:@"ScanUp"] ||
             [command isEqualToString:@"FastPlayForward"])
    {
        imageName = @"FastForward";
    }
    else if ([command isEqualToString:@"Play"])
    {
        imageName = command;
    }
    else if ([command isEqualToString:@"Pause"])
    {
        imageName = command;
    }
    else if ([command isEqualToString:@"SkipDown"])
    {
        imageName = @"Previous";
    }
    else if ([command isEqualToString:@"SkipUp"])
    {
        imageName = @"Next";
    }
    else if ([command isEqualToString:@"Replay"])
    {
        imageName = @"JumpBack";
    }
    else if ([command isEqualToString:@"30SecondSkipForward"] ||
             [command isEqualToString:@"Advance"])
    {
        imageName = @"JumpForward";
    }
    else if ([command isEqualToString:@"Stop"])
    {
        imageName = command;
    }
    else if ([command isEqualToString:@"ToggleShuffle"])
    {
        imageName = @"shuffle";
    }
    else if ([command isEqualToString:@"ToggleRepeat"])
    {
        imageName = @"repeat";
    }
    else if ([command isEqualToString:@"Eject"])
    {
        imageName = command;
    }
    else if ([command isEqualToString:@"Record"])
    {
        imageName = command;
    }
    else if ([command isEqualToString:@"CameraBrightnessDown"])
    {
        imageName = @"BrightnessDown";
    }
    else if ([command isEqualToString:@"CameraBrightnessUp"])
    {
        imageName = @"BrightnessUp";
    }
    else if ([command isEqualToString:@"CameraZoomOut"])
    {
        imageName = @"ZoomOut";
    }
    else if ([command isEqualToString:@"CameraZoomIn"])
    {
        imageName = @"ZoomIn";
    }
    else if ([command isEqualToString:kSCUCollectionViewAdditionalActionCommand])
    {
        imageName = @"VolumePlus";
    }

    return imageName;
}

- (NSNumber *)preferredOrderForCommand:(NSString *)command
{
    if ([command isEqualToString:@"someString"]) //example will remove
    {
        // some order number
    }
    return nil; //default no order
}

#pragma mark -

- (NSDictionary *)modelObjectForServiceCommand:(NSString *)command
{
    NSString *title = nil;
    NSString *imageName = nil;
    NSNumber *preferredOrder = nil;
    [self title:&title imageName:&imageName preferredOrder:&preferredOrder serviceCommand:command];
    return [self modelObjectWithTitle:title imageName:imageName command:command preferredOrder:preferredOrder];
}

@end
