//
//  SAVCollectionTypes.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Foundation;

typedef id (^SAVArrayMappingBlock)(id object);

typedef id (^SAVArrayMappingWithIdxBlock)(id object, NSUInteger idx, BOOL *stop);

typedef BOOL (^SAVArrayFilteringBlock)(id object);

typedef id (^SAVArrayInterposeBlock)(void);
