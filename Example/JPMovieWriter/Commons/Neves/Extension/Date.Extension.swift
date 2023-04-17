//
//  Date.Extension.swift
//  Neves
//
//  Created by 周健平 on 2021/9/25.
//

extension Date: JPCompatible {}
extension JP where Base == Date {
    
    var mmssString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss"
        return formatter.string(from: base)
    }
    
    var ssString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss"
        return formatter.string(from: base)
    }
    
}
