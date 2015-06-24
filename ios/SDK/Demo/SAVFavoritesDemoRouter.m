//
//  SAVFavoriteDemoRouter.m
//  SavantControl
//
//  Created by Nathan Trapp on 10/17/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVFavoritesDemoRouter.h"
#import "SAVFavorite.h"
#import "Savant.h"
#import "SAVControlPrivate.h"

@import Extensions;

static NSString *const SAVFavorite_UpdateFavorite    = @"UpdateFavorite";
static NSString *const SAVFavorite_CreateFavorite    = @"CreateFavorite";
static NSString *const SAVFavorite_RemoveFavorite    = @"RemoveFavorite";

static NSString *const SAVFavorite_State_Favorites   = @"favorites.";

static NSString *const SAVFavoriteIDKey     = @"id";

@interface SAVFavoritesDemoRouter ()

@property NSMutableDictionary *favorites;
@property NSString *registeredServiceType;

@end

@implementation SAVFavoritesDemoRouter

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self generateDemoFavorites];
    }
    return self;
}

- (BOOL)handleDISRequest:(SAVDISRequest *)request
{
    BOOL shouldHandle = NO;

    id response = nil;

    if ([request.request isEqualToString:@"register"])
    {
        NSString *state = request.arguments[SAVMESSAGE_STATE_KEY];

        if ([state hasPrefix:SAVFavorite_State_Favorites])
        {
            self.registeredServiceType = [state stringByReplacingOccurrencesOfString:SAVFavorite_State_Favorites withString:@""];
            response = [self fetchFavoritesList];
        }
    }
    else if ([request.request isEqualToString:SAVFavorite_CreateFavorite])
    {
        response = [self addFavorite:request.arguments];
    }
    else if ([request.request isEqualToString:SAVFavorite_RemoveFavorite])
    {
        response = [self removeFavorite:request.arguments[SAVFavoriteIDKey]];
    }
    else if ([request.request isEqualToString:SAVFavorite_UpdateFavorite])
    {
        response = [self saveFavoriteSettings:request.arguments];
    }

    if (response)
    {
        shouldHandle = YES;

        if ([response isKindOfClass:[SAVDISResults class]])
        {
            SAVDISResults *results = (SAVDISResults *)response;
            results.app = request.app;
            results.request = request.request;
        }
        else if ([response isKindOfClass:[SAVDISFeedback class]])
        {
            SAVDISFeedback *feedback = (SAVDISFeedback *)response;
            feedback.app = request.app;

            if (self.registeredServiceType)
            {
                feedback.state = [feedback.state stringByAppendingString:self.registeredServiceType];
            }
        }

        [[Savant control].demoServer sendMessage:response];
    }

    return shouldHandle;
}

#pragma mark -

- (SAVDISFeedback *)addFavorite:(NSDictionary *)settings
{
    return [self saveFavoriteSettings:settings];
}

- (SAVDISFeedback *)removeFavorite:(NSString *)identifier
{
    [self.favorites removeObjectForKey:identifier];

    return [self fetchFavoritesList];
}

- (SAVDISFeedback *)fetchFavoritesList
{
    SAVDISFeedback *favoritesList = [[SAVDISFeedback alloc] init];
    favoritesList.state = SAVFavorite_State_Favorites;

    NSMutableArray *favorites = [NSMutableArray array];

    for (SAVFavorite *favorite in [self.favorites allValues])
    {
        [favorites addObject:[favorite dictionaryRepresentation]];
    }

    favoritesList.value = favorites;

    return favoritesList;
}

- (SAVDISFeedback *)saveFavoriteSettings:(NSDictionary *)settings
{
    SAVFavorite *favorite = nil;

    BOOL newFavorite = NO;

    if (settings[SAVFavoriteIDKey])
    {
        favorite = self.favorites[settings[SAVFavoriteIDKey]];
    }
    else
    {
        favorite = [[SAVFavorite alloc] init];
        newFavorite = YES;
    }

    [favorite applySettings:settings];

    if (newFavorite || !favorite.identifier)
    {
        favorite.identifier = [[NSUUID UUID] UUIDString];
    }

    self.favorites[favorite.identifier] = favorite;

    return [self fetchFavoritesList];
}

- (void)generateDemoFavorites
{
    self.favorites = [NSMutableDictionary dictionary];

    NSDictionary *iconNames = @{@"ABC": @"channel_icon_abc.png",
                                @"NBC": @"channel_icon_nbc.png",
                                @"CBS": @"channel_icon_cbs.png",
                                @"CNN": @"channel_icon_cnn.png",
                                @"ESPN": @"channel_icon_espn.png",
                                @"HBO": @"channel_icon_hbo.png"};

    NSInteger channelNumber = 410;

    for (NSString *favoriteName in iconNames)
    {
        SAVFavorite *favorite = [[SAVFavorite alloc] init];
        favorite.name = NSLocalizedString(favoriteName, nil);
        favorite.imageKey = iconNames[favoriteName];
        favorite.number = [NSString stringWithFormat:@"%ld", (long)channelNumber++];

        [self addFavorite:[favorite dictionaryRepresentation]];
    }
}

@end
