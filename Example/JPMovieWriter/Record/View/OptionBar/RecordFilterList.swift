//
//  RecordFilterList.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/3/26.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import pop

protocol RecordFilterListDelegate: AnyObject {
    func filterListDidChangedFilter(_ filterList: RecordFilterList, model: RecordFilterList.Model)
    func filterListDidChangedFilterValue(_ filterList: RecordFilterList, model: RecordFilterList.Model)
}

class RecordFilterList: UIView {
    static let itemSpace: CGFloat = 2.px
    static let itemSize: CGSize = [50.px, 60.px]
    static let horInset: CGFloat = HalfDiffValue(PortraitScreenWidth, RecordFilterList.itemSize.width)
    
    static let models: [Model] = RecordOption.Filter.models.map { .init($0) }
    static var selectedModel: Model { models[selectedIndex] }
    static var selectedIndex = 0
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: [0, 0, PortraitScreenWidth, Self.itemSize.height], collectionViewLayout: Layout())
        collectionView.jp.contentInsetAdjustmentNever()
        collectionView.backgroundColor = .clear
        collectionView.register(Cell.self, forCellWithReuseIdentifier: "cell")
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()
    
    private lazy var selectedView: SelectedView = {
        let frame = CGRect(origin: [HalfDiffValue(PortraitScreenWidth, Self.itemSize.width), collectionView.y],
                           size: Self.itemSize)
        let selectedView = SelectedView(frame: frame.insetBy(dx: -1.5.px, dy: -1.5.px))
        return selectedView
    }()
    
    private lazy var slider: RecordSlider = {
        let slider = RecordSlider(frame: [0, selectedView.maxY, PortraitScreenWidth, 40.px])
        slider.valueDidChangedForUser = { [weak self] value in
            guard let self = self else { return }
            Self.selectedModel.value = value
            self.delegate?.filterListDidChangedFilterValue(self, model: Self.selectedModel)
        }
        return slider
    }()
    
    private var _isFirstDecelerate = true
    private var _isDecelerate = false
    private var _isDidClickAnimating = false
    
    private var selectedIndex: Int {
        set {
            guard Self.selectedIndex != newValue else { return }
            Self.selectedIndex = newValue
            delegate?.filterListDidChangedFilter(self, model: Self.selectedModel)
        }
        get { Self.selectedIndex }
    }
    
    weak var delegate: RecordFilterListDelegate?
    var viewHeightDidChangedHandler: ((_ viewHeight: CGFloat) -> ())?
    
    init(delegate: RecordFilterListDelegate?, viewHeightDidChangedHandler: ((_ viewHeight: CGFloat) -> ())?) {
        self.delegate = delegate
        self.viewHeightDidChangedHandler = viewHeightDidChangedHandler
        super.init(frame: .zero)
        clipsToBounds = false
        addSubview(collectionView)
        addSubview(selectedView)
        addSubview(slider)
        hideSliderIfNeeded(at: selectedIndex, animated: false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else { return }
        collectionView.contentOffset.x = CGFloat(Self.selectedIndex) * (Self.itemSize.width + Self.itemSpace)
        slider.value = Self.selectedModel.value
    }
    
    private func hideSliderIfNeeded(at index: Int, animated: Bool) {
        let isHideSlider: Bool
        let model = Self.models[index]
        switch model.filterModel.filter {
        case .origin:
            isHideSlider = true
        default:
            isHideSlider = false
        }
        
        let sliderAlpha: CGFloat = isHideSlider ? 0 : 1
        let viewHeight = isHideSlider ? (selectedView.maxY + 10.px) : slider.maxY
        guard slider.alpha != sliderAlpha || size.height != viewHeight else { return }
        
        size = [PortraitScreenWidth, viewHeight]
        viewHeightDidChangedHandler?(viewHeight)
        
        guard animated else {
            slider.alpha = sliderAlpha
            return
        }
        
        let anim = POPBasicAnimation(propertyNamed: kPOPViewAlpha)!
        anim.duration = 0.2
        anim.toValue = sliderAlpha
        slider.pop_add(anim, forKey: kPOPViewAlpha)
    }
}

extension RecordFilterList {
    class SelectedView: UIView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false
            layer.borderColor = UIColor.white.cgColor
            layer.borderWidth = 2.px
            layer.cornerRadius = 5.5.px
            layer.masksToBounds = false
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension RecordFilterList {
    class Model {
        let filterModel: RecordOption.Filter.Model
        var imgName: String { filterModel.imgName }
        var filePath: String { filterModel.filePath }
        
        let title: NSAttributedString
        
        var value: CGFloat {
            set { filterModel.value = newValue }
            get { filterModel.value }
        }
        
        init(_ filterModel: RecordOption.Filter.Model) {
            self.filterModel = filterModel
            self.title = NSAttributedString(string: filterModel.name, attributes: [
                .font: UIFont.boldSystemFont(ofSize: 10.px),
                .foregroundColor: UIColor.white,
                .shadow: {
                    let shadow = NSShadow()
                    shadow.shadowBlurRadius = 5
                    shadow.shadowColor = UIColor(white: 0, alpha: 0.5)
                    return shadow
                }()
            ])
        }
    }
}

extension RecordFilterList {
    class Layout: UICollectionViewFlowLayout {
        override init() {
            super.init()
            scrollDirection = .horizontal
            itemSize = RecordFilterList.itemSize
            minimumLineSpacing = RecordFilterList.itemSpace
            minimumInteritemSpacing = 0
            sectionInset = UIEdgeInsets(top: 0, left: RecordFilterList.horInset, bottom: 0, right: RecordFilterList.horInset)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
            guard let collectionView = self.collectionView else { return .zero }
            guard let atts = super.layoutAttributesForElements(in: [proposedContentOffset.x, 0, collectionView.width, collectionView.height]) else { return .zero }
            
            let centerX = proposedContentOffset.x + collectionView.width * 0.5
            
            var minDelta: CGFloat = centerX
            var targetAtt: UICollectionViewLayoutAttributes?
            
            for att in atts {
                let delta = abs(att.center.x - centerX)
                if delta < minDelta {
                    minDelta = delta
                    targetAtt = att
                }
            }
            
            guard let att = targetAtt else { return .zero }
            return [att.frame.origin.x - sectionInset.left, 0]
        }
    }
}

extension RecordFilterList {
    class Cell: UICollectionViewCell {
        var model: RecordFilterList.Model? = nil {
            didSet {
                imgView.image = model.map { UIImage(named: $0.imgName) } ?? nil
                nameLabel.attributedText = model?.title
            }
        }
        
        let imgView: UIImageView = {
            let imgView = UIImageView(frame: CGRect(origin: .zero, size: RecordFilterList.itemSize))
            imgView.contentMode = .scaleAspectFill
            imgView.layer.cornerRadius = 5.px
            imgView.layer.masksToBounds = true
            return imgView
        }()
        
        let nameLabel: UILabel = {
            let nameLabel = UILabel(frame: [0, RecordFilterList.itemSize.height - 16.px, RecordFilterList.itemSize.width, 16.px])
            nameLabel.textAlignment = .center
            return nameLabel
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            contentView.addSubview(imgView)
            contentView.addSubview(nameLabel)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension RecordFilterList: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        Self.models.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! Cell
        cell.model = Self.models[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard selectedIndex != indexPath.item else { return }
        
        _isDidClickAnimating = true
        collectionView.isUserInteractionEnabled = false
        
        hideSliderIfNeeded(at: indexPath.item, animated: true)
        
        // 点击动画不会自动调用`scrollViewWillBeginDragging`，所以在这里（点击前）手动调用
        scrollViewWillBeginDragging(collectionView)
        
        let anim = POPBasicAnimation(propertyNamed: kPOPCollectionViewContentOffset)!
        anim.toValue = CGPoint(x: CGFloat(indexPath.item) * (Self.itemSize.width + Self.itemSpace), y: 0)
        anim.duration = 0.3
        anim.completionBlock = { [weak self] _, _ in
            guard let self = self else { return }
            self.collectionView.isUserInteractionEnabled = true
            self.scrollViewDidEndDecelerating(self.collectionView)
        }
        collectionView.pop_add(anim, forKey: kPOPCollectionViewContentOffset)
    }
    
    // PS：点击动画不会自动走这里，如需记得在点击前手动调用
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        slider.isShowSlider = false
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewDidEndDecelerating(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if _isFirstDecelerate {
            _isFirstDecelerate = false
            _isDecelerate = decelerate
        }
        if !_isDecelerate { scrollViewDidEndDecelerating(scrollView) }
    }

    // 手指滑动动画停止时会调用该方法
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        _isFirstDecelerate = true
        _isDidClickAnimating = false
        
        let centerX = scrollView.contentOffset.x + scrollView.width * 0.5
        if let indexPath = collectionView.indexPathForItem(at: [centerX, 0]) {
            selectedIndex = indexPath.item
        }
        
        hideSliderIfNeeded(at: selectedIndex, animated: true)
        
        slider.value = Self.selectedModel.value
        slider.isShowSlider = true
    }
}
