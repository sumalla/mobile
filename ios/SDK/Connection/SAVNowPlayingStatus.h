//
//  SAVNowPlayingStatus.h
//  Savant
//
//  Created by Cameron Pulsford on 5/27/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

@import Foundation;

@interface SAVNowPlayingStatus : NSObject

@property (nonatomic, readonly) NSString *artist;
@property (nonatomic, readonly) NSString *album;
@property (nonatomic, readonly) NSString *song;

@end
