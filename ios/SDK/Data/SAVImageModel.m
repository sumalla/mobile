//
//  SCUImageModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 6/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SAVImageModel.h"
#import <SDK/SAVControlPrivate.h>
#import "SAVImageCache.h"
#import "rpmSharedLogger.h"
#import "SAVSettings.h"
#import "Savant.h"
@import Extensions;

NSString *const SAVUserDataIdentifer = @"userData";

static NSString *const SAVSizeStringSmall  = @"Small";
static NSString *const SAVSizeStringMedium = @"Medium";
static NSString *const SAVSizeStringLarge  = @"Large";
static NSString *const SAVSizeStringXLarge = @"XLarge";

//-------------------------------------------------------------------
// Never change the key.
//-------------------------------------------------------------------
static NSString *const SAVImageModelCacheKey = @"SAVImageModelCacheKey";

//-------------------------------------------------------------------
// Update the cache version if something major changes that warrants
// invalidating the cache.
//-------------------------------------------------------------------
static NSUInteger const SAVImageModelCacheVersion = 1;

#define IMAGE_QUEUE_DEBUGGING 0

@protocol SAVImageModelQueueItemDelegate;

@interface SAVImageModelQueueItem : NSObject

@property (nonatomic, weak) id<SAVImageModelQueueItemDelegate> delegate;
@property (nonatomic) NSString *key;
@property (nonatomic, readonly) NSString *blurredKey;
@property (nonatomic) SAVImageType imageType;
@property (nonatomic) SAVImageSize imageSize;
@property (nonatomic, weak) id requestingIdentifier;
@property (nonatomic, copy) SCUImageModelCallback callback;
@property (nonatomic, weak) NSTimer *timeoutTimer;
@property (nonatomic) NSString *componentIdentifier;
@property (nonatomic) BOOL blurred;

- (void)startTimer;

- (void)stopTimer;

@end

@protocol SAVImageModelQueueItemDelegate <NSObject>

- (void)queueItemDidTimeout:(SAVImageModelQueueItem *)item;

@end

@interface SAVImageModel () <ConnectionBinaryTransferDelegate, SAVImageModelQueueItemDelegate, StateDelegate, DISResultDelegate, SystemStatusDelegate>

@property dispatch_queue_t imageOperationQueue;
@property NSMutableArray *currentOperations;
@property NSMutableArray *pendingOperations;
@property BOOL addToQueueImmediately;
@property SAVImageCache *imageCache;
@property NSMutableDictionary *watchedKeys;
@property SAVDISRequestGenerator *disRequestGenerator;
@property (nonatomic) SAVSettings *imageVersions;
@property (nonatomic) UIImage *defaultThumbnailArtwork;

@end

@implementation SAVImageModel

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        [[Savant control] addSystemStatusObserver:self];
        [self registerStates];

        self.currentOperations = [NSMutableArray array];
        self.pendingOperations = [NSMutableArray array];
        [[Savant control] addBinaryTransferObserver:self];

        //-------------------------------------------------------------------
        // Assumptions:
        //  * The cache is (relatively) expensive to update/retrieve from.
        //
        // Requirements
        //  * No cache CRUD operations should block the main thread.
        //  * The cache must be valid (created/initialized) before we can perform operations on it.
        //
        // To meet these goals we use a serial dispatch queue.
        // The cache is free to create, so it is created immediately.
        //-------------------------------------------------------------------
        self.imageOperationQueue = dispatch_queue_create("com.savantav.Controller.imageQueue", DISPATCH_QUEUE_SERIAL);
        [self initializeCache];

        [NSUserDefaults sav_updateCacheVersion:SAVImageModelCacheVersion forKey:SAVImageModelCacheKey updateBlock:^{
            //-------------------------------------------------------------------
            // Uncomment this the next time we bump the image version.
            //-------------------------------------------------------------------
            //            [self purgeCache];
        }];
    }

    return self;
}

#pragma mark - Retrieving images

- (BOOL)cachedImageForKey:(NSString *)key
                     type:(SAVImageType)type
                     size:(SAVImageSize)size
                  blurred:(BOOL)blurred
        completionHandler:(SCUImageModelCallback)completionHandler
{
    return [self cachedImageFullQualifiedKey:[self fullyQualifiedKeyFromKey:key andType:type] size:size blurred:blurred completionHandler:completionHandler];
}

