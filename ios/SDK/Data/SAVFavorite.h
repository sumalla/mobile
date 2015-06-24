//
//  SAVFavorite.h
//  SavantControl
//
//  Created by Nathan Trapp on 10/17/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

@import UIKit;

typedef void (^SAVFavoriteImageChangeCallback)(UIImage *image);

@interface SAVFavorite : NSObject

+ (SAVFavorite *)favoriteWithSettings:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryRepresentation;
- (void)applySettings:(NSDictionary *)settings;

@property (nonatomic) NSString *identifier;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *number;
@property (nonatomic) NSString *imageKey;
@property (nonatomic) BOOL hasCustomImage;

@property (nonatomic, readonly) UIImage *image;

@property (nonatomic, copy) SAVFavoriteImageChangeCallback imageChangeCallback;

@end
