//
//  Photo.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2022/5/21.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Photos

enum PhotoSaveType {
    case image(_ image: UIImage)
    case video(_ videoURL: URL)
    case file(_ fileURL: URL)
    
    var changeRequest: PHAssetChangeRequest? {
        switch self {
        case let .image(img):
            return PHAssetChangeRequest.creationRequestForAsset(from: img)
        case let .video(url):
            return PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        case let .file(url):
            return PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
        }
    }
}

enum PhotoSaveError: Error {
    case getAlbumFail(_ error: Error? = nil)
    case saveFail(_ error: Error? = nil)
    case other(_ error: Error? = nil)
}

typealias PhotoSaveResult = Result<String, PhotoSaveError>

typealias PhotoSaveComplete = (PhotoSaveResult) -> ()

struct Photo {
    static let shared = Photo()
    
    /// app相册
    var appAssetCollection: PHAssetCollection? {
        let appName = Bundle.main.appName
        
        var appCollection: PHAssetCollection?
        let fetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        fetchResult.enumerateObjects { collection, _, stop in
            if collection.localizedTitle == appName {
                appCollection = collection
                stop.pointee = true
            }
        }
        
        guard appCollection == nil else { return appCollection }
        
        // 没有则新建相册（为了创建之后就能马上获取到相册）
        var assetID: String?
        do {
            try PHPhotoLibrary.shared().performChangesAndWait {
                assetID = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: appName).placeholderForCreatedAssetCollection.localIdentifier
            }
        } catch {}
        
        guard let assetID = assetID else { return nil }
        
        let result = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [assetID], options: nil)
        return result.firstObject
    }
    
    /// 保存图片/视频/文件到相册
    func save(_ type: PhotoSaveType, withAppAssetCollection isWith: Bool = true, completion: PhotoSaveComplete?) {
        guard !Thread.isMainThread else {
            Asyncs.async { save(type, withAppAssetCollection: isWith, completion: completion) }
            return
        }
        
        var assetID: String?
        var error: Error?
        do {
            try PHPhotoLibrary.shared().performChangesAndWait {
                assetID = type.changeRequest?.placeholderForCreatedAsset?.localIdentifier
            }
        } catch let kError {
            error = kError
        }
        
        saveDone(assetID, error, withAppAssetCollection: isWith, completion: completion)
    }
}

private extension Photo {
    func saveDone(_ assetID: String?, _ error: Error?, withAppAssetCollection isWith: Bool, completion: PhotoSaveComplete?) {
        let result: PhotoSaveResult
        if let assetID = assetID {
            result = .success(assetID)
        } else {
            result = .failure(.saveFail(error))
        }
        
        if isWith {
            switch result {
            case let .success(assetID):
                insert(asset: assetID, toAppAssetCollection: completion)
                return
            default:
                break
            }
        }
        
        guard let completion = completion else { return }
        if Thread.isMainThread {
            completion(result)
        } else {
            Asyncs.main { completion(result) }
        }
    }
    
    /// 将照片/视频/文件转移到App相册
    func insert(asset assetID: String, toAppAssetCollection completion: PhotoSaveComplete?) {
        guard !Thread.isMainThread else {
            Asyncs.async { insert(asset: assetID, toAppAssetCollection: completion) }
            return
        }
        
        var result: PhotoSaveResult = .success(assetID)
        defer {
            if let completion = completion {
                Asyncs.main { completion(result) }
            }
        }
        
        // 获得app相册
        guard let appAssetCollection = appAssetCollection else {
            result = .failure(.getAlbumFail())
            return
        }
        
        do {
            try PHPhotoLibrary.shared().performChangesAndWait {
                guard let request = PHAssetCollectionChangeRequest(for: appAssetCollection) else {
                    result = .failure(.saveFail())
                    return
                }
                
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
                request.insertAssets(assets, at: IndexSet(integer: 0))
            }
        } catch let error {
            result = .failure(.saveFail(error))
        }
    }
}
