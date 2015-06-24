//
//  SCUReorderableTileLayoutSpan.h
//  SavantController
//
//  Created by Cameron Pulsford on 7/24/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Foundation;

@interface SCUReorderableTileLayoutSpan : NSObject

@property (nonatomic) NSUInteger width;
@property (nonatomic) NSUInteger height;

+ (instancetype)spanWithWidth:(NSUInteger)width height:(NSUInteger)height;

@end
