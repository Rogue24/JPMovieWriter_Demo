//
//  RecordViewController.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/3/27.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Combine
import JPBasic
import pop

class RecordViewController: UIViewController {
    @discardableResult
    static func show(_ recordedCache: RecordCache? = nil, recordDoneHandler: ((_ newCache: RecordCache) -> Void)? = nil) -> RecordViewController? {
        guard !JPMovieWriter.isAlive() else {
            JPProgressHUD.showInfo(withStatus: "有录制器没有彻底销毁，不能打开新的录制器！请稍后再试。")
            return nil
        }
        let recordVC = RecordViewController()
        recordVC.recordedCache = recordedCache
        recordVC.recordDoneHandler = recordDoneHandler
        recordVC.modalPresentationStyle = .fullScreen
        GetTopMostViewController()?.present(recordVC, animated: true)
        return recordVC
    }
    
    private(set) var recordedCache: RecordCache?
    private(set) var recordedDuration: TimeInterval = 0
    
    var recordDoneHandler: ((_ newCache: RecordCache) -> Void)?
    
    let filterMgr = RecordFilterManager()
    
    lazy var previewView: JPPreviewView = {
        let previewView = JPPreviewView(frame: CGRect(origin: [0, NavTopMargin], size: UIConfig.videoViewSize))
        previewView.fillMode = GPUImageFillModeType.preserveAspectRatio
        previewView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(pinchAction(_:))))
        return previewView
    }()
    
    lazy var optionBar: RecordOptionBar = {
        let optionBar = RecordOptionBar(isOnVortex: RecordConfig.isOnVortex, isFrontCamera: RecordConfig.isFrontCamera, isOpeningTorch: torchTool.isOpening, delegate: self)
        optionBar.y = StatusBarH
        return optionBar
    }()
    
    lazy var controlBar: RecordControlBar = {
        let controlBar = RecordControlBar(delegate: self)
        controlBar.y = PortraitScreenHeight - DiffTabBarH - controlBar.height - 60.px
        return controlBar
    }()
    
    var controlBtn: RecordControlButton { controlBar.controlBtn }
    
    lazy var writer: JPMovieWriter = {
        let recordedURLs: [URL] = recordedCache.map { [URL(fileURLWithPath: $0.recordCachePath)] } ?? []
        let writer = JPMovieWriter(fileType: AVFileType.mp4,
                                   videoSize: UIConfig.videoSize,
                                   videoSettings: RecordConfig.videoOutputSettings,
                                   recordedURLs: recordedURLs)
        // 是否对视频进行编码，这个设置为YES，AVAssetWriterInput的expectsMediaDataInRealTime则也为YES，代表需要从capture session实时获取数据
        writer.encodingLiveVideo = true
        writer.setHasAudioTrack(true, audioSettings: RecordConfig.audioOutputSettings)
        writer.maxRecordDuration = RecordConfig.videoMaxDuration
        writer.delegate = self
        return writer
    }()
    
    lazy var camera: GPUImageStillCamera = {
        let camera = GPUImageStillCamera(sessionPreset: AVCaptureSession.Preset.high.rawValue, cameraPosition: RecordConfig.isFrontCamera ? .front : .back)!
        camera.outputImageOrientation = .portrait
        camera.horizontallyMirrorFrontFacingCamera = true
        camera.captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
        camera.jp_setAudioEncodingTarget(writer) // 把采集的音频交给JPMovieWriter写入
        torchTool.camera = camera.inputCamera
        return camera
    }()
    
    let torchTool = TorchTool()
    
    var cancellable1: AnyCancellable?
    var cancellable2: AnyCancellable?
    
    private var _distance: CGFloat = 1
    private var distance: CGFloat {
        set {
            guard let inputCamera = camera.inputCamera else { return }
            var distance = newValue
            if distance < 1 {
                distance = 1
            } else if distance > 5 {
                distance = 5
            }
            do {
                try inputCamera.lockForConfiguration()
                inputCamera.videoZoomFactor = distance
                inputCamera.unlockForConfiguration()
                _distance = distance
            } catch {}
        }
        get { _distance }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupFilter()
        setupObserver()
        setupOther()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        pauseBackgroundSound()
        
        // 防止卡顿
        Asyncs.async {
            self.camera.startCapture()
        } mainTask: {
            UIView.transition(with: self.previewView, duration: 0.5, options: .transitionCrossDissolve) {
                self.previewView.isHidden = false
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if writer.isRecording {
            controlBar.isEnabled = false
            writer.finishRecord() { [weak self] _ in
                guard let self = self else { return }
                self.controlBar.isEnabled = true
            }
//            camera.isWriterPause = true
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        camera.stopCapture()
//        resumeBackgroundSound()
    }
    
    deinit {
        cancellable1?.cancel()
        cancellable2?.cancel()
        writer.cancelRecord()
        camera.removeAllTargets()
        camera.stopCapture()
        JPrint("挂柴")
    }
}

private extension RecordViewController {
    func setupUI() {
        view.backgroundColor = .black
        view.addSubview(previewView)
        view.addSubview(optionBar)
        view.addSubview(controlBar)
    }
    
    func setupFilter() {
        filterMgr.bridging(from: camera)
            .jp_addTarget(writer)
            .jp_addTarget(previewView)
        
        filterMgr.bridgeDone()
    }
    
    func setupObserver() {
        cancellable1 = NotificationCenter.default
                .publisher(for: UIApplication.willResignActiveNotification) // App进入后台
                .sink() { [weak self] _ in
                    guard let self = self, self.writer.isRecording else { return }
                    self.controlBar.isEnabled = false
                    self.writer.finishRecord() { [weak self] _ in
                        guard let self = self else { return }
                        self.controlBar.isEnabled = true
                    }
//                    self.camera.isWriterPause = true
                }
        
        cancellable2 = torchTool.$isOpening
            .dropFirst() // 忽略第一次
            .removeDuplicates() // 忽略重复值（过滤相同、没变化的）
            .sink { [weak self] isOpening in
                guard let self = self else { return }
                self.optionBar.isOpeningTorch = isOpening
            }
    }
    
    func setupOther() {
        previewView.isHidden = true
        
        recordedDuration = writer.recordDuration
        
        let progress = recordedDuration / writer.maxRecordDuration
        controlBtn.setProgress(progress, animated: false)
    }
    
//    func resumeBackgroundSound() {
//        do {
//            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
//        } catch {
//
//        }
//    }
    
//    func pauseBackgroundSound() {
//        do {
//            try AVAudioSession.sharedInstance().setCategory(.soloAmbient)
//            try AVAudioSession.sharedInstance().setCategory(.playback)
//            try AVAudioSession.sharedInstance().setActive(true)
//        } catch {
//
//        }
//    }
}

// MARK: - Gesture Handle
private extension RecordViewController {
    // 捏合手势：调整焦距
    @objc func pinchAction(_ pinchGR: UIPinchGestureRecognizer) {
        let diffScale = pinchGR.scale - 1
        distance += diffScale
        pinchGR.scale = 1
    }
}

//extension RecordViewController {
//
//    @objc func switchFilter() {
//
//        watermark.x += 1
//        watermark.y += 1
//        watermarkElement.update()
//    }
//
//}

// MARK: - <RecordOptionBarDelegate>
extension RecordViewController: RecordOptionBarDelegate {
    // MARK: - RecordOptionBarDelegate
    func optionBarDidClick(_ optionBar: RecordOptionBar, option: RecordOption?) {
        optionBarHeightDidChanged(optionBar)
        
        guard let option = option else { return }
        switch option {
//        case .watermark:
//            let imagePicker = UIImagePickerController()
//            imagePicker.sourceType = .savedPhotosAlbum
//            present(imagePicker, animated: true)
            
        case .watermark, .vortex:
            JPProgressHUD.show(nil, status: "敬请期待")
            
        case .flashlight:
            if torchTool.isOpening {
                torchTool.close()
            } else {
                torchTool.open()
            }
            
        default:
            break
        }
    }
    
    func optionBarHeightDidChanged(_ optionBar: RecordOptionBar) {
        var frame = previewView.frame
        frame.origin.y = optionBar.maxY
        
        let anim = POPBasicAnimation(propertyNamed: kPOPViewFrame)!
        anim.duration = 0.3
        anim.toValue = frame
        previewView.pop_add(anim, forKey: kPOPViewFrame)
    }
    
    // MARK: - RecordBeautySliderDelegate
    func beautySliderDidChangedValue(_ beautySlider: RecordBeautySlider, value: CGFloat, isBeauty: Bool) {
        if isBeauty {
            filterMgr.beautyLevel = value
        } else {
            filterMgr.brightLevel = value
        }
    }
    
    // MARK: - RecordFilterListDelegate
    func filterListDidChangedFilter(_ filterList: RecordFilterList, model: RecordFilterList.Model) {
        filterMgr.switchLookup(ofFile: model.filePath, intensity: model.value)
    }
    
    func filterListDidChangedFilterValue(_ filterList: RecordFilterList, model: RecordFilterList.Model) {
        filterMgr.lookupIntensity = model.value
    }
    
}

// MARK: - <RecordControlBarDelegate>
extension RecordViewController: RecordControlBarDelegate {
    func controlButtonDidClick(_ controlBtn: RecordControlButton) -> Bool {
        if writer.isRecording {
            controlBar.isEnabled = false
            writer.finishRecord() { _ in
                self.controlBar.isEnabled = true
            }
//            camera.isWriterPause = true
        } else {
            if writer.startRecord() {
//                camera.isWriterPause = false
            }
        }
        return writer.isRecording
    }
    
    func controlBarDidClickRotateCamera(_ controlBar: RecordControlBar) {
        torchTool.close()
        optionBar.isFrontCamera.toggle()
        
        previewView.setIsShowBlur(true, duration: 0.15) { [weak self] in
            guard let self = self else { return }
            
            UIView.transition(with: self.previewView, duration: 0.5, options: [
                .curveEaseInOut,
                self.camera.cameraPosition() == .front ? .transitionFlipFromLeft : .transitionFlipFromRight
            ]) {} completion: { _ in
                self.previewView.setIsShowBlur(false, duration: 0.15, complete: nil)
            }
            
            Asyncs.mainDelay(0.05) {
                self.camera.rotateCamera()
                
                let inputCamera = self.camera.inputCamera
                self.torchTool.camera = inputCamera
                
                let isFrontCamera = self.camera.cameraPosition() == .front
                self.optionBar.isFrontCamera = isFrontCamera
                RecordConfig.isFrontCamera = isFrontCamera
            }
        }
    }
    
    func controlBarDidClickClose(_ controlBar: RecordControlBar) {
        if writer.isRecording {
            confirmStopRecord()
        } else {
            let recordCount = writer.recordedURLs.count - (recordedCache != nil ? 1 : 0)
            if recordCount > 0 {
                confirmQuit()
            } else {
                dismiss(animated: true)
            }
        }
    }
}

private extension RecordViewController {
    func confirmStopRecord() {
        JPProgressHUD.show()
        controlBar.isEnabled = false
        writer.finishRecord() { [weak self] _ in
            JPProgressHUD.dismiss()
            guard let self = self else { return }
            self.controlBar.isEnabled = true
            self.confirmQuit()
        }
    }
    
    func confirmQuit() {
        let isMoreThanOneSecond = (writer.recordDuration - recordedDuration) >= 1
        let alertCtr = UIAlertController.build(.alert, title: "确定退出？", message: isMoreThanOneSecond ? nil : "录制不足1秒不能保存")
        
        if isMoreThanOneSecond {
            alertCtr.addAction("保存并退出") {
                self.quit(isSave: true)
            }
        }
        
        alertCtr.addAction("重新录制") {
            self.reRecorded()
        }
        .addDestructive("删除并退出") {
            self.quit(isSave: false)
        }
        .addCancel()
        .present(from: self)
    }
}

private extension RecordViewController {
    func quit(isSave: Bool) {
        JPProgressHUD.show()
        if isSave {
            VideoTool.mergeVideos(writer.recordedURLs,
                                  videoSize: UIConfig.videoSize,
                                  contentMode: .scaleAspectFit,
                                  maxDuration: CMTime(value: Int64(RecordConfig.videoMaxDuration), timescale: 1)) { mergedFilePath in
                Asyncs.async {
                    self.writer.cleanRecord()
                    
                    let newCache = self.recordedCache ?? RecordCache()
                    RecordCacheTool.recordDoneToSave(newCache, recordFilePath: mergedFilePath)
                    
                    Asyncs.main {
                        JPProgressHUD.dismiss()
                        let recordDoneHandler = self.recordDoneHandler
                        self.dismiss(animated: true) {
                            recordDoneHandler?(newCache)
                        }
                    }
                }
            } faild: { error in
                JPProgressHUD.dismiss()
                
                UIAlertController
                    .build(.alert,
                           title: "录制失败",
                           message: (error as? NSError)?.localizedDescription)
                    .addAction("重试") {
                        self.quit(isSave: true)
                    }
                    .addAction("重新录制") {
                        self.reRecorded()
                    }
                    .addDestructive("删除并退出") {
                        self.quit(isSave: false)
                    }
                    .present(from: self)
            }
        } else {
            writer.cleanRecord() { [weak self] in
                JPProgressHUD.dismiss()
                self?.dismiss(animated: true)
            }
        }
    }
    
    func reRecorded() {
        controlBar.isEnabled = false
        writer.cleanRecord() { [weak self] in
            guard let self = self else { return }
            self.controlBar.isEnabled = true
            
            let progress = self.writer.recordDuration / self.writer.maxRecordDuration
            self.controlBtn.setProgress(progress, animated: true)
        }
    }
}


// MARK: - <JPMovieWriterDelegate>
extension RecordViewController: JPMovieWriterDelegate {
    func movieWriter(_ writer: JPMovieWriter, resetFailed recordedURLs: [URL], error: Error) {
        JPProgressHUD.showError(withStatus: (error as NSError).localizedDescription, userInteractionEnabled: true)
    }
    
    func movieWriter(_ writer: JPMovieWriter, recording recordDuration: TimeInterval, totalDuration: TimeInterval) {
        let progress = recordDuration / totalDuration
        controlBtn.setProgress(progress, animated: false)
    }
    
    func movieWriter(_ writer: JPMovieWriter, recordWillDone error: Error?) {
        JPProgressHUD.show(withStatus: error == nil ? "正在结束录制" : "录制发生错误")
        controlBar.isEnabled = false
    }

    func movieWriter(_ writer: JPMovieWriter, recordDone recordedURLs: [URL], error: Error?) {
        if let error = error as? NSError {
            JPProgressHUD.showError(withStatus: error.localizedDescription, userInteractionEnabled: true)
            controlBar.isEnabled = true
            let progress = writer.recordDuration / writer.maxRecordDuration
            controlBtn.setProgress(progress, animated: true)
            return
        }
        
        VideoTool.mergeVideos(recordedURLs, videoSize: UIConfig.videoSize, contentMode: .scaleAspectFit, maxDuration: CMTime(value: Int64(RecordConfig.videoMaxDuration), timescale: 1)) { mergedFilePath in
            Asyncs.async {
                recordedURLs.forEach { File.manager.deleteFile($0) }
            } mainTask: {
                JPProgressHUD.dismiss()
                self.controlBar.isEnabled = true
                
                UIAlertController
                    .build(.alert, title: "录制完成")
                    .addAction("保存") {
                        JPProgressHUD.show()
                        Asyncs.async {
                            self.writer.cleanRecord()
                            
                            let newCache = self.recordedCache ?? RecordCache()
                            RecordCacheTool.recordDoneToSave(newCache, recordFilePath: mergedFilePath)
                            
                            Asyncs.main {
                                JPProgressHUD.dismiss()
                                let recordDoneHandler = self.recordDoneHandler
                                self.dismiss(animated: true) {
                                    recordDoneHandler?(newCache)
                                }
                            }
                        }
                    }
                    .addAction("重新录制") {
                        self.reRecorded()
                    }
                    .present(from: self)
            }
        } faild: { kError in
            JPProgressHUD.dismiss()
            self.controlBar.isEnabled = true
            
            UIAlertController
                .build(.alert,
                       title: "录制失败",
                       message: (kError as? NSError)?.localizedDescription)
                .addAction("重试") {
                    self.quit(isSave: true)
                }
                .addAction("重新录制") {
                    self.reRecorded()
                }
                .addDestructive("删除并退出") {
                    self.quit(isSave: false)
                }
                .present(from: self)
        }
    }
}