- (UIImage *)imageForKey:(NSString *)key
                    type:(SAVImageType)imageType
                    size:(SAVImageSize)imageSize
                 blurred:(BOOL)blurred
{
    NSString *fullKey = [self fullyQualifiedKeyFromKey:key andType:imageType];

    UIImage *image = nil;

    if (blurred)
    {
        NSString *blurKey = [self blurredKeyFromFullyQualifiedKey:fullKey];
        image = [self.imageCache imageForKey:blurKey andSize:imageSize inflate:NO];

        if (!image)
        {
            UIImage *nonBlurredImage = [self.imageCache imageForKey:fullKey andSize:imageSize inflate:NO];

            if (nonBlurredImage)
            {
                image = [nonBlurredImage applySavantBlur];

                [self dispatchAsyncWork:^{
                    [self.imageCache setImage:image forKey:blurKey andSize:imageSize];
                }];
            }
        }
    }
    else
    {
        image = [self.imageCache imageForKey:fullKey andSize:imageSize];
    }

    return image;
}

- (void)imageForKey:(NSString *)key
               type:(SAVImageType)imageType
               size:(SAVImageSize)imageSize
            blurred:(BOOL)blurred
requestingIdentifier:(id)requestingIdentifier
componentIdentifier:(NSString *)componentIdentifier
  completionHandler:(SCUImageModelCallback)completionHandler
{
    [self imageForFullQualifiedKey:[self fullyQualifiedKeyFromKey:key andType:imageType]
                              type:imageType
                              size:imageSize
                           blurred:blurred
              requestingIdentifier:requestingIdentifier
               componentIdentifier:componentIdentifier
                 completionHandler:completionHandler];
}

- (void)imageForFullyQualifiedKey:(NSString *)key
                             size:(SAVImageSize)imageSize
                          blurred:(BOOL)blurred
             requestingIdentifier:(id)requestingIdentifier
              componentIdentifier:(NSString *)componentIdentifier
                completionHandler:(SCUImageModelCallback)completionHandler
{
    [self imageForFullQualifiedKey:key
                              type:[self imageTypeForFullyQualifiedKey:key]
                              size:imageSize
                           blurred:blurred
              requestingIdentifier:requestingIdentifier
               componentIdentifier:componentIdentifier
                 completionHandler:completionHandler];
}

- (void)cancelImageRequestForRequestingIdentifier:(id)requestingIdentifier
{
    NSParameterAssert(requestingIdentifier);

    [self dispatchAsyncWork:^{
        for (SAVImageModelQueueItem *item in self.currentOperations)
        {
            if (item.requestingIdentifier == requestingIdentifier)
            {
                item.delegate = nil;
                [item stopTimer];
                item.callback = NULL;
            }
        }

        [self.pendingOperations filterArrayUsingBlock:^BOOL(SAVImageModelQueueItem *item) {
            return item.requestingIdentifier != requestingIdentifier;
        }];
    }];
}

- (void)cancelAllRequests
{
    [self dispatchAsyncWork:^{
        [self.currentOperations removeAllObjects];
        [self.pendingOperations removeAllObjects];
    }];
}

#pragma mark - Saving images to the host

- (NSString *)saveImage:(UIImage *)image withKey:(NSString *)key type:(SAVImageType)type
{
    //-------------------------------------------------------------------
    // This method does not need to be run on the background queue.
    //-------------------------------------------------------------------
    NSParameterAssert(image);
    NSParameterAssert(key);

    NSString *fullKey = nil;
    NSString *uri = nil;
    BOOL isGlobal = YES;

    switch (type)
    {
        case SAVImageTypeUnknown:
        case SAVImageTypeLMQNowPlayingArtwork:
        case SAVImageTypeLMQThumbnailArtwork:
        {
            break;
        }
        case SAVImageTypeFavoriteImage:
        {
            uri = @"dis/userData";
            fullKey = [NSString stringWithFormat:@"favorites.%@", [[NSUUID UUID] UUIDString]];
            isGlobal = NO;
            break;
        }
        case SAVImageTypeRoomImage:
        {
            uri = @"dis/userData";
            fullKey = [NSString stringWithFormat:@"room.%@", key];
            break;
        }
        case SAVImageTypeSceneImage:
        {
            uri = @"dis/userData";
            fullKey = [NSString stringWithFormat:@"scene.%@", key];
            isGlobal = NO;
            break;
        }
        case SAVImageTypeUserImage:
        {
            uri = @"dis/userData";
            fullKey = [NSString stringWithFormat:@"user.%@", key];
            break;
        }
        case SAVImageTypeHomeImage:
        {
            uri = @"dis/userData";
            fullKey = [NSString stringWithFormat:@"home"];
            break;
        }
    }

    [self dispatchAsyncWork:^{
        [self.imageCache removeImageForKey:fullKey];
        [self.imageCache setImage:image forKey:fullKey andSize:SAVImageSizeOriginal];

        [self.imageVersions removeObjectForKey:[self scopedKeyForKey:fullKey isGlobal:isGlobal]];
        [self.imageVersions synchronize];

        [self watchedKeyChanged:fullKey toVersion:@(-2)];

        if (uri && fullKey)
        {
            NSData *data = UIImageJPEGRepresentation(image, .85);

            NSDictionary *payload = @{@"key": fullKey, @"global": @(isGlobal), @"request": @"SaveImage"};

            dispatch_async(dispatch_get_main_queue(), ^{
                SAVBinaryTransfer *binaryTransfer = [[SAVBinaryTransfer alloc] initWithData:data uri:uri payload:payload];
                [[Savant control] sendMessage:binaryTransfer];
            });
        }
    }];

    return fullKey;
}

