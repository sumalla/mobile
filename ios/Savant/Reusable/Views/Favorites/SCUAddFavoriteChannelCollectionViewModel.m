//
//  SCUAddFavoriteChannelCollectionViewModel.m
//  SavantController
//
//  Created by Stephen Silber on 10/15/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAddFavoriteChannelCell.h"
#import "SCUAddFavoriteChannelCollectionViewModel.h"
@import SDK;

@interface SCUAddFavoriteChannelCollectionViewModel ()

@property (nonatomic) NSMutableDictionary *images;

@end

@implementation SCUAddFavoriteChannelCollectionViewModel

- (instancetype)initWithCommands:(NSArray *)commands
{
    self = [super initWithCommands:commands];
    if (self)
    {
        self.images = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL)isSystemImage:(NSIndexPath *)indexPath
{
    return [self.systemImages containsObject:[self commandForIndexPath:indexPath]];
}

- (UIImage *)imageForIndexPath:(NSIndexPath *)indexPath
{
    NSString *command = [self commandForIndexPath:indexPath];

    if (!self.images[command])
    {
        SAVWeakSelf;
        [[Savant images] imageForFullyQualifiedKey:command
                                                                       size:SAVImageSizeMedium
                                                                    blurred:NO
                                                       requestingIdentifier:self
                                                        componentIdentifier:SAVUserDataIdentifer
                                                          completionHandler:^(UIImage *image, BOOL isDefault) {
                                                              SAVStrongWeakSelf;
                                                              if (image)
                                                              {
                                                                  [sSelf.images setObject:image forKey:command];
                                                              }
                                                              else
                                                              {
                                                                  [sSelf.images removeObjectForKey:command];
                                                              }

                                                              [sSelf.delegate reloadIndexPath:[sSelf indexPathForCommand:command]];
                                                          }];
    }

    return self.images[command];
}

- (NSString *)commandForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];
    return modelObject[SCUDefaultCollectionViewCellKeyModelObject];
}

- (NSIndexPath *)indexPathForCommand:(NSString *)command
{
    return [NSIndexPath indexPathForItem:[self.commands indexOfObject:command] inSection:0];
}

- (NSDictionary *)modelObjectForServiceCommand:(NSString *)command
{
    NSMutableDictionary *modelObject = [[super modelObjectForServiceCommand:command] mutableCopy];

    if ([self.systemImages containsObject:command])
    {
        [modelObject removeObjectForKey:SCUCollectionViewCellImageNameKey];
    }

    if ([command isEqualToString:kSCUCollectionViewAdditionalActionCommand])
    {
        return [modelObject dictionaryByAddingObject:@(UIViewContentModeCenter) forKey:CellImageContentMode];
    }
    
    return modelObject;
}

@end
