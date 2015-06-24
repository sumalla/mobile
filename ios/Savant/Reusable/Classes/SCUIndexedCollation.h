//
//  SCUIndexedCollation.h
//  SavantController
//
//  Created by Cameron Pulsford on 1/10/13.
//  Copyright (c) 2013 Savant Systems. All rights reserved.
//

@import Foundation;

typedef NSString * (^SCUIndexedCollationStringBlock)(id modelObject);

@interface SCUIndexedCollation : NSObject

//--------------------------------------------------
// By default these are 'A-Z' with a catch all '#'.
//
// If custom values are set, the arrays MUST be
// equal in length. Additionally, each element of
// sectionIndexTitles MUST be capitalized (when
// applicable).
//--------------------------------------------------
@property (copy) NSArray *sectionIndexTitles;
@property (copy) NSArray *sectionTitles;

- (NSInteger)sectionForSectionIndexTitleAtIndex:(NSInteger)indexTitleIndex;

- (NSArray *)preparedModelObjectsFromArray:(NSArray *)array trimmed:(BOOL)trimmed usingBlock:(SCUIndexedCollationStringBlock)block;

//- (NSArray *)mergeNewModelObjects:(NSArray *)newModelObjects withCollation:(NSArray *)existingCollation usingBlock:(SCUIndexedCollationStringBlock)block;

#pragma mark - Methods to sublcass

/**
 *  Returns the first non-white space character in the given string. Override this to account for things like "A ", or "The ".
 *
 *  @param string The string.
 *
 *  @return The first non-white space character of the given string.
 */
- (unichar)firstCharacterInString:(NSString *)string;

@end
