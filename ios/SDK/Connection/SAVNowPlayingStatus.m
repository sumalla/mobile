//
//  SAVNowPlayingStatus.m
//  Savant
//
//  Created by Cameron Pulsford on 5/27/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SAVNowPlayingStatusPrivate.h"
#import "SAVNowPlayingManagerPrivate.h"

@implementation SAVNowPlayingStatus

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.states = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)setObject:(id)object forKey:(NSString *)key
{
    self.states[key] = object;
}

- (NSString *)description
{
    return [self.states description];
}

- (NSString *)artist
{
    return self.states[SAVStateNameArtistName];
}

- (NSString *)album
{
    return self.states[SAVStateNameAlbumName];
}

- (NSString *)song
{
    return self.states[SAVStateNameSongName];
}

@end
