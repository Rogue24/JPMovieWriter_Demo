//
//  RecordCacheTool.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/3/27.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import WCDBSwift

let VideoDotName = "jp_video"
let CoverDotName = "jp_cover"

enum RecordDot: Int, Codable, CaseIterable {
    case recording
    case recordCache
    case cover
    
    var dotPath: String {
        switch self {
        case .recording:
            return File.tmpFilePath(VideoDotName)
        case .recordCache:
            return File.documentFilePath(VideoDotName)
        case .cover:
            return File.documentFilePath(CoverDotName)
        }
    }
    
    func filePath(_ fileName: String) -> String { dotPath + "/" + fileName }
}

enum RecordCacheTool {

    static func setup() {
        RecordDot.allCases.forEach { File.manager.createDirectory($0.dotPath) }
        WCDBManager.shared.createTable(table: RecordCache.tableName, of: RecordCache.self)
    }
    
    static func insertOrReplace(_ recordCache: RecordCache) {
        WCDBManager.shared.insertOrReplaceToDb(
            object: recordCache,
            table: RecordCache.tableName
        )
    }
    
    static func delete(_ recordCache: RecordCache) {
        File.manager.deleteFile(recordCache.recordCachePath)
        File.manager.deleteFile(recordCache.coverPath)
        let identifier = recordCache.identifier
        WCDBManager.shared.deleteFromDb(
            fromTable: RecordCache.tableName,
            where: RecordCache.Properties.identifier == identifier
        )
    }
    
    static func update(_ identifier: Int,
                       videoTitle: String? = nil,
                       coverRatio: Double? = nil,
                       coverTag: Int? = nil,
                       isEditedCover: Bool? = nil,
                       recordTimeInt: Int? = nil) {
        guard videoTitle != nil || coverRatio != nil || coverTag != nil || isEditedCover != nil || recordTimeInt != nil else { return }
        
        var propertys: [PropertyConvertible] = []
        var row: [ColumnEncodable] = []
        
        if let videoTitle = videoTitle {
            propertys.append(RecordCache.Properties.videoTitle)
            row.append(videoTitle)
        }
        
        if let coverRatio = coverRatio {
            propertys.append(RecordCache.Properties.coverRatio)
            row.append(coverRatio <= 0 ? 1 : coverRatio)
        }
        
        if let coverTag = coverTag {
            propertys.append(RecordCache.Properties.coverTag)
            row.append(coverTag)
        }
        
        if let isEditedCover = isEditedCover {
            propertys.append(RecordCache.Properties.isEditedCover)
            row.append(isEditedCover)
        }
        
        if let recordTimeInt = recordTimeInt {
            propertys.append(RecordCache.Properties.recordTimeInt)
            row.append(recordTimeInt)
        }
        
        WCDBManager.shared.updateToDb(
            table: RecordCache.tableName,
            on: propertys,
            with: row,
            where: RecordCache.Properties.identifier == identifier
        )
    }
    
    // 自定义orderBy
    static func qurey(where condition: Condition? = nil,
                      orderBy orderList: [OrderBy]? = nil,
                      limit: Limit? = nil,
                      offset: Offset? = nil) -> [RecordCache] {
        WCDBManager.shared.qureyObjectsFromDb(
            fromTable: RecordCache.tableName,
            where: condition,
            orderBy: orderList,
            limit: limit,
            offset: offset
        ) ?? []
    }
    
    // 升降序
    static func qurey(where condition: Condition? = nil,
                      asOrder term: OrderTerm? = nil,
                      limit: Limit? = nil,
                      offset: Offset? = nil) -> [RecordCache] {
        WCDBManager.shared.qureyObjectsFromDb(
            fromTable: RecordCache.tableName,
            where: condition,
            orderBy: [RecordCache.Properties.recordTimeInt.asOrder(by: term)],
            limit: limit,
            offset: offset
        ) ?? []
    }
    
}

extension RecordCacheTool {
    static func recordDoneToSave(_ cache: RecordCache, recordFilePath: String) {
        if cache.recordTimeInt == 0 {
            cache.recordTimeInt = Int(Date().timeIntervalSince1970)
            
            if cache.videoTitle.count == 0 {
                cache.videoTitle = UIConfig.titles.randomElement()!
            }
        }
        
        File.manager.deleteFile(cache.recordCachePath)
        File.manager.moveFile(recordFilePath, toPath: cache.recordCachePath)
        
        let asset = AVURLAsset(url: URL(fileURLWithPath: cache.recordCachePath))
        if !cache.isEditedCover || !File.manager.fileExists(cache.coverPath) {
            let result = VideoTool.getVideoImage(with: asset,
                                                 time: asset.duration,
                                                 maximumSize: UIConfig.videoSize)
            switch result {
            case let .success(image):
                if let imageData = image.jpegData(compressionQuality: 0.9) {
                    File.manager.deleteFile(cache.coverPath)
                    cache.coverRatio = 1
                    cache.coverTag += 1
                    do {
                        try imageData.write(to: URL(fileURLWithPath: cache.coverPath))
                        cache.coverRatio = image.size.width / image.size.height
                    } catch {}
                }
            default:
                break
            }
        }
        
        insertOrReplace(cache)
        
        if let videoTrack = asset.tracks(withMediaType: .video).first {
            let videoSize = File.manager.fileSize(cache.recordCachePath)
            let sizeStr = File.fileSizeString(videoSize)
            JPrint("videoTrack.nominalFrameRate", videoTrack.nominalFrameRate)
            JPrint("videoTrack.estimatedDataRate", videoTrack.estimatedDataRate)
            JPrint("videoTrack.naturalSize", videoTrack.naturalSize)
            JPrint("videoFileSize", sizeStr)
            JPrint("=================")
        }
    }
}
