//
//  WebrtcClient.m
//  Pods
//
//  Created by Joseph Ross on 4/1/15.
//
//

#import "SAVWebrtcClient.h"
#import <WebRTC/RTCICECandidate.h>
#import <WebRTC/RTCSessionDescription.h>
#import <WebRTC/RTCSessionDescriptionDelegate.h>
#import <WebRTC/RTCPeerConnectionFactory.h>
#import <WebRTC/RTCPeerConnection.h>
#import <WebRTC/RTCMediaStream.h>
#import <WebRTC/RTCMediaConstraints.h>
#import <WebRTC/RTCICEServer.h>
#import <WebRTC/RTCICECandidate.h>
#import <WebRTC/RTCDataChannel.h>
#import <WebRTC/RTCPair.h>
#import <WebRTC/RTCVideoTrack.h>
#import "RTCICECandidate+JSON.h"
#import "RTCSessionDescription+JSON.h"
#import "WebRTC/RTCEAGLVideoView.h"

@interface SAVVideoView ()

- (void)attachVideoForTrack:(RTCVideoTrack *)videoTrack;

@end

@interface SAVWebrtcClient () <RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate>

@property(nonatomic,strong) RTCPeerConnection *peerConnection;
@property(nonatomic,strong) RTCPeerConnectionFactory *factory;
@property(nonatomic,strong) RTCVideoTrack *videoTrack;

@end

@implementation SAVWebrtcClient

- (instancetype)initWithDelegate:(NSObject<SAVWebrtcClientDelegate>*)delegate {
    return [self initWithDelegate:delegate iceServerJson:nil];
}

- (instancetype)initWithDelegate:(NSObject<SAVWebrtcClientDelegate>*)delegate iceServerJson:(NSDictionary*)iceServerJson {
    if (self = [super init]) {
        self.delegate = delegate;
        // Create peer connection.
        [RTCPeerConnectionFactory initializeSSL];
        NSArray *iceServers = [self iceServersFromJson:iceServerJson];
        if (iceServers.count == 0) {
            iceServers = @[[self defaultStunServer], [self defaultTurnServer]];
        }
        RTCMediaConstraints *constraints = [self defaultPeerConnectionConstraints];
        self.factory = [[RTCPeerConnectionFactory alloc] init];
        self.peerConnection = [self.factory peerConnectionWithICEServers:iceServers constraints:constraints delegate:self];
        RTCMediaStream *localStream = [self createLocalMediaStream];
        [self.peerConnection addStream:localStream];
    }
    return self;
}

- (NSArray *)iceServersFromJson:(NSDictionary *)iceServerJson {
    
    //    iceServers: {
    //    password = "v+GE+aN1qsm23UoE88p8Zv/HwgA=";
    //    ttl = 604800;
    //    uris =     (
    //    "stun:stun.l.google.com:19302",
    //    "turn:54.186.242.129:80?transport=udp"
    //    );
    //    username = "1429593575:LPK6kOWuS-GWkBhvrCkc4A";
    //    }
    
    NSMutableArray *rtcIceServers = [NSMutableArray arrayWithCapacity:2];
    
    NSString *username = iceServerJson[@"username"];
    NSString *password = iceServerJson[@"password"];
    for (NSString *uriString in iceServerJson[@"uris"]) {
        NSURL *uri = [NSURL URLWithString:uriString];
        if (uri != nil) {
            RTCICEServer *iceServer = [[RTCICEServer alloc] initWithURI:uri username:username password:password];
            [rtcIceServers addObject:iceServer];
        }
    }
    return rtcIceServers;
}

- (void)hangup {
    self.videoTrack = nil;
    [self.peerConnection close];
    self.peerConnection.delegate = nil;
    self.peerConnection = nil;
    self.factory = nil;
}


- (void)receiveOfferSdp:(NSString *)sdp {
    RTCSessionDescription *description = [[RTCSessionDescription alloc] initWithType:@"offer" sdp:sdp];
    [self.peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:description];
}

- (void)attachVideoToView:(SAVVideoView *)videoView {
    [videoView attachVideoForTrack:self.videoTrack];
}


/// MARK - RTCPeerConnection utilities and defaults

- (RTCMediaStream*)createLocalMediaStream {
    // We offer audio only
    RTCMediaStream *localStream = [self.factory mediaStreamWithLabel:@"ARDAMS"];
    [localStream addAudioTrack:[self.factory audioTrackWithID:@"ARDAMSa0"]];
    return localStream;
}

- (RTCMediaConstraints *)defaultAnswerConstraints {
    NSArray *mandatoryConstraints = @[
                                      [[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"],
                                      [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:@"true"],
                                      ];
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints optionalConstraints:nil];
    return constraints;
}

- (RTCMediaConstraints*)defaultPeerConnectionConstraints {
    NSArray *optionalConstraints = @[[[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"]];
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:optionalConstraints];
    return constraints;
}

- (RTCICEServer*)defaultStunServer {
    return [[RTCICEServer alloc] initWithURI:[NSURL URLWithString:@"stun:10.101.2.17:3478"] username:@"" password:@""];
}

- (RTCICEServer*)defaultTurnServer {
    return [[RTCICEServer alloc] initWithURI:[NSURL URLWithString:@"turn:10.101.2.17:3478"] username:@"" password:@""];
}

/// MARK - RTCPeerConnectionDelegate implementation

- (void)peerConnection:(RTCPeerConnection *)peerConnection
 signalingStateChanged:(RTCSignalingState)stateChanged{}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
           addedStream:(RTCMediaStream *)stream{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Received %lu video tracks and %lu audio tracks",
              (unsigned long)stream.videoTracks.count,
              (unsigned long)stream.audioTracks.count);
        if (stream.videoTracks.count) {
            self.videoTrack = stream.videoTracks[0];
            [self.delegate webrtcClientReadyToAttachVideo:self];
        }
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
         removedStream:(RTCMediaStream *)stream{}

- (void)peerConnectionOnRenegotiationNeeded:(RTCPeerConnection *)peerConnection{}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
  iceConnectionChanged:(RTCICEConnectionState)newState{}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
   iceGatheringChanged:(RTCICEGatheringState)newState{
    if (newState == RTCICEGatheringComplete) {
        [self.delegate webrtcClientFinishedGeneratingCandidates:self];
    }
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
       gotICECandidate:(RTCICECandidate *)candidate{
    NSDictionary *dataJson = [NSJSONSerialization JSONObjectWithData:candidate.JSONData options:0 error:nil];
    NSDictionary *candidateJson = @{
                                    @"sdpMLineIndex":dataJson[@"label"],
                                    @"sdpMid":dataJson[@"id"],
                                    @"candidate":dataJson[@"candidate"],
                                    };
    [self.delegate webrtcClient:self generatedCandidate:candidateJson];
}

- (void)peerConnection:(RTCPeerConnection*)peerConnection
    didOpenDataChannel:(RTCDataChannel*)dataChannel{}

- (void)     peerConnection:(RTCPeerConnection *)peerConnection
didCreateSessionDescription:(RTCSessionDescription *)sdp
                      error:(NSError *)error
{
    if (error != nil) {
        //TODO handle/report the error
    } else {
        [self.peerConnection setLocalDescriptionWithDelegate:self
                                          sessionDescription:sdp];
        [self.delegate webrtcClient:self generatedAnswerSdp:sdp.description];
    }
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didSetSessionDescriptionWithError:(NSError *)error{
    if (!self.peerConnection.localDescription) {
        RTCMediaConstraints *constraints = [self defaultAnswerConstraints];
        [self.peerConnection createAnswerWithDelegate:self constraints:constraints];
    }
}

@end
