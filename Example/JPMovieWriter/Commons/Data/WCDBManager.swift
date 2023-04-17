//
//  WCDBManager.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/3/17.
//  Copyright © 2023 CocoaPods. All rights reserved.
//
//  版本：pod 'WCDB.swift', '~> 1.0.8.2'
//  学自1：https://www.jianshu.com/p/899541691876
//  学自2：https://blog.csdn.net/kyl282889543/article/details/100538486

import WCDBSwift

/// wcdb数据库
let dbPath = File.documentFilePath("ZJPWCDBDataBase/WCDBSwift.db")

class WCDBManager {

    static let shared = WCDBManager()

    static let defaultDatabase: Database = {
        return Database.init(withFileURL: URL.init(fileURLWithPath: dbPath))
    }()

    private var dataBase: Database?
    
    init() {
        dataBase = createDb()
        JPrint("dbPath ---", dbPath)
    }
    
}


// MARK: - 建

extension WCDBManager {
    
    // MARK: 创建db
    /// 创建db
    private func createDb() -> Database {
        return Database(withFileURL: URL.init(fileURLWithPath: dbPath))
    }

    // MARK: 创建表
    /// 创建表
    func createTable<T: TableDecodable>(table: String, of type: T.Type) -> Void {
        do {
            try dataBase?.create(table: table, of: type)
        } catch {
            print(error.localizedDescription)
        }
    }
    
}


// MARK: - 插

extension WCDBManager {
    
    // MARK: 插入（多个）
    /// 插入（多个）
    func insertToDb<T: TableEncodable>(objects: [T], table: String) -> Void {
        do {
            /// 如果主键存在的情况下，插入就会失败
            /// 执行事务
            try dataBase?.run(transaction: {
                try dataBase?.insert(objects: objects, intoTable: table)
            })
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: 插入或更新（单个）
    /// 插入或更新（单个）
    func insertOrReplaceToDb<T: TableEncodable>(object: T, table: String) -> Void {
        do {
            /// 执行事务
            try dataBase?.run(transaction: {
                try dataBase?.insertOrReplace(objects: object, intoTable: table)
            })
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: 插入或更新（多个）
    /// 插入或更新（多个）
    func insertOrReplaceToDb<T: TableEncodable>(objects: [T], table: String) -> Void {
        do {
            /// 执行事务
            try dataBase?.run(transaction: {
                try dataBase?.insertOrReplace(objects: objects, intoTable: table)
            })
        } catch {
            print(error.localizedDescription)
        }
    }
    
}


// MARK: - 改

extension WCDBManager {
    
    // MARK: 修改
    /// 通过`object`对象进行更新。
    /// 只会修改`propertys`中【包含】的字段。
    func updateToDb<T: TableEncodable>(table: String, on propertys: [PropertyConvertible], with object: T, where condition: Condition? = nil) -> Void {
        do {
            try dataBase?.update(table: table, on: propertys, with: object, where: condition)
        } catch {
            print(error.localizedDescription)
        }
    }
    /**
     🌰🌰🌰🌰🌰
     
         let propertys: [PropertyConvertible] = [RecordCache.Properties.videoTitle]
         let testCache = RecordCache()
         testCache.videoTitle = UIConfig.titles.randomElement()!
         testCache.coverRatio = Double.random(in: 4...7) / Double.random(in: 4...7)
     
         WCDBManager.shared.updateToDb(
             table: RecordCache.tableName,
             on: propertys,
             with: testCache,
             where: RecordCache.Properties.identifier == targetIdentifier
         )
     
     * 只有`videoTitle`会修改，其他字段的值不会变动。
     */
    
    // MARK: 修改（字段映射）
    /// 通过`row`来对数据进行更新。
    /// 只会修改`propertys`中【包含】的字段。
    /// - `propertys`中的第x个字段 ==对应修改的值==> `row`中的第x个值
    /// 如果映射的类型不一致，会类似OC那样尝试转型：
    /// - 例如字段类型本来是`Double`，`row`中对应的类型却是`"0.75"`（字符串类型），这种能转为`0.75`，而如果是`"hello"`或者取不到（超出了`row`的长度），则会转成`0`。
    func updateToDb(table: String, on propertys: [PropertyConvertible], with row: [ColumnEncodable], where condition: Condition? = nil) -> Void {
        do {
            try dataBase?.update(table: table, on: propertys, with: row, where: condition)
        } catch {
            print(error.localizedDescription)
        }
    }
    /**
     🌰🌰🌰🌰🌰
     
         let propertys: [PropertyConvertible] = [RecordCache.Properties.videoTitle, RecordCache.Properties.coverRatio, RecordCache.Properties.recordTimeInt]
         let row: [ColumnEncodable] = [UIConfig.titles.randomElement()!, "hello"]
     
         WCDBManager.shared.updateToDb(
             table: RecordCache.tableName,
             on: propertys,
             with: row,
             where: RecordCache.Properties.identifier == targetIdentifier
         )
     
     * 只有`videoTitle`会修改，`coverRatio`由于类型转换失败为0，`recordTimeInt`由于取出的是空值（超出了`row`的长度）所以为0。
     */
    
}


// MARK: - 删

extension WCDBManager {
    
    // MARK: 删除
    /// 删除
    func deleteFromDb(fromTable: String, where condition: Condition? = nil, orderBy orderList: [OrderBy]? = nil, limit: Limit? = nil, offset: WCDBSwift.Offset? = nil) {
        do {
            try dataBase?.run(transaction: {
                try dataBase?.delete(fromTable: fromTable, where: condition, orderBy: orderList, limit: limit, offset: offset)
            })
        } catch {
            print(error.localizedDescription)
        }
    }
    
}


// MARK: - 查

extension WCDBManager {
    
    // MARK: 查询
    /// 查询
    func qureyObjectsFromDb<T: TableDecodable>(fromTable: String, where condition: Condition? = nil, orderBy orderList: [OrderBy]? = nil, limit: Limit? = nil, offset: Offset? = nil) -> [T]? {
        do {
            let allObjects: [T]? = try (dataBase?.getObjects(fromTable: fromTable, where: condition, orderBy: orderList, limit: limit, offset: offset))!
            return allObjects
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }

    // MARK: 查询单条数据
    /// 查询单条数据
    func qureySingleObjectFromDb<T: TableDecodable>(fromTable: String, where condition: Condition? = nil, orderBy orderList: [OrderBy]? = nil) -> T? {
        do {
            let object: T? = try (dataBase?.getObject(fromTable: fromTable, where: condition, orderBy: orderList))
            return object
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
}