- (void)removeImageForKey:(NSString *)key andType:(SAVImageType)type
{
    [self removeImageForFullyQualifiedKey:[self fullyQualifiedKeyFromKey:key andType:type]];
}

- (void)removeImageForFullyQualifiedKey:(NSString *)key
{
    //-------------------------------------------------------------------
    // This method does not need to be run on the background queue.
    //-------------------------------------------------------------------
    NSParameterAssert(key);

    BOOL isGlobal = YES;
    BOOL removeable = NO;

    switch ([self imageTypeForFullyQualifiedKey:key])
    {
        case SAVImageTypeUnknown:
        case SAVImageTypeLMQNowPlayingArtwork:
        case SAVImageTypeLMQThumbnailArtwork:
        {
            break;
        }
        case SAVImageTypeUserImage:
        case SAVImageTypeRoomImage:
        case SAVImageTypeHomeImage:
        {
            removeable = YES;
            break;
        }
        case SAVImageTypeSceneImage:
        case SAVImageTypeFavoriteImage:
        {
            isGlobal = NO;
            removeable = YES;
            break;
        }
    }

    if (removeable)
    {
        [self.imageCache removeImageForKey:key];
        [self.imageCache removeImageForKey:[self blurredKeyFromFullyQualifiedKey:key]];
        [self watchedKeyChanged:key toVersion:@(-1)];

        SAVDISRequest *request = [self.disRequestGenerator request:@"DeleteImage" withArguments:@{@"key": key, @"global": @(isGlobal)}];
        [[Savant control] sendMessage:request];
    }
}

#pragma mark - ConnectionBinaryTransferDelegate

- (NSString *)filePathForBinaryTransferWithIdentifier:(id)identifier
{
    __block NSString *filePath = nil;

    [self dispatchSyncWork:^{
        SAVImageModelQueueItem *item = [self itemForIdentifier:identifier inCurrentQueue:YES];

        if (item.imageType == SAVImageTypeRoomImage
            || item.imageType == SAVImageTypeHomeImage)
        {
            filePath = [[self.imageCache pathForKey:item.key size:item.imageSize] stringByAppendingPathExtension:@"savTempPath"];
        }
    }];

    return filePath;
}

- (void)didStartBinaryTransferForIdentifier:(id)identifier withSize:(NSUInteger)size
{
    [self dispatchAsyncWork:^{
        if ([self itemForIdentifier:identifier inCurrentQueue:YES])
        {
            [self startNextOperation];
        }
    }];
}

- (void)didFinishBinaryTransferWithFilePath:(NSString *)filePath forIdentifier:(id)identifier
{
    [self dispatchAsyncWork:^{
        SAVImageModelQueueItem *item = [self itemForIdentifier:identifier inCurrentQueue:YES];
        item.delegate = nil;
        [item stopTimer];

        NSString *realFilePath = [filePath stringByReplacingOccurrencesOfString:@".savTempPath" withString:@""];

        NSError *error = nil;
        BOOL moveSuccess = [[NSFileManager defaultManager] moveItemAtPath:filePath toPath:realFilePath error:&error];

        if (!moveSuccess)
        {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
            RPMLogErr(@"Error with file at path %@ -- %@", realFilePath, error);
        }

        if (item.key && moveSuccess)
        {
            UIImage *image = [self.imageCache imageForKey:item.key andSize:item.imageSize];

            if (image)
            {
                if ([identifier isKindOfClass:[NSDictionary class]])
                {
                    BOOL global = [[identifier objectForKey:@"global"] boolValue];
                    NSNumber *version = [identifier objectForKey:@"version"];

                    if (version)
                    {
                        [self.imageVersions setObject:version forKey:[self scopedKeyForKey:item.key isGlobal:global]];
                        [self.imageVersions synchronize];

                        [self watchedKeyChanged:item.key toVersion:version];
                    }
                }

                SCUImageModelCallback callback = item.callback;

                if (callback && image)
                {
                    dispatch_async_main(^{
                        callback(image, NO);
                    });
                }
            }
            else
            {
                RPMLogErr(@"Couldn't load file at path %@", realFilePath);
            }
        }
        
        [self.currentOperations removeObject:item];
    }];
}

