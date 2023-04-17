//
//  LoremPicsum.swift
//  Neves
//
//  Created by 周健平 on 2022/3/24.
//
//  图片资源首页：https://picsum.photos
//  所有图片列表：https://picsum.photos/images
//  PS：此处`size`的单位是【像素】，如果想要适配手机像素，`size`的宽高记得乘以`UIScreen.main.scale`

enum LoremPicsum {
    
    static let baseURL = "https://picsum.photos"
    
    enum Option {
        /// 灰度
        case gray
        /// 模糊度（范围：1...10）
        case blur(value: Int)
        /// 灰度+模糊度（范围：1...10）
        case grayBlur(value: Int)
    }
    
    enum Suffix: String {
        case jpg
        case webp
    }
    
    /// 随机图片URL
    /// - Parameters:
    ///   - size: 图片尺寸（单位是【像素】，如果想要适配手机像素，`size`的宽高记得乘以`UIScreen.main.scale`）
    ///   - id: 图片ID（具体去 https://picsum.photos/images 查询）
    ///   - option: 图片效果
    ///   - randomId: 随机ID（当请求多个相同大小的图像时，添加该参数以防止获取缓存的同一图片）
    ///   - suffix: 图片后缀
    static func photoURL(size: CGSize,
                         id: Int? = nil,
                         option: Option? = nil,
                         randomId: Int? = nil,
                         suffix: Suffix? = nil) -> URL {
        var urlStr = Self.baseURL
        
        if let id = id {
            urlStr += "/id/\(id)"
        }
        
        urlStr += "/\(Int(size.width))/\(Int(size.height))"
        
        if let option = option {
            switch option {
            case .gray:
                urlStr += "?grayscale"
                
            case .blur(var value):
                value = value < 1 ? 1 : (value > 10 ? 10 : value)
                urlStr += "?blur=\(value)"
                
            case .grayBlur(var value):
                value = value < 1 ? 1 : (value > 10 ? 10 : value)
                urlStr += "?grayscale&blur=\(value)"
            }
        }
        
        if let randomId = randomId {
            if urlStr.contains("?") {
                urlStr += "&random=\(randomId)"
            } else {
                urlStr += "?random=\(randomId)"
            }
        }
        
        if let suffix = suffix {
            urlStr += ".\(suffix.rawValue)"
        }
        
        return URL(string: urlStr)!
    }
    
    /// 随机图片列表
    /// - Parameters:
    ///   - page: 页码
    ///   - limit: 每一页的图片数（默认30张一页）
    static func photoListURL(page: Int, limit: Int? = nil) -> URL {
        var urlStr = Self.baseURL + "/v2/list" + "?page=\(page)"
        
        if let limit = limit {
            urlStr += "&limit=\(limit)"
        }
        
        return URL(string: urlStr)!
    }
    
    /// 图片信息
    /// - Parameters:
    ///   - id: 图片ID（具体去 https://picsum.photos/images 查询）
    static func photoInfoURL(id: Int) -> URL {
        let urlStr = Self.baseURL + "/id/\(id)/info"
        return URL(string: urlStr)!
    }
    
}

extension LoremPicsum {
    /// 随机图片URL（自带随机ID，范围：1...10000）
    /// - Parameters:
    ///   - size: 图片尺寸（单位是【像素】，如果想要适配手机像素，`size`的宽高记得乘以`UIScreen.main.scale`）
    static func photoURLwithRandomId(size: CGSize) -> URL {
        return photoURL(size: size,
                        id: nil,
                        option: nil,
                        randomId: Int.random(in: 1...10000),
                        suffix: nil)
    }
    
    /// 随机图片URL
    /// - Parameters:
    ///   - size: 图片尺寸（单位是【像素】，如果想要适配手机像素，`size`的宽高记得乘以`UIScreen.main.scale`）
    ///   - randomId: 随机ID（当请求多个相同大小的图像时，添加该参数以防止获取缓存的同一图片）
    static func photoURL(size: CGSize, randomId: Int) -> URL {
        return photoURL(size: size,
                        id: nil,
                        option: nil,
                        randomId: randomId,
                        suffix: nil)
    }
    
    /// 随机图片URL
    /// - Parameters:
    ///   - size: 图片尺寸（单位是【像素】，如果想要适配手机像素，`size`的宽高记得乘以`UIScreen.main.scale`）
    ///   - option: 图片效果
    static func photoURL(size: CGSize, option: Option) -> URL {
        return photoURL(size: size,
                        id: nil,
                        option: option,
                        randomId: nil,
                        suffix: nil)
    }
    
    /// 随机图片URL
    /// - Parameters:
    ///   - size: 图片尺寸（单位是【像素】，如果想要适配手机像素，`size`的宽高记得乘以`UIScreen.main.scale`）
    static func photoURL(size: CGSize) -> URL {
        return photoURL(size: size,
                        id: nil,
                        option: nil,
                        randomId: nil,
                        suffix: nil)
    }
}
