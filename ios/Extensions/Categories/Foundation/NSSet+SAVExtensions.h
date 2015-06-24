//
//  NSSet+SAVExtensions.h
//  SavantExtensions
//
//  Created by Stephen Silber on 11/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Foundation;

@interface NSSet (SAVExtensions)

- (NSSet *)sav_minusSet:(NSSet *)set;

- (NSSet *)sav_minusArray:(NSArray *)array;

@end
