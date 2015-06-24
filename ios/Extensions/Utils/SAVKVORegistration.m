//
//  SAVKVORegistration.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/9/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SAVKVORegistration.h"

@interface SAVKVORegistration ()

@property id target;
@property (assign) id weakTarget;
@property NSString *keyPath;
@property (copy) SAVKVORegistrationBlock handler;

@end

@implementation SAVKVORegistration

- (void)dealloc
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-exception-parameter"
    @try
    {
        [self.target removeObserver:self forKeyPath:self.keyPath];
        [self.weakTarget removeObserver:self forKeyPath:self.keyPath];
    }
    @catch (NSException *exception)
    {
        ;
    }
#pragma clang diagnostic pop
}

- (instancetype)initWithObserver:(id)observer
                          target:(id)target
                         keyPath:(NSString *)keyPath
                         options:(NSKeyValueObservingOptions)options
                         handler:(SAVKVORegistrationBlock)handler
{
    NSParameterAssert(observer);
    NSParameterAssert(target);
    NSParameterAssert([keyPath length]);
    NSParameterAssert(handler);

    self = [super init];

    if (self)
    {
        if (observer == target)
        {
            self.weakTarget = target;
        }
        else
        {
            self.target = target;
        }

        self.keyPath = keyPath;
        self.handler = handler;

        [target addObserver:self
                 forKeyPath:keyPath
                    options:options
                    context:NULL];
    }

    return self;
}

- (instancetype)initWithObserver:(id)observer
                          target:(id)target
                        selector:(SEL)selector
                         options:(NSKeyValueObservingOptions)options
                         handler:(SAVKVORegistrationBlock)handler
{
    self = [self initWithObserver:observer
                           target:target
                          keyPath:NSStringFromSelector(selector)
                          options:options
                          handler:handler];

    return self;
}

- (instancetype)initWithObserver:(id)observer
                          target:(id)target
                        selector:(SEL)selector
                 callImmediately:(BOOL)callImmediately
                         handler:(SAVKVORegistrationBlock)handler
{
    NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew;

    if (callImmediately)
    {
        options |= NSKeyValueObservingOptionInitial;
    }

    self = [self initWithObserver:observer
                           target:target
                         selector:selector
                          options:options
                          handler:handler];

    return self;
}

- (instancetype)initWithObserver:(id)observer
                          target:(id)target
                        selector:(SEL)selector
                         handler:(SAVKVORegistrationBlock)handler
{
    self = [self initWithObserver:observer
                           target:target
                         selector:selector
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          handler:handler];

    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    self.handler(change);
}

@end
