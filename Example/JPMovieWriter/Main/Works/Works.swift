//
//  Works.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/3/8.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import AVKit

struct Works: Identifiable {
    let id = UUID()
    
    let cache: RecordCache
    let asset: AVURLAsset
    let second: TimeInterval
    var timescale: CMTimeScale { asset.duration.timescale }
    
    var recordingPath: String { cache.recordingPath }
    var recordCachePath: String { cache.recordCachePath }
    var coverPath: String { cache.coverPath }
    var title: String { cache.videoTitle }
    var subtitle: String { cache.recordDateStr }
    
    let imageRatio: CGFloat
    let imageURL: URL
    let durationStr: String
    
    init(_ cache: RecordCache) {
        self.cache = cache
        self.asset = AVURLAsset(url: URL(fileURLWithPath: cache.recordCachePath))
        self.second = CMTimeGetSeconds(asset.duration)
        
        let secInt = Int(second)
        let sec = secInt % 60
        var min = secInt / 60
        if min >= 60 {
            let hour = min / 60
            min = min % 60
            self.durationStr = String(format: "%02d:%02d:%02d", hour, min, sec)
        } else {
            self.durationStr = String(format: "%02d:%02d", min, sec)
        }
        
        if cache.coverRatio <= 0 {
            self.imageRatio = 1
        } else {
            self.imageRatio = cache.coverRatio
        }
        
        if File.manager.fileExists(cache.coverPath) {
            self.imageURL = URL(fileURLWithPath: cache.coverPath)
        } else {
            self.imageURL = LoremPicsum.photoURLwithRandomId(size: [PortraitScreenWidth.op, (PortraitScreenWidth / self.imageRatio).op])
        }
    }
}

