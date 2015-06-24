//
//  SAVUser.h
//  Pods
//
//  Created by Cameron Pulsford on 8/19/14.
//
//

@import Foundation;

@interface SAVUser : NSObject <NSCopying>

@property (nonatomic) NSSet *zoneBlackList;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
