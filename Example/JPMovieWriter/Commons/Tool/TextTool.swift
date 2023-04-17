//
//  TextTool.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/3/10.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import YYText

enum TextTool {
    static func buildTextLayout(with text: String, font: UIFont, color: UIColor, space: CGFloat, maxSize: CGSize) -> YYTextLayout {
        let textAttStr = NSMutableAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
        var textLayout = YYTextLayout(containerSize: maxSize, text: textAttStr)!
        // 如果超出1行，得加上行距
        if textLayout.rowCount > 1 {
            let parag = NSMutableParagraphStyle()
            parag.lineSpacing = space
            textAttStr.addAttributes([.paragraphStyle: parag], range: NSRange(location: 0, length: textAttStr.string.count))
            // 重新计算文本高度
            textLayout = YYTextLayout(containerSize: maxSize, text: textAttStr)!
        }
        return textLayout
    }
    
    typealias AttStrResult = (attStr: NSAttributedString, textSize: CGSize)
    static func buildTextAttStr(with text: String, font: UIFont, color: UIColor, space: CGFloat, maxSize: CGSize) -> AttStrResult {
        let textAttStr = NSMutableAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
        var textSize = textAttStr.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, context: nil).size
        if textSize.height > font.lineHeight {
            let parag = NSMutableParagraphStyle()
            parag.lineSpacing = space
            textAttStr.addAttributes([.paragraphStyle: parag], range: NSRange(location: 0, length: textAttStr.string.count))
            // 重新计算文本高度
            textSize = textAttStr.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, context: nil).size
        }
        return (textAttStr, textSize)
    }
}

extension Float {
    var timeStr: String {
        return TimeInterval(self).timeStr
    }
}

extension CGFloat {
    var timeStr: String {
        return TimeInterval(self).timeStr
    }
}

extension TimeInterval {
    var timeStr: String {
        let sec: Int = Int(self)
        let second = sec % 60
        var minute = sec / 60
        guard minute >= 60 else {
            return String(format: "%02d:%02d", minute, second)
        }
        let hour = minute / 60
        minute %= 60
        return String(format: "%02d:%02d:%02d", hour, minute, second)
    }
}
