//
//  RecordOptionBar.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/3/26.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import pop

protocol RecordOptionBarDelegate: RecordBeautySliderDelegate, RecordFilterListDelegate {
    func optionBarDidClick(_ optionBar: RecordOptionBar, option: RecordOption?)
    func optionBarHeightDidChanged(_ optionBar: RecordOptionBar)
}

class RecordOptionBar: UIView {
    weak var delegate: RecordOptionBarDelegate?
    
    var isOnVortex: Bool {
        didSet {
            guard isOnVortex != oldValue else { return }
            guard let btn = optionBtns.first(where: { $0.tag == RecordOption.vortex.rawValue }) else { return }
            btn.setImage(UIImage(systemName: optionImageName(.vortex)), for: .normal)
        }
    }
    
    var isFrontCamera: Bool {
        didSet {
            guard isFrontCamera != oldValue else { return }
            optionButtonsUpdateLayout(animated: true)
        }
    }
    
    var isOpeningTorch: Bool {
        didSet {
            guard isOpeningTorch != oldValue else { return }
            guard let btn = optionBtns.first(where: { $0.tag == RecordOption.flashlight.rawValue }) else { return }
            btn.setImage(UIImage(systemName: optionImageName(.flashlight)), for: .normal)
        }
    }
    
    var optionBtns: [UIButton] = []
    
    var selectedBtn: UIButton? = nil {
        didSet {
            guard selectedBtn != oldValue else { return }
            
            if let btn = oldValue {
                let anim = POPBasicAnimation(propertyNamed: kPOPViewTintColor)!
                anim.duration = 0.2
                anim.toValue = UIColor.white
                btn.pop_add(anim, forKey: kPOPViewTintColor)
            }
            
            if let btn = selectedBtn {
                let anim = POPBasicAnimation(propertyNamed: kPOPViewTintColor)!
                anim.duration = 0.2
                anim.toValue = UIColor.systemBlue
                btn.pop_add(anim, forKey: kPOPViewTintColor)
            }
        }
    }
    
    init(isOnVortex: Bool, isFrontCamera: Bool, isOpeningTorch: Bool, delegate: RecordOptionBarDelegate?) {
        self.isOnVortex = isOnVortex
        self.isFrontCamera = isFrontCamera
        self.isOpeningTorch = isOpeningTorch
        self.delegate = delegate
        
        super.init(frame: [0, 0, PortraitScreenWidth, NavBarH])
        clipsToBounds = false
        
        let bgView = UIView(frame: [0, NavBarH - NavTopMargin, PortraitScreenWidth, NavTopMargin])
        bgView.backgroundColor = .black
        addSubview(bgView)
        
        buildOptionButtons()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func btnDidClick(_ sender: UIButton) {
        guard let option = RecordOption(rawValue: sender.tag) else { return }
        
        if let oldBtn = selectedBtn, let oldOption = RecordOption(rawValue: oldBtn.tag), oldOption == option {
            height = NavBarH
            selectedBtn = nil
            hidePopView()
            delegate?.optionBarDidClick(self, option: nil)
            return
        }
        
        var popView: UIView?
        
        switch option {
        case .beauty:
            popView = RecordBeautySlider(delegate: delegate)
            
        case .filter:
            popView = RecordFilterList(delegate: delegate) { [weak self] viewHeight in
                guard let self = self else { return }
                self.height = NavBarH + viewHeight + 5.px
                self.delegate?.optionBarHeightDidChanged(self)
            }
            
        default:
            delegate?.optionBarDidClick(self, option: option)
            return
        }
        
        if let popView = popView {
            height = NavBarH + popView.height + 5.px
            selectedBtn = sender
        } else {
            height = NavBarH
            selectedBtn = nil
        }
        showPopView(popView)
        
        delegate?.optionBarDidClick(self, option: option)
    }
    
    
    var popView: UIView?
    
    func showPopView(_ popView: UIView?) {
        hidePopView()
        guard let popView = popView else { return }
        
        popView.alpha = 0
        insertSubview(popView, at: 0)
        self.popView = popView
        
        var frame = popView.frame
        frame.origin.y = NavBarH + 5.px
        
        let anim1 = POPBasicAnimation(propertyNamed: kPOPViewFrame)!
        anim1.duration = 0.3
        anim1.toValue = frame
        popView.pop_add(anim1, forKey: kPOPViewFrame)
        
        let anim2 = POPBasicAnimation(propertyNamed: kPOPViewAlpha)!
        anim2.duration = 0.3
        anim2.toValue = 1
        popView.pop_add(anim2, forKey: kPOPViewAlpha)
    }
    
    func hidePopView() {
        guard let popView = self.popView else { return }
        self.popView = nil
        
        popView.pop_removeAllAnimations()
        
        var frame = popView.frame
        frame.origin.y = selectedBtn == nil ? (height - frame.height) : 0
        
        let anim1 = POPBasicAnimation(propertyNamed: kPOPViewFrame)!
        anim1.duration = 0.3
        anim1.toValue = frame
        popView.pop_add(anim1, forKey: kPOPViewFrame)
        
        let anim2 = POPBasicAnimation(propertyNamed: kPOPViewAlpha)!
        anim2.duration = 0.25
        anim2.toValue = 0
        anim2.completionBlock = { [weak popView] _, _ in
            popView?.removeFromSuperview()
        }
        popView.pop_add(anim2, forKey: kPOPViewAlpha)
    }
}

extension RecordOptionBar {
    func buildOptionButtons() {
        RecordOption.allCases.forEach {
            let btn = UIButton(type: .system)
            btn.tag = $0.rawValue
            btn.setImage(UIImage(systemName: optionImageName($0)), for: .normal)
            btn.tintColor = .white
            btn.size = [NavBarH, NavBarH]
            btn.addTarget(self, action: #selector(btnDidClick(_:)), for: .touchUpInside)
            addSubview(btn)
            optionBtns.append(btn)
        }
        optionButtonsUpdateLayout(animated: false)
    }
    
    func optionImageName(_ option: RecordOption) -> String {
        switch option {
        case .beauty: return "face.dashed.fill"
        case .filter: return "camera.filters"
        case .watermark: return "pencil.and.outline"
        case .vortex: return isOnVortex ? "hurricane" : "tropicalstorm"
        case .flashlight: return isOpeningTorch ? "flashlight.on.fill" : "flashlight.off.fill"
        }
    }
    
    func optionButtonsUpdateLayout(animated: Bool) {
        let singleWidth: CGFloat
        if isFrontCamera {
            singleWidth = width / 4.0
        } else {
            singleWidth = width / 5.0
        }
        
        let update: () -> Void = {
            for i in 0 ..< self.optionBtns.count {
                let optionBtn = self.optionBtns[i]
                optionBtn.centerX = singleWidth * CGFloat(i) + singleWidth * 0.5
            }
        }
        
        guard animated else {
            update()
            return
        }
        
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.78, initialSpringVelocity: 1, animations: update)
    }
}
