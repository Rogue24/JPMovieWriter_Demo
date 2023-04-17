//
//  RecordCache.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/3/28.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import WCDBSwift
import Foundation

final class RecordCache: TableCodable {
    var identifier: Int
    var videoTitle: String
    var coverRatio: Double
    var coverTag: Int
    var isEditedCover: Bool
    var recordTimeInt: Int
    
    /// 用于定义是否使用自增的方式插入
    var isAutoIncrement: Bool = true
    
    /// 用于获取自增插入后的主键值
    var lastInsertedRowID: Int64 = 0
    
    /// 对应数据库表名
    static var tableName: String { "RecordCache" }
    
    enum CodingKeys: String, CodingTableKey {
        typealias Root = RecordCache
        
        case identifier
        case videoTitle
        case coverRatio
        case coverTag
        case isEditedCover
        case recordTimeInt
        
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
            [identifier: ColumnConstraintBinding(isPrimary: true)]
        }
    }
    
    init(identifier: Int = Int(Date().timeIntervalSince1970),
         videoTitle: String = "",
         coverRatio: Double = 1,
         coverTag: Int = 0,
         isEditedCover: Bool = false,
         recordTimeInt: Int = 0)
    {
        self.identifier = identifier
        self.videoTitle = videoTitle
        self.coverRatio = coverRatio
        self.coverTag = coverTag
        self.isEditedCover = isEditedCover
        self.recordTimeInt = recordTimeInt
    }
    
    var recordingPath: String {
        let fileName = "\(identifier)" + ".mp4"
        return RecordDot.recording.filePath(fileName)
    }
    
    var recordCachePath: String {
        let fileName = "\(identifier)" + ".mp4"
        return RecordDot.recordCache.filePath(fileName)
    }
    
    var coverPath: String {
        let fileName = "\(identifier)_\(coverTag)" + ".jpg"
        return RecordDot.cover.filePath(fileName)
    }
    
    var recordDateStr: String {
        let date = recordTimeInt > 0 ? Date(timeIntervalSince1970: TimeInterval(recordTimeInt)) : Date()
        return UIConfig.videoDateFormatter.string(from: date)
    }
}

/*
 ColumnConstraintBinding(
     isPrimary: Bool = false, // 该字段是否为主键。字段约束中只能同时存在一个主键
     orderBy term: OrderTerm? = nil, // 当该字段是主键时，存储顺序是升序还是降序
     isAutoIncrement: Bool = false, // 当该字段是主键时，其是否支持自增。只有整型数据可以定义为自增。
     onConflict conflict: Conflict? = nil, // 当该字段是主键时，若产生冲突，应如何处理
     isNotNull: Bool = false, // 该字段是否可以为空
     isUnique: Bool = false, // 该字段是否可以具有唯一性
     defaultTo defaultValue: ColumnDef.DefaultType? = nil // 该字段在数据库内使用什么默认值
 )
*/
