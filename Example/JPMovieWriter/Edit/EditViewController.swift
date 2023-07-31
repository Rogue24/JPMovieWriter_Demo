//
//  EditViewController.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/4/16.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import Photos
import Combine
import JPBasic
import Kingfisher

class EditViewController: UIViewController {
    var works: Works!
    var saveHandler: ((_ works: Works, _ image: UIImage?, _ title: String?) -> Void)?
    
    let scrollView = UIScrollView(frame: PortraitScreenBounds)
    let imageView = UIImageView()
    let titLabel = UILabel()
    let textFieldBgView = UIView()
    let textField = JPTextField()
    
    var cancellable: AnyCancellable?
    
    var isEditedCover = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "编辑封面&标题"
        view.backgroundColor = UIConfig.mainBgColor
        
        scrollView.jp.contentInsetAdjustmentNever()
        scrollView.contentInset = UIEdgeInsets(top: NavTopMargin, left: 0, bottom: DiffTabBarH, right: 0)
        scrollView.keyboardDismissMode = .onDrag
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        
        var imageSize: CGSize = [PortraitScreenWidth, PortraitScreenWidth / works.imageRatio]
        if imageSize.height > PortraitScreenWidth {
            imageSize.height = PortraitScreenWidth
        }
        imageView.frame = CGRect(origin: .zero, size: imageSize)
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.jp.fadeSetImage(with: works.imageURL, viewSize: imageView.size)
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(editImage)))
        scrollView.addSubview(imageView)
        
        titLabel.font = .systemFont(ofSize: 16.px, weight: .heavy)
        titLabel.textColor = .lightGray
        titLabel.text = "标题"
        titLabel.sizeToFit()
        titLabel.frame = [12.px, imageView.maxY + 15.px, titLabel.width, 20.px]
        scrollView.addSubview(titLabel)
        
        textFieldBgView.frame = [0, titLabel.maxY + 10.px, PortraitScreenWidth, 44.px]
        textFieldBgView.backgroundColor = UIConfig.secBgColor
        scrollView.addSubview(textFieldBgView)
        
        textField.frame = textFieldBgView.bounds.insetBy(dx: 12.px, dy: 0)
        textField.textAlignment = .left
        textField.textColor = .white
        textField.font = .systemFont(ofSize: 15.px)
        textField.attributedPlaceholder = NSAttributedString(string: "空空如也", attributes: [.font: textField.font!, .foregroundColor: UIColor.rgb(155, 155, 155)])
        textField.clearButtonMode = .never
        textField.returnKeyType = .done
        textField.maxLimitNums = 100
        textFieldBgView.addSubview(textField)
        textField.reachMaxLimitNums = { maxLimitNums in
            JPProgressHUD.showInfo(withStatus: "最多\(maxLimitNums)字", userInteractionEnabled: true)
        }
        textField.returnKeyDidClick = { kTextField, _ in
            kTextField?.resignFirstResponder()
            return true
        }
        textField.setAndCheckText(works.title)
        
        let randomBtn = UIButton(type: .system)
        randomBtn.titleLabel?.font = .systemFont(ofSize: 12.px)
        randomBtn.setTitle("随机", for: .normal)
        randomBtn.addTarget(self, action: #selector(randomTitle), for: .touchUpInside)
        textField.rightView = randomBtn
        textField.rightViewMode = .unlessEditing
        
        cancellable = NotificationCenter.default
                .publisher(for: UIApplication.keyboardWillChangeFrameNotification)
                .sink() { [weak self] notification in
                    guard let self = self else { return }
                    
                    let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0
                    let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
                    
                    var offsetY = -NavTopMargin
                    if keyboardFrame.origin.y < PortraitScreenHeight {
                        offsetY = self.textFieldBgView.maxY - keyboardFrame.origin.y + 20.px
                        if offsetY < -NavTopMargin {
                            offsetY = -NavTopMargin
                        }
                    }
                    
                    UIView.animate(withDuration: duration) {
                        self.scrollView.contentOffset = [0, offsetY]
                    }
                }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let saveItem = UIBarButtonItem(title: "保存", style: .plain, target: self, action: #selector(save))
        navigationItem.rightBarButtonItem = saveItem
    }
    
    deinit {
        cancellable?.cancel()
    }
    
    @objc func save() {
        navigationController?.popViewController(animated: true)
        guard let saveHandler = self.saveHandler else { return }
        let image = isEditedCover ? imageView.image : nil
        let title = textField.text.map { $0 == works.title ? nil : $0 } ?? nil
        saveHandler(works, image, title)
    }
    
    @objc func randomTitle() {
        textField.setAndCheckText(UIConfig.titles.randomElement()!)
    }
    
    @objc func editImage() {
        UIAlertController
            .build(.actionSheet)
            .addAction("裁剪") {
                guard let image = self.imageView.image else { return }
                let vc = CropViewController(image: image) { [weak self] cropedImage in
                    guard let self = self else { return }
                    self.replaceCover(cropedImage)
                }
                self.navigationController?.pushViewController(vc, animated: true)
            }
            .addAction("从视频截取") {
                let viVC = VideoInterception.ViewController()
                viVC.asset = self.works.asset
                viVC.confirmImage = { [weak self] image in
                    guard let self = self else { return }
                    self.replaceCover(image)
                }
                self.navigationController?.pushViewController(viVC, animated: true)
            }
            .addAction("拍照") {
                ImagePicker.photograph { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case let .success(image):
                        self.replaceCover(image)
                    case let .failure(error):
                        guard !error.isUserCancel else { return }
                        JPProgressHUD.showError(withStatus: "拍照失败", userInteractionEnabled: true)
                    }
                }
            }
            .addAction("相册") {
                ImagePicker.openAlbumForImage { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case let .success(image):
                        self.replaceCover(image)
                    case let .failure(error):
                        guard !error.isUserCancel else { return }
                        JPProgressHUD.showError(withStatus: "照片获取失败", userInteractionEnabled: true)
                    }
                }
            }
            .addCancel()
            .present(from: self)
    }
    
    func replaceCover(_ image: UIImage) {
        isEditedCover = true
        
        let imageRatio = image.size.width / image.size.height
        var imageH = PortraitScreenWidth / imageRatio
        if imageH > PortraitScreenWidth {
            imageH = PortraitScreenWidth
        }
        
        UIView.transition(with: self.imageView, duration: 0.2, options: .transitionCrossDissolve) {
            self.imageView.image = image
        } completion: { _ in
            guard self.imageView.height != imageH else { return }
            UIView.animate(withDuration: 0.55, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1) {
                self.imageView.height = imageH
                self.titLabel.y = self.imageView.maxY + 15.px
                self.textFieldBgView.y = self.titLabel.maxY + 10.px
            }
        }
    }
}
