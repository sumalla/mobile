//
//  HomeMonitorServiceViewController.swift
//  Savant
//
//  Created by Joseph Ross on 3/23/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

extension UINavigationController {
    public override func supportedInterfaceOrientations() -> Int {
        if let topController = self.topViewController {
            return topController.supportedInterfaceOrientations()
        } else {
            return UIInterfaceOrientation.Portrait.rawValue
        }
    }
    
    public override func shouldAutorotate() -> Bool {
        if let topController = self.topViewController {
            return topController.shouldAutorotate()
        } else {
            return false
        }
    }
}

enum MonitorsProtectState {
    case AllProtect
    case SomeProtect
    case AllSense
}

class HomeMonitorServiceViewController: SCUServiceViewController, HomeMonitorObserver {

    var monitorModel:HomeMonitorModel! = nil
    var monitorCollection:HomeMonitorCollectionViewController! = nil
    let prompt = TitleAndPromptNavigationView(frame: CGRect(x: 0, y: 0, width: 200, height: Sizes.row * 4))
    var toggleSenseProtectBarButton:UIBarButtonItem! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = ""
        navigationItem.titleView = prompt
        var zoneName = model.service?.zoneName?.uppercaseString
        if zoneName == nil {
            zoneName = NSLocalizedString("HOME", comment: "")
        }
        toggleSenseProtectBarButton = UIBarButtonItem(image: UIImage(named: "protect"), style: UIBarButtonItemStyle.Plain, target: self, action: Selector("toggleSenseProtectBarButtonPressed"))
        let space = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil)
        space.width = 17
        navigationItem.rightBarButtonItems = [space, toggleSenseProtectBarButton]
        prompt.title.text = NSLocalizedString("HOME MONITOR", comment: "")
        navigationController?.navigationBar.setTitleVerticalPositionAdjustment(0, forBarMetrics:UIBarMetrics.Default)
        prompt.prompt.text = zoneName
        contentView.backgroundColor = Colors.color3shade1
        monitorModel = HomeMonitorModel(service: model.service)
        monitorModel.objects?.map() { (monitor) -> Void in
            monitor.observer = self
        }
        monitorCollection = HomeMonitorCollectionViewController(model:monitorModel)
        addChildViewController(monitorCollection)
        contentView.addSubview(monitorCollection.view)
        contentView.sav_pinView(monitorCollection.view, withOptions: .ToLeft | .ToRight | .ToBottom)
        contentView.sav_pinView(monitorCollection.view, withOptions: .ToTop)
        
    }
    
    func monitorsProtectState() -> MonitorsProtectState {
        var allProtect = true
        var someProtect = false
        if let monitors = monitorModel.objects {
            for monitor in monitors {
                if (monitor.mode == .Sense) {
                    allProtect = false
                } else {
                    someProtect = true
                }
            }
        }
        if allProtect { return .AllProtect }
        if someProtect { return .SomeProtect }
        return .AllSense
    }
    
    func updateToggleButton() {
        let state = monitorsProtectState()
        
        switch state {
        case .AllProtect:
            toggleSenseProtectBarButton.image = UIImage(named: "protect")
            toggleSenseProtectBarButton.tintColor = Colors.color1shade1
        case .SomeProtect:
            toggleSenseProtectBarButton.image = UIImage(named: "protect")
            toggleSenseProtectBarButton.tintColor = Colors.color1shade3
        case .AllSense:
            toggleSenseProtectBarButton.image = UIImage(named: "sense")
            toggleSenseProtectBarButton.tintColor = Colors.color1shade1
        }
    }
    
    func homeMonitorDidChangeMode(homeMonitor: HomeMonitor) {
        updateToggleButton()
    }
    
    func toggleSenseProtectBarButtonPressed() {
        let state = monitorsProtectState()
        if state == .AllProtect {
            if let monitors = monitorModel.objects {
                for monitor in monitors {
                    monitor.updateMonitorMode(.Sense)
                }
            }
        } else {
            if let monitors = monitorModel.objects {
                for monitor in monitors {
                    monitor.updateMonitorMode(.Protect)
                }
            }
        }
        updateToggleButton()
        monitorCollection.reloadSections(NSIndexSet(index: 0), animation: .Fade)
    }
    
    func startSnapshotRefreshTimer() {
        monitorModel.objects?.map() {(monitor) -> Void in
            monitor.startFetchingSnapshots()
        }
    }
    
    func stopSnapshotRefreshTimer() {
        monitorModel.objects?.map() {(monitor) -> Void in
            monitor.stopFetchingSnapshots()
        }
    }
    
    func homeMonitorDidUpdateSnapshot(homeMonitor: HomeMonitor, snapshot: UIImage) {
        if let monitors = monitorModel.objects {
            var rowIndex = 0;
            for monitor in monitors {
                if monitor == homeMonitor {
                    let indexPath = NSIndexPath(forRow: rowIndex, inSection: 0)
                    let modelItem = monitorModel.itemForIndexPath(indexPath)
                    modelItem?.image = snapshot
                    self.monitorCollection.reloadIndexPaths([indexPath], animation: .None)
                }
                rowIndex++
            }
            
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        monitorCollection.reloadData()
        startSnapshotRefreshTimer()
        updateToggleButton()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        stopSnapshotRefreshTimer()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }

}
