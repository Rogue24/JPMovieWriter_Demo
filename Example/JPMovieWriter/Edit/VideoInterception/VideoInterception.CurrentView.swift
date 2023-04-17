//
//  VideoInterception.CurrentView.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/4/13.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

extension VideoInterception {
    class CurrentView: UIView {
        let playerLayer: AVPlayerLayer
        
        init(player: AVPlayer) {
            self.playerLayer = AVPlayerLayer(player: player)
            
            let verMargin = 4.px
            let horMargin = 4.px
            super.init(frame: CGRect(origin: .zero, size: Cell.size).insetBy(dx: -horMargin, dy: -verMargin))
            backgroundColor = .rgb(56, 121, 242)
            layer.cornerRadius = verMargin
            layer.masksToBounds = true
            
            playerLayer.masksToBounds = true
            playerLayer.videoGravity = .resizeAspectFill
            playerLayer.backgroundColor = UIColor.rgb(14, 14, 36).cgColor
            playerLayer.frame = bounds.insetBy(dx: horMargin, dy: verMargin)
            layer.addSublayer(playerLayer)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
