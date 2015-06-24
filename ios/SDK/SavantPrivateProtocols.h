//
//  SavantPrivateProtocols.h
//  SavantControl
//
//  Created by Adam Shiemke on 2/10/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

@protocol ConnectionStatusDelegate <NSObject>

- (void)connectionDidConnect:(SAVConnection *)connection;
- (void)connectionDidRequestAuthentication:(SAVConnection *)connection;
- (void)connectionIsReady:(SAVConnection *)connection;
- (void)connectionDidDisconnect:(SAVConnection *)connection;
- (void)connection:(SAVConnection *)connection didFailWithError:(NSError *)error;
- (BOOL)connectionIsConnectedToCloudSystem:(SAVConnection *)connection;
- (void)connection:(SAVConnection *)connection authenticationAttemptDidFailWithCode:(NSUInteger)code;

@end

@protocol SuspensionDelegate <NSObject>

@optional

- (void)savantControlDidSuspend;
- (void)savantControlDidResume;

@end

@protocol ConnectionStateDelegate <NSObject>

- (void)connection:(SAVConnection *)connection didReceiveStateUpdate:(id)stateUpdate;

@end

@protocol ConnectionDISDelegate <NSObject>

- (void)connection:(SAVConnection *)connection didReceiveDISFeedback:(SAVDISFeedback *)disFeedback;
- (void)connection:(SAVConnection *)connection didReceiveDISResults:(SAVDISResults *)results;

@end


@protocol ConnectionMessageDelegate <NSObject>

- (void)connection:(SAVConnection *)connection didReceiveMessage:(id)message;

@end

@protocol ConnectionStateUpdateDelegate <NSObject>

- (void)connection:(SAVConnection *)connection didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate;

@end
