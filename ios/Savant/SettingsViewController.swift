//
//  SettingsViewController.swift
//  Savant
//
//  Created by Cameron Pulsford on 4/13/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit
import Coordinator

class SettingsViewController: UIViewController {

    let homeImageButton = UIButton.buttonWithType(.Custom) as! UIButton
    var homeNameField:ResizingTextField!
    let prompt = TitleAndPromptNavigationView(frame: CGRect(x: 0, y: 0, width: 260, height: Sizes.row * 4))
    let switchHomesButton = SCUButton(style: .StandardPill, title: Strings.switchHomes)
    let notificationsButton = SCUButton(title: Strings.notifications)
    let submitDiagnosticsButton = SCUButton(title: Strings.submitDiagnostics)
    let coordinator: CoordinatorReference<InterfaceState>

    init(coordinator c: CoordinatorReference<InterfaceState>) {
        coordinator = c
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.titleView = prompt
        navigationItem.leftBarButtonItem = dismissButtonForOrientation(UIDevice.interfaceOrientation())
        prompt.title.text = Strings.settings.uppercaseString
        configureRowButton(notificationsButton)
        let chevron = UIImageView(image: (UIImage(named: "ChevronForward")?.tintedImageWithColor(Colors.color1shade1)))
        notificationsButton.addSubview(chevron)
        notificationsButton.sav_pinView(chevron, withOptions: .CenterY)
        notificationsButton.sav_pinView(chevron, withOptions: .ToRight, withSpace:Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 3)
        configureRowButton(submitDiagnosticsButton)
        view.addSubview(homeImageButton)
        view.addSubview(notificationsButton)
        view.addSubview(submitDiagnosticsButton)
        
        view.sav_pinView(submitDiagnosticsButton, withOptions: .ToLeft | .ToBottom | .ToRight)
        view.sav_setHeight(Sizes.row * 8, forView: submitDiagnosticsButton, isRelative: false)
        view.sav_pinView(notificationsButton, withOptions: .ToLeft | .ToRight)
        view.sav_pinView(notificationsButton, withOptions: .ToTop, ofView:submitDiagnosticsButton, withSpace: 0)
        view.sav_setHeight(Sizes.row * 8, forView: notificationsButton, isRelative: false)
        view.sav_pinView(homeImageButton, withOptions: .ToTop | .ToLeft | .ToRight)
        view.sav_pinView(homeImageButton, withOptions: .ToTop, ofView:notificationsButton, withSpace: 0)
        
        let topGradient = SCUGradientView(frame: CGRectZero, andColors: [Colors.color5shade1.colorWithAlphaComponent(0.4), Colors.color5shade1.colorWithAlphaComponent(0.0)])
        let bottomGradient = SCUGradientView(frame: CGRectZero, andColors: [Colors.color5shade1.colorWithAlphaComponent(0.0), Colors.color5shade1.colorWithAlphaComponent(0.4)])
        
        view.addSubview(topGradient)
        view.sav_pinView(topGradient, withOptions: .ToLeft | .ToRight)
        view.sav_pinView(topGradient, withOptions: .ToTop, withSpace: 0)
        view.sav_setHeight(Sizes.row * 8, forView: topGradient, isRelative: false)
        
        view.addSubview(bottomGradient)
        view.sav_pinView(bottomGradient, withOptions: .ToLeft | .ToRight)
        view.sav_pinView(bottomGradient, withOptions: .ToBottom, ofView:homeImageButton, withSpace: -Sizes.row * 9)
        view.sav_setHeight(Sizes.row * 9, forView: bottomGradient, isRelative: false)

        view.addSubview(switchHomesButton)
        view.sav_pinView(switchHomesButton, withOptions: .CenterX)
        view.sav_pinView(switchHomesButton, withOptions: .ToTop, ofView:notificationsButton, withSpace:Sizes.row * 4)
        view.sav_setHeight(switchHomesButton.cornerRadius * 2, forView: switchHomesButton, isRelative: false)

        switchHomesButton.contentEdgeInsets = UIEdgeInsetsMake(0, Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 4, 0, Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 4)
        let chevronDown = UIImageView(image: UIImage(named: "chevron-down")?.tintedImageWithColor(Colors.color1shade2))
        chevronDown.contentMode = .ScaleAspectFit
        switchHomesButton.addSubview(chevronDown)
        switchHomesButton.sav_setWidth(Sizes.row * 2, forView: chevronDown, isRelative: false)
        switchHomesButton.sav_pinView(chevronDown, withOptions: .CenterY)
        switchHomesButton.sav_pinView(chevronDown, withOptions: .ToRight, withSpace:Sizes.row * 2)
        
        homeNameField = ResizingTextField(frame:CGRectZero, maxWidth:view.bounds.size.width)
        homeNameField.textField.textColor = Colors.color1shade1
        homeNameField.textField.font = Fonts.body
        homeNameField.backgroundColor = UIColor.clearColor()
        homeNameField.textFieldUpdate = { [unowned self] (newHomeName:String, finishedEditing:Bool) -> Void in
            if finishedEditing {
                self.updateHomeName(newHomeName)
            }
        }
        view.addSubview(homeNameField)
        view.sav_pinView(homeNameField, withOptions: .CenterX)
        view.sav_pinView(homeNameField, withOptions: .ToTop, withSpace: Sizes.row * 14)
        
        if let systemName = Savant.control().currentSystem?.name {
            homeNameField.text = systemName
        }
        
        loadHomeImage()
        
        switchHomesButton.releaseCallback = {
            RootCoordinator.transitionToState(.HomePicker)
        }
        
        notificationsButton.releaseCallback = { [unowned self] in
            self.coordinator.transitionToState(.NotificationSettings)
        }
        
        submitDiagnosticsButton.releaseCallback = { [unowned self] in
            self.triggerLogUpload()
        }
        
        homeImageButton.setImage(UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("whole-home", ofType: "jpg")!), forState: .Normal)
        homeImageButton.imageView?.contentMode = .ScaleAspectFill
        homeImageButton.clipsToBounds = true
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "homeImageLongPressed:")
        longPressRecognizer.minimumPressDuration = 1.5
        homeImageButton.addGestureRecognizer(longPressRecognizer)
        
    }
    
    func homeImageLongPressed(recognizer:UILongPressGestureRecognizer) {
        if (recognizer.state == .Began) {
            promptChangeHomeImage()
        }
    }
    
    func loadHomeImage() {
        let requestingIdentifier = NSUUID().description
        Savant.images().imageForKey("", type: .HomeImage, size: .Large, blurred: false, requestingIdentifier: requestingIdentifier, componentIdentifier: "userData", completionHandler: { [weak self] (image, success) -> Void in
            self?.homeImageButton.setImage(image, forState: .Normal)
        })
    }
    
    func updateHomeName(newHomeName:String) {
        if let system = Savant.control().currentSystem {
            system.name = newHomeName
            Savant.cloud().modifySystemName(system, completionHandler: { (success, _, error, _) -> Void in
                if !success {
                    let message = Strings.updateHomeNameError(system.name)
                    let alert = SCUAlertView(title: Strings.updateFailed, message: message, buttonTitles: [Strings.ok])
                    alert.show()
                    //TODO: what is the best way to log the error details?
                    println("Error updating system name: %@", error)
                }
            });
        }
    }

    func updateHomeImage(image:UIImage) {
        homeImageButton.setImage(image, forState: .Normal)
        let imageKey = Savant.images().saveImage(image, withKey: "", type:.HomeImage)
    }
    
    func promptChangeHomeImage() {
        
        if (UIImagePickerController.isSourceTypeAvailable(.Camera)) {
            let buttonTitles:[NSString] = [Strings.takePhoto, Strings.chooseExistingPhoto]
            let actionSheet = SCUActionSheet(buttonTitles: buttonTitles)
            actionSheet.delegate = self
            actionSheet.showInView(view)
        } else {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
    
    func triggerLogUpload() {
        let message = SAVLogUploadRequest()
        Savant.control().sendMessage(message)
    }
    
    func configureRowButton(button:SCUButton) {
        button.backgroundColor = Colors.color3shade1
        button.borderWidth = 2
        button.borderColor = Colors.color5shade1
        button.contentHorizontalAlignment = .Left
        button.contentEdgeInsets = UIEdgeInsetsMake(0, Sizes.columnForOrientation(UIDevice.interfaceOrientation()) * 8, 0, 0)
    }
    
    private func dismissButtonForOrientation(orientation: UIInterfaceOrientation) -> UIBarButtonItem {
        if UIDevice.isPhone() || UIInterfaceOrientationIsPortrait(orientation) {
            return UIBarButtonItem(image: UIImage(named: "chevron-down"), style: .Plain, target: self, action: "goBack")
        } else {
            return UIBarButtonItem(image: UIImage(named: "chevron-down"), style: .Plain, target: self, action: "goBack")
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    func goBack() {
        coordinator.transitionBack()
    }
    
}

extension SettingsViewController : SCUActionSheetDelegate {
    func actionSheet(actionSheet:SCUActionSheet, clickedButtonAtIndex buttonIndex:NSInteger) {
        var sourceType:UIImagePickerControllerSourceType? = nil
        
        if buttonIndex == 0 {
            sourceType = UIImagePickerControllerSourceType.Camera
        } else if buttonIndex == 1 {
            sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        }
        if let sourceType = sourceType {
            let picker = UIImagePickerController()
            picker.sourceType = sourceType
            picker.delegate = self
            presentViewController(picker, animated: true, completion: nil)
        }
    }
}

extension SettingsViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        dismissViewControllerAnimated(true, completion: nil)
        let newHomeImage:UIImage? = info[UIImagePickerControllerEditedImage] as? UIImage ?? info[UIImagePickerControllerOriginalImage] as? UIImage
        if let newHomeImage = newHomeImage {
            let fixedHomeImage = fixOrientation(newHomeImage)
            self.updateHomeImage(fixedHomeImage)
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func fixOrientation(img:UIImage) -> UIImage {
        
        if (img.imageOrientation == UIImageOrientation.Up) {
            return img;
        }
        
        UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale);
        let rect = CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
        img.drawInRect(rect)
        
        var normalizedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return normalizedImage;
        
    }
}
