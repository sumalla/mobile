//
//  SAVNowPlayingStatusPrivate.h
//  Savant
//
//  Created by Cameron Pulsford on 5/27/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#ifndef Savant_SAVNowPlayingStatusPrivate_h
#define Savant_SAVNowPlayingStatusPrivate_h

#import "SAVNowPlayingStatus.h"

@interface SAVNowPlayingStatus ()

@property (nonatomic) NSMutableDictionary *states;

- (void)setObject:(id)object forKey:(NSString *)key;

@end

#endif