- (void)didFinishBinaryTransferWithData:(NSData *)data forIdentifier:(id)identifier
{
    [self dispatchAsyncWork:^{
        SAVImageModelQueueItem *item = [self itemForIdentifier:identifier inCurrentQueue:YES];
        item.delegate = nil;
        [item stopTimer];

        UIImage *image = nil;
        BOOL isDefault = NO;

        if ([data length])
        {
            image = [UIImage imageWithData:data];

            if (item.imageType == SAVImageTypeLMQThumbnailArtwork)
            {
                image = [image scaleToSize:CGSizeMake(100, 100)];
            }

            //-------------------------------------------------------------------
            // Cache the image data
            //-------------------------------------------------------------------
            if (item.key && image)
            {
                [self.imageCache removeImageForKey:item.key andSize:SAVImageSizeOriginal];
                [self.imageCache setImage:image forKey:item.key andSize:item.imageSize];

                if (item.blurred)
                {
                    UIImage *blurredImage = [image applySavantBlur];
                    NSString *blurredKey = [self blurredKeyFromFullyQualifiedKey:item.key];
                    [self.imageCache removeImageForKey:blurredKey andSize:SAVImageSizeOriginal];
                    [self.imageCache setImage:blurredImage forKey:blurredKey andSize:item.imageSize];

                    if (item.callback && blurredImage)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            item.callback(blurredImage, isDefault);
                        });
                    }
                }
                else
                {
                    if (item.callback && image)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            item.callback(image, isDefault);
                        });
                    }
                }

                if ([identifier isKindOfClass:[NSDictionary class]])
                {
                    BOOL global = [[identifier objectForKey:@"global"] boolValue];
                    NSNumber *version = [identifier objectForKey:@"version"];

                    if (version)
                    {
                        [self.imageVersions setObject:version forKey:[self scopedKeyForKey:item.key isGlobal:global]];
                        [self.imageVersions synchronize];

                        [self watchedKeyChanged:item.key toVersion:version];
                    }
                }
            }
        }
        else
        {
            image = [self defaultImageForImageType:item.imageType size:item.imageSize];

            if (image)
            {
                isDefault = YES;
            }

            if (item.callback && image)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    item.callback(image, isDefault);
                });
            }
        }

        [self.currentOperations removeObject:item];
    }];
}

#pragma mark - SAVImageModelQueueItemDelegate

- (void)queueItemDidTimeout:(SAVImageModelQueueItem *)item
{
    [self dispatchAsyncWork:^{
        [self didFinishBinaryTransferWithData:nil forIdentifier:item.key];
        [self startNextOperation];;
    }];
}

#pragma mark -

- (BOOL)cachedImageFullQualifiedKey:(NSString *)key size:(SAVImageSize)imageSize blurred:(BOOL)blurred completionHandler:(SCUImageModelCallback)completionHandler
{
    BOOL hasImage = [self.imageCache imageExistsForKey:key andSize:imageSize];

    [self dispatchAsyncWork:^{
        UIImage *image = [self.imageCache imageForKey:key andSize:imageSize];

        if (image)
        {
            if (blurred)
            {
                NSString *blurredKey = [self blurredKeyFromFullyQualifiedKey:key];
                UIImage *blurredImage = [self.imageCache imageForKey:blurredKey andSize:imageSize];

                if (blurredImage)
                {
                    image = blurredImage;
                }
                else
                {
                    image = [image applySavantBlur];
                    [self.imageCache setImage:image forKey:blurredKey andSize:imageSize];
                }
            }

            dispatch_async_main(^{
                completionHandler(image, NO);
            });
        }
    }];

    return hasImage;
}

- (void)imageForFullQualifiedKey:(NSString *)key type:(SAVImageType)imageType size:(SAVImageSize)imageSize blurred:(BOOL)blurred requestingIdentifier:(id)requestingIdentifier componentIdentifier:(NSString *)componentIdentifier completionHandler:(SCUImageModelCallback)completionHandler
{
    if (![key length])
    {
        if (completionHandler)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler([self defaultImageForImageType:imageType size:imageSize], YES);
            });
        }

        return;
    }

    NSParameterAssert([key length]);
    NSParameterAssert(requestingIdentifier);
    NSParameterAssert(completionHandler);

    //-------------------------------------------------------------------
    // Check for cached image
    //-------------------------------------------------------------------
    if (![self cachedImageFullQualifiedKey:key size:imageSize blurred:blurred completionHandler:completionHandler])
    {
        [self dispatchAsyncWork:^{
            SAVImageModelQueueItem *item = [[SAVImageModelQueueItem alloc] init];
            item.key = key;
            item.imageType = imageType;
            item.imageSize = imageSize;
            item.requestingIdentifier = requestingIdentifier;
            item.callback = completionHandler;
            item.componentIdentifier = componentIdentifier;
            item.blurred = blurred;

            BOOL addToQueue = NO;

            if (self.addToQueueImmediately)
            {
                //-------------------------------------------------------------------
                // Something was asked to be queued previously but nothing was available.
                //-------------------------------------------------------------------
                self.addToQueueImmediately = NO;
                addToQueue = YES;
            }
            else if (![self.currentOperations count])
            {
                //-------------------------------------------------------------------
                // Nothing is in progress so start immediately.
                //-------------------------------------------------------------------
                addToQueue = YES;
            }

            if (addToQueue)
            {
                [self addItemToQueue:item];
            }
            else
            {
                [self.pendingOperations addObject:item];
            }
        }];
    }
}

