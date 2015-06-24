//
//  SavantProtocols.h
//  SavantControl
//
//  Created by Adam Shiemke on 2/10/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVConnectionState.h"

@class SAVConnection;
@class SAVStateUpdate;
@class SAVDiscovery;
@class SAVSystem;
@class SAVDISFeedback;
@class SAVDISResults;

#pragma mark - System status

@protocol SystemStatusDelegate <NSObject>

@optional

- (void)connectionDidConnect;
- (BOOL)didConnectToSystemWithProtocolVersion:(uint32_t)protocolVersion;
- (void)connectionDidFailToConnect;
- (void)establishedConnectionDidFail;

- (void)connectionDidReceiveAuthChallenge;
- (void)connectionDidAuthorizeForUser:(NSString *)user;
- (void)connectionDidReceiveAuthChallengeForUser:(NSString *)user;

- (void)connectionIsReady;

- (void)connectionDidStartConfigurationDownload;
- (void)connectionDidReceiveConfigurationDownloadUpdate:(float)progress isInstalling:(BOOL)isInstalling;

- (void)connectionDidChangeToState:(SAVConnectionState)state;

- (void)connectionShouldLogOut;

- (void)connectionAdminStatusDidChange;

- (void)connectionPermissionsDidChange;

@end

@protocol UserLevelSecurityDelegate <NSObject>

- (void)checkUserLevelSecurityBeforeAuthenticating:(void (^)(BOOL shouldContinue))continueBlock;

@end

#pragma mark - States/responses

@protocol StateDelegate <NSObject>

@optional
- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate;
- (void)didReceiveDISFeedback:(SAVDISFeedback *)feedback;

@end

@protocol DISResultDelegate <NSObject>

- (void)disRequestDidCompleteWithResults:(SAVDISResults *)results;

@end

@protocol MediaResponseDelegate <NSObject>

- (void)mediaRequestDidCompleteWithResults:(NSArray *)results;

@end

#pragma mark - Transfers

@protocol ConnectionBinaryTransferDelegate <NSObject>

- (NSString *)filePathForBinaryTransferWithIdentifier:(id)identifier;
- (void)didStartBinaryTransferForIdentifier:(id)identifier withSize:(NSUInteger)size;
- (void)didFinishBinaryTransferWithData:(NSData *)data forIdentifier:(id)identifier;
- (void)didFinishBinaryTransferWithFilePath:(NSString *)filePath forIdentifier:(id)identifier;

@end

@protocol CameraFetchDelegate <NSObject>

- (void)didReceiveImageData:(NSData *)imageData forSession:(NSString *)sesion;
- (NSString *)registeredName;

@end

#pragma mark - Discovery

@protocol DiscoveryDelegate <NSObject>

@optional
- (void)discovery:(SAVDiscovery *)discovery didFindSystem:(SAVSystem *)system;
- (void)discovery:(SAVDiscovery *)discovery didLoseSystem:(SAVSystem *)system;
- (void)discovery:(SAVDiscovery *)discovery didUpdateSystem:(SAVSystem *)system;
- (void)discoveryDidUpdateSystemList:(SAVDiscovery *)discovery;
- (void)discoveryDidUpdateProvisionablePeripheralList:(SAVDiscovery *)discovery;

@end
