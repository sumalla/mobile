//
//  SAVSettings.m
//  SavantControl
//
//  Created by Nathan Trapp on 6/20/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVSettings.h"
#import "Savant.h"
#import "SAVControlPrivate.h"
@import Extensions;

@interface SAVSettings () <StateDelegate, DISResultDelegate>

@property NSString *currentHostID;
@property NSString *settingsPath;
@property NSMutableDictionary *currentSettings;
@property (nonatomic) BOOL syncsSettings;
@property NSString *domain;
@property BOOL global;
@property NSMutableDictionary *watchedKeys;
@property SAVSettings *versions;

@property SAVDISRequestGenerator *disRequestGenerator;

@end

@implementation SAVSettings

static SAVSettings *userSettings = nil;
static SAVSettings *globalSettings = nil;
static SAVSettings *localSettings = nil;

+ (void)resetAllSettings
{
    [[self class] resetLocalSettings];
    [[self class] resetUserSettings];
    [[self class] resetGlobalSettings];
}

+ (instancetype)settingsForDomain:(NSString *)domain
{
    SAVSettings *settings = nil;

    if ([domain isEqualToString:userSettings.domain])
    {
        settings = userSettings;
    }
    else if ([domain isEqualToString:globalSettings.domain])
    {
        settings = globalSettings;
    }
    else if ([domain isEqualToString:localSettings.domain])
    {
        settings = localSettings;
    }

    if (!settings || ![settings.currentHostID isEqualToString:[Savant control].currentSystem.hostID])
    {
        settings = [[SAVSettings alloc] initWithDomain:domain];
    }

    return settings;
}

+ (instancetype)localSettings
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localSettings = [[SAVSettings alloc] initWithDomain:@"local"];
    });

    return localSettings;
}

+ (void)resetLocalSettings
{
    if (!localSettings)
    {
        [SAVSettings localSettings];
    }
    else
    {
        localSettings = [self settingsForDomain:@"local"];
    }
}

+ (instancetype)userSettings
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        userSettings = [[SAVSettings alloc] initWithDomain:[@"users" stringByAppendingPathComponent:[Savant control].lowerCaseUserName]];
        userSettings.syncsSettings = YES;
    });

    return userSettings;
}

+ (void)resetUserSettings
{
    if (!userSettings)
    {
        [SAVSettings userSettings];
    }
    else
    {
        userSettings = [self settingsForDomain:[@"users" stringByAppendingPathComponent:[Savant control].lowerCaseUserName]];
        userSettings.syncsSettings = YES;
    }
}

+ (instancetype)globalSettings
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        globalSettings = [[SAVSettings alloc] initWithDomain:@"global"];
        globalSettings.syncsSettings = YES;
    });

    return globalSettings;
}

+ (void)resetGlobalSettings
{
    if (!globalSettings)
    {
        [SAVSettings globalSettings];
    }
    else
    {
        globalSettings = [self settingsForDomain:@"global"];
        globalSettings.syncsSettings = YES;
    }
}

- (instancetype)initWithDomain:(NSString *)domain
{
    self = [super init];

    if (self)
    {
        NSAssert(domain, @"Missing required domain value");

        self.domain = domain;

        SAVControl *savantControl = [Savant control];
        NSString *systemPath = [savantControl systemPathForUID:savantControl.currentSystem.hostID];
        self.currentHostID = savantControl.currentSystem.hostID;

        self.settingsPath = [systemPath stringByAppendingPathComponent:[NSString stringWithFormat:@"settings/%@.json", domain]];

        if (![[NSFileManager defaultManager] fileExistsAtPath:[self.settingsPath stringByDeletingLastPathComponent]])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:[self.settingsPath stringByDeletingLastPathComponent]
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:NULL];
        }

        NSData *settingsData = [NSData dataWithContentsOfFile:self.settingsPath];
        if (settingsData)
        {
            self.currentSettings = [[NSJSONSerialization JSONObjectWithData:settingsData options:0 error:NULL] mutableCopy];
        }

        if (!self.currentSettings)
        {
            self.currentSettings = [NSMutableDictionary dictionary];
        }
    }

    return self;
}

- (void)dealloc
{
    [self synchronize];
}