- (NSString *)fullyQualifiedKeyFromKey:(NSString *)key andType:(SAVImageType)imageType
{
    NSParameterAssert(imageType != SAVImageTypeUnknown);

    NSString *fullKey = nil;

    switch (imageType)
    {
        case SAVImageTypeUnknown:
            break;
        case SAVImageTypeLMQNowPlayingArtwork:
        case SAVImageTypeLMQThumbnailArtwork:
        {
            fullKey = key;
            break;
        }
        case SAVImageTypeFavoriteImage:
        {
            fullKey = [NSString stringWithFormat:@"favorites.%@", [[NSUUID UUID] UUIDString]];
            break;
        }
        case SAVImageTypeRoomImage:
        {
            fullKey = [NSString stringWithFormat:@"room.%@", key];
            break;
        }
        case SAVImageTypeSceneImage:
        {
            fullKey = [NSString stringWithFormat:@"scene.%@", key];
            break;
        }
        case SAVImageTypeUserImage:
        {
            fullKey = [NSString stringWithFormat:@"user.%@", key];
            break;
        }
        case SAVImageTypeHomeImage:
        {
            fullKey = [NSString stringWithFormat:@"home"];
            break;
        }
    }

    return fullKey;
}

- (NSString *)blurredKeyFromFullyQualifiedKey:(NSString *)key
{
    NSString *blurredKey = nil;

    if (key)
    {
        blurredKey = [@"blurred." stringByAppendingString:key];
    }

    return blurredKey;
}

- (SAVImageType)imageTypeForFullyQualifiedKey:(NSString *)key
{
    SAVImageType imageType = SAVImageTypeUnknown;

    if ([key hasPrefix:@"favorite"])
    {
        imageType = SAVImageTypeFavoriteImage;
    }
    else if ([key hasPrefix:@"room"])
    {
        imageType = SAVImageTypeRoomImage;
    }
    else if ([key hasPrefix:@"home"])
    {
        imageType = SAVImageTypeHomeImage;
    }
    else if ([key hasPrefix:@"user"])
    {
        imageType = SAVImageTypeUserImage;
    }
    else if ([key hasPrefix:@"scene"])
    {
        imageType = SAVImageTypeSceneImage;
    }

    return imageType;
}

- (NSString *)sizeStringForImageSize:(SAVImageSize)imageSize
{
    NSString *sizeString = nil;

    switch (imageSize)
    {
        case SAVImageSizeExtraLarge:
            sizeString = SAVSizeStringXLarge;
            break;
        case SAVImageSizeLarge:
            sizeString = SAVSizeStringLarge;
            break;
        case SAVImageSizeMedium:
            sizeString = SAVSizeStringMedium;
            break;
        case SAVImageSizeSmall:
            sizeString = SAVSizeStringSmall;
            break;
        default:
            break;
    }

    return sizeString;
}

- (void)startNextOperation
{
    [self debugQueue];

    //-------------------------------------------------------------------
    // A transfer has started, pull off and enqueue the next item. We use
    // a FILO queue.
    //-------------------------------------------------------------------
    if ([self.pendingOperations count])
    {
        SAVImageModelQueueItem *item = [self.pendingOperations lastObject];
        [self.pendingOperations removeLastObject];
        [self addItemToQueue:item];
    }
    else
    {
        //-------------------------------------------------------------------
        // There is nothing queued, set this flag so the next transfer that is
        // added is started immediately.
        //-------------------------------------------------------------------
        self.addToQueueImmediately = YES;
    }
}

- (void)addItemToQueue:(SAVImageModelQueueItem *)item
{
    [self debugQueue];

    // skip this, it's already going
    if ([self.currentOperations containsObject:item])
    {
        [self startNextOperation];
        return;
    }

    //-------------------------------------------------------------------
    // Format the request here.
    //-------------------------------------------------------------------
    [self.currentOperations addObject:item];
    item.delegate = self;

    dispatch_async_main(^{
        SAVMessage *message = [self messageForItem:item];
        [[Savant control] sendMessage:message];
        [item startTimer];
    });
}

