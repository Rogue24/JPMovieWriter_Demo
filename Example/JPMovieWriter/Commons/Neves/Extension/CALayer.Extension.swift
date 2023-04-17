//
//  CALayer.Extension.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2022/7/21.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

extension CALayer {
    
    var x: CGFloat {
        set { frame.origin.x = newValue }
        get { frame.origin.x }
    }
    var midX: CGFloat {
        set { frame.origin.x += (newValue - frame.midX) }
        get { frame.midX }
    }
    var maxX: CGFloat {
        set { frame.origin.x += (newValue - frame.maxX) }
        get { frame.maxX }
    }
    
    var y: CGFloat {
        set { frame.origin.y = newValue }
        get { frame.origin.y }
    }
    var midY: CGFloat {
        set { frame.origin.y += (newValue - frame.midY) }
        get { frame.midY }
    }
    var maxY: CGFloat {
        set { frame.origin.y += (newValue - frame.maxY) }
        get { frame.maxY }
    }
    
    var width: CGFloat {
        set { frame.size.width = newValue }
        get { frame.width }
    }
    
    var height: CGFloat {
        set { frame.size.height = newValue }
        get { frame.height }
    }
    
    var positionX: CGFloat {
        set { position.x = newValue }
        get { position.x }
    }
    var positionY: CGFloat {
        set { position.y = newValue }
        get { position.y }
    }
    
    var anchorPointX: CGFloat {
        set { anchorPoint.x = newValue }
        get { anchorPoint.x }
    }
    var anchorPointY: CGFloat {
        set { anchorPoint.y = newValue }
        get { anchorPoint.y }
    }
    
    var origin: CGPoint {
        set { frame.origin = newValue }
        get { frame.origin }
    }
    
    var size: CGSize {
        set { frame.size = newValue }
        get { frame.size }
    }
    
    var right: CGFloat {
        set {
            guard let superlayer = self.superlayer else { return }
            x = superlayer.width - width - newValue
        }
        get {
            guard let superlayer = self.superlayer else { return 0 }
            return superlayer.width - maxX
        }
    }
    
    var bottom: CGFloat {
        set {
            guard let superlayer = self.superlayer else { return }
            y = superlayer.height - height - newValue
        }
        get {
            guard let superlayer = self.superlayer else { return 0 }
            return superlayer.height - maxY
        }
    }
    
    var radian: CGFloat { value(forKeyPath: "transform.rotation.z") as? CGFloat ?? 0 }
    
    var angle: CGFloat { (radian * 180.0) / CGFloat.pi }
    
    var scaleX: CGFloat { value(forKeyPath: "transform.scale.x") as? CGFloat ?? 0 }
    
    var scaleY: CGFloat { value(forKeyPath: "transform.scale.y") as? CGFloat ?? 0 }
    
    var scale: CGPoint { .init(x: scaleX, y: scaleY) }
    
    var translationX: CGFloat { value(forKeyPath: "transform.translation.x") as? CGFloat ?? 0 }
    
    var translationY: CGFloat { value(forKeyPath: "transform.translation.x") as? CGFloat ?? 0 }
    
    var translation: CGPoint { .init(x: translationX, y: translationY) }
}
