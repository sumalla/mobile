//
//  SCUIndexedCollation.m
//  SavantController
//
//  Created by Cameron Pulsford on 1/10/13.
//  Copyright (c) 2013 Savant Systems. All rights reserved.
//

#import "SCUIndexedCollation.h"

@import Extensions;

#define SCU_INDEXEDCOLLATION_DEFAULTALPHABET [[NSArray alloc] initWithObjects: \
                                               @"A", @"B", @"C", \
                                               @"D", @"E", @"F", \
                                               @"G", @"H", @"I", \
                                               @"J", @"K", @"L", \
                                               @"M", @"N", @"O", \
                                               @"P", @"Q", @"R", \
                                               @"S", @"T", @"U", \
                                               @"V", @"W", @"X", \
                                               @"Y", @"Z", @"#", \
                                               nil]

@interface SCUIndexedCollation ()

@property (nonatomic) NSArray *collation;

@property (nonatomic, copy) NSArray *sectionForSectionIndexTitles;

@end

@implementation SCUIndexedCollation

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.sectionIndexTitles = SCU_INDEXEDCOLLATION_DEFAULTALPHABET;
        self.sectionTitles = SCU_INDEXEDCOLLATION_DEFAULTALPHABET;
    }
    
    return self;
}

- (NSInteger)sectionForSectionIndexTitleAtIndex:(NSInteger)indexTitleIndex
{
    return [self.sectionForSectionIndexTitles[indexTitleIndex] integerValue];
}

- (NSArray *)preparedModelObjectsFromArray:(NSArray *)array trimmed:(BOOL)trimmed usingBlock:(SCUIndexedCollationStringBlock)block
{
    //--------------------------------------------------
    // Fill up an array with enough empty subarrays for
    // each index.
    //--------------------------------------------------
    NSUInteger sections = [self.sectionIndexTitles count];
    NSMutableArray *unsortedModelObjects = [NSMutableArray array];

    for (NSUInteger i = 0; i < sections; i++)
    {
        [unsortedModelObjects addObject:[NSMutableArray array]];
    }

    //--------------------------------------------------
    // Place each model object into the appropriate
    // subarray.
    //--------------------------------------------------
    for (id obj in array)
    {
        NSInteger section = [self sectionForObject:obj usingBlock:block];
        [unsortedModelObjects[(NSUInteger)section] addObject:obj];
    }

    //--------------------------------------------------
    // Sort the contents of all the subarrays.
    //--------------------------------------------------
    NSMutableArray *sortedModelObjects = [NSMutableArray array];

    for (NSArray *unsortedObjects in unsortedModelObjects)
    {
        NSArray *sortedArray = [self sortedArrayFromArray:unsortedObjects usingBlock:block];
        [sortedModelObjects addObject:sortedArray];
    }

    if (trimmed)
    {
        __block NSUInteger idx = 0;
        NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];

        self.collation = [sortedModelObjects filteredArrayUsingBlock:^BOOL(NSArray *section) {
            BOOL keep = [section count] > 0;

            if (!keep)
            {
                [indexSet addIndex:idx];
            }

            idx++;

            return keep;
        }];

        if ([indexSet count])
        {
            NSMutableArray *sectionIndexTitles = [self.sectionTitles mutableCopy];
            [sectionIndexTitles removeObjectsAtIndexes:indexSet];
            self.sectionTitles = [sectionIndexTitles copy];
        }
    }
    else
    {
        self.collation = sortedModelObjects;
    }

    self.sectionForSectionIndexTitles = [self parseSectionIndexTitleMap];

    return self.collation;
}
//- (NSArray *)mergeNewModelObjects:(NSArray *)newModelObjects withCollation:(NSArray *)existingCollation usingBlock:(SCUIndexedCollationStringBlock)block
//{
//    //-------------------------------------------------------------------
//    // TODO: The internal data structures should optimized so sorting
//    // happens less.
//    //-------------------------------------------------------------------
//    NSArray *newCollation = [self preparedModelObjectsFromArray:newModelObjects usingBlock:block];
//
//    NSMutableArray *combinedCollation = [NSMutableArray array];
//
//    //-------------------------------------------------------------------
//    // The new and existing collations will be the same length.
//    //-------------------------------------------------------------------
//    NSAssert(([newCollation count] == [existingCollation count]), @"Two collations we're not the same length!");
//    for (NSUInteger i = 0; i < [newCollation count]; i++)
//    {
//        NSArray *newArray = [newCollation objectAtIndex:i];
//        NSArray *existingArray = [existingCollation objectAtIndex:i];
//        NSArray *combinedArray = [newArray arrayByAddingObjectsFromArray:existingArray];
//        NSArray *sortedArray = [self sortedArrayFromArray:combinedArray usingBlock:block];
//        [combinedCollation addObject:sortedArray];
//    }
//
//    return combinedCollation;
//}

#pragma mark - Methods to sublcass

- (unichar)firstCharacterInString:(NSString *)string
{
    unichar theChar = '\0';

    if (string)
    {
        NSRange range = [string rangeOfCharacterFromSet:[NSCharacterSet alphanumericCharacterSet] options:NSCaseInsensitiveSearch];
        
        if (range.location != NSNotFound)
        {
            theChar = [string characterAtIndex:range.location];
        }
    }
    
    return theChar;
}

#pragma mark -

- (NSInteger)sectionForObject:(id)modelObject usingBlock:(SCUIndexedCollationStringBlock)block
{
    NSString *theString = block(modelObject);
    unichar theChar = [self firstCharacterInString:theString];

    //--------------------------------------------------
    // Find the section it belongs to.
    //--------------------------------------------------
    NSString *s = [[NSString stringWithCharacters:&theChar length:1] uppercaseString];
    NSUInteger theSection = 0;

    for (NSString *section in self.sectionIndexTitles)
    {
        if ([section isEqualToString:s])
        {
            break;
        }

        theSection++;
    }

    //--------------------------------------------------
    // We didn't find what we were looking for, so it
    // must be the catch all.
    //--------------------------------------------------
    if (theSection == [self.sectionIndexTitles count])
    {
        theSection--;
    }

    return (NSInteger)theSection;
}

- (NSArray *)sortedArrayFromArray:(NSArray *)array usingBlock:(SCUIndexedCollationStringBlock)block
{
    return [array sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *s1 = block(obj1);
        NSString *s2 = block(obj2);
        return [s1 compare:s2];
    }];
}

- (NSArray *)parseSectionIndexTitleMap
{
    //-------------------------------------------------------------------
    // This method sets up the mapping between the sectionIndexTitles and
    // sectionTitles.
    //-------------------------------------------------------------------
    NSMutableArray *array = [NSMutableArray array];

    NSUInteger i = 0;

    NSString *lastFoundLetter = nil;

    for (NSString *letter in self.sectionIndexTitles)
    {
        if ([self.sectionTitles containsObject:letter])
        {
            if (lastFoundLetter)
            {
                i++;
            }

            lastFoundLetter = letter;
        }

        [array addObject:@(i)];
    }

    return [array copy];
}

@end
