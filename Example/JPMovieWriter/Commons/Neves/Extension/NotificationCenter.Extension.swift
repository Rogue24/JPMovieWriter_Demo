//
//  NotificationCenter.Extension.swift
//  Neves_Example
//
//  Created by 周健平 on 2020/10/12.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation

extension NotificationCenter: JPCompatible {}
extension JP where Base: NotificationCenter {
    
    static func removeObserver(_ observer: Any, name: NSNotification.Name? = nil, object: Any? = nil) {
        if let aName = name {
            Base.default.removeObserver(observer, name: aName, object: object)
        } else {
            Base.default.removeObserver(observer)
        }
    }
    
    static func addObserver(_ observer: Any, selector aSelector: Selector, name aName: NSNotification.Name, object anObject: Any? = nil) {
        Base.default.addObserver(observer, selector: aSelector, name: aName, object: anObject)
    }
    
    static func addObserver(_ observer: Any, selector aSelector: Selector, name aName: String, object anObject: Any? = nil) {
        Base.default.addObserver(observer, selector: aSelector, name: Notification.Name(rawValue: aName), object: anObject)
    }
    
    static func addObserver(forName name: NSNotification.Name, object obj: Any? = nil, queue: OperationQueue? = nil, using block: @escaping (Notification) -> Void) {
        Base.default.addObserver(forName: name, object: obj, queue: queue, using: block)
    }
    
    static func addObserver(forName name: String, object obj: Any? = nil, queue: OperationQueue? = nil, using block: @escaping (Notification) -> Void) {
        Base.default.addObserver(forName: Notification.Name(rawValue: name), object: obj, queue: queue, using: block)
    }
    
    static func post(name aName: NSNotification.Name, object anObject: Any? = nil, userInfo aUserInfo: [AnyHashable : Any]? = nil) {
        Base.default.post(name: aName, object: anObject, userInfo: aUserInfo)
    }
    
    static func post(name aName: String, object anObject: Any? = nil, userInfo aUserInfo: [AnyHashable : Any]? = nil) {
        Base.default.post(name: Notification.Name(rawValue: aName), object: anObject, userInfo: aUserInfo)
    }
    
}