- (SAVMessage *)messageForItem:(SAVImageModelQueueItem *)item
{
    NSParameterAssert(item.imageType != SAVImageTypeUnknown);

    SAVMessage *message = nil;

    switch (item.imageType)
    {
        case SAVImageTypeUnknown:
            break;
        case SAVImageTypeLMQNowPlayingArtwork:
        {
            SAVFileRequest *request = [[SAVFileRequest alloc] init];
            request.fileURI = [NSString stringWithFormat:@"avc/%@", item.componentIdentifier];
            request.payload = @{@"key": item.key, @"type": SAVMESSAGE_FILETYPE_NOWPLAYING_ARTWORK};
            message = request;
            break;
        }
        case SAVImageTypeLMQThumbnailArtwork:
        {
            SAVFileRequest *request = [[SAVFileRequest alloc] init];
            request.fileURI = [NSString stringWithFormat:@"avc/%@", item.componentIdentifier];
            request.payload = @{@"key": item.key, @"type": SAVMESSAGE_FILETYPE_THUMBNAIL_ARTWORK};
            message = request;
            break;
        }
        case SAVImageTypeFavoriteImage:
        case SAVImageTypeRoomImage:
        case SAVImageTypeSceneImage:
        case SAVImageTypeUserImage:
        case SAVImageTypeHomeImage:
        {
            SAVFileRequest *request = [[SAVFileRequest alloc] init];
            request.fileURI = [NSString stringWithFormat:@"dis/%@", item.componentIdentifier];

            NSMutableDictionary *payload = [NSMutableDictionary dictionaryWithDictionary:@{@"key": item.key, @"request": @"FetchImage"}];

            //-------------------------------------------------------------------
            // TODO: Add in scaling support when the backend is fixed.
            //-------------------------------------------------------------------
            if ([self sizeStringForImageSize:item.imageSize])
            {
                payload[@"size"] = [self sizeStringForImageSize:item.imageSize];
            }

            if (item.imageType == SAVImageTypeRoomImage ||
                item.imageType == SAVImageTypeUserImage ||
                item.imageType == SAVImageTypeHomeImage)
            {
                payload[@"global"] = @(1);
            }
            else if (item.imageType == SAVImageTypeFavoriteImage &&
                     [item.key containsString:@".bpImage."])
            {
                payload[@"global"] = @(1);
            }

            request.payload = payload;

            message = request;
            break;
        }
    }

    if (!message)
    {
        [NSException raise:NSInternalInconsistencyException format:@"Message must not be nil"];
    }

    return message;
}

- (SAVImageModelQueueItem *)itemForIdentifier:(id)identifier inCurrentQueue:(BOOL)inCurrentQueue
{
    [self debugQueue];

    SAVImageModelQueueItem *itemForIdentifier = nil;

    for (SAVImageModelQueueItem *item in inCurrentQueue ? self.currentOperations : self.pendingOperations)
    {
        NSString *key = nil;

        if ([identifier isKindOfClass:[NSDictionary class]])
        {
            key = [identifier objectForKey:@"key"];
        }
        else if ([identifier isKindOfClass:[NSString class]])
        {
            key = identifier;
        }

        if ([item.key isEqual:key])
        {
            itemForIdentifier = item;
            break;
        }
    }

    return itemForIdentifier;
}

- (UIImage *)defaultImageForImageType:(SAVImageType)imageType size:(SAVImageSize)imageSize
{
    UIImage *image = nil;

    switch (imageType)
    {
        case SAVImageTypeUnknown:
            break;
        case SAVImageTypeLMQNowPlayingArtwork:
            image = [UIImage imageNamed:@"No_Album_Art"];
            break;
        case SAVImageTypeLMQThumbnailArtwork:
        {
            if (!self.defaultThumbnailArtwork)
            {
                self.defaultThumbnailArtwork = [[UIImage imageNamed:@"No_Album_Art"] scaleToSize:CGSizeMake(100, 100)];
            }

            image = self.defaultThumbnailArtwork;

            break;
        }
        case SAVImageTypeFavoriteImage:
        case SAVImageTypeRoomImage:
        case SAVImageTypeUserImage:
        case SAVImageTypeSceneImage:
        case SAVImageTypeHomeImage:
            break;
    }

    return image;
}

- (void)initializeCache
{
    self.imageCache = [[SAVImageCache alloc] init];
}

- (void)dispatchAsyncWork:(dispatch_block_t)work
{
    dispatch_async(self.imageOperationQueue, ^{
        @autoreleasepool
        {
            work();
        }
    });
}

- (void)dispatchSyncWork:(dispatch_block_t)work
{
    dispatch_sync(self.imageOperationQueue, ^{
        @autoreleasepool
        {
            work();
        }
    });
}

- (void)debugQueue
{
#if IMAGE_QUEUE_DEBUGGING
    //-------------------------------------------------------------------
    // Assume we are on the imageOperationQueue.
    //
    // dispatch_get_current_queue() is deprecated but still useful for
    // debugging.
    //-------------------------------------------------------------------
    assert(dispatch_get_current_queue() == self.imageOperationQueue);
#endif
}

