//
//  GifMakeViewController.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/4/13.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import JPImageresizerView
import JPBasic

class GifMakeViewController: UIViewController {
    static let gifSeconds: [Int] = [1, 3, 5, 10]
    static var currentSeconds: Int = 3
    var selectedSeconds: Int = GifMakeViewController.currentSeconds
    
    var videoURL: URL!
    
    private var imageresizerView: JPImageresizerView!
    
    let operationBar = UIView()
    var secondsBtns: [UIButton] = []
    let stackView = UIStackView()
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        JPProgressHUD.showInfo(withStatus: "📢📢📢\nGIF是从【进度条的滑块处】开始截取", userInteractionEnabled: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
}

extension GifMakeViewController {
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
        
        let label = UILabel()
        label.font = .systemFont(ofSize: 15.px, weight: .bold)
        label.textColor = .white
        label.text = "GIF时长："
        label.sizeToFit()
        label.origin = [15.px, HalfDiffValue(50.px, label.height)]
        operationBar.addSubview(label)
        
        let btnFont = UIFont.systemFont(ofSize: 13.px)
        var btnX: CGFloat = label.maxX + 5.px
        let btnS: CGFloat = 10.px
        let btnW: CGFloat = (PortraitScreenWidth - btnX - 15.px - CGFloat(Self.gifSeconds.count - 1) * btnS) / CGFloat(Self.gifSeconds.count)
        let btnH: CGFloat = 24.px
        let btnY: CGFloat = HalfDiffValue(50.px, btnH)
        for seconds in Self.gifSeconds {
            let btn = UIButton(type: .system)
            btn.setTitle("\(seconds)秒", for: .normal)
            btn.titleLabel?.font = btnFont
            btn.layer.cornerRadius = 4.px
            btn.layer.masksToBounds = true
            btn.frame = [btnX, btnY, btnW, btnH]
            btn.tag = seconds
            if seconds == selectedSeconds {
                btn.setTitleColor(UIColor(white: 1, alpha: 1), for: .normal)
                btn.backgroundColor = .systemBlue
            } else {
                btn.setTitleColor(UIColor(white: 1, alpha: 0.5), for: .normal)
                btn.backgroundColor = .clear
            }
            btn.addTarget(self, action: #selector(selectGifSeconds(_:)), for: .touchUpInside)
            operationBar.addSubview(btn)
            secondsBtns.append(btn)
            btnX = btn.maxX + btnS
        }
        
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
        
        let verMirrorBtn = UIButton(type: .system)
        verMirrorBtn.setImage(UIImage(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right"), for: .normal)
        verMirrorBtn.tintColor = .white
        verMirrorBtn.addTarget(self, action: #selector(verMirror), for: .touchUpInside)
        verMirrorBtn.size = [NavBarH, NavBarH]
        stackView.addArrangedSubview(verMirrorBtn)
        
        let horMirrorBtn = UIButton(type: .system)
        horMirrorBtn.setImage(UIImage(systemName: "arrow.up.and.down.righttriangle.up.righttriangle.down"), for: .normal)
        horMirrorBtn.tintColor = .white
        horMirrorBtn.addTarget(self, action: #selector(horMirror), for: .touchUpInside)
        horMirrorBtn.size = [NavBarH, NavBarH]
        stackView.addArrangedSubview(horMirrorBtn)
        
        let recoverBtn = UIButton(type: .system)
        recoverBtn.setImage(UIImage(systemName: "gobackward"), for: .normal)
        recoverBtn.tintColor = .white
        recoverBtn.addTarget(self, action: #selector(recover), for: .touchUpInside)
        recoverBtn.size = [NavBarH, NavBarH]
        stackView.addArrangedSubview(recoverBtn)
        
        let doneBtn = UIButton(type: .system)
        doneBtn.setTitle("生成", for: .normal)
        doneBtn.titleLabel?.font = .systemFont(ofSize: 15.px, weight: .bold)
        doneBtn.addTarget(self, action: #selector(makeGif), for: .touchUpInside)
        doneBtn.size = [NavBarH, NavBarH]
        stackView.addArrangedSubview(doneBtn)
    }
    
    func setupCroper() {
        // 1.初始配置
        let configure = JPImageresizerConfigure
            .defaultConfigure(withVideoURL: videoURL,
                              make: nil,
                              fixErrorBlock: nil,
                              fixStart: nil,
                              fixProgressBlock: nil)
            .jp_viewFrame(PortraitScreenBounds)
            .jp_bgColor(.black)
            .jp_frameType(.classicFrameType)
            .jp_contentInsets(.init(top: StatusBarH + 15.px, left: 15.px, bottom: 50.px + NavBarH + DiffTabBarH + 15.px, right: 15.px))

        // 2.创建imageresizerView
        let imageresizerView = JPImageresizerView(configure: configure) { _ in } imageresizerIsPrepareToScale: { [weak self] isPrepareToScale in
            // 当预备缩放设置按钮不可点，结束后可点击
            self?.operationBar.isUserInteractionEnabled = !isPrepareToScale
        }

        // 3.添加到视图上
        view.insertSubview(imageresizerView, at: 0)
        self.imageresizerView = imageresizerView
    }
}

extension GifMakeViewController {
    @objc func selectGifSeconds(_ sender: UIButton) {
        Self.currentSeconds = sender.tag
        selectedSeconds = sender.tag
        secondsBtns.forEach {
            if $0.tag == selectedSeconds {
                $0.setTitleColor(UIColor(white: 1, alpha: 1), for: .normal)
                $0.backgroundColor = .systemBlue
            } else {
                $0.setTitleColor(UIColor(white: 1, alpha: 0.5), for: .normal)
                $0.backgroundColor = .clear
            }
        }
    }
    
    @objc func goBack() {
        if let navCtr = navigationController, navCtr.viewControllers.count > 1 {
            navCtr.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    @objc func rotateLeft() {
        imageresizerView.rotation()
    }
    
    @objc func verMirror() {
        imageresizerView.verticalityMirror.toggle()
    }

    @objc func horMirror() {
        imageresizerView.horizontalMirror.toggle()
    }
    
    @objc func recover() {
        imageresizerView.recovery()
    }
    
    @objc func makeGif() {
        JPProgressHUD.show()
        imageresizerView.cropVideoToGIFFromCurrentSecond(withDuration: TimeInterval(selectedSeconds), cacheURL: URL(fileURLWithPath: File.tmpFilePath("\(Int(Date().timeIntervalSince1970)).gif"))) { _, _ in
            JPProgressHUD.showError(withStatus: "制作失败，请重试", userInteractionEnabled: true)
        } complete: { result in
            var imageURL: URL?
            var image: UIImage?
            Asyncs.async {
                guard let result = result, result.isCacheSuccess,
                      let cacheURL = result.cacheURL,
                      let data = try? Data(contentsOf: cacheURL) else { return }
                imageURL = cacheURL
                image = JPImageresizerTool.decodeGIFData(data)
            } mainTask: {
                guard let imageURL = imageURL, let image = image else {
                    JPProgressHUD.showError(withStatus: "制作失败，请重试", userInteractionEnabled: true)
                    return
                }
                
                JPProgressHUD.dismiss()
                GifPreviewView.show(image) {
                    JPProgressHUD.show()
                    Photo.shared.save(.file(imageURL)) { result in
                        switch result {
                        case .success:
                            JPProgressHUD.showSuccess(withStatus: "保存成功", userInteractionEnabled: true)
                        case .failure:
                            JPProgressHUD.showSuccess(withStatus: "保存失败", userInteractionEnabled: true)
                        }
                    }
                }
            }
        }
    }
}