- (BOOL)synchronize
{
    BOOL success = NO;
    
    NSError *error = nil;
    NSData *settingsData = nil;
    
    @synchronized(self.currentSettings)
    {
        settingsData = [NSJSONSerialization dataWithJSONObject:self.currentSettings options:0 error:&error];
    }
    
    if (!error)
    {
        success = [settingsData writeToFile:self.settingsPath atomically:YES];
    }
    
    return success;
}

- (void)setObject:(id)setting forKey:(NSString *)key
{
    [self setObject:setting forKey:key syncAfter:YES];
}

- (void)setObject:(id)setting forKey:(NSString *)key syncAfter:(BOOL)shouldSync
{
    if (setting && key)
    {
        NSArray *keys = [key componentsSeparatedByString:@"."];
        
        @synchronized(self.currentSettings)
        {
            id data = nil;
            
            for (NSUInteger i = 0; i < [keys count]; i++)
            {
                NSMutableDictionary *dict = nil;
                
                if (i == 0)
                {
                    dict = self.currentSettings;
                }
                else
                {
                    dict = data;
                }
                
                if ((i + 1) == [keys count])
                {
                    dict[keys[i]] = setting;
                }
                else
                {
                    data = [dict[keys[i]] mutableCopy];
                    
                    if (!data || ![data isKindOfClass:[NSDictionary class]])
                    {
                        data = [NSMutableDictionary dictionary];
                    }
                    
                    dict[keys[i]] = data;
                }
            }
        }
    }
    
    if (self.syncsSettings && shouldSync && key && setting)
    {
        SAVDISRequest *request = [self.disRequestGenerator request:@"SaveSetting"
                                                     withArguments:@{@"key": key,
                                                                     @"value": setting,
                                                                     @"global": @(self.global)}];
        [[Savant control] sendMessage:request];
    }

    [self watchedKeyChanged:key];
}

- (void)removeObjectForKey:(NSString *)key
{
    [self removeObjectForKey:key syncAfter:YES];

    [self watchedKeyChanged:key];
}

- (void)removeObjectForKey:(NSString *)key syncAfter:(BOOL)shouldSync
{
    if (key)
    {
        NSArray *keys = [key componentsSeparatedByString:@"."];
        
        @synchronized(self.currentSettings)
        {
            id data = nil;
            
            for (NSUInteger i = 0; i < [keys count]; i++)
            {
                NSMutableDictionary *dict = nil;
                
                if (i == 0)
                {
                    dict = self.currentSettings;
                }
                else
                {
                    dict = data;
                }
                
                if ((i + 1) == [keys count])
                {
                    [dict removeObjectForKey:keys[i]];
                }
                else
                {
                    data = [dict[keys[i]] mutableCopy];
                    
                    if (!data || ![data isKindOfClass:[NSDictionary class]])
                    {
                        data = [NSMutableDictionary dictionary];
                    }
                    
                    dict[keys[i]] = data;
                }
            }
        }
    }
    
    if (self.syncsSettings && shouldSync && key)
    {
        SAVDISRequest *request = [self.disRequestGenerator request:@"DeleteSetting"
                                                     withArguments:@{@"key": key,
                                                                     @"global": @(self.global)}];
        [[Savant control] sendMessage:request];
    }
}

- (id)objectForKey:(NSString *)key
{
    id object = nil;
    
    if (key)
    {
        NSArray *keys = [key componentsSeparatedByString:@"."];
        
        @synchronized(self.currentSettings)
        {
            id data = nil;
            
            for (NSUInteger i = 0; i < [keys count]; i++)
            {
                NSMutableDictionary *dict = nil;
                
                if (i == 0)
                {
                    dict = self.currentSettings;
                }
                else
                {
                    dict = data;
                }
                
                if ((i + 1) == [keys count])
                {
                    object = dict[keys[i]];
                }
                else
                {
                    data = [dict[keys[i]] mutableCopy];
                    
                    if (!data || ![data isKindOfClass:[NSDictionary class]])
                    {
                        data = [NSMutableDictionary dictionary];
                    }
                    
                    dict[keys[i]] = data;
                }
            }
        }
    }
    
    return object;
}

#pragma mark - Key Observeration

