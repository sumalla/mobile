//
//  SCUImageModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 6/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

typedef NS_OPTIONS(NSUInteger, SAVImageType)
{
    SAVImageTypeUnknown               = 1 << 0,
    SAVImageTypeLMQNowPlayingArtwork  = 1 << 1, /* ignores image size */
    SAVImageTypeLMQThumbnailArtwork   = 1 << 2, /* ignores image size */
    SAVImageTypeFavoriteImage         = 1 << 3,
    SAVImageTypeRoomImage             = 1 << 4,
    SAVImageTypeUserImage             = 1 << 5,
    SAVImageTypeSceneImage            = 1 << 6,
    SAVImageTypeHomeImage             = 1 << 7,
};

typedef NS_ENUM(NSUInteger, SAVImageSize)
{
    SAVImageSizeOriginal,
    SAVImageSizeExtraLarge, /* <= 2048 */
    SAVImageSizeLarge, /* <= 1024 */
    SAVImageSizeMedium, /* <= 512 */
    SAVImageSizeSmall /* <= 256 */
};

typedef void (^SCUImageModelCallback)(UIImage *image, BOOL isDefault);
typedef void (^SAVImageModelKeyUpdate)(NSInteger version);

extern NSString *const SAVUserDataIdentifer;

@interface SAVImageModel : NSObject

#pragma mark - Retrieving images

/**
 *  Returns the image for the given parameters, or nil.
 *
 *  @param key       The image's key.
 *  @param imageType The type of image.
 *  @param imageSize The size of the image.
 *  @param blurred   YES to blur the image; otherwise, NO.
 *
 *  @return The image for the given parameters, or nil.
 */
- (UIImage *)imageForKey:(NSString *)key
                    type:(SAVImageType)imageType
                    size:(SAVImageSize)imageSize
                 blurred:(BOOL)blurred;

/**
 *  Request an image.
 *
 *  @param key                  The image's key.
 *  @param imageType            The type of image.
 *  @param imageSize            The size of the image.
 *  @param blurred              YES to blur the image; otherwise, NO.
 *  @param requestingIdentifier Just pass self.
 *  @param componentIdentifier  Optional. A DIS app name or an avc name or some other process name.
 *  @param completionHandler    Called with an image or nil when the request completes.
 */
- (void)imageForKey:(NSString *)key
               type:(SAVImageType)imageType
               size:(SAVImageSize)imageSize
            blurred:(BOOL)blurred
requestingIdentifier:(id)requestingIdentifier
componentIdentifier:(NSString *)componentIdentifier
  completionHandler:(SCUImageModelCallback)completionHandler;

/**
 *  Request an image.
 *
 *  @param key                  The image's key.
 *  @param imageSize            The size of the image.
 *  @param blurred              YES to blur the image; otherwise, NO.
 *  @param requestingIdentifier Just pass self.
 *  @param componentIdentifier  Optional. A DIS app name or an avc name or some other process name.
 *  @param completionHandler    Called with an image or nil when the request completes.
 */
- (void)imageForFullyQualifiedKey:(NSString *)key
                             size:(SAVImageSize)imageSize
                          blurred:(BOOL)blurred
             requestingIdentifier:(id)requestingIdentifier
              componentIdentifier:(NSString *)componentIdentifier
                completionHandler:(SCUImageModelCallback)completionHandler;

/**
 *  Cancel all the current and queued image request for the given identifier. Outgoing requests will finish and be cached but the completion handlers will not be called.
 *
 *  @param requestingIdentifier Just pass self.
 */
- (void)cancelImageRequestForRequestingIdentifier:(id)requestingIdentifier;

/**
 *  Cancel every pending and current request.
 */
- (void)cancelAllRequests;

#pragma mark - Saving images to the host

/**
 *  Save an image to the host.
 *
 *  @param image The image to save.
 *  @param key   The partial key to save the image with. Varies based on the provided SAVImageType.
 *  @param type  The image type.
 *
 *  @return The fully qualified key to use when requesting images in the future.
 */
- (NSString *)saveImage:(UIImage *)image withKey:(NSString *)key type:(SAVImageType)type;

/**
 *  Remove an image from the host.
 *
 *  @param key   The key to remove.
 *  @param type  The image type.
 */
- (void)removeImageForKey:(NSString *)key andType:(SAVImageType)type;

/**
 *  Remove an image from the host.
 *
 *  @param key   The key to remove.
 */
- (void)removeImageForFullyQualifiedKey:(NSString *)key;

/**
 *  Add a generic observer to a key.
 *
 *  @param key      The key value to observe.
 *  @param size     The image size to use.
 *  @param callback The callback, with an image or nil.
 *
 *  @return An opaque object to act as the observer.
 */
- (id)addObserverForFullyQualifiedKey:(NSString *)key size:(SAVImageSize)size blurred:(BOOL)blurred andCompletionHandler:(SCUImageModelCallback)callback;

/**
 *  Add a generic observer to a key.
 *
 *  @param key      The key value to observe.
 *  @param type     The image type.
 *  @param size     The image size to use.
 *  @param callback The callback, with an image or nil.
 *
 *  @return An opaque object to act as the observer.
 */
- (id)addObserverForKey:(NSString *)key type:(SAVImageType)type size:(SAVImageSize)size blurred:(BOOL)blurred andCompletionHandler:(SCUImageModelCallback)callback;

/**
 *  Remove an observer registration.
 *
 *  @param observer An opaque observer object.
 */
- (void)removeObserver:(id)observer;

/**
 * Purge all in memory cache.
 */
- (void)purgeMemory;

/**
 *  Purge all the images.
 */
- (void)purgeCache;

@end
