//
//  JPError.swift
//  Neves
//
//  Created by 周健平 on 2021/6/4.
//

struct JPError {
    var error: Error?
    var msg: String
    var errorMsg: String { error.map { $0.localizedDescription } ?? "" }
    /// 错误信息的优先级：高 msg -> localizedDescription -> defaultMsg 低
    init(_ error: Error?, msg: String? = nil, _ defaultMsg: @autoclosure () -> String?) {
        self.error = error
        self.msg = msg ?? error.map { $0.localizedDescription } ?? defaultMsg() ?? ""
    }
}