- (id)addObserverForKey:(NSString *)key usingBlock:(SAVSettingsKeyUpdate)block
{
    NSString *ident = nil;

    if (key && block)
    {
        NSMutableDictionary *blocks = self.watchedKeys[key];

        if (!self.watchedKeys)
        {
            self.watchedKeys = [NSMutableDictionary dictionary];
        }

        if (!blocks)
        {
            blocks = [NSMutableDictionary dictionary];
            self.watchedKeys[key] = blocks;
        }

        ident = [[NSUUID UUID] UUIDString];

        blocks[ident] = block;
    }
    
    return ident;
}

- (void)removeObserver:(id)observer
{
    if (observer && [self.watchedKeys count])
    {
        for (NSString *key in [self.watchedKeys copy])
        {
            NSMutableDictionary *blocks = self.watchedKeys[key];
            [blocks removeObjectForKey:observer];

            if (![blocks count])
            {
                [self.watchedKeys removeObjectForKey:key];
            }
        }
    }
}

- (void)watchedKeyChanged:(NSString *)key
{
    NSArray *keys = [key componentsSeparatedByString:@"."];

    NSString *partialKey = nil;

    for (NSString *k in keys)
    {
        if (partialKey)
        {
            partialKey = [partialKey stringByAppendingFormat:@".%@", k];
        }
        else
        {
            partialKey = k;
        }

        if (self.watchedKeys[partialKey])
        {
            NSDictionary *blocks = self.watchedKeys[partialKey];
            for (SAVSettingsKeyUpdate block in [blocks allValues])
            {
                block(partialKey, [self objectForKey:partialKey]);
            }
        }
    }
}

#pragma mark - Properties

- (void)setSyncsSettings:(BOOL)syncsSettings
{
    _syncsSettings = syncsSettings;

    if (syncsSettings && [Savant control].controlMode & SAVControlModeSettingsStates)
    {
        self.disRequestGenerator = [[SAVDISRequestGenerator alloc] initWithApp:SAVUserDataIdentifer];
        NSArray *states = [self.disRequestGenerator feedbackStringsWithStateNames:[[self stateNames] allKeys]];
        [[Savant states] registerForStates:states forObserver:self];

        self.global = self == globalSettings ? YES : NO;

        self.versions = [[SAVSettings alloc] initWithDomain:[self.domain stringByAppendingString:@"-versions"]];

        [[Savant control] addDISResultObserver:self forApp:SAVUserDataIdentifer];
    }
}

#pragma mark - States

- (NSDictionary *)stateNames
{
    NSString *state = nil;

    if (self == userSettings)
    {
        state = @"user";
    }
    else
    {
        state = self.domain;
    }

    state = [state stringByAppendingString:@".setting.update"];

    return @{state: NSStringFromSelector(@selector(handleSettingsUpdate:))};
}

- (void)handleSettingsUpdate:(NSDictionary *)update
{
    //-------------------------------------------------------------------
    // TODO: Need to cleanup settings on initial update
    //-------------------------------------------------------------------
    for (NSString *key in update)
    {
        NSNumber *version = update[key];

        if ([version isEqualToNumber:@(-1)])
        {
            [self.versions removeObjectForKey:key];
            [self removeObjectForKey:key syncAfter:NO];

            if ([self synchronize])
            {
                [self.versions synchronize];
            }
        }
        else if (![version isEqual:[self.versions objectForKey:key]])
        {
            SAVDISRequest *request = [self.disRequestGenerator request:@"FetchSetting"
                                                         withArguments:@{@"key": key,
                                                                         @"global": @(self.global)}];
            [[Savant control] sendMessage:request];
        }
    }
}

#pragma mark - StateDelegate

- (void)didReceiveDISFeedback:(SAVDISFeedback *)feedback
{
    SEL selector = NSSelectorFromString([self stateNames][feedback.state]);

    if (selector)
    {
        SAVFunctionForSelector(function, self, selector, void, NSDictionary *);
        function(self, selector, feedback.value);
    }
}

#pragma mark - DISResultsDelegate

- (void)disRequestDidCompleteWithResults:(SAVDISResults *)results
{
    BOOL global = [results.results[@"global"] boolValue];
    NSString *key = results.results[@"key"];
    id value = results.results[@"value"];
    NSNumber *version = results.results[@"version"];

    if (key && value && version && global == self.global)
    {
        [self.versions setObject:version forKey:key];
        [self setObject:value forKey:key syncAfter:NO];
        if ([self synchronize])
        {
            [self.versions synchronize];
        }
    }
}

@end
