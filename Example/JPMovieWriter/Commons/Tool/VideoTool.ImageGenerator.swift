//
//  VideoTool.ImageGenerator.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/3/22.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

extension VideoTool {
    class ImageGenerator {
        let videoAsset: AVURLAsset
        let generator: AVAssetImageGenerator
        
        var imgDic: [Int: UIImage] = [:]
        var imgTotalCount = 0
        var fps: Double = 0
        
        init?(videoAsset: AVURLAsset?) {
            guard let videoAsset = videoAsset else { return nil }
            
            self.videoAsset = videoAsset
            
            self.generator = AVAssetImageGenerator(asset: videoAsset)
            generator.maximumSize = [200, 200]
            generator.appliesPreferredTrackTransform = true
//            generator.requestedTimeToleranceAfter = .zero
//            generator.requestedTimeToleranceBefore = .zero
        }
        
        deinit {
            generator.cancelAllCGImageGeneration()
        }
        
        func asyncGenerateImages() {
            let totalSec = CMTimeGetSeconds(videoAsset.duration)
            
            imgTotalCount = Int(totalSec * 5)
            if imgTotalCount > 100 {
                imgTotalCount = 100 // 最多100张
            }
            
            fps = totalSec / Double(imgTotalCount)
            
            var times: [NSValue] = []
            
            for i in 0 ..< imgTotalCount {
                let time = CMTime(seconds: Double(i) * fps, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                times.append(NSValue(time: time))
            }
            
            let totalCount = times.count
            var count = 0
            
            generator.generateCGImagesAsynchronously(forTimes: times) { [weak self] requestedTime, imageRef, actualTime, result, error in
                guard let self = self else { return }
                
                defer {
                    count += 1
                    if count == totalCount {
                        JPrint("全部加载完了")
                    }
                }
                
                let key = Int(CMTimeGetSeconds(requestedTime) * 1000)

                guard result == .succeeded, let imageRef = imageRef else {
                    JPrint("失败 key:", key)
                    return
                }
                
                JPrint("成功 key:", key)
                let image = UIImage(cgImage: imageRef)
                
                Asyncs.main {
                    self.imgDic[key] = image
                }
            }
        }
        
        func getVideoImage(_ seconds: TimeInterval) -> UIImage? {
            let multiple = floor(seconds / fps)
            let key = Int(multiple * fps * 1000)
    //        JPrint("要取 key:", key)
            return imgDic[key]
        }
        
        func asyncGetVideoImage(at time: CMTime, complete: @escaping (_ result: Result<CGImage, Error>) -> Void) {
            Asyncs.async {
                do {
                    let imageRef = try self.generator.copyCGImage(at: time, actualTime: nil)
                    Asyncs.main { complete(.success(imageRef)) }
                } catch {
                    Asyncs.main { complete(.failure(error)) }
                }
            }
        }
    }

    static func getVideoImage(with asset: AVURLAsset,
                              time: CMTime,
                              maximumSize: CGSize) -> Result<UIImage, Error> {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.maximumSize = maximumSize
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceAfter = .zero
        generator.requestedTimeToleranceBefore = .zero
        do {
            let imageRef = try generator.copyCGImage(at: time, actualTime: nil)
            return .success(UIImage(cgImage: imageRef))
        } catch {
            return .failure(error)
        }
    }
    
    static func asyncGetVideoImage(with asset: AVURLAsset,
                                   time: CMTime,
                                   maximumSize: CGSize,
                                   complete: @escaping (_ result: Result<UIImage, Error>) -> ()) {
        Asyncs.async {
            let result = getVideoImage(with: asset,
                                       time: time,
                                       maximumSize: maximumSize)
            Asyncs.main {
                complete(result)
            }
        }
    }
}
