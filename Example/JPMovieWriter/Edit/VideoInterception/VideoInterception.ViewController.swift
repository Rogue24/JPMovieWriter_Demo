//
//  VideoInterceptionViewController.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/4/13.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import Combine
import JPBasic
import pop

extension VideoInterception {
    class ViewController: UIViewController {
        var asset: AVURLAsset!
        
        var frameTotal = 0
        var thumbnails: [Thumbnail] = []
        
        var isDidAppear = false
        var allItemWidth: CGFloat = 0
        
        lazy var duration = CMTimeGetSeconds(asset.duration)
        lazy var imageGenerator = VideoTool.ImageGenerator(videoAsset: asset)!
        lazy var previewView: PreviewView = PreviewView(player: player, delegate: self)
        lazy var playerLayer = AVPlayerLayer(player: player)
        lazy var player: AVPlayer = {
            let player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
            player.volume = 0
            player.rate = 0
            return player
        }()
        
        var confirmImage: ((_ image: UIImage) -> Void)?
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupBase()
            setupNavigationBar()
            setupBottomView()
            setupPlayerLayer()
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            guard !isDidAppear else { return }
            
            let anim = POPBasicAnimation(propertyNamed: kPOPLayerOpacity)!
            anim.duration = 0.2
            anim.toValue = 1
            playerLayer.pop_add(anim, forKey: kPOPLayerOpacity)
            
            var thumbnails: [Thumbnail] = []
            Asyncs.async {
                guard self.duration > 0 else { return }
                
                var frameInterval = 1.0 + self.duration / 60.0
                if frameInterval < 1 {
                    frameInterval = 1
                }
                
                var frameTotal = Int(self.duration / frameInterval)
                if frameTotal > 60 {
                    frameTotal = 60
                }
                
                for i in 1 ... frameTotal {
                    let second = floor(TimeInterval(i) * TimeInterval(frameInterval) * 10) / 10.0
                    let time = CMTime(seconds: second, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                    thumbnails.append(Thumbnail(index: i - 1, time: time))
                }
            } mainTask: {
                self.thumbnails = thumbnails
                self.allItemWidth = Cell.size.width * CGFloat(thumbnails.count)
                self.previewView.collectionView.reloadSections(IndexSet(integer: 0))
            }
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard !isDidAppear else { return }
            isDidAppear = true
        }
        
        func setupBase() {
            title = "视频截取"
            view.backgroundColor = UIConfig.mainBgColor
        }

        func setupNavigationBar() {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "确定", style: .plain, target: self, action: #selector(confirm))
        }

        func setupBottomView() {
            let h = previewView.height + DiffTabBarH
            let bottomView = UIView(frame: [0, PortraitScreenHeight - h, PortraitScreenWidth, h])
            bottomView.backgroundColor = UIConfig.secBgColor
            view.addSubview(bottomView)
            bottomView.addSubview(previewView)
        }

        func setupPlayerLayer() {
            let x: CGFloat = 12.px
            let y = NavTopMargin + 12.px
            playerLayer.frame = [12.px, y, PortraitScreenWidth - 2 * x, previewView.superview!.y - 12.px - y]
            playerLayer.videoGravity = .resizeAspect
            playerLayer.opacity = 0
            view.layer.addSublayer(playerLayer)
        }
        
        @objc func confirm() {
            JPProgressHUD.dismiss()
            VideoTool.asyncGetVideoImage(with: asset, time: player.currentTime(), maximumSize: UIConfig.videoSize) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case let .success(image):
                    JPProgressHUD.dismiss()
                    self.navigationController?.popViewController(animated: true)
                    self.confirmImage?(image)
                    
                case .failure:
                    JPProgressHUD.showError(withStatus: "截取失败", userInteractionEnabled: true)
                }
            }
        }
    }
}

extension VideoInterception.ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        thumbnails.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let thumbnail = thumbnails[indexPath.item]
        return previewView.dequeueReusableCell(for: indexPath, imageRef: thumbnail.imageRef)
    }
}

extension VideoInterception.ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let thumbnail = thumbnails[indexPath.item]
        guard thumbnail.imageRef == nil else { return }
        
        imageGenerator.asyncGetVideoImage(at: thumbnail.time) { [weak self] result in
            guard let self = self else { return }
            var thumbnail = self.thumbnails[indexPath.item]
            guard thumbnail.imageRef == nil else { return }
            
            switch result {
            case let .success(imageRef):
                thumbnail.imageRef = imageRef
                self.thumbnails[indexPath.item] = thumbnail
                if collectionView.indexPathsForVisibleItems.contains(indexPath) {
                    collectionView.reloadItems(at: [indexPath])
                }
            default:
                break
            }
        }
        
        // 在这里调用 cellForItemAtIndexPath 还是会获取nil，因为此时的这个cell超出显示范围或还没初始完毕，不过在这里之后就获取到了，例如在 dispatch_async(dispatch_get_main_queue(), ^{} 里面调用就获取就可以拿到，因为任务是排在这个方法之后。
    }
        
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        let process = offsetX / allItemWidth
        let second = duration * process
        let time = CMTime(seconds: second, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
}
