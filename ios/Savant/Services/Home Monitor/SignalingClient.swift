//
//  SignalingClient.swift
//  Savant
//
//  Created by Joseph Ross on 3/30/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation

protocol SignalingClientDelegate :NSObjectProtocol {
    func signalingClient(signalingClient:SignalingClient, disconnectedWithError error:NSError)
    func signalingClientReadyToAttachVideo(signalingClient:SignalingClient)
}

class SignalingClient : NSObject, SAVWebrtcClientDelegate {

    weak var delegate:SignalingClientDelegate? = nil
    var sessionId:String? = nil
    var iceServerJson:[String:AnyObject]? = nil
    var authorizationHeader:String? = nil
    let homeMonitor:HomeMonitor
    var longPollingCancelBlock:SCSCancelBlock? = nil
    var isLongPollingEnabled:Bool = false
    let signaling = Savant.signaling()
    var webrtc:SAVWebrtcClient? = nil
    
    
    init(monitor:HomeMonitor) {
        homeMonitor = monitor
        super.init()
    }
    
    func startSession() {
        let cancelBlock = signaling.createSignalingSession { (response:[String: AnyObject]?, error:NSError?) -> Void in
            if let error = error {
                self.delegate?.signalingClient(self, disconnectedWithError: error)
            } else if let response = response
                , let sessionId = response["sessionId"] as? String {
                    self.sessionId = sessionId
                    self.iceServerJson = response["iceServers"] as? [String: AnyObject]
                    self.startLongPolling()
                    self.sendHostStart()
                    self.startWebrtc()
            }
        }
    }
    
    func hangup() {
        stopLongPolling()
        webrtc?.hangup()
    }
    
    func startWebrtc() {
        
        webrtc = SAVWebrtcClient(delegate:self, iceServerJson:iceServerJson)
    }
    
    func sendHostStart() {
        if let sessionId = sessionId {
            let assUrl = Savant.control().cloudAssAddress
            var dict:[String: AnyObject] = ["sessionId" : sessionId, "url": "https://\(assUrl)"]
            if let iceServerJson = iceServerJson {
                dict["iceServers"] = iceServerJson
            }
            if let authorizationHeader = authorizationHeader {
                dict["authorizationHeader"] = authorizationHeader
            }
            let message = SAVHomeMonitorRequest(dictionary: dict, command:"start", homeMonitorId:String(homeMonitor.identifier))
            Savant.control().sendMessage(message)
        }
    }
    
    func startLongPolling() {
        isLongPollingEnabled = true
        if let sessionId = sessionId {
            longPollingCancelBlock = signaling.doLongPollForSession(sessionId, completion: { (response:[String: AnyObject]?, error:NSError?) -> Void in
                if let response = response {
                    self.handlePollingResponse(response)
                }
                if self.isLongPollingEnabled {
                    self.startLongPolling()
                }
            })
        }
    }
    
    func stopLongPolling() {
        isLongPollingEnabled = false
        if let longPollingCancelBlock = longPollingCancelBlock {
            longPollingCancelBlock()
        }
        longPollingCancelBlock = nil
    }
    
    func handlePollingResponse(response:[String: AnyObject]) {
        if let sdp = response["sdp"] as? String {
            webrtc?.receiveOfferSdp(sdp)
        }
        
    }
    
    /// MARK - WebrtcClientDelegate implementation
    func webrtcClientReadyToAttachVideo(client: SAVWebrtcClient!) {
        self.delegate?.signalingClientReadyToAttachVideo(self)
    }
    
    func webrtcClient(client: SAVWebrtcClient!, generatedAnswerSdp sdp: String!) {
        if let sessionId = sessionId {
            let message:[String:String] = ["sdp":sdp]
            let cancelBlock = signaling.sendMessageForSession(sessionId, message:message, completion:{ (response:[String: AnyObject]?, error:NSError?) -> Void in
            })
        }
    }
    
    func webrtcClient(client: SAVWebrtcClient!, generatedCandidate candidate: [NSObject : AnyObject]!) {
        if let sessionId = sessionId {
            if let candidate = candidate as? [String : AnyObject] {
                let cancelBlock = signaling.sendMessageForSession(sessionId, message:candidate, completion:{ (response:[String: AnyObject]?, error:NSError?) -> Void in
                })
            }
        }
    }
    func webrtcClientFinishedGeneratingCandidates(client: SAVWebrtcClient!) {
        if let sessionId = sessionId {
            let message = ["completed":"true"]
                let cancelBlock = signaling.sendMessageForSession(sessionId, message:message, completion:{ (response:[String: AnyObject]?, error:NSError?) -> Void in
                })
        }
    }
    
}