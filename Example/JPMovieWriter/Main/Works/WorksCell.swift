//
//  WorksCell.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/3/7.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import YYText
import Kingfisher

class WorksCell: UICollectionViewCell {
    static let cellWidth: CGFloat = (PortraitScreenWidth - ViewController.edgeInsets.left - ViewController.edgeInsets.right - CGFloat(ViewController.colCount - 1) * ViewController.colMargin) / CGFloat(ViewController.colCount)
    
    static let durationColor: UIColor = .white
    static let durationFont: UIFont = .systemFont(ofSize: 10.px)
    
    static let titleFont: UIFont = .systemFont(ofSize: 13.px, weight: .semibold)
    static let titleSpace = 3.px
    static let titleMaxWidth: CGFloat = cellWidth - 16.px
    
    static let subtitleFont: UIFont = .systemFont(ofSize: 10.px, weight: .medium)
    
    let imgView: UIImageView = {
        let imgView = UIImageView()
        imgView.backgroundColor = UIConfig.imageBgColor
        imgView.contentMode = .scaleAspectFill
        imgView.clipsToBounds = true
        return imgView
    }()
    
    let durationLabel: UILabel = {
        let label = UILabel()
        label.font = WorksCell.durationFont
        label.textColor = WorksCell.durationColor
        label.textAlignment = .center
        label.layer.backgroundColor = UIColor.rgb(0, 0, 0, a: 0.5).cgColor
        label.layer.cornerRadius = 4.px
        label.layer.masksToBounds = true
        return label
    }()
    
    let titleLabel: YYLabel = {
        let label = YYLabel()
//        label.backgroundColor = .randomColor
        label.textVerticalAlignment = YYTextVerticalAlignment.top
        label.displaysAsynchronously = true
        label.ignoreCommonProperties = true // 只使用textLayout
        label.fadeOnHighlight = false
        label.fadeOnAsynchronouslyDisplay = false
        label.numberOfLines = 0
        return label
    }()
    
    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = WorksCell.subtitleFont
        label.textColor = UIConfig.subtitleColor
        label.textAlignment = .left
        return label
    }()
    
    var worksCM: WorksCellModel? = nil {
        didSet { updateUI() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
//        contentView.backgroundColor = UIConfig.itemBgColor
//        contentView.layer.cornerRadius = 5.px
//        contentView.layer.masksToBounds = true
        imgView.backgroundColor = UIConfig.imageBgColor
        imgView.layer.cornerRadius = 4.px
        imgView.layer.masksToBounds = true
        
        contentView.addSubview(imgView)
        contentView.addSubview(durationLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateUI() {
        guard let worksCM = self.worksCM else {
            return
        }
        
        imgView.frame = worksCM.imageFrame
        durationLabel.frame = worksCM.durationFrame
        titleLabel.frame = worksCM.titleFrame
        subtitleLabel.frame = worksCM.subtitleFrame
        
        imgView.jp.fadeSetImage(with: worksCM.imageURL, viewSize: worksCM.imageFrame.size)
        durationLabel.text = worksCM.durationStr
        titleLabel.textLayout = worksCM.titleLayout
        subtitleLabel.text = worksCM.subtitle
    }
}

//imgView.jp.fadeSetImage(with: worksCM.imageURL, viewSize: worksCM.imageFrame.size, completionHandler: { result in
//    switch result {
//    case .success(let value):
//        let image = value.image
//        JPrint("000 image", image.size, image.scale)
//        switch value.cacheType {
//        case .none:
//            JPrint("111 result none")
//        case .memory:
//            JPrint("222 result 内存")
//        case .disk:
//            JPrint("333 result 磁盘")
//        }
//
//    case .failure(let error):
//        JPrint("Error: \(error)")
//    }
//})
