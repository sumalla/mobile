//
//  AppDelegate.swift
//  Prototype
//
//  Created by Nathan Trapp on 1/31/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import DataSource
import Fabric
import Crashlytics

let RootCoordinator = NewAppCoordinator()

#if DEBUG
    let RootViewController = ShakeViewController()
#else
    let RootViewController = AppViewController()
#endif

private let SAVCustomServerAddress = "SAVCustomServerAddress"

@UIApplicationMain
class SAVAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        Fabric.with([Crashlytics()])
        
        SCUBackgroundHandler.sharedInstance().start()
        setupSDK()
        setupAppearance()

        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.tintColor = Colors.color1shade1
        window?.rootViewController = RootViewController
        window?.rootViewController?.view.backgroundColor = Colors.color2shade1
        window?.makeKeyAndVisible()
        RootViewController.loadInitialView()

        return true
    }

    func setupSDK() {
        let sdk = Savant.control()
        sdk.deviceFormFactor = UIDevice.isPad() ? "tablet" : "phone"
        sdk.deviceManufacturer = "Apple"
        sdk.deviceOperatingSystem = UIDevice.currentDevice().systemName
        sdk.deviceOperatingSystemVersion = UIDevice.currentDevice().systemVersion
        sdk.deviceName = UIDevice.currentDevice().name
        sdk.deviceModel = UIDevice.currentDevice().model
        sdk.deviceModelVersion = UIDevice.currentDevice().sav_modelVersion()
        sdk.deviceUID = UIDevice.currentDevice().identifierForVendor.UUIDString
        sdk.appName = "Savant"
        sdk.appVersion = appVersion()
    }
    
    func setupAppearance() {
        let colors = SCUColors.shared()

        window?.backgroundColor = colors.color03shade01
        window?.tintColor = colors.color04

        UINavigationBar.appearance().barTintColor = Colors.color2shade1
        UINavigationBar.appearance().tintColor = Colors.color4shade1
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: colors.color04]

        UITextField.appearance().keyboardAppearance = .Dark

        DataSourceTableViewCell.appearance().backgroundColor = colors.color03shade03
        UITableView.appearance().backgroundColor = Colors.color2shade1
        UITableView.appearance().separatorColor = colors.color03shade04
        
        DiscreteVolumeCell.appearance().backgroundColor = Colors.color1shade1
        RelativeVolumeCell.appearance().backgroundColor = Colors.color1shade1
        MasterVolumeCell.appearance().backgroundColor = Colors.color3shade3

        SCUAppearance.setupAppearance()
    }

    func appVersion() -> String {
        if let info = NSBundle.mainBundle().infoDictionary as? [String: AnyObject] {
            let version = info["ActualVersion"] as? String
            let branch = info["BranchName"] as? String
            let buildNumber = info["BuildNumber"] as? String
            let hash = info["ShortCommit"] as? String
            let environment: String

            #if SERVER_PRODUCTION
                environment = "production"
            #elseif SERVER_DEV1
                environment = "cdev1"
            #elseif SERVER_DEV2
                environment = "cdev2"
            #elseif SERVER_ALPHA
                environment = "alpha"
            #elseif SERVER_BETA
                environment = "beta"
            #elseif SERVER_TRAINING
                environment = "training"
            #elseif DEBUG
                switch Savant.control().cloudServerAddress {
                case .Production:
                    environment = "production"
                case .Dev1:
                    environment = "cdev1"
                case .Dev2:
                    environment = "cdev2"
                case .Alpha:
                    environment = "alpha"
                case .Beta:
                    environment = "beta"
                case .Training:
                    environment = "training"
                default:
                    environment = "unknown"
                }
            #else
                environment = "unknown"
            #endif

            #if SERVER_PRODUCTION
                if let version = version {
                    return version
                } else {
                    return "unknown"
                }
            #else
                if let version = version, branch = branch, buildNumber = buildNumber, hash = hash {
                    return "\(version)-\(branch)-\(environment)-\(buildNumber)-\(hash)"
                }
            #endif
        }

        return "unknown"
    }
    
    func application(application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: String) -> Bool {
        if extensionPointIdentifier == UIApplicationKeyboardExtensionPointIdentifier {
            return false
        }

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        SCUBackgroundHandler.sharedInstance().willDeactivate()
    }

    func applicationDidEnterBackground(application: UIApplication) {
        SCUBackgroundHandler.sharedInstance().suspend()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        SCUBackgroundHandler.sharedInstance().resume()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        SCUBackgroundHandler.sharedInstance().becomeActive()
    }

    func applicationWillTerminate(application: UIApplication) {
        
    }

}

