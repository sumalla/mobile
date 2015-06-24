//
//  SAVFavorite.m
//  SavantControl
//
//  Created by Nathan Trapp on 10/17/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVFavorite.h"
#import "Savant.h"
#import "SAVControl.h"
@import Extensions;

@interface SAVFavorite () <NSCopying>

@property (nonatomic) UIImage *image;
@property (nonatomic) id imageObserver;

@end

@implementation SAVFavorite

+ (SAVFavorite *)favoriteWithSettings:(NSDictionary *)dictionary
{
    SAVFavorite *favorite = [[[self class] alloc] init];
    [favorite applySettings:dictionary];

    return favorite;
}

- (id)copyWithZone:(NSZone *)zone
{
    SAVFavorite *favorite = [SAVFavorite favoriteWithSettings:[self dictionaryRepresentation]];

    return favorite;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    [dict setValue:self.identifier forKey:@"id"];
    [dict setValue:self.imageKey forKey:@"imageRef"];
    if (self.imageKey)
    {
        [dict setObject:@(self.hasCustomImage) forKey:@"hasCustomImage"];
    }
    [dict setValue:self.name forKey:@"channelDescription"];
    [dict setValue:self.number forKey:@"channelNumber"];

    return [dict copy];
}

- (void)applySettings:(NSDictionary *)settings
{
    self.identifier = settings[@"id"];
    self.name = settings[@"channelDescription"];
    self.hasCustomImage = [settings[@"hasCustomImage"] boolValue];
    self.imageKey = settings[@"imageRef"];
    self.number = settings[@"channelNumber"];
}

- (void)dealloc
{
    [[Savant images] removeObserver:self.imageObserver];
}

- (void)setImageKey:(NSString *)imageKey
{
    if (_imageKey != imageKey)
    {
        _imageKey = imageKey;

        [[Savant images] removeObserver:self.imageObserver];

        if (self.hasCustomImage)
        {
            SAVWeakSelf;
            self.imageObserver = [[Savant images] addObserverForFullyQualifiedKey:imageKey size:SAVImageSizeMedium blurred:NO andCompletionHandler:^(UIImage *image, BOOL isDefault) {
                SAVStrongWeakSelf;
                sSelf.image = image;

                if (sSelf.imageChangeCallback)
                {
                    sSelf.imageChangeCallback(image);
                }
            }];
        }
        else
        {
            self.image = [UIImage sav_imageNamed:imageKey];

            if (self.imageChangeCallback)
            {
                self.imageChangeCallback(self.image);
            }
        }
    }
}

@end
