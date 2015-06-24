//
//  VideoClip.swift
//  Savant
//
//  Created by Joseph Ross on 4/7/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import Foundation

// TODO: this should extend/composite some kind of ActivityEvent class, and use common factoring with other activity feed items
class VideoClipEvent : NSObject {
    let title:String
    let videoClips:[VideoClip]
    
    init(title:String, videoClips:[VideoClip]) {
        self.title = title
        self.videoClips = videoClips
        super.init()
    }
}

class VideoClip : NSObject {
    var title:String! = nil
    var videoUrl:NSURL! = nil
    var snapshotUrl:NSURL! = nil
    var recordDate:NSDate! = nil
    var duration:NSTimeInterval = 0
    
}
