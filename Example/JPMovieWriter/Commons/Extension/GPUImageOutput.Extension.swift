//
//  GPUImageOutput.Extension.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/3/24.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

//extension GPUImageOutput: JPCompatible {}
//extension JP where Base: GPUImageOutput {
//    @discardableResult
//    func addTargetToNext<T>(_ target: T) -> JP<T> where T: GPUImageInput {
//        base.addTarget(target)
//        return JP<T>(target)
//    }
//
//    @discardableResult
//    func addTarget<T>(_ target: T) -> JP<Base> where T: GPUImageInput {
//        base.addTarget(target)
//        return JP(base)
//    }
//}

extension GPUImageOutput {
    typealias OutputInput = GPUImageOutput & GPUImageInput
    typealias AnyInput = NSObject & GPUImageInput
    
    @discardableResult
    func jp_addTargetToNext(_ target: OutputInput) -> OutputInput {
        addTarget(target)
        return target
    }
    
    @discardableResult
    func jp_addTarget(_ target: AnyInput) -> Self {
        addTarget(target)
        return self
    }
}
