//
//  String.Extension.swift
//  Neves_Example
//
//  Created by 周健平 on 2020/10/9.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation

extension String: JPCompatible {}
extension NSString: JPCompatible {}
extension JP where Base: ExpressibleByStringLiteral {
    var isContainsChinese: Bool {
        if let str = base as? NSString {
            for i in 0..<str.length {
                let a = str.character(at: i)
                if a > 0x4e00, a < 0x9fff {
                    return true
                }
            }
        }
        return false
    }
    
    func textSize(withFont font: UIFont,
                  lineSpace: CGFloat = 0,
                  isOneLine: inout Bool,
                  maxSize: CGSize) -> CGSize {
        
        guard let str = base as? NSString else { return .zero }
        
        var attributes = [NSAttributedString.Key: Any]()
        attributes[.font] = font
        
        if lineSpace > 0 {
            let parag = NSMutableParagraphStyle()
            parag.lineSpacing = lineSpace
            attributes[.paragraphStyle] = parag
        }
        
        var rect = str.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        
        // 文本的高度 - 字体高度 > 行间距 -----> 判断为当前超过1行
        let isMoreThanOneLine = (rect.size.height - font.lineHeight) > lineSpace
        if !isMoreThanOneLine, self.isContainsChinese {
            rect.size.height -= lineSpace
        }
        
        if rect.size.height > 0, rect.size.height < font.lineHeight {
            rect.size.height = font.lineHeight
        }
        
        isOneLine = !isMoreThanOneLine
        return rect.size
    }
    
    func textSize(withFont font: UIFont,
                  lineSpace: CGFloat = 0,
                  maxSize: CGSize = [9999, 9999]) -> CGSize {
        
        guard let str = base as? NSString else { return .zero }
        
        var attributes = [NSAttributedString.Key: Any]()
        attributes[.font] = font
        
        if lineSpace > 0 {
            let parag = NSMutableParagraphStyle()
            parag.lineSpacing = lineSpace
            attributes[.paragraphStyle] = parag
        }
        
        var rect = str.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        
        // 文本的高度 - 字体高度 > 行间距 -----> 判断为当前超过1行
        let isMoreThanOneLine = (rect.size.height - font.lineHeight) > lineSpace
        if !isMoreThanOneLine, self.isContainsChinese {
            rect.size.height -= lineSpace
        }
        
        if rect.size.height > 0, rect.size.height < font.lineHeight {
            rect.size.height = font.lineHeight
        }
        
        return rect.size
    }
    
    var isEmpty: Bool {
        guard let str = base as? NSString else { return false }
        let set = NSCharacterSet.whitespacesAndNewlines
        return str.trimmingCharacters(in: set).count == 0
    }
    
    func urlParams() -> [String: Any]? {
        guard let str = base as? String else { return nil }
        
        let arr1 = str.components(separatedBy: "?")
        guard arr1.count > 1, let allParmStr = arr1.last else { return nil }
        
        let arr2 = allParmStr.components(separatedBy: "&")
        guard arr2.count > 0 else { return nil }
        
        var params = [String: Any]()
        for parmStr in arr2 {
            let arr3 = parmStr.components(separatedBy: "=")
            if arr3.count == 2, let key = arr3.first, let value = arr3.last {
                params[key] = value
            } else {
                continue
            }
        }
        return params
    }
}

extension String {
    var isContainsChinese: Bool {
        let str = self as NSString
        for i in 0..<str.length {
            let a = str.character(at: i)
            if a > 0x4e00, a < 0x9fff {
                return true
            }
        }
        return false
    }
    
    func textSize(withFont font: UIFont,
                  lineSpace: CGFloat,
                  isOneLine: inout Bool,
                  maxSize: CGSize = .init(width: 999, height: 999)) -> CGSize {
        
        var attributes = [NSAttributedString.Key: Any]()
        attributes[.font] = font
        
        if lineSpace > 0 {
            let parag = NSMutableParagraphStyle()
            parag.lineSpacing = lineSpace
            attributes[.paragraphStyle] = parag
        }
        
        var rect = (self as NSString).boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        
        // 文本的高度 - 字体高度 > 行间距 -----> 判断为当前超过1行
        let isMoreThanOneLine = (rect.size.height - font.lineHeight) > lineSpace
        if !isMoreThanOneLine, self.isContainsChinese {
            rect.size.height -= lineSpace
        }
        
        if rect.size.height > 0, rect.size.height < font.pointSize {
            rect.size.height = font.pointSize
        }
        
        isOneLine = !isMoreThanOneLine
        return rect.size
    }
    
}
