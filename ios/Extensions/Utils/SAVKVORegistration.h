//
//  SAVKVORegistration.h
//  SavantController
//
//  Created by Cameron Pulsford on 4/9/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Foundation;

typedef void (^SAVKVORegistrationBlock)(NSDictionary *changeDictionary);

@interface SAVKVORegistration : NSObject

- (instancetype)initWithObserver:(id)observer
                          target:(id)target
                         keyPath:(NSString *)keyPath
                         options:(NSKeyValueObservingOptions)options
                         handler:(SAVKVORegistrationBlock)handler;

- (instancetype)initWithObserver:(id)observer
                          target:(id)target
                        selector:(SEL)selector
                         options:(NSKeyValueObservingOptions)options
                         handler:(SAVKVORegistrationBlock)handler;

- (instancetype)initWithObserver:(id)observer
                          target:(id)target
                        selector:(SEL)selector
                 callImmediately:(BOOL)callImmediately
                         handler:(SAVKVORegistrationBlock)handler;

- (instancetype)initWithObserver:(id)observer
                          target:(id)target
                        selector:(SEL)selector
                         handler:(SAVKVORegistrationBlock)handler;

@end
