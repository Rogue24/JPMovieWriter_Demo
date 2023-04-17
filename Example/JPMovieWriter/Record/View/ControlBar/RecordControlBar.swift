//
//  RecordControlBar.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/3/26.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

protocol RecordControlBarDelegate: RecordControlButtonDelegate {
    func controlBarDidClickRotateCamera(_ controlBar: RecordControlBar)
    func controlBarDidClickClose(_ controlBar: RecordControlBar)
}

class RecordControlBar: FloatContainer {
    weak var delegate: RecordControlBarDelegate?
    
    var isEnabled = true {
        didSet {
            if !isEnabled {
                controlBtn.stopRecord()
            }
            controlBtn.isEnabled = isEnabled
        }
    }
    
    let controlBtn: RecordControlButton
    
    init(delegate: RecordControlBarDelegate?) {
        self.delegate = delegate
        self.controlBtn = RecordControlButton(delegate: delegate)
        super.init(frame: [0, 0, PortraitScreenWidth, 80.px])
        
        controlBtn.center = [width * 0.5, height * 0.5]
        addSubview(controlBtn)
        
        let btnWH: CGFloat = 44.px
        
        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "chevron.down.circle.fill"), for: .normal)
        closeBtn.tintColor = .white
        closeBtn.frame = [HalfDiffValue(controlBtn.x, btnWH),
                          HalfDiffValue(height, btnWH),
                          btnWH, btnWH]
        closeBtn.addTarget(self, action: #selector(close), for: .touchUpInside)
        addSubview(closeBtn)
        
        let rotateCameraBtn = UIButton(type: .system)
        rotateCameraBtn.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera.fill"), for: .normal)
        rotateCameraBtn.tintColor = .white
        rotateCameraBtn.frame = [controlBtn.maxX + HalfDiffValue(width - controlBtn.maxX, btnWH),
                                 HalfDiffValue(height, btnWH),
                                 btnWH, btnWH]
        rotateCameraBtn.addTarget(self, action: #selector(rotateCamera), for: .touchUpInside)
        addSubview(rotateCameraBtn)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func rotateCamera() {
        guard isEnabled, let delegate = self.delegate else { return }
        delegate.controlBarDidClickRotateCamera(self)
    }
    
    @objc func close() {
        guard isEnabled, let delegate = self.delegate else { return }
        delegate.controlBarDidClickClose(self)
    }
}
