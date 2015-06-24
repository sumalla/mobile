//
//  SAVNowPlayingManagerPrivate.h
//  Savant
//
//  Created by Cameron Pulsford on 5/19/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#ifndef Savant_SAVNowPlayingManagerPrivate_h
#define Savant_SAVNowPlayingManagerPrivate_h

@import Foundation;

extern NSString * const SAVStateNameArtistName;
extern NSString * const SAVStateNameAlbumName;
extern NSString * const SAVStateNameSongName;

#import "SAVNowPlayingManager.h"

@interface SAVNowPlayingManager ()

- (void)reset;

@end

#endif
