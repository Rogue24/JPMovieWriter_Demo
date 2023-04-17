//
//  aaaaabbb.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/4/13.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

extension VideoInterception {
    class Cell: UICollectionViewCell {
        static let size: CGSize = [70.px, 70.px]
        
        let imageLayer = CALayer()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            imageLayer.frame = CGRect(origin: .zero, size: Self.size)
            imageLayer.contentsGravity = .resizeAspectFill
            imageLayer.masksToBounds = true
            imageLayer.contentsScale = 1
            contentView.layer.addSublayer(imageLayer)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setImageRef(_ imageRef: Any?) {
            imageLayer.contents = imageRef
        }
    }
}
