//
//  JanusClient.swift
//  AppRTCDemo
//
//  Created by Joseph Ross on 2/23/15.
//  Copyright (c) 2015 Savant Systems LLC. All rights reserved.
//
//

#import "CameraRestClient.h"
#import "SAVWebrtcClient.h"

/***

JanusClient will set up a WebRTC session to a live camera feed, given a signaling url.  Here are the steps needed:

Create peer connection instance
"Create" Janus session
"Attach" streaming plugin
"Watch" the stream
Receive offer SDP
set offer sdp as remote description on peer connection
When notified video track added, notify delegate so the renderer (RTCEAGLVideoView) can be set
Create answer SDP
set answer SDP as local session description on peer connection
send answer SDP?
trickle candidates
trickle complete

*/


typedef void (^JsonRestCompletionBlock)(NSDictionary * message);

@interface CameraRestClient () <SAVWebrtcClientDelegate>

@property(nonatomic,strong) NSString *urlBase;
@property(nonatomic,strong) NSString *sessionId;
@property(nonatomic,weak) NSObject<CameraRestClientDelegate> *delegate;
@property(nonatomic,strong) SAVWebrtcClient *webrtc;

@end

@implementation CameraRestClient

- (instancetype)initWithDelegate:(NSObject<CameraRestClientDelegate>*)delegate {
  
  if ((self = [super init])) {
    self.delegate = delegate;
  }
  return self;
}

- (void)connectToUrl:(NSString*)url {
  self.urlBase = url;
  self.webrtc = [[SAVWebrtcClient alloc] initWithDelegate:self];
  
  //start signaling
  [self createSession];
    
}

- (void)attachVideoToView:(SAVVideoView *)videoView {
    [self.webrtc attachVideoToView:videoView];
}

- (void)hangup {
  [self deleteSession];
  self.sessionId = nil;
  [self.webrtc hangup];
  self.webrtc.delegate = nil;
  self.webrtc = nil;
}


- (void)post:(NSDictionary*)message toPath:(NSString*)path completion:(JsonRestCompletionBlock)completion {
    [self request:@"POST" body:message toPath:path completion:completion];
}

- (void)request:(NSString*)method body:(NSDictionary*)message toPath:(NSString*)path completion:(JsonRestCompletionBlock)completion {
    NSString *urlString = [self.urlBase stringByAppendingPathComponent:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    if (message != nil) {
        NSData *json = [NSJSONSerialization dataWithJSONObject:message options:0 error:nil];
        request.HTTPBody = json;
    }
    request.HTTPMethod = method;
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSDictionary *responseJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        completion(responseJson[@"payload"]);
    }];
    [task resume];
}

- (void)getFromPath:(NSString*)path completion:(JsonRestCompletionBlock)completion {
    NSString *urlString = [self.urlBase stringByAppendingPathComponent:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"GET";
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSDictionary *responseJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (responseJson == nil && data.length > 0) {
            NSString *sdp = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            sdp = [NSString stringWithFormat:@"{\"sdp\":%@}", sdp];
            responseJson = [NSJSONSerialization JSONObjectWithData:[sdp dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        }
        
        completion(responseJson[@"payload"]);
    }];
    [task resume];
}

/// MARK - Janus signaling utilities
  
- (void)createSession {
    self.sessionId = [NSUUID UUID].UUIDString;
    NSDictionary *msg = @{
                          @"id":self.sessionId,
                          @"url":@"savant.com",
                          @"stuns":@[@"10.101.2.17:3478"],
                          @"turns":@[@"10.101.2.17:3478"],
                          };
    
    [self post:msg toPath:@"/webrtc/sessions" completion:^(NSDictionary *message) {
        NSString *sdp = message[@"sdp"];
        [self.webrtc receiveOfferSdp:sdp];
    }];
}

- (void)deleteSession {
    NSString *path = [@"webrtc/sessions" stringByAppendingPathComponent:self.sessionId];
    [self request:@"DELETE" body:nil toPath:path completion:^(NSDictionary *message) {}];
}

/// MARK - WebrtcClient delegate implementation

- (void)webrtcClient:(SAVWebrtcClient *)client generatedAnswerSdp:(NSString *)sdp {
    NSString *path = [[@"webrtc/sessions" stringByAppendingPathComponent:self.sessionId] stringByAppendingPathComponent:@"answer"];
    NSDictionary *msg = @{ @"sdp": sdp };
    [self post:msg toPath:path completion:^(NSDictionary *message) {
        
    }];
}


- (void)webrtcClient:(SAVWebrtcClient *)client generatedCandidate:(NSDictionary *)candidate {
    NSString *path = [[@"webrtc/sessions" stringByAppendingPathComponent:self.sessionId] stringByAppendingPathComponent:@"candidates"];

    [self post:candidate toPath:path completion:^(NSDictionary *message) {
        
    }];
}

- (void)webrtcClientFinishedGeneratingCandidates:(SAVWebrtcClient *)client {
    NSString *path = [[@"webrtc/sessions" stringByAppendingPathComponent:self.sessionId] stringByAppendingPathComponent:@"candidates"];
    [self request:@"PUT" body:nil toPath:path completion:^(NSDictionary *message) {}];
}

- (void)webrtcClientReadyToAttachVideo:(SAVWebrtcClient *)client {
    [self.delegate cameraRestClientReadyToAttachVideo:self];
}

@end