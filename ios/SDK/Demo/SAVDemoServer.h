//
//  SAVDemoServer.h
//  SavantControl
//
//  Created by Nathan Trapp on 4/25/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

@import Foundation;

@protocol SAVDemoServerDelegate, SAVDemoRouter;
@class SAVDISRequest, SAVMediaRequest, SAVServiceRequest, SAVMessage, SAVStateRegister, SAVStateUnregister, SAVFileRequest;

@interface SAVDemoServer : NSObject

- (void)startDemoServer;
- (void)stopDemoServer;

- (id)restorationInfo;
- (void)restoreState:(id)state;

@property (nonatomic, assign) int port;
@property (nonatomic, readonly) BOOL isReady;
@property (nonatomic, readonly) BOOL isValid;
@property (readonly, atomic) NSMutableDictionary *allStates;

@property (weak) id <SAVDemoServerDelegate> delegate;

- (void)addRouter:(id <SAVDemoRouter>)router;
- (void)removeRouter:(id <SAVDemoRouter>)router;

- (BOOL)sendMessage:(SAVMessage *)message;
- (BOOL)sendMessages:(NSArray *)messages;
- (void)sendURIToDevice:(NSString *)uri withMessages:(NSArray *)messages;

- (void)sendBinaryData:(NSData *)data ofType:(NSUInteger)type withIdentifier:(id)identifier;

- (void)sendStateUpdate:(NSDictionary *)states;

@end

@protocol SAVDemoServerDelegate <NSObject>

- (void)demoServerIsReady;

@end

@protocol SAVDemoRouter <NSObject>

@optional
- (BOOL)handleStateRegistration:(SAVStateRegister *)request;
- (BOOL)handleStateUnregistration:(SAVStateUnregister *)request;
- (BOOL)handleDISRequest:(SAVDISRequest *)request;
- (BOOL)handleMediaRequest:(SAVMediaRequest *)request;
- (BOOL)handleServiceRequest:(SAVServiceRequest *)request;
- (BOOL)handleFileRequest:(SAVFileRequest *)request;

@end
