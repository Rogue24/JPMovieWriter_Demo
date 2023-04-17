//
//  UIImageView.Extension.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/3/10.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import Kingfisher

extension JP where Base: UIImageView {
    func cancelSetImage() {
        base.kf.cancelDownloadTask()
    }
    
    @discardableResult
    func fadeSetImage(with url: URL?,
                      placeholder: UIImage? = nil,
                      viewSize: CGSize? = nil,
                      isForceRefresh: Bool = false,
                      progressBlock: DownloadProgressBlock? = nil,
                      completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) -> DownloadTask?
    {
        return setImage(with: url,
                        placeholder: placeholder,
                        viewSize: viewSize,
                        isForceRefresh: isForceRefresh,
                        transition: .fade(0.25),
                        progressBlock: progressBlock,
                        completionHandler: completionHandler)
    }
    
    @discardableResult
    func setImage(with url: URL?,
                  placeholder: UIImage? = nil,
                  viewSize: CGSize? = nil,
                  isForceRefresh: Bool = false,
                  transition: ImageTransition? = nil,
                  progressBlock: DownloadProgressBlock? = nil,
                  completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) -> DownloadTask?
    {
        var options = KingfisherOptionsInfo()
        options.append(.cacheOriginalImage)
        options.append(.backgroundDecode)
        
        if let viewSize = viewSize, viewSize.width > 0, viewSize.height > 0 {
            let processor = DownsamplingImageProcessor(size: viewSize)
            options.append(.processor(processor))
            options.append(.scaleFactor(ScreenScale))
        }
        
        if isForceRefresh {
            options.append(.forceRefresh)
        }
        
        if let transition = transition {
            options.append(.transition(transition))
        }
        
        return base.kf.setImage(with: url,
                                placeholder: placeholder,
                                options: options,
                                progressBlock: progressBlock,
                                completionHandler: completionHandler)
    }
    
    func test(imageURL: URL, imageViewSize: CGSize) {
//        let imageURL = URL(fileURLWithPath: "/Users/aa/Desktop/381678022774sss.jpg")
//            let imageURL = LoremPicsum.photoURL(size: imageSize)
        
        JPrint(File.documentDirPath)
        
        JPrint("imageViewSize", imageViewSize)
        
        
        let processor = DownsamplingImageProcessor(size: imageViewSize)
//            let processor = ResizingImageProcessor(referenceSize: imageViewSize)
        
//            let processor = BlurImageProcessor(blurRadius: 10)
        
//            let processor = DownsamplingImageProcessor(size: imageViewSize)
//            |> ResizingImageProcessor(referenceSize: imageViewSize)
        
        
        base.kf.setImage(with: imageURL, options: [
            .processor(processor),
            .scaleFactor(ScreenScale),
            .cacheOriginalImage,
            .backgroundDecode
//                .cacheMemoryOnly,
//                .backgroundDecode,
        ]) { result in
            switch result {
            case .success(let value):
                let image = value.image
                JPrint("111 result", image.size, image.scale)
                switch value.cacheType {
                case .none:
                    JPrint("222 result none")
                case .memory:
                    JPrint("222 result 内存")
                case .disk:
                    JPrint("222 result 磁盘")
                }
                
            case .failure(let error):
                JPrint("Error: \(error)")
            }
        }
    }
}

