//
//  RecordOption.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/3/27.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

enum RecordOption: Int, CaseIterable {
    case beauty = 0
    case filter
    case watermark
    case vortex
    case flashlight
}

extension RecordOption {
    enum Beauty {
        static var beautyLevel: CGFloat = 0.5
        static var brightLevel: CGFloat = 0.5
    }
}

extension RecordOption {
    enum Filter: String, CaseIterable {
        /// 原图
        case origin
        /// 标准
        case normal
        /// 樱红滤镜
        case yinghong
        /// 云裳滤镜
        case yunshang
        /// 纯真滤镜
        case chunzhen
        /// 白兰滤镜
        case bailan
        /// 元气滤镜
        case yuanqi
        /// 超脱滤镜
        case chaotuo
        /// 香氛滤镜
        case xiangfen
        /// 美白滤镜
        case white
        /// 浪漫滤镜
        case langman
        /// 清新滤镜
        case qingxin
        /// 唯美滤镜
        case weimei
        /// 粉嫩滤镜
        case fennen
        /// 怀旧滤镜
        case huaijiu
        /// 蓝调滤镜
        case landiao
        /// 清凉滤镜
        case qingliang
        /// 日系滤镜
        case rixi
        
        var name: String {
            switch self {
            case .origin: return "原图"
            case .normal: return "标准"
            case .yinghong: return "樱红"
            case .yunshang: return "云裳"
            case .chunzhen: return "纯真"
            case .bailan: return "白兰"
            case .yuanqi: return "元气"
            case .chaotuo: return "超脱"
            case .xiangfen: return "香氛"
            case .white: return "美白"
            case .langman: return "浪漫"
            case .qingxin: return "清新"
            case .weimei: return "唯美"
            case .fennen: return "粉嫩"
            case .huaijiu: return "怀旧"
            case .landiao: return "蓝调"
            case .qingliang: return "清凉"
            case .rixi: return "日系"
            }
        }
        
        var filePath: String {
            Bundle.main.path(forResource: "FilterResource", ofType: "bundle")! + "/\(rawValue).png"
        }
        
        var defaultValue: CGFloat {
            switch self {
            case .origin: return 0
            case .normal: return 0.5
            case .yinghong: return 0.8
            case .yunshang: return 0.8
            case .chunzhen: return 0.7
            case .bailan: return 1
            case .yuanqi: return 0.8
            case .chaotuo: return 1
            case .xiangfen: return 0.5
            case .white,
                 .langman,
                 .qingxin,
                 .weimei,
                 .fennen,
                 .huaijiu,
                 .landiao,
                 .qingliang,
                 .rixi: return 0.3
            }
        }
        
        class Model {
            let filter: Filter
            var name: String { filter.name }
            var imgName: String { filter.rawValue }
            var filePath: String { filter.filePath }
            var value: CGFloat
            
            init(_ filter: Filter) {
                self.filter = filter
                self.value = filter.defaultValue
            }
        }
        
        static let models: [Model] = Filter.allCases.map { Model($0) }
    }
}