#pragma mark - Key Observeration

- (id)addObserverForFullyQualifiedKey:(NSString *)key size:(SAVImageSize)size blurred:(BOOL)blurred andCompletionHandler:(SCUImageModelCallback)callback
{
    SAVWeakSelf;
    [self imageForFullyQualifiedKey:key size:size blurred:blurred requestingIdentifier:self componentIdentifier:SAVUserDataIdentifer completionHandler:callback];

    return [self addObserverForFullyQualifiedKey:key usingBlock:^(NSInteger version) {
        SAVStrongWeakSelf;
        if (version == -2)
        {
            [sSelf cachedImageFullQualifiedKey:key size:size blurred:blurred completionHandler:callback];
        }
        else if (version == -1)
        {
            callback(nil, NO);
        }
        else
        {
            [sSelf imageForFullyQualifiedKey:key size:size blurred:blurred requestingIdentifier:sSelf componentIdentifier:SAVUserDataIdentifer completionHandler:callback];
        }
    }];
}

- (id)addObserverForKey:(NSString *)key type:(SAVImageType)type size:(SAVImageSize)size blurred:(BOOL)blurred andCompletionHandler:(SCUImageModelCallback)callback
{
    return [self addObserverForFullyQualifiedKey:[self fullyQualifiedKeyFromKey:key andType:type]
                                            size:size
                                         blurred:blurred
                            andCompletionHandler:callback];
}

- (id)addObserverForFullyQualifiedKey:(NSString *)key usingBlock:(SAVImageModelKeyUpdate)block
{
    NSMutableDictionary *blocks = self.watchedKeys[key];

    if (!self.watchedKeys)
    {
        self.watchedKeys = [NSMutableDictionary dictionary];
    }

    if (!blocks)
    {
        blocks = [NSMutableDictionary dictionary];
        self.watchedKeys[key] = blocks;
    }

    NSString *ident = [[NSUUID UUID] UUIDString];

    blocks[ident] = block;

    return ident;
}

- (id)addObserverForKey:(NSString *)key type:(SAVImageType)type usingBlock:(SAVImageModelKeyUpdate)block
{
    return [self addObserverForFullyQualifiedKey:[self fullyQualifiedKeyFromKey:key andType:type] usingBlock:block];;
}

- (void)removeObserver:(id)observer
{
    if (observer)
    {
        for (NSString *key in [self.watchedKeys copy])
        {
            NSMutableDictionary *blocks = self.watchedKeys[key];
            [blocks removeObjectForKey:observer];

            if (![blocks count])
            {
                [self.watchedKeys removeObjectForKey:key];
            }
        }
    }
}

- (void)purgeMemory
{
    [self dispatchAsyncWork:^{
        [self.imageCache purgeMemory];
    }];
}

- (void)purgeCache
{
    [self dispatchAsyncWork:^{
        [self.imageCache purgeCache];
    }];
}

- (void)watchedKeyChanged:(NSString *)key toVersion:(NSNumber *)version
{
    if (self.watchedKeys[key])
    {
        NSDictionary *blocks = self.watchedKeys[key];
        for (SAVImageModelKeyUpdate block in [blocks allValues])
        {
            block([version integerValue]);
        }
    }
}

#pragma mark - States

- (NSDictionary *)stateNames
{
    NSString *suffix = @".image.update";

    return @{[@"global" stringByAppendingString:suffix]: NSStringFromSelector(@selector(handleSettingsUpdate:isGlobal:)),
             [@"user" stringByAppendingString:suffix]: NSStringFromSelector(@selector(handleSettingsUpdate:isGlobal:))};
}

- (void)handleSettingsUpdate:(NSDictionary *)update isGlobal:(BOOL)global
{
    [self dispatchAsyncWork:^{
        for (NSString *key in update)
        {
            NSString *scopedKey = [self scopedKeyForKey:key isGlobal:global];

            NSNumber *version = update[key];
            NSNumber *currentVersion = [self.imageVersions objectForKey:scopedKey];

            if (![version isEqual:currentVersion])
            {
                if (currentVersion)
                {
                    [self.imageCache removeImageForKey:key];
                    [self.imageCache removeImageForKey:[self blurredKeyFromFullyQualifiedKey:key]];

                    [self.imageVersions removeObjectForKey:scopedKey];
                    [self.imageVersions synchronize];
                }

                dispatch_async_main(^{
                    [self watchedKeyChanged:key toVersion:version];
                });
            }
        }
    }];
}

- (NSString *)scopedKeyForKey:(NSString *)key isGlobal:(BOOL)global
{
    return global ? [@"global." stringByAppendingString:key] : [@"user." stringByAppendingString:key];
}

#pragma mark - StateDelegate

