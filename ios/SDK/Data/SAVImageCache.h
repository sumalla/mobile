//
//  SAVImageCache.h
//  SavantControl
//
//  Created by Nathan Trapp on 6/27/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

@import UIKit;
#import "SAVImageModel.h"

@interface SAVImageCache : NSObject

- (BOOL)imageExistsForKey:(NSString *)key andSize:(SAVImageSize)size;
- (UIImage *)imageForKey:(NSString *)key andSize:(SAVImageSize)size inflate:(BOOL)inflate;
- (UIImage *)imageForKey:(NSString *)key andSize:(SAVImageSize)size;
- (UIImage *)imageForKey:(NSString *)key;
- (BOOL)setImage:(UIImage *)image forKey:(NSString *)key andSize:(SAVImageSize)size;
- (BOOL)removeImageForKey:(NSString *)key andSize:(SAVImageSize)size;
- (BOOL)removeImageForKey:(NSString *)key;
- (void)purgeMemory;
- (void)purgeCache;
- (NSString *)pathForKey:(NSString *)key size:(SAVImageSize)size;

@end
