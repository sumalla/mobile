//
//  HomeMonitor.swift
//  Savant
//
//  Created by Joseph Ross on 4/6/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import SDK

protocol HomeMonitorObserver : NSObjectProtocol {
    func homeMonitorDidChangeMode(homeMonitor:HomeMonitor)
    func homeMonitorDidUpdateSnapshot(homeMonitor:HomeMonitor, snapshot:UIImage)
}

class HomeMonitor: NSObject, CameraFetchDelegate {
    private let cameraEntity:SAVCameraEntity
    var endpointURL:NSURL? = nil
    private var monitorMode = HomeMonitorMode.Unknown
    private var latestSnapshot:UIImage? = nil
    private var isFetchingSnapshots = false
    var loadSnapshotCompletionBlocks:[() -> Void] = []
    var localSnapshotFetchTimer:NSTimer? = nil
    weak var observer:HomeMonitorObserver? = nil
    
    let imageCache = SAVImageCache()
    
    let kSnapshotUpdateInterval:NSTimeInterval = 3.0
    
    private init(cameraEntity:SAVCameraEntity) {
        self.cameraEntity = cameraEntity
        super.init()
        //TODO: remove this temporary persistence mechanism
        monitorMode = HomeMonitorMode(rawValue: NSUserDefaults.standardUserDefaults().integerForKey(imageCacheKey()) ?? HomeMonitorMode.Unknown.rawValue)!
    }
    
    deinit {
        Savant.control().removeCameraObserver(self)
    }
    
    var name:String? {
        get {
            return cameraEntity.label
        }
    }
    
    var zoneName:String? {
        get {
            return cameraEntity.zoneName
        }
    }
    
    var identifier:Int {
        get {
            return cameraEntity.identifier
        }
    }
    
    var mode:HomeMonitorMode {
        return monitorMode
    }
    
    func updateMonitorMode(mode:HomeMonitorMode) {
        monitorMode = mode
        submitModeChange()
        for observer in Savant.control().homeMonitorObservers.allObjects {
            if let observer = observer as? HomeMonitorObserver {
                observer.homeMonitorDidChangeMode(self)
            }
        }
        
        //TODO: remove this temporary persistence mechanism
        NSUserDefaults.standardUserDefaults().setInteger(mode.rawValue, forKey: imageCacheKey())
    }
    
    class func allMonitors() -> [HomeMonitor] {
        return monitorsForService(nil)
    }
    
    class func monitorsForService(service:SAVService?) -> [HomeMonitor] {
        let allCameras = Savant.data().cameraEntities(nil, zone: nil, service: service)
        var items:[HomeMonitor] = map(allCameras) { (cameraObj) -> HomeMonitor in
            let camera = cameraObj as! SAVCameraEntity
            let homeMonitor = HomeMonitor(cameraEntity:camera)
            return homeMonitor
        }
        return items
    }
    
    var snapshot:UIImage? {
        if latestSnapshot == nil {
            latestSnapshot = imageCache.imageForKey(imageCacheKey())
        }
        return latestSnapshot
    }
    
    func imageCacheKey() -> String {
        return "homemonitor-\(identifier)-frame"
    }
    
    func startFetchingSnapshots() {
        let isHostLocal = Savant.control().connectionState == .Local
        if isHostLocal {
            localSnapshotFetchTimer?.invalidate()
            localSnapshotFetchTimer = NSTimer.scheduledTimerWithTimeInterval(kSnapshotUpdateInterval, target: self, selector: Selector("loadLocalSnapshot"), userInfo: nil, repeats: true)
            loadLocalSnapshot()
        } else {
            let message = SAVHomeMonitorRequest(dictionary:["frequency":1.0 / kSnapshotUpdateInterval, "large":true], command:"startFetch", homeMonitorId:String(identifier))
            Savant.control().sendMessage(message)
            Savant.control().addCameraObserver(self)
        }
    }
    
    func stopFetchingSnapshots() {
        let isHostLocal = Savant.control().connectionState == .Local
        if isHostLocal {
            localSnapshotFetchTimer?.invalidate()
            localSnapshotFetchTimer = nil
        } else {
            let message = SAVHomeMonitorRequest(dictionary:[:], command:"stopFetch", homeMonitorId:String(identifier))
            Savant.control().sendMessage(message)
            Savant.control().removeCameraObserver(self)
        }
    }
    
