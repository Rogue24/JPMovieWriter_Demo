//
//  TorchTool.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/4/4.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Combine

class TorchTool: ObservableObject {
    weak var camera: AVCaptureDevice? {
        didSet {
            if let camera = self.camera {
                isOpening = camera.torchMode != .off
            } else {
                isOpening = false
            }
        }
    }
    
    @Published private(set) var isOpening: Bool = false
    
    private var cancellable: AnyCancellable?
    
    init() {
        cancellable = NotificationCenter.default
                .publisher(for: UIApplication.didBecomeActiveNotification)
                .sink() { [weak self] _ in
                    guard let self = self else { return }
                    if let camera = self.camera {
                        self.isOpening = camera.torchMode != .off
                    } else {
                        self.isOpening = false
                    }
                }
    }
    
    deinit {
        cancellable?.cancel()
    }
    
    // 开启闪光灯
    func open() {
        guard let camera = self.camera, camera.hasTorch, camera.torchMode == .off else { return }
        do {
            try camera.lockForConfiguration()
            camera.torchMode = .on
            camera.unlockForConfiguration()
            isOpening = true
        } catch {
            JPrint("open failed:", error)
        }
    }
    
    // 关闭闪光灯
    func close() {
        guard let camera = self.camera, camera.torchMode == .on else { return }
        do {
            try camera.lockForConfiguration()
            camera.torchMode = .off
            camera.unlockForConfiguration()
            isOpening = false
        } catch {
            JPrint("close failed:", error)
        }
    }
}
