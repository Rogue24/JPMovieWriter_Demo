//
//  RecordControlButton.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/3/26.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import pop

protocol RecordControlButtonDelegate: AnyObject {
    func controlButtonDidClick(_ controlBtn: RecordControlButton) -> Bool
}

class RecordControlButton: UIView {
    weak var delegate: RecordControlButtonDelegate?
    
    let botLayer = CALayer()
    let topLayer = CALayer()
    let progressLayer = CAShapeLayer()
    
    var progress: CGFloat { progressLayer.strokeEnd }
    
    private var isTouchBegin = false
    
    private var _isTouching = false
    private(set) var isTouching: Bool {
        set {
            guard _isTouching != newValue else { return }
            _isTouching = newValue
            
            updateBgScale()
            
            guard _isTouching else { return }
            if #available(iOS 10.0, *) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        get { _isTouching }
    }
    
    var isEnabled: Bool = true {
        didSet {
            guard isEnabled != oldValue else { return }
            if isEnabled {
                isUserInteractionEnabled = true
            } else {
                delayEnabled()
            }
        }
    }
    
    private func delayEnabled() {
        guard isUserInteractionEnabled else { return }
        isUserInteractionEnabled = false
        Asyncs.mainDelay(0.5) { [weak self] in
            guard let self = self, self.isEnabled else { return }
            self.isUserInteractionEnabled = true
        }
    }
    
    private var isRecording: Bool = false
    
    init(delegate: RecordControlButtonDelegate?)
    {
        self.delegate = delegate
        super.init(frame: [0, 0, 80.px, 80.px])
        clipsToBounds = false
        
        botLayer.frame = bounds
        botLayer.backgroundColor = UIColor.rgb(230, 230, 230, a: 0.5).cgColor
        botLayer.cornerRadius = bounds.height * 0.5
        botLayer.masksToBounds = true
        layer.addSublayer(botLayer)
        
        topLayer.frame = [HalfDiffValue(bounds.width, 60.px), HalfDiffValue(bounds.height, 60.px), 60.px, 60.px]
        topLayer.backgroundColor = UIColor.rgb(255, 255, 255, a: 0.9).cgColor
        topLayer.cornerRadius = 30.px
        topLayer.masksToBounds = true
        layer.addSublayer(topLayer)
        
        progressLayer.lineWidth = 5.px
        progressLayer.strokeColor = UIColor.rgb(255, 87, 169, a: 0.9).cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineCap = .round
        progressLayer.lineJoin = .round
        progressLayer.path = UIBezierPath(arcCenter: [bounds.width * 0.5, bounds.height * 0.5],
                                          radius: (bounds.width - progressLayer.lineWidth) * 0.5,
                                          startAngle: -CGFloat.pi / 2,
                                          endAngle: (-CGFloat.pi / 2 + CGFloat.pi * 2),
                                          clockwise: true).cgPath
//        progressLayer.strokeEnd = beginDuration / totalDuration
//        progressLayer.opacity = beginDuration > 0 ? 1 : 0
        progressLayer.strokeEnd = 0
        progressLayer.opacity = 0
        botLayer.addSublayer(progressLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouchBegin = true
        isTouching = true
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isTouchBegin else { return }
        
        guard let touch = event?.allTouches?.first else {
            isTouchBegin = false
            isTouching = false
            return
        }
        
        let point = touch.location(in: self)
        isTouching = bounds.contains(point)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isTouchBegin else { return }
        isTouchBegin = false
        isTouching = false
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isEnabled else {
            JPrint("不可响应")
            isRecording = false
            touchEnd()
            return
        }
        
        guard isTouchBegin else { return }
        isTouchBegin = false
        
        guard _isTouching else { return }
        isRecording = delegate?.controlButtonDidClick(self) ?? false
        touchEnd()
    }
}

// extension RecordControlButton {
//    func resume() {
//        isTouchBegin = false
//        _isTouching = false
//        isRecording = true
//
//        updateBgScale()
//
//        delegate?.controlButtonDidResumed(self)
//    }
//
//    func pause() {
//        isTouchBegin = false
//        _isTouching = false
//        isRecording = false
//
//        updateBgScale()
//
//        delegate?.controlButtonDidPaused(self)
//    }
//
//    func finish() {
//        isTouchBegin = false
//        _isTouching = false
//        isRecording = false
//
//        updateBgScale()
//        removeProgress()
//
//        delegate?.controlButtonDidFinished(self)
//    }
//
//    func cancel() {
//        isTouchBegin = false
//        _isTouching = false
//        isRecording = false
//
//        updateBgScale()
//
//        delegate?.controlButtonDidCancelled(self)
//    }
//
//    func disable() {
//        isTouchBegin = false
//        _isTouching = false
//        isRecording = false
//
//        updateBgScale()
//    }
//}

private extension RecordControlButton {
    func touchEnd() {
        isTouchBegin = false
        _isTouching = false
        updateBgScale()
    }
    
    func updateBgScale() {
        switch (isRecording, _isTouching) {
        case (true, true):
            updateBgScale(1.3, 0.65)
        case (true, false):
            updateBgScale(1.2, 0.7)
        case (false, true):
            updateBgScale(1, 1)
        case (false, false):
            updateBgScale(1, 1)
        }
    }
    
    func updateBgScale(_ botScale: CGFloat, _ topScale: CGFloat) {
        botLayer.pop_removeAllAnimations()
        topLayer.pop_removeAllAnimations()
        
        let anim1 = POPSpringAnimation(propertyNamed: kPOPLayerScaleXY)!
        anim1.springSpeed = 17
        anim1.springBounciness = 10
        anim1.toValue = CGPoint(x: botScale, y: botScale)
        botLayer.pop_add(anim1, forKey: kPOPLayerScaleXY)
        
        let anim2 = POPSpringAnimation(propertyNamed: kPOPLayerScaleXY)!
        anim2.springSpeed = 10
        anim2.springBounciness = 10
        anim2.toValue = CGPoint(x: topScale, y: topScale)
        topLayer.pop_add(anim2, forKey: kPOPLayerScaleXY)
    }
}

extension RecordControlButton {
    func setProgress(_ progress: CGFloat, animated: Bool) {
        if progress == 0, animated {
            resetProgress()
            return
        }
        
        showOrHiddenProgress(progress)
        
        guard progress > 0 else { return }
        if animated {
            let anim1 = POPBasicAnimation(propertyNamed: kPOPShapeLayerStrokeEnd)!
            anim1.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            anim1.fromValue = progressLayer.strokeEnd
            anim1.toValue = progress
            anim1.duration = 0.35
            progressLayer.pop_add(anim1, forKey: kPOPShapeLayerStrokeEnd)
        } else {
            progressLayer.pop_removeAnimation(forKey: kPOPShapeLayerStrokeEnd)
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            progressLayer.strokeEnd = progress
            CATransaction.commit()
        }
    }
    
    private func resetProgress() {
        let anim1 = POPBasicAnimation(propertyNamed: kPOPShapeLayerStrokeEnd)!
        anim1.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        anim1.fromValue = progressLayer.strokeEnd
        anim1.toValue = 0
        anim1.duration = 0.35
        progressLayer.pop_add(anim1, forKey: kPOPShapeLayerStrokeEnd)
        
        let anim = POPBasicAnimation(propertyNamed: kPOPLayerOpacity)!
        anim.toValue = 0
        anim.beginTime = CACurrentMediaTime() + 0.2
        anim.duration = 0.15
        progressLayer.pop_add(anim, forKey: kPOPLayerOpacity)
    }
    
    private func showOrHiddenProgress(_ progress: CGFloat) {
        let opacity: Float = progress > 0 ? 1 : 0
        
        guard progressLayer.opacity != opacity else {
            if opacity == 0 {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                progressLayer.strokeEnd = 0
                CATransaction.commit()
            }
            return
        }
        
        if let kAnim = progressLayer.pop_animation(forKey: kPOPLayerOpacity) as? POPBasicAnimation,
           let toValue = kAnim.toValue as? Float, toValue == opacity {
            return
        }
        
        let anim = POPBasicAnimation(propertyNamed: kPOPLayerOpacity)!
        anim.toValue = opacity
        anim.duration = 0.2
        anim.completionBlock = { [weak self] _, finished in
            guard let self = self, finished, opacity == 0 else { return }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.progressLayer.strokeEnd = 0
            CATransaction.commit()
        }
        progressLayer.pop_add(anim, forKey: kPOPLayerOpacity)
    }
    
    func stopRecord() {
        guard isRecording else { return }
        isRecording = false
        updateBgScale()
    }
    
    
//    func recoverProgress() {
//        guard !isRecording, beginDuration > 0 else { return }
//        progressLayer.pop_removeAllAnimations()
//        progressLayer.strokeEnd = beginDuration / totalDuration
//
//        let anim = POPBasicAnimation(propertyNamed: kPOPLayerOpacity)!
//        anim.toValue = 1
//        anim.duration = 0.2
//        progressLayer.pop_add(anim, forKey: kPOPLayerOpacity)
//    }
//
//    func resumeProgress() {
//        guard isRecording else { return }
//
//        let anim1 = POPBasicAnimation(propertyNamed: kPOPShapeLayerStrokeEnd)!
//        anim1.timingFunction = CAMediaTimingFunction(name: .linear)
//        anim1.fromValue = progressLayer.strokeEnd
//        anim1.toValue = 1
//        anim1.duration = totalDuration * (1 - progress)
//        anim1.completionBlock = { [weak self] _, finished in
//            guard finished, let self = self else { return }
//            self.finish()
//        }
//        progressLayer.pop_add(anim1, forKey: kPOPShapeLayerStrokeEnd)
//
//        let anim2 = POPBasicAnimation(propertyNamed: kPOPLayerOpacity)!
//        anim2.toValue = 1
//        anim2.duration = 0.15
//        progressLayer.pop_add(anim2, forKey: kPOPLayerOpacity)
//    }
//
//    func removeProgress() {
//        guard !isRecording else { return }
//
//        let anim = POPBasicAnimation(propertyNamed: kPOPLayerOpacity)!
//        anim.toValue = 0
//        anim.duration = 0.15
//        anim.completionBlock = { [weak self] _, _ in
//            guard let self = self else { return }
//            CATransaction.begin()
//            CATransaction.setDisableActions(true)
//            self.progressLayer.strokeEnd = 0
//            CATransaction.commit()
//        }
//        progressLayer.pop_add(anim, forKey: kPOPLayerOpacity)
//    }
}
