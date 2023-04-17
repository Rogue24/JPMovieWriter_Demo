//
//  AppDelegate.swift
//  JPMovieWriter
//
//  Created by 周健平 on 03/21/2023.
//  Copyright (c) 2023 zhoujianping. All rights reserved.
//

import UIKit
import JPBasic

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        JPProgressHUD.setMaxSupportedWindowLevel(.alert)
        JPProgressHUD.setMinimumDismissTimeInterval(1.3)
        
        RecordCacheTool.setup()
        
        ScreenRotator.shared.isLockOrientationWhenDeviceOrientationDidChange = false
        ScreenRotator.shared.isLockLandscapeWhenDeviceOrientationDidChange = false
        
        if #available(iOS 15.0, *) {
            let navigationBar = UINavigationBar.appearance()
            let appearance = UINavigationBarAppearance()
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.standardAppearance = appearance
        }
        
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return ScreenRotator.shared.orientationMask
    }

    
    func applicationDidEnterBackground(_ application: UIApplication) {
        if backgroundTaskIdentifier != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
        }
        
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask() {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
            self.backgroundTaskIdentifier = .invalid
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        if backgroundTaskIdentifier != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
        }
    }
}

