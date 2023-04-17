//
//  RecordBeautySlider.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/3/26.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

protocol RecordBeautySliderDelegate: AnyObject {
    func beautySliderDidChangedValue(_ beautySlider: RecordBeautySlider, value: CGFloat, isBeauty: Bool)
}

class RecordBeautySlider: UIView {
    static var isSelectdBeauty = true
    
    let beautyBtn = UIButton(type: .system)
    let brightBtn = UIButton(type: .system)
    let stackView = UIStackView()
    let slider = RecordSlider(frame: [0, 0, PortraitScreenWidth, 40.px])
    
    var value: CGFloat {
        set {
            if Self.isSelectdBeauty {
                RecordOption.Beauty.beautyLevel = newValue
            } else {
                RecordOption.Beauty.brightLevel = newValue
            }
        }
        get {
            if Self.isSelectdBeauty {
                return RecordOption.Beauty.beautyLevel
            } else {
                return RecordOption.Beauty.brightLevel
            }
        }
    }
    
    weak var delegate: RecordBeautySliderDelegate?
    
    init(delegate: RecordBeautySliderDelegate?) {
        self.delegate = delegate
        super.init(frame: .zero)
        
        stackView.frame = [0, 0, PortraitScreenWidth, 20.px]
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        addSubview(stackView)
        
        beautyBtn.setTitle("美白", for: .normal)
        beautyBtn.setTitleColor(.white, for: .normal)
        beautyBtn.setTitleColor(.white, for: .selected)
        beautyBtn.addTarget(self, action: #selector(btnDidClick(_:)), for: .touchUpInside)
        beautyBtn.size = [40.px, 20.px]
        stackView.addArrangedSubview(beautyBtn)
        
        brightBtn.setTitle("亮度", for: .normal)
        brightBtn.setTitleColor(.white, for: .normal)
        brightBtn.setTitleColor(.white, for: .selected)
        brightBtn.addTarget(self, action: #selector(btnDidClick(_:)), for: .touchUpInside)
        brightBtn.size = [40.px, 20.px]
        stackView.addArrangedSubview(brightBtn)
        
        beautyBtn.isSelected = Self.isSelectdBeauty
        brightBtn.isSelected = !Self.isSelectdBeauty
        
        slider.y = stackView.maxY
        slider.valueDidChangedForUser = { [weak self] value in
            guard let self = self else { return }
            self.value = value
            self.delegate?.beautySliderDidChangedValue(self, value: value, isBeauty: Self.isSelectdBeauty)
        }
        addSubview(slider)
        
        size = [PortraitScreenWidth, slider.maxY]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else { return }
        slider.value = value
    }
    
    @objc func btnDidClick(_ sender: UIButton) {
        guard !sender.isSelected else { return }
        Self.isSelectdBeauty = sender == beautyBtn
        beautyBtn.isSelected = Self.isSelectdBeauty
        brightBtn.isSelected = !Self.isSelectdBeauty
        slider.value = value
    }
}
