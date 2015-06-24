//
//  SAVImageCache.m
//  SavantControl
//
//  Created by Nathan Trapp on 6/27/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVImageCache.h"
#import "SAVControlPrivate.h"
#import "Savant.h"
@import Extensions;
@import ImageIO;

@interface SAVImageCache ()

@property NSCache *imageCache;

@end

@implementation SAVImageCache

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.imageCache = [[NSCache alloc] init];
    }
    return self;
}

- (NSString *)cacheDirectory
{
    static NSString *cacheDirectory = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cacheDirectory = [[Savant control].sharedDataPath stringByAppendingPathComponent:@"imageData"];

        if (![[NSFileManager defaultManager] fileExistsAtPath:cacheDirectory])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
        }
    });

    return cacheDirectory;
}

- (NSString *)pathForKey:(NSString *)key
{
    return [[self cacheDirectory] stringByAppendingPathComponent:key];
}

- (NSString *)key:(NSString *)key withSize:(SAVImageSize)size
{
    return [NSString stringWithFormat:@"%@.%lu.%@", [Savant control].currentSystem.hostID, (unsigned long)size, key];
}

- (BOOL)imageExistsForKey:(NSString *)key andSize:(SAVImageSize)size
{
    BOOL imageExists = NO;
    NSString *fullKey = [self key:key withSize:size];

    if ([self.imageCache objectForKey:fullKey])
    {
        imageExists = YES;
    }
    else
    {
        NSString *path = [self pathForKey:fullKey];

        if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:NULL])
        {
            imageExists = YES;
        }
    }

    return imageExists;
}

- (UIImage *)imageForKey:(NSString *)key andSize:(SAVImageSize)size inflate:(BOOL)inflate
{
    @autoreleasepool
    {
        NSParameterAssert(key);

        NSString *fullKey = [self key:key withSize:size];

        if (![self.imageCache objectForKey:fullKey])
        {
            NSString *path = [self pathForKey:fullKey];

            if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:NULL])
            {
                UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];

                if (inflate)
                {
                    UIGraphicsBeginImageContextWithOptions(image.size, YES, 0);
                    [image drawAtPoint:CGPointMake(0, 0)];
                    UIGraphicsEndImageContext();
                }

                if (image)
                {
                    [self.imageCache setObject:image forKey:fullKey];
                }
            }
        }
        
        return [self.imageCache objectForKey:fullKey];
    }
}

- (UIImage *)imageForKey:(NSString *)key andSize:(SAVImageSize)size
{
    return [self imageForKey:key andSize:size inflate:YES];
}

- (UIImage *)imageForKey:(NSString *)key
{
    NSParameterAssert(key);

    UIImage *image = nil;

    if ([self imageForKey:key andSize:SAVImageSizeOriginal])
    {
        image = [self imageForKey:key andSize:SAVImageSizeOriginal];
    }
    else if ([self imageForKey:key andSize:SAVImageSizeExtraLarge])
    {
        image = [self imageForKey:key andSize:SAVImageSizeExtraLarge];
    }
    else if ([self imageForKey:key andSize:SAVImageSizeLarge])
    {
        image = [self imageForKey:key andSize:SAVImageSizeLarge];
    }
    else if ([self imageForKey:key andSize:SAVImageSizeMedium])
    {
        image = [self imageForKey:key andSize:SAVImageSizeMedium];
    }
    else if ([self imageForKey:key andSize:SAVImageSizeSmall])
    {
        image = [self imageForKey:key andSize:SAVImageSizeSmall];
    }

    return image;
}

- (BOOL)removeImageForKey:(NSString *)key
{
    [self removeImageForKey:key andSize:SAVImageSizeOriginal];
    [self removeImageForKey:key andSize:SAVImageSizeExtraLarge];
    [self removeImageForKey:key andSize:SAVImageSizeLarge];
    [self removeImageForKey:key andSize:SAVImageSizeMedium];
    [self removeImageForKey:key andSize:SAVImageSizeSmall];
 
    return YES;
}

- (BOOL)removeImageForKey:(NSString *)key andSize:(SAVImageSize)size
{
    NSParameterAssert(key);
    
    NSString *fullKey = [self key:key withSize:size];
    
    [self.imageCache removeObjectForKey:fullKey];
    return [[NSFileManager defaultManager] removeItemAtPath:[self pathForKey:fullKey] error:NULL];
}

- (BOOL)setImage:(UIImage *)image forKey:(NSString *)key andSize:(SAVImageSize)size
{
    @autoreleasepool
    {
        BOOL success = NO;

        if (image && key)
        {
            if ([UIDevice isPad])
            {
                image = [image stripOrientation];
            }

            NSData *data = UIImageJPEGRepresentation(image, 0.85);

            if (data)
            {
                NSString *fullKey = [self key:key withSize:size];

                //-------------------------------------------------------------------
                // TODO: Purge cache occasionally.
                //-------------------------------------------------------------------
                [self.imageCache setObject:image forKey:fullKey];
                success = [data writeToFile:[self pathForKey:fullKey] atomically:YES];
            }
        }
        
        return success;
    }
}

- (NSString *)pathForKey:(NSString *)key size:(SAVImageSize)size
{
    return [self pathForKey:[self key:key withSize:size]];
}

- (void)purgeMemory
{
    [self.imageCache removeAllObjects];
}

- (void)purgeCache
{
    for (NSString *filePath in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self cacheDirectory] error:NULL])
    {
        NSString *fullPath = [[self cacheDirectory] stringByAppendingPathComponent:filePath];
        [[NSFileManager defaultManager] removeItemAtPath:fullPath error:NULL];
    }

    [self purgeMemory];
}

@end
