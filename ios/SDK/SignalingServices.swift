//
//  SAVAssServices.swift
//  Savant
//
//  Created by Joseph Ross on 4/1/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation

public class SignalingServices: SAVRestServices {

    override init() {
        super.init()
    }
    
    public override func serviceScheme() -> String {
        return "https"
    }
    
    public override func serviceAddress() -> String {
        return Savant.control().cloudAssAddress;
    }

    public override func servicePort() -> Int {
        return Savant.control().cloudWebPort;
    }
    
    public override func serviceRequestBase() -> String {
        return ""
    }
    
    public override func attemptReloginWithFailureBlock(failureBlock: dispatch_block_t!) -> Bool {
        return Savant.scs().attemptReloginWithFailureBlock(failureBlock)
    }
    
    public override func urlRequestWithHTTPMethod(method: String!, request: String!, body: [NSObject : AnyObject]!, requiresAuth: Bool) -> NSURLRequest! {
        self.authenticationToken = Savant.scs().authenticationToken
        self.secretKey = Savant.scs().secretKey
        self.userID = Savant.scs().userID
        return super.urlRequestWithHTTPMethod(method, request: request, body: body, requiresAuth: requiresAuth)
    }
    
    public func createSignalingSession(completion:(response:[String : AnyObject]?, error:NSError?) -> Void) -> SCSCancelBlock {
        let request = urlRequestWithHTTPMethod("POST", request: "ass/start", body: nil, requiresAuth: true)
        return sendRequest(request, success: { (response:AnyObject!) -> Void in
            if let responseJSON = (response as? [String:AnyObject]) {
                completion(response:responseJSON, error:nil)
            }
            }) { (error:NSError!, isHttpError:Bool) -> Void in
                completion(response: nil, error: error)
        }
    }
    
    public func doLongPollForSession(sessionId:String, completion:(response:[String : AnyObject]?, error:NSError?) -> Void) -> SCSCancelBlock {
        let request = urlRequestWithHTTPMethod("GET", request: "ass/sessions/\(sessionId)", body: nil, requiresAuth: true) as! NSMutableURLRequest
        request.timeoutInterval = 60
        return sendRequest(request, success: { (response:AnyObject!) -> Void in
            if let responseJSON = (response as? [String:AnyObject]) {
                completion(response:responseJSON, error:nil)
            }
            }) { (error:NSError!, isHttpError:Bool) -> Void in
                completion(response: nil, error: error)
        }
    }
    
    public func sendMessageForSession(sessionId:String, message:[String:AnyObject], completion:(response:[String : AnyObject]?, error:NSError?) -> Void) -> SCSCancelBlock {
        let request = urlRequestWithHTTPMethod("POST", request: "ass/sessions/\(sessionId)", body: message, requiresAuth: true)
        return sendRequest(request, success: { (response:AnyObject!) -> Void in
            if let responseJSON = (response as? [String:AnyObject]) {
                completion(response:responseJSON, error:nil)
            }
            }) { (error:NSError!, isHttpError:Bool) -> Void in
                completion(response: nil, error: error)
        }
    }
}