- (void)didReceiveDISFeedback:(SAVDISFeedback *)feedback
{
    SEL selector = NSSelectorFromString([self stateNames][feedback.state]);

    if (selector)
    {
        SAVFunctionForSelector(function, self, selector, void, NSDictionary *, BOOL);
        function(self, selector, feedback.value, [feedback.state hasPrefix:@"global"]);
    }
}

- (void)disRequestDidCompleteWithResults:(SAVDISResults *)results
{
    if ([results.request isEqualToString:@"FetchImage"])
    {
        NSString *key = results.results[@"key"];
        BOOL global = [results.results[@"global"] boolValue];
        NSNumber *version = results.results[@"version"];
        NSString *path = results.results[@"path"];
        //        SAVImageSize size = [results.results[@"size"] integerValue];

        [self dispatchAsyncWork:^{
            if ([self itemForIdentifier:key inCurrentQueue:YES])
            {
                [self startNextOperation];
            }
        }];

        if (path && key)
        {
            [self dispatchAsyncWork:^{
                if ([[NSFileManager defaultManager] fileExistsAtPath:path])
                {
                    UIImage *image = [UIImage imageWithContentsOfFile:path];

                    SAVImageModelQueueItem *item = [self itemForIdentifier:key inCurrentQueue:YES];
                    item.delegate = nil;
                    [item stopTimer];

                    if (item.key && image)
                    {
                        [self.imageCache removeImageForKey:item.key andSize:SAVImageSizeOriginal];
                        [self.imageCache setImage:image forKey:item.key andSize:item.imageSize];

                        if (version)
                        {
                            [self.imageVersions setObject:version forKey:[self scopedKeyForKey:item.key isGlobal:global]];
                            [self.imageVersions synchronize];

                            [self watchedKeyChanged:item.key toVersion:version];
                        }
                    }

                    SCUImageModelCallback callback = item.callback;

                    if (callback && image)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            callback(image, NO);
                        });
                    }

                    [self.currentOperations removeObject:item];
                }
            }];
        }
    }
}

#pragma mark - SystemStatusDelegate

- (void)connectionIsReady
{
    self.currentOperations = [NSMutableArray array];
    self.pendingOperations = [NSMutableArray array];

    [self registerStates];
}

- (void)registerStates
{
    if ([Savant control].controlMode & SAVControlModeImageStates)
    {
        //-------------------------------------------------------------------
        // Register for image update states
        //-------------------------------------------------------------------
        [[Savant control] addDISResultObserver:self forApp:SAVUserDataIdentifer];
        self.disRequestGenerator = [[SAVDISRequestGenerator alloc] initWithApp:SAVUserDataIdentifer];
        NSArray *states = [self.disRequestGenerator feedbackStringsWithStateNames:[[self stateNames] allKeys]];
        [[Savant states] registerForStates:states forObserver:self];
        self.imageVersions = [[SAVSettings alloc] initWithDomain:@"imageVersions"];
    }
}

@end

#pragma mark - SAVImageModelQueueItem

@implementation SAVImageModelQueueItem

- (void)dealloc
{
    [self.timeoutTimer invalidate];
}

- (void)startTimer
{
    SAVWeakSelf;
    self.timeoutTimer = [NSTimer sav_scheduledBlockWithDelay:[self timeout] block:^{
        SAVStrongWeakSelf;
        [sSelf.delegate queueItemDidTimeout:sSelf];
    }];
}

- (void)stopTimer
{
    [self.timeoutTimer invalidate];
}

- (NSTimeInterval)timeout
{
    NSTimeInterval timeout = 15;

    switch (self.imageType)
    {
        case SAVImageTypeUnknown:
        case SAVImageTypeLMQThumbnailArtwork:
            timeout = 1;
            break;
        case SAVImageTypeLMQNowPlayingArtwork:
            timeout = 4;
            break;
        case SAVImageTypeFavoriteImage:
        case SAVImageTypeRoomImage:
        case SAVImageTypeHomeImage:
        case SAVImageTypeSceneImage:
        case SAVImageTypeUserImage:
            break;
    }
    
    return timeout;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[SAVImageModelQueueItem class]])
    {
        return [self isEqualToItem:(SAVImageModelQueueItem *)object];
    }

    return NO;
}

- (NSString *)blurredKey
{
    NSString *blurredKey = nil;

    if (self.key)
    {
        blurredKey = [@"blurred." stringByAppendingString:self.key];
    }

    return blurredKey;
}

- (BOOL)isEqualToItem:(SAVImageModelQueueItem *)item
{
    BOOL key = [self.key isEqualToString:item.key];
    BOOL type = self.imageType == item.imageType;
    BOOL size = self.imageSize == item.imageSize;
    BOOL identifier = [self.requestingIdentifier isEqual:item.requestingIdentifier];
    BOOL component = [self.componentIdentifier isEqualToString:item.componentIdentifier];

    return key && type && size && identifier && component;
}

@end
