//
//  HostServices.swift
//  Savant
//
//  Created by Joseph Ross on 3/26/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

public class HostServices : SAVRestServices {
    
    override init() {
        super.init()
    }
    
    public override func serviceScheme() -> String {
        return "http"
    }
    
    public override func serviceAddress() -> String {
        return Savant.control().currentSystem!.localAddress!;
    }
    
    public override func servicePort() -> Int {
        return 9000;
    }
    
    public override func serviceRequestBase() -> String {
        return ""
    }
    
    public override func attemptReloginWithFailureBlock(failureBlock: dispatch_block_t!) -> Bool {
        return Savant.scs().attemptReloginWithFailureBlock(failureBlock)
    }
    
    public override func urlRequestWithHTTPMethod(method: String!, request: String!, body: [NSObject : AnyObject]!, requiresAuth: Bool) -> NSURLRequest! {
        self.authenticationToken = Savant.credentials().cloudAuthenticationToken
        self.secretKey = Savant.credentials().cloudAuthenticationSecretKey
        self.userID = Savant.credentials().cloudAuthenticationID
        return super.urlRequestWithHTTPMethod(method, request: request, body: body, requiresAuth: requiresAuth)
    }
    
    public func fetchEndpointForCamera(cameraEntity:SAVCameraEntity, completionHandler:SCSResponseBlock) -> SCSCancelBlock {
        let cameraId = cameraEntity.identifier
        let request = urlRequestWithHTTPMethod("GET", request: "components/\(cameraId)/endpoint", body: nil, requiresAuth: true)
        return sendRequest(request, success: { (response:AnyObject!) -> Void in
            completionHandler(true, response, nil, false)
            }, failure: { (error:NSError!, isHttpError:Bool) -> Void in
            completionHandler(false, nil, error, isHttpError)
        })
    }
    
    public func getHomeCredentials(#success:([String:String]) -> Void, failure:(NSError!) -> Void) -> SCSCancelBlock {
        let request = urlRequestWithHTTPMethod("GET", request: "credentials", body: nil, requiresAuth: true)
        return sendRequest(request, success: { (response) -> Void in
            if let response = response as? [String:String] {
                success(response)
            } else {
                //TODO create official errors
                failure(NSError(domain: SCSResponseErrorDomain, code: 0, userInfo: ["localizedDescription":"Expected credentials to be a flat String -> String map"]))
            }
        }, failure: { (error, isHttpError) -> Void in
            failure(error)
        })
    }
}