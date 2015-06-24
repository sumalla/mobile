//
//  SCUScenesExtensionModel.h
//  SavantController
//
//  Created by Nathan Trapp on 11/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Foundation;

extern NSUInteger const SCUMaxScenes;

@protocol SCUScenesExtensionModelDelegate;
@class SAVScene;

@interface SCUScenesExtensionModel : NSObject

@property (nonatomic, weak) id <SCUScenesExtensionModelDelegate> delegate;
@property (nonatomic, readonly) NSArray *identifiers;

- (instancetype)initWithDelegate:(id <SCUScenesExtensionModelDelegate>)delegate;

- (BOOL)loadPreviousConnection;

- (void)selectItem:(NSUInteger)item;

- (SAVScene *)sceneForItem:(NSUInteger)item;

- (NSString *)sceneIdentifierForItem:(NSUInteger)item;

- (NSUInteger)numberOfScenes;

@end

@protocol SCUScenesExtensionModelDelegate <NSObject>

- (void)showLoadingIndicator;
- (void)loadScenes:(BOOL)ready;
- (void)connectionLostToSystem:(NSString *)name;

@end