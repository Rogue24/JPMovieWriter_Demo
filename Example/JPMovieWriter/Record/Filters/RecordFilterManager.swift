//
//  RecordFilterManager.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/4/4.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

class RecordFilterManager {
    let beautifyFilter: LFGPUImageBeautyFilter = {
        let filter = LFGPUImageBeautyFilter()
        filter.beautyLevel = RecordOption.Beauty.beautyLevel
        filter.brightLevel = RecordOption.Beauty.brightLevel
        return filter
    }()
    
    let lookupFilter: GPUImageLookupFilter = {
        let filter = GPUImageLookupFilter()
        filter.intensity = RecordOption.Filter.models[0].value
        return filter
    }()
    
//        let swirlFilter: GPUImageSwirlFilter = {
//            let filter = GPUImageSwirlFilter()
//            filter.radius = 0
//            return filter
//        }()
    
    let blendFilter: GPUImageAlphaBlendFilter = {
        let filter = GPUImageAlphaBlendFilter()
        filter.mix = 1
        return filter
    }()
    
    let watermarkElement: JPWatermarkElement = {
        let watermarkView = UIView(frame: CGRect(origin: .zero, size: UIConfig.videoViewSize))
        let filter = JPWatermarkElement(contentView: watermarkView)!
        return filter
    }()
    
    lazy var lookupImage: GPUImagePicture = {
        let filterPath = RecordOption.Filter.models[0].filePath
        let lookupTableImage = UIImage(contentsOfFile: filterPath)!
        return GPUImagePicture(image: lookupTableImage)!
    }()
    
    var watermarkView: UIView {
        return watermarkElement.contentView
    }
    
    func bridging(from target: GPUImageOutput) -> GPUImageOutput {
        target
            .jp_addTargetToNext(beautifyFilter)
            .jp_addTargetToNext(lookupFilter)
//                .jp_addTargetToNext(swirlFilter)
            .jp_addTargetToNext(blendFilter)
        
        //        camera.jp
        //            .addTargetToNext(beautifyFilter)
        //            .addTargetToNext(lookupFilter)
        //            .addTargetToNext(swirlFilter)
        //            .addTargetToNext(blendFilter)
        //                .addTarget(movieWriter)
        //            .addTargetToNext(previewView)
                
        //        camera
        //            .jp_addTargetToNext(beautifyFilter)
        //            .jp_addTargetToNext(lookupFilter)
        //            .jp_addTargetToNext(swirlFilter)
        //            .jp_addTargetToNext(blendFilter)
        //                .jp_addTarget(movieWriter)
        //                .jp_addTarget(previewView)
    }
    
    func bridgeDone() {
        lookupImage.addTarget(lookupFilter)
        lookupImage.useNextFrameForImageCapture()
        lookupImage.processImage()
        
        watermarkElement.addTarget(blendFilter)
        watermarkElement.update()
    }
    
    func switchLookup(ofFile filterPath: String, intensity: CGFloat) {
        lookupImage.removeFramebuffer()
        lookupImage.removeAllTargets()
        
        let lookupTableImage = UIImage(contentsOfFile: filterPath)!
        lookupImage = GPUImagePicture(image: lookupTableImage)!

        lookupImage.addTarget(lookupFilter)
        lookupImage.useNextFrameForImageCapture()
        lookupImage.processImage()
        
        lookupFilter.intensity = intensity
    }
    
    func updateWatermark() {
        watermarkElement.update()
    }
    
    var beautyLevel: CGFloat {
        set { beautifyFilter.beautyLevel = newValue }
        get { beautifyFilter.beautyLevel }
    }
    
    var brightLevel: CGFloat {
        set { beautifyFilter.brightLevel = newValue }
        get { beautifyFilter.brightLevel }
    }
    
    var lookupIntensity: CGFloat {
        set { lookupFilter.intensity = newValue }
        get { lookupFilter.intensity }
    }
}
