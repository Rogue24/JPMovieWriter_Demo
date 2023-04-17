//
//  RecordConfig.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/3/26.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

enum RecordConfig {
    static let videoMaxDuration: TimeInterval = 30
    
    static let bitRate = 2000000
    static let frameInterval = 20
    
    static var isFrontCamera = false
    
    static var isOnVortex = false
    
    static var videoOutputSettings: [String: Any] {
        let videoCleanApertureSettings: [String: Any] = [
            AVVideoCleanApertureWidthKey: UIConfig.videoSize.width,
            AVVideoCleanApertureHeightKey: UIConfig.videoSize.height,
            AVVideoCleanApertureHorizontalOffsetKey: 0,
            AVVideoCleanApertureVerticalOffsetKey: 0
        ]
        
        let videoAspectRatioSettings: [String: Any] = [
            AVVideoPixelAspectRatioHorizontalSpacingKey: 3,
            AVVideoPixelAspectRatioVerticalSpacingKey: 3
        ]
        
        let compressionProperties: [String: Any] = [
            AVVideoCleanApertureKey: videoCleanApertureSettings,
            AVVideoPixelAspectRatioKey: videoAspectRatioSettings,
            AVVideoAverageBitRateKey: bitRate, // 2000000 降低码率 体积更小
            AVVideoMaxKeyFrameIntervalKey: frameInterval,
            AVVideoProfileLevelKey: AVVideoProfileLevelH264Main31
        ]
        
        return [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: UIConfig.videoSize.width,
            AVVideoHeightKey: UIConfig.videoSize.height,
            AVVideoCompressionPropertiesKey: compressionProperties
        ]
    }
    
    static var audioOutputSettings: [String: Any] {
        let acl = UnsafeMutablePointer<AudioChannelLayout>.allocate(capacity: 1)
        let size = MemoryLayout<AudioChannelLayout>.size
        bzero(acl, size)
        acl.pointee.mChannelLayoutTag = kAudioChannelLayoutTag_Mono
        
        return [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey: 44100,
            AVEncoderBitRateKey: 64000,
            AVChannelLayoutKey: Data(bytes: acl, count: size)
        ]
    }
}