    func didReceiveSnapshot(snapshot:UIImage) {
        self.latestSnapshot = snapshot
        self.imageCache.setImage(snapshot, forKey: self.imageCacheKey(), andSize: .Original)
        self.observer?.homeMonitorDidUpdateSnapshot(self, snapshot: snapshot)
    }
    
    func loadLocalSnapshot() {
        if endpointURL == nil {
            fetchEndpoint({ self.loadLocalSnapshot() })
        } else {
            if let urlString = endpointURL?.absoluteString?.stringByAppendingPathComponent("frames/current"),
                    let url = NSURL(string: urlString) {
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), { () -> Void in
                    if let data = NSData(contentsOfURL: url)
                        , let image = UIImage(data:data) {
                            dispatch_async(dispatch_get_main_queue(), {
                                self.didReceiveSnapshot(image)
                            });
                    }
                });
            }
        }
    }
    
    func fetchEndpoint(completion:() -> Void) {
        if !Savant.control().connectedRemotely {
            let cancelBlock = Savant.control().fetchEndpointForCamera(cameraEntity, completionHandler: { (isSuccess, response:AnyObject!, error, isHttpError) -> Void in
                if let response = response as? NSDictionary,
                    let endpoint:String = response["url"] as? String {
                        self.endpointURL = NSURL(string:endpoint)
                        completion()
                }
            })
        }
    }
    
    func fetchVideoClipEvents(completion:([VideoClipEvent]) -> Void) {
        let videoClip1 = VideoClip()
        videoClip1.title = "Joe"
        videoClip1.videoUrl = NSURL(string: "http://10.101.3.159/savantcloud-videoclips1-uswest2/an/Dan/0bcdf622-2243-4382-ae79-4dda48738a20.mp4")
        videoClip1.snapshotUrl = NSURL(string:"http://10.11.200.21:9001/frames/current")
        videoClip1.recordDate = NSDate()
        videoClip1.duration = 12.897
        
        let videoClip2 = VideoClip()
        videoClip2.title = "Patrick"
        videoClip2.videoUrl = NSURL(string: "http://10.101.3.159/savantcloud-videoclips1-uswest2/an/Dan/02e59dff-e1c0-48ac-8983-568e35b0808d.mp4")
        videoClip2.snapshotUrl = NSURL(string:"http://10.11.200.18:9001/frames/current")
        videoClip2.recordDate = NSDate()
        videoClip2.duration = 16.313
        
        let videoClipEvent = VideoClipEvent(title:"Joe & Patrick", videoClips:[videoClip1, videoClip2])
        
        
        let videoClip3 = VideoClip()
        videoClip3.title = "Andrew"
        videoClip3.videoUrl = NSURL(string: "http://10.101.3.159/savantcloud-videoclips1-uswest2/an/Dan/3af70ebc-5ae6-424a-921f-845ffeb47dc5.mp4")
        videoClip3.snapshotUrl = NSURL(string:"http://10.11.200.21:9001/frames/current")
        videoClip3.recordDate = NSDate()
        videoClip3.duration = 5
        
        let videoClipEvent2 = VideoClipEvent(title:"Andrew", videoClips:[videoClip3])
        
        completion([videoClipEvent, videoClipEvent2])
    }
    
    func submitModeChange() {
        let modeInt = mode == .Sense ? 0 : 1
        let message = SAVHomeMonitorRequest(dictionary:["mode":modeInt], command:"mode", homeMonitorId:String(identifier))
        Savant.control().sendMessage(message)
        
    }
    
    /// MARK - CameraFetchDelegate implementation
    
    func didReceiveImageData(imageData: NSData!, forSession sesion: String!) {
        if let snapshot = UIImage(data: imageData) {
            didReceiveSnapshot(snapshot)
        }
    }
    
    func registeredName() -> String! {
        return "homemonitor-\(identifier)"
    }
    
}

@objc enum HomeMonitorMode : Int {
        case Unknown = 0
        case Sense
        case Protect
};
