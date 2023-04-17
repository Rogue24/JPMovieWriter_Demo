//
//  UIImage.Extension.swift
//  Neves
//
//  Created by 周健平 on 2021/5/20.
//

extension UIImage: JPCompatible {}
extension JP where Base: UIImage {
    
    // 按照图片像素（字体根据比例相应缩放）
    var watermark: UIImage? {
        let scale = base.size.width / PortraitScreenWidth
        
        let str: NSString = "帅哥平哇哈哈哈哦"
        let font = UIFont.systemFont(ofSize: 20.px * scale)
        
        let shadow = NSShadow()
        shadow.shadowBlurRadius = 2
        shadow.shadowOffset = .zero
        shadow.shadowColor = UIColor.rgb(0, 0, 0, a: 0.3)
//        let attDic: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor(white: 1, alpha: 0.5), .shadow: shadow]
        let attDic: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.red, .shadow: shadow]
        
        let size = str.jp.textSize(withFont: font)
        let x = base.size.width - size.width - 7.5.px * scale
        let y = base.size.height - size.height - 7.5.px * scale
        let rect = CGRect(origin: [x, y], size: size)
        
        UIGraphicsBeginImageContextWithOptions(base.size, false, base.scale)
        base.draw(at: .zero)
        str.draw(in: rect, withAttributes: attDic)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    // 按照屏幕像素（图片像素不够就扩大）
    var watermarkOnScreenWidth: UIImage? {
        let str: NSString = "帅哥平哇哈哈哈哦"
        let font = UIFont.systemFont(ofSize: 20.px)
        
        let shadow = NSShadow()
        shadow.shadowBlurRadius = 2
        shadow.shadowOffset = .zero
        shadow.shadowColor = UIColor.rgb(0, 0, 0, a: 0.3)
//        let attDic: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor(white: 1, alpha: 0.5), .shadow: shadow]
        let attDic: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.red, .shadow: shadow]
        
        let size = str.jp.textSize(withFont: font)
        let x = PortraitScreenWidth - size.width - 7.5.px
        let y = PortraitScreenWidth - size.height - 7.5.px
        let rect = CGRect(origin: [x, y], size: size)
        
        let imgRect: CGRect
        if base.size.width > base.size.height {
            let imgY = HalfDiffValue(PortraitScreenWidth,  PortraitScreenWidth * (base.size.height / base.size.width))
            imgRect = [0, imgY, PortraitScreenWidth, PortraitScreenWidth - 2 * imgY]
        } else {
            let imgX = HalfDiffValue(PortraitScreenWidth,  PortraitScreenWidth * (base.size.width / base.size.height))
            imgRect = [imgX, 0, PortraitScreenWidth - 2 * imgX, PortraitScreenWidth]
        }
        
        UIGraphicsBeginImageContextWithOptions([PortraitScreenWidth, PortraitScreenWidth], false, ScreenScale)
//        base.draw(at: [imgX, imgY])
        base.draw(in: imgRect)
        str.draw(in: rect, withAttributes: attDic)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    static func fromBundle(_ name: String, type: String? = nil) -> UIImage? {
        Base(contentsOfFile: Bundle.jp.resourcePath(withName: name, type: type))
    }
    
    var isContainsAlpha: Bool { base.cgImage?.jp.isContainsAlpha ?? false }
}

extension CGImage: JPCompatible {}
extension JP where Base: CGImage {
    var isContainsAlpha: Bool {
        let alphaInfo = base.alphaInfo
        if alphaInfo == .premultipliedLast ||
            alphaInfo == .premultipliedFirst ||
            alphaInfo == .last ||
            alphaInfo == .first {
            return true
        }
        return false
    }
}
