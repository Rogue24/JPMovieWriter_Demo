//
//  FloatContainer.swift
//  Neves
//
//  Created by 周健平 on 2022/3/28.
//

class FloatContainer: UIView {
    // MARK: 拦截点击，只让子视图响应，自己则穿透
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isHidden, subviews.count > 0 else { return nil }
        for subview in subviews.reversed() where subview.isUserInteractionEnabled && !subview.isHidden && subview.alpha > 0.01 && subview.frame.contains(point) {
            let childP = convert(point, to: subview)
            guard let rspView = subview.hitTest(childP, with: event) else { continue }
            return rspView
        }
        return nil
    }
}
