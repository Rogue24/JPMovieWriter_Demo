//
//  Const.swift
//  Neves_Example
//
//  Created by 周健平 on 2020/10/9.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit

let ScreenScale: CGFloat = UIScreen.mainScale

let PortraitScreenWidth: CGFloat = min(UIScreen.mainWidth, UIScreen.mainHeight)
let PortraitScreenHeight: CGFloat = max(UIScreen.mainWidth, UIScreen.mainHeight)
let PortraitScreenSize: CGSize = CGSize(width: PortraitScreenWidth, height: PortraitScreenHeight)
let PortraitScreenBounds: CGRect = CGRect(origin: .zero, size: PortraitScreenSize)

let LandscapeScreenWidth: CGFloat = PortraitScreenHeight
let LandscapeScreenHeight: CGFloat = PortraitScreenWidth
let LandscapeScreenSize: CGSize = CGSize(width: LandscapeScreenWidth, height: LandscapeScreenHeight)
let LandscapeScreenBounds: CGRect = CGRect(origin: .zero, size: LandscapeScreenSize)

let IsBangsScreen: Bool = PortraitScreenHeight > 736.0

private var _DiffTabBarH: CGFloat = 0
var DiffTabBarH: CGFloat {
    guard _DiffTabBarH == 0 else { return _DiffTabBarH }
    
    if #available(iOS 11.0, *),
       let window = UIApplication.shared.delegate?.window ?? UIApplication.shared.windows.first
    {
        _DiffTabBarH = window.safeAreaInsets.bottom
    }
    
    guard _DiffTabBarH == 0 else { return _DiffTabBarH }
    
    if IsBangsScreen {
        return 34.0
    } else {
        return 0
    }
}
let BaseTabBarH: CGFloat = 49.0
let TabBarH: CGFloat = BaseTabBarH + DiffTabBarH

private var _StatusBarH: CGFloat = 0
var StatusBarH: CGFloat {
    guard _StatusBarH == 0 else { return _StatusBarH }
    
    if #available(iOS 11.0, *) {
        if let window = UIApplication.shared.delegate?.window ?? UIApplication.shared.windows.first {
            if #available(iOS 13.0, *) {
                if let statusBarManager = window.windowScene?.statusBarManager {
                    _StatusBarH = statusBarManager.statusBarFrame.height
                } else {
                    _StatusBarH = window.safeAreaInsets.top
                }
            } else {
                _StatusBarH = window.safeAreaInsets.top
            }
        } else {
            if #available(iOS 13.0, *) {} else {
                _StatusBarH = UIApplication.shared.statusBarFrame.height
            }
        }
    } else {
        _StatusBarH = UIApplication.shared.statusBarFrame.height
    }
    
    guard _StatusBarH == 0 else { return _StatusBarH }
    
    if IsBangsScreen {
        if #available(iOS 13.0, *) {
            return 48.0
        } else {
            return 44.0
        }
    } else {
        return BaseStatusBarH
    }
}
let BaseStatusBarH: CGFloat = 20.0
let DiffStatusBarH: CGFloat = StatusBarH - BaseStatusBarH

let NavBarH: CGFloat = 44.0
let NavTopMargin: CGFloat = StatusBarH + NavBarH

let BasisWScale: CGFloat = PortraitScreenWidth / 375.0
let BasisHScale: CGFloat = (PortraitScreenHeight - DiffStatusBarH - DiffTabBarH) / 667.0

let SeparateLineThick: CGFloat = ScreenScale > 2 ? 0.333 : 0.5;

let AspectRatio_16_9: CGFloat = 16.0 / 9.0
let AspectRatio_9_16: CGFloat = 9.0 / 16.0

let hhmmssSSFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "hh:mm:ss:SS"
    return formatter
}()

let ColorSpace = CGColorSpaceCreateDeviceRGB()
