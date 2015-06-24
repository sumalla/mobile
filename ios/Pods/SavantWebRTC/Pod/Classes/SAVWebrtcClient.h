//
//  WebrtcClient.h
//  Pods
//
//  Created by Joseph Ross on 4/1/15.
//
//

#import <Foundation/Foundation.h>
#import "SAVVideoView.h"

@class SAVWebrtcClient;

@protocol SAVWebrtcClientDelegate
- (void)webrtcClient:(SAVWebrtcClient*)client generatedAnswerSdp:(NSString *)sdp;
- (void)webrtcClient:(SAVWebrtcClient*)client generatedCandidate:(NSDictionary *)candidate;
- (void)webrtcClientFinishedGeneratingCandidates:(SAVWebrtcClient*)client;
- (void)webrtcClientReadyToAttachVideo:(SAVWebrtcClient*)client;
@end

@interface SAVWebrtcClient : NSObject
@property(nonatomic,weak) NSObject<SAVWebrtcClientDelegate> *delegate;

- (instancetype)initWithDelegate:(NSObject<SAVWebrtcClientDelegate>*)delegate;
- (instancetype)initWithDelegate:(NSObject<SAVWebrtcClientDelegate>*)delegate iceServerJson:(NSDictionary*)iceServerJson;
- (void)hangup;
- (void)receiveOfferSdp:(NSString *)sdp;
- (void)attachVideoToView:(SAVVideoView *)videoView;

@end
