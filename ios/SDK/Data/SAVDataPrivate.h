//
//  SAVDataPrivate.h
//  SavantControl
//
//  Created by Cameron Pulsford on 9/25/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVData.h"

@interface SAVData ()

- (void)updateDatabasePath:(NSString *)databasePath;

- (void)updateServiceBlacklist:(NSSet *)serviceBlacklist zoneBlacklist:(NSSet *)zoneBlacklist;

@end
