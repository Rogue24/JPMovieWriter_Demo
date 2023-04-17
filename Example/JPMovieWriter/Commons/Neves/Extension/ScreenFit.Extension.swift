//
//  ScreenFit.Extension.swift
//  Neves
//
//  Created by 周健平 on 2021/2/7.
//

// MARK: - 乘以`基准375宽`系数
extension Int {
    var px: CGFloat { CGFloat(self) * BasisWScale }
}

extension Float {
    var px: CGFloat { CGFloat(self) * BasisWScale }
}

extension Double {
    var px: CGFloat { CGFloat(self) * BasisWScale }
}

extension CGFloat {
    var px: CGFloat { self * BasisWScale }
}

extension CGPoint {
    var px: CGPoint { .init(x: self.x * BasisWScale, y: self.y * BasisWScale) }
    
    static func px(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x * BasisWScale, y: y * BasisWScale)
    }
}

extension CGSize {
    var px: CGSize { .init(width: self.width * BasisWScale, height: self.height * BasisWScale) }
    
    static func px(_ w: CGFloat, _ h: CGFloat) -> CGSize {
        CGSize(width: w * BasisWScale, height: h * BasisWScale)
    }
}

extension CGRect {
    var px: CGRect { .init(x: self.origin.x * BasisWScale,
                           y: self.origin.y * BasisWScale,
                           width: self.width * BasisWScale,
                           height: self.height * BasisWScale) }
    
    static func px(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
        CGRect(x: x * BasisWScale,
               y: y * BasisWScale,
               width: w * BasisWScale,
               height: h * BasisWScale)
    }
    
    static func px(_ origin: CGPoint, _ size: CGSize) -> CGRect {
        CGRect(origin: .init(x: origin.x * BasisWScale,
                             y: origin.y * BasisWScale),
               size: .init(width: size.width * BasisWScale,
                           height: size.height * BasisWScale))
    }
}

// MARK: - 乘以`屏幕缩放`系数
extension Int {
    var op: CGFloat { CGFloat(self) * ScreenScale }
}

extension Float {
    var op: CGFloat { CGFloat(self) * ScreenScale }
}

extension Double {
    var op: CGFloat { CGFloat(self) * ScreenScale }
}

extension CGFloat {
    var op: CGFloat { self * ScreenScale }
}

extension CGPoint {
    var op: CGPoint { .init(x: self.x * ScreenScale, y: self.y * ScreenScale) }
    
    static func op(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x * ScreenScale, y: y * ScreenScale)
    }
}

extension CGSize {
    var op: CGSize { .init(width: self.width * ScreenScale, height: self.height * ScreenScale) }
    
    static func op(_ w: CGFloat, _ h: CGFloat) -> CGSize {
        CGSize(width: w * ScreenScale, height: h * ScreenScale)
    }
}

extension CGRect {
    var op: CGRect { .init(x: self.origin.x * ScreenScale,
                           y: self.origin.y * ScreenScale,
                           width: self.width * ScreenScale,
                           height: self.height * ScreenScale) }
    
    static func op(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
        CGRect(x: x * ScreenScale,
               y: y * ScreenScale,
               width: w * ScreenScale,
               height: h * ScreenScale)
    }
    
    static func op(_ origin: CGPoint, _ size: CGSize) -> CGRect {
        CGRect(origin: .init(x: origin.x * ScreenScale,
                             y: origin.y * ScreenScale),
               size: .init(width: size.width * ScreenScale,
                           height: size.height * ScreenScale))
    }
}
