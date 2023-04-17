//
//  VideoInterceptionPreviewView.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/4/13.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

extension VideoInterception {
    class PreviewView: UIView {
        let collectionView: UICollectionView
        let currentView: CurrentView
        
        init(player: AVPlayer, delegate: (AnyObject & UICollectionViewDataSource & UICollectionViewDelegate)) {
            let frame: CGRect = [0, 0, PortraitScreenWidth, Cell.size.height * 2]
            
            let verInset = (frame.height - Cell.size.height) * 0.5
            let horInset = frame.width * 0.5
            
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            layout.itemSize = Cell.size
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 0
            layout.sectionInset = UIEdgeInsets(top: verInset, left: horInset, bottom: verInset, right: horInset)
            self.collectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
            
            self.currentView = CurrentView(player: player)
            
            super.init(frame: frame)
            backgroundColor = .clear
            
            collectionView.jp.contentInsetAdjustmentNever()
            collectionView.backgroundColor = .clear
            collectionView.showsHorizontalScrollIndicator = false
            collectionView.bounces = false
            collectionView.register(Cell.self, forCellWithReuseIdentifier: "cell")
            collectionView.dataSource = delegate
            collectionView.delegate = delegate
            addSubview(collectionView)
            
            currentView.center = [frame.width * 0.5, frame.height * 0.5]
            currentView.isUserInteractionEnabled = false
            addSubview(currentView)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func dequeueReusableCell(for indexPath: IndexPath, imageRef: Any?) -> Cell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! Cell
            cell.setImageRef(imageRef)
            return cell
        }
    }
}
