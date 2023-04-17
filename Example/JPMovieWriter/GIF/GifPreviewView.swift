//
//  GifPreviewView.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/4/17.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import JPImageresizerView
import JPBasic

class GifPreviewView: UIView {
    static func show(_ gifImage: UIImage, saveHandler: @escaping () -> Void) {
        let gifView = GifPreviewView(gifImage, saveHandler)
        GetTopMostViewController()?.view.addSubview(gifView)
        Asyncs.main {
            gifView.show()
        }
    }
    
    let imageView = UIImageView()
    let blurView = UIVisualEffectView(effect: nil)
    let closeBtn = UIButton(type: .system)
    let saveBtn = UIButton(type: .system)
    
    var startY: CGFloat = 0
    
    let saveHandler: () -> Void
    
    init(_ gifImage: UIImage, _ saveHandler: @escaping () -> Void) {
        self.saveHandler = saveHandler
        super.init(frame: PortraitScreenBounds)
        
        blurView.frame = bounds
        addSubview(blurView)
        
        let btnWH = 55.px
        
        imageView.layer.cornerRadius = 8.px
        imageView.layer.masksToBounds = true
        imageView.image = gifImage
        imageView.frame = [16.px, 0, PortraitScreenWidth - 32.px, (PortraitScreenWidth - 32.px) * (gifImage.size.height / gifImage.size.width)]
        
        var totalH = imageView.height + 15.px + btnWH
        if totalH > (PortraitScreenHeight - StatusBarH - DiffTabBarH) {
            totalH = PortraitScreenHeight - StatusBarH - DiffTabBarH
            let imageViewH = totalH - 15.px - btnWH
            let imageViewW = imageViewH * (gifImage.size.width / gifImage.size.height)
            imageView.frame = [HalfDiffValue(PortraitScreenWidth, imageViewW), 0, imageViewW, imageViewH]
        }
        
        closeBtn.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        closeBtn.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15.px, weight: .medium)), for: .normal)
        closeBtn.tintColor = .white
        closeBtn.size = [btnWH, btnWH]
        closeBtn.layer.cornerRadius = btnWH * 0.5
        closeBtn.layer.masksToBounds = true
        closeBtn.backgroundColor = .systemBlue
        closeBtn.isUserInteractionEnabled = false
        
        saveBtn.addTarget(self, action: #selector(saveAction), for: .touchUpInside)
        saveBtn.setImage(UIImage(systemName: "square.and.arrow.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15.px, weight: .medium)), for: .normal)
        saveBtn.tintColor = .white
        saveBtn.size = [btnWH, btnWH]
        saveBtn.layer.cornerRadius = btnWH * 0.5
        saveBtn.layer.masksToBounds = true
        saveBtn.backgroundColor = .systemPink
        saveBtn.isUserInteractionEnabled = false
        
        imageView.y = HalfDiffValue(PortraitScreenHeight, totalH)
        closeBtn.origin = [HalfDiffValue(PortraitScreenWidth, btnWH + 30.px + btnWH), imageView.maxY + 15.px]
        saveBtn.origin = [closeBtn.maxX + 30.px, closeBtn.y]
        
        addSubview(imageView)
        addSubview(closeBtn)
        addSubview(saveBtn)
        
        startY = imageView.y
        
        imageView.maxY = 0
        closeBtn.y += 60.px
        closeBtn.alpha = 0
        saveBtn.y += 60.px
        saveBtn.alpha = 0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func closeAction() {
        close()
    }
    
    @objc func saveAction() {
        close()
        saveHandler()
    }
    
    func show() {
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1) {
            self.blurView.effect = UIBlurEffect(style: .dark)
        }
        
        UIView.animate(withDuration: 0.55, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 1) {
            self.imageView.y = self.startY
        }
        
        UIView.animate(withDuration: 0.55, delay: 0.3, usingSpringWithDamping: 0.7, initialSpringVelocity: 1) {
            self.closeBtn.y -= 60.px
            self.closeBtn.alpha = 1
        } completion: { _ in
            self.closeBtn.isUserInteractionEnabled = true
        }
        
        UIView.animate(withDuration: 0.55, delay: 0.35, usingSpringWithDamping: 0.7, initialSpringVelocity: 1) {
            self.saveBtn.y -= 60.px
            self.saveBtn.alpha = 1
        } completion: { _ in
            self.saveBtn.isUserInteractionEnabled = true
        }
    }
    
    func close() {
        isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0) {
            self.blurView.effect = nil
        } completion: { _ in
            self.removeFromSuperview()
        }
        
        UIView.animate(withDuration: 0.55, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1) {
            self.imageView.y -= 60.px
            self.imageView.alpha = 0
            self.closeBtn.y += 60.px
            self.closeBtn.alpha = 0
            self.saveBtn.y += 60.px
            self.saveBtn.alpha = 0
        }
    }
}
