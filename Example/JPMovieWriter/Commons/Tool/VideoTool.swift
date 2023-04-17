//
//  VideoTool.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/4/5.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import AVKit

enum VideoTool {
    static let workQueue = DispatchQueue(label: "VideoTool")
    static let workLock = DispatchSemaphore(value: 0)
    static var exporterSession: AVAssetExportSession?
    
    enum ContentMode {
        case scaleToFill
        case scaleAspectFit // contents scaled to fit with fixed aspect. remainder is transparent
        case scaleAspectFill // contents scaled to fill with fixed aspect. some portion of content may be clipped.
    }
    
    static func mergeVideos(_ videoFileUrls: [URL],
                            videoSize: CGSize? = nil,
                            contentMode: ContentMode = .scaleToFill,
                            maxDuration: CMTime? = nil,
                            success: ((_ mergedFilePath: String) -> ())?,
                            faild: ((_ error: Error?) -> ())?) {
        guard videoFileUrls.count > 0 else {
            if let faild = faild {
                Asyncs.main { faild(nil) }
            }
            return
        }
        
        workQueue.async {
            _mergeVideos(videoFileUrls, videoSize, contentMode, maxDuration) { filePath in
                guard let success = success else { return }
                Asyncs.main { success(filePath) }
            } faild: { error in
                JPrint("error", error ?? "diaonim")
                guard let faild = faild else { return }
                Asyncs.main { faild(error) }
            }
        }
    }
    
    static private func _mergeVideos(_ videoFileUrls: [URL],
                                     _ videoSize: CGSize?,
                                     _ contentMode: ContentMode,
                                     _ maxDuration: CMTime?,
                                     success: ((_ mergedFilePath: String) -> ())?,
                                     faild: ((_ error: Error?) -> ())?) {
        let composition = AVMutableComposition()
        
        guard let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            JPrint("000 faild")
            faild?(nil)
            return
        }
        
        let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        // TODO: - 使用了AVMutableVideoComposition码率会翻倍，导致视频文件体积变大，日后务必解决！
        var videoComposition: AVMutableVideoComposition? = nil
        var instructions: [AVMutableVideoCompositionInstruction] = []
        
        var startTime = CMTime.zero
        var renderSize: CGSize = videoSize ?? .zero
        
        for i in 0 ..< videoFileUrls.count {
            let fileURL = videoFileUrls[i]
            let asset = AVURLAsset(url: fileURL, options: [
                // 为true，duration需要返回一个精确值，计算量会比较大，耗时比较长。
                AVURLAssetPreferPreciseDurationAndTimingKey: true,
            ])
            
            var duration = CMTime.zero
            var isOver = false
            
            guard let videoTrack = asset.tracks(withMediaType: .video).first else {
                JPrint("111 faild")
                faild?(nil)
                return
            }
            
            duration = videoTrack.timeRange.duration
            if let maxDuration = maxDuration {
                let totalDuration = CMTimeAdd(startTime, duration)
                if totalDuration > maxDuration {
                    duration = CMTimeSubtract(duration, CMTimeSubtract(totalDuration, maxDuration))
                    isOver = true
                }
            }

            let videoTimeRange = CMTimeRange(start: .zero, duration: duration)
            do {
                try videoCompositionTrack.insertTimeRange(videoTimeRange, of: videoTrack, at: startTime)
            } catch {
                JPrint("222 faild")
                faild?(nil)
                return
            }
            
            if let audioCompositionTrack = audioCompositionTrack, let audioTrack = asset.tracks(withMediaType: .audio).first {
                let audioTimeRange = CMTimeRange(start: .zero, duration: CMTimeMinimum(duration, audioTrack.timeRange.duration))
                do {
                    try audioCompositionTrack.insertTimeRange(audioTimeRange, of: audioTrack, at: startTime)
                } catch {
                    JPrint("333 faild")
                    faild?(nil)
                    return
                }
            }
            
            JPrint("videoTrack.nominalFrameRate", videoTrack.nominalFrameRate)
            JPrint("videoTrack.estimatedDataRate", videoTrack.estimatedDataRate)
            
            let naturalSize = videoTrack.naturalSize
            let preferredTransform = videoTrack.preferredTransform
            let preferredSize = CGRect(origin: .zero, size: naturalSize).applying(preferredTransform).size
            if renderSize.equalTo(.zero) {
                renderSize = preferredSize
            }
            
            JPrint("naturalSize", naturalSize)
            JPrint("preferredTransform is identity ---", preferredTransform == .identity)
            JPrint("preferredSize", preferredSize)
            JPrint("renderSize", renderSize)
            
            /// 使用了AVMutableVideoComposition码率会翻倍，导致视频文件体积变大，
            /// 尽可能不用，真的需要才用吧
            if videoComposition == nil {
                if preferredTransform != .identity {
                    // 1.视频已经发生了形变（经过了相册的编辑）
                    videoComposition = AVMutableVideoComposition()
                } else if let videoSize = videoSize {
                    // 2.【目标视频尺寸videoSize】与【实际视频尺寸preferredSize】不一样
                    if videoSize != preferredSize {
                        videoComposition = AVMutableVideoComposition()
                    }
                } else if contentMode != .scaleToFill {
                    let renderRatio = renderSize.width / renderSize.height
                    let preferredRatio = preferredSize.width / preferredSize.height
                    // 3.非拉伸的情况下，【导出视频宽高比renderRatio】与【实际视频宽高比preferredRatio】不一样
                    if renderRatio != preferredRatio {
                        videoComposition = AVMutableVideoComposition()
                    }
                }
            }
            
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
            let transform = buildVideoTransform(contentMode, renderSize, preferredSize, preferredTransform)
            layerInstruction.setTransform(transform, at: .zero)
            
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: startTime, duration: duration)
            instruction.layerInstructions = [layerInstruction]
            instructions.append(instruction)
            
