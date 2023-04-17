//
//  CropViewController.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/4/4.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import JPCrop
import JPBasic

class CropViewController: UIViewController {
    let image: UIImage
    let cropDone: (_ cropedImage: UIImage) -> Void
    
    var croper: Croper!
    
    let operationBar = UIView()
    
    var slider: CropSlider!
    let stackView = UIStackView()
    
    var ratioBar: CropRatioBar?
    lazy var ratio: CGSize = image.size
    
    init(image: UIImage, cropDone: @escaping (_ cropedImage: UIImage) -> Void) {
        self.image = image
        self.cropDone = cropDone
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBase()
        setupOperationBar()
        setupCroper()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
}

extension CropViewController {
    func setupBase() {
        view.clipsToBounds = true
        view.backgroundColor = .black
    }
    
    func setupOperationBar() {
        let h = 50.px + NavBarH + DiffTabBarH
        operationBar.frame = [0, PortraitScreenHeight - h, PortraitScreenWidth, h]
        view.addSubview(operationBar)
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = operationBar.bounds
        operationBar.addSubview(blurView)
        
        let slider = CropSlider(minimumValue: -Float(Croper.diffAngle), maximumValue: Float(Croper.diffAngle), value: 0)
        slider.y = 10.px
        slider.sliderWillChangedForUser = { [weak self] in
            guard let self = self else { return }
            self.croper.showRotateGrid(animated: true)
        }
        slider.sliderDidChangedForUser = { [weak self] value in
            guard let self = self else { return }
            self.croper.rotate(value)
        }
        slider.sliderEndChangedForUser = { [weak self] in
            guard let self = self else { return }
            self.croper.hideRotateGrid(animated: true)
        }
        operationBar.addSubview(slider)
        self.slider = slider
        
        stackView.backgroundColor = .clear
        stackView.frame = [0, 50.px, PortraitScreenWidth, NavBarH]
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        operationBar.addSubview(stackView)
        
        let backBtn = UIButton(type: .system)
        backBtn.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        backBtn.tintColor = .white
        backBtn.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        backBtn.size = [NavBarH, NavBarH]
        stackView.addArrangedSubview(backBtn)
        
        let rotateBtn = UIButton(type: .system)
        rotateBtn.setImage(UIImage(systemName: "rotate.left"), for: .normal)
        rotateBtn.tintColor = .white
        rotateBtn.addTarget(self, action: #selector(rotateLeft), for: .touchUpInside)
        rotateBtn.size = [NavBarH, NavBarH]
        stackView.addArrangedSubview(rotateBtn)
        
        let ratioBtn = UIButton(type: .system)
        ratioBtn.setImage(UIImage(systemName: "aspectratio"), for: .normal)
        ratioBtn.tintColor = .white
        ratioBtn.addTarget(self, action: #selector(switchRatio), for: .touchUpInside)
        ratioBtn.size = [NavBarH, NavBarH]
        stackView.addArrangedSubview(ratioBtn)
        
        let recoverBtn = UIButton(type: .system)
        recoverBtn.setImage(UIImage(systemName: "gobackward"), for: .normal)
        recoverBtn.tintColor = .white
        recoverBtn.addTarget(self, action: #selector(recover), for: .touchUpInside)
        recoverBtn.size = [NavBarH, NavBarH]
        stackView.addArrangedSubview(recoverBtn)
        
        let doneBtn = UIButton(type: .system)
        doneBtn.setTitle("完成", for: .normal)
        doneBtn.titleLabel?.font = .systemFont(ofSize: 15.px, weight: .bold)
        doneBtn.addTarget(self, action: #selector(crop), for: .touchUpInside)
        doneBtn.size = [NavBarH, NavBarH]
        stackView.addArrangedSubview(doneBtn)
    }
    
    func setupCroper() {
        Croper.margin = UIEdgeInsets(top: StatusBarH + 15.px,
                                     left: 15.px,
                                     bottom: 50.px + NavBarH + DiffTabBarH + 15.px,
                                     right: 15.px)
        
        let w = PortraitScreenWidth - 30.px
        let h = w / UIConfig.videoRatio
        let h2 = PortraitScreenHeight - (StatusBarH + 15.px) - (50.px + NavBarH + DiffTabBarH + 15.px)
        JPrint("w", w, "h", h, "h2", h2)
        
        let configure = Croper.Configure(image, cropWHRatio: image.size.width / image.size.height)
        
        let croper = Croper(frame: PortraitScreenBounds, configure)
        croper.clipsToBounds = false
        view.insertSubview(croper, at: 0)
        self.croper = croper
    }
}

// MARK: - 监听返回/恢复/旋转/比例切换/裁剪事件
extension CropViewController {
    @objc func goBack() {
        if let navCtr = navigationController, navCtr.viewControllers.count > 1 {
            navCtr.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    @objc func rotateLeft() {
        ratio = ratio.exchange
        croper.updateCropWHRatio(ratio.width / ratio.height, animated: true)
        croper.rotateLeft(animated: true)
    }
    
    @objc func switchRatio() {
        showRatioBar()
    }
    
    @objc func recover() {
        croper.recover(animated: true)
        slider.updateValue(0, animated: true)
    }
    
    @objc func crop() {
        JPProgressHUD.show()
        croper.asyncCrop { [weak self] in
            guard let self = self else { return }
            guard let image = $0 else {
                JPProgressHUD.showError(withStatus: "裁剪失败", userInteractionEnabled: true)
                return
            }
            JPProgressHUD.dismiss()
            self.navigationController?.popViewController(animated: true)
            self.cropDone(image)
        }
    }
}

extension CropViewController {
    func showRatioBar() {
        guard self.ratioBar == nil else { return }
        
        let ratioBar = CropRatioBar(imageSize: image.size, ratio: ratio) { [weak self] ratio in
            guard let self = self else { return }
            self.ratio = ratio
            self.croper.updateCropWHRatio(ratio.width / ratio.height, animated: true)
        } closeHandler: { [weak self] in
            self?.hideRatioBar()
        }
        ratioBar.alpha = 0
        ratioBar.y = operationBar.height * 0.3
        operationBar.addSubview(ratioBar)
        self.ratioBar = ratioBar
        
        let diffH = operationBar.frame.height * 0.3
        
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1) {
            self.slider.y += diffH
            self.slider.alpha = 0
            self.stackView.y += diffH
            self.stackView.alpha = 0
        }
        
        UIView.animate(withDuration: 0.45, delay: 0.1, usingSpringWithDamping: 0.9, initialSpringVelocity: 1) {
            ratioBar.y = 0
            ratioBar.alpha = 1
        }
    }
    
    func hideRatioBar() {
        guard let ratioBar = self.ratioBar else { return }
        self.ratioBar = nil
        
        let diffH = operationBar.frame.height * 0.3
        
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1) {
            ratioBar.y = diffH
            ratioBar.alpha = 0
        } completion: { _ in
            ratioBar.removeFromSuperview()
        }
        
        UIView.animate(withDuration: 0.45, delay: 0.1, usingSpringWithDamping: 0.9, initialSpringVelocity: 1) {
            self.slider.y -= diffH
            self.slider.alpha = 1
            self.stackView.y -= diffH
            self.stackView.alpha = 1
        }
    }
}