            JPrint("startTime", CMTimeGetSeconds(startTime))
            JPrint("duration", CMTimeGetSeconds(duration))
            startTime = CMTimeAdd(startTime, duration)
            JPrint("totalDuration", CMTimeGetSeconds(startTime))
            JPrint("-----------------------")
            if isOver {
                break
            }
        }
        
        // 如果创建了audioCompositionTrack，但是没有往audioCompositionTrack导入音频的话会【合成错误】
        if let audioCompositionTrack = audioCompositionTrack, audioCompositionTrack.segments.count == 0 {
            // 没有音频就得手动移除
            composition.removeTrack(audioCompositionTrack)
        }
        
        guard let exporterSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            JPrint("444 faild")
            faild?(nil)
            return
        }
        self.exporterSession = exporterSession
        
        if let videoComposition = videoComposition {
            JPrint("使用了AVMutableVideoComposition")
            videoComposition.frameDuration = CMTime(value: 1, timescale: Int32(RecordConfig.frameInterval))
            videoComposition.renderScale = 1
            videoComposition.renderSize = renderSize
            videoComposition.instructions = instructions
            exporterSession.videoComposition = videoComposition
        }
        
        let exporterFileName = "\(Int(Date().timeIntervalSince1970)).mp4"
        let exporterFilePath = File.tmpFilePath(exporterFileName)
        let exporterFileURL = URL(fileURLWithPath: exporterFilePath)
        
        exporterSession.outputURL = exporterFileURL
        exporterSession.outputFileType = .mp4
        exporterSession.shouldOptimizeForNetworkUse = true
        exporterSession.exportAsynchronously {
            defer { workLock.signal() }
            JPrint("exporter 111 Thread.current", Thread.current)
            
            guard let exporterSession = self.exporterSession else {
                File.manager.deleteFile(exporterFilePath)
                JPrint("555 faild")
                faild?(nil)
                return
            }
            self.exporterSession = nil
            
            guard exporterSession.status == .completed else {
                File.manager.deleteFile(exporterFilePath)
                JPrint("666 faild")
                faild?(exporterSession.error)
                return
            }
            
            success?(exporterFilePath)
            
            // 去压缩？
//            VideoCompress.compressVideo(withVideoUrl: URL(fileURLWithPath: exporterFilePath), withBiteRate: NSNumber(value: RecordConfig.bitRate), withFrameRate: NSNumber(value: RecordConfig.frameInterval), withVideoWidth: NSNumber(value: Double(videoSize?.width ?? 500)), withVideoHeight: NSNumber(value: Double(videoSize?.height ?? 500))) { urlStr in
//                success?(urlStr)
//            }
        }
        
        workLock.wait()
        JPrint("exporter 222 Thread.current", Thread.current)
    }
    
    static func buildVideoTransform(_ contentMode: ContentMode,
                                    _ renderSize: CGSize,
                                    _ videoSize: CGSize,
                                    _ preferredTransform: CGAffineTransform) -> CGAffineTransform {
        let sx: CGFloat
        let sy: CGFloat
        switch contentMode {
        case .scaleToFill:
            sx = renderSize.width / videoSize.width
            sy = renderSize.height / videoSize.height
        case .scaleAspectFit:
            sx = min(renderSize.width / videoSize.width, renderSize.height / videoSize.height)
            sy = sx
        case .scaleAspectFill:
            sx = max(renderSize.width / videoSize.width, renderSize.height / videoSize.height)
            sy = sx
        }
        let tx = HalfDiffValue(renderSize.width, videoSize.width * sx)
        let ty = HalfDiffValue(renderSize.height, videoSize.height * sy)
        
        let scale = CGAffineTransform(scaleX: sx, y: sy)
        let move = CGAffineTransform(translationX: tx, y: ty)
        
        var transform = preferredTransform
        transform = CGAffineTransformConcat(transform, scale)
        transform = CGAffineTransformConcat(transform, move)
        return transform
    }
}
