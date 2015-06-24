//
//  LocalizedStrings.swift
//  Savant
//
//  Created by Cameron Pulsford on 5/12/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

let Strings = LocalizedStrings()

class LocalizedStrings: NSObject {
    
    private override init() {}
    
    let ok = NSLocalizedString("OK_KEY", value: "OK", comment: "Accept the default action")
    
    let yes = NSLocalizedString("YES_KEY", value: "Yes", comment: "Yes")

    let no = NSLocalizedString("NO_KEY", value: "No", comment: "No")
    
    let next = NSLocalizedString("NEXT_KEY", value: "Next", comment: "Next")
    
    let continu = NSLocalizedString("CONTINUE_KEY", value: "Continue", comment: "Continue with the default action")
    
    let cancel = NSLocalizedString("CANCEL_KEY", value: "Cancel", comment: "Cancel the current in progress action")
	
	let done = NSLocalizedString("DONE_KEY", value: "Done", comment: "Finish current in progress action")
	
    let reset = NSLocalizedString("RESET_KEY", value: "Reset", comment: "Reset according to the given instructions")
    
    let add = NSLocalizedString("ADD_KEY", value: "Add", comment: "Add something to a list")
    
    let signIn = NSLocalizedString("SIGN_IN_KEY", value: "Sign In", comment: "Sign in to an account")
    
    let createAccount = NSLocalizedString("CREATE_ACCOUNT_KEY", value: "Create Account", comment: "Create a new savant cloud account")
    
    let learnMoreAboutSavant = NSLocalizedString("LEARN_MORE_ABOUT_SAVANT_KEY", value: "Learn More", comment: "Learn more about what savant has to offer")
    
    let iForgotMyPassword = NSLocalizedString("I_FORGOT_MY_PASSWORD_KEY", value: "I forgot my password.", comment: "This is the user saying that they forgot their password")
    
    let forgotYourPasswordQuestionMark = NSLocalizedString("DID_YOU_FORGET_YOUR_PASSWORD_KEY", value: "Forgot Password?", comment: "This is the app asking if a user forgot their password")
    
    let forgotYourPasswordInstructions = NSLocalizedString("CHANGE_YOUR_PASSWORD_INSTRUCTIONS_KEY", value: "Changing your password is easy. Tap reset and you will receive an email with further instructions.", comment: "")
    
    let invalidPassword = NSLocalizedString("INVALID_PASSWORD_KEY", value: "Invalid password", comment: "An invalid password was entered when logging in to an account")
    
    let emailAddressNotFound = NSLocalizedString("EMAIL_NOT_FOUND_KEY", value: "Email address not found", comment: "An email that has no account associated with it was entered while logging in. They most likely mispelled their email.")
    
    let enterValidEmailAddress = NSLocalizedString("ENTER_VALID_EMAIL_KEY", value: "Enter a valid email address", comment: "An incorrectly formatted email address was entered")
    
    let email = NSLocalizedString("EMAIL_KEY", value: "Email", comment: "The generic word for email")
    
    let password = NSLocalizedString("PASSWORD_KEY", value: "Password", comment: "The generic word for password")
    
    let connectionError = NSLocalizedString("ERROR_TITLE_CONNECTION_ERROR_KEY", value: "Connection Error", comment: "An error title, specifically a connection error")
    
    let couldNotCommunicateWithSavant = NSLocalizedString("ERROR_BODY_COULD_NOT_COMMUNICATE_WITH_SAVANT_KEY", value: "Could not communicate with Savant.", comment: "An error body, an HTTP request to savant failed")
    
    func hostsFound(numberOfHosts: Int) -> String {
        if numberOfHosts == 1 {
            return NSLocalizedString("ONE_HOST_FOUND_KEY", value: "1 Host Found", comment: "1 host was found")
        } else {
            return String(format: NSLocalizedString("MANY_HOSTS_FOUND_KEY", value: "%d Hosts Found", comment: "1 host was found"), numberOfHosts)
        }
    }
    
    func homesFound(numberOfHosts: Int) -> String {
        switch numberOfHosts {
        case 0:
            return NSLocalizedString("NO_HOMES_FOUND_KEY", value: "No Homes Found", comment: "1 host was found")
        case 1:
            return NSLocalizedString("ONE_HOME_FOUND_KEY", value: "1 Home Found", comment: "1 host was found")
        default:
            return String(format: NSLocalizedString("MANY_HOMES_FOUND_KEY", value: "%d Homes Found", comment: "1 host was found"), numberOfHosts)
        }
    }
    
    let noHomesError = NSLocalizedString("ERROR_BODY_NO_HOMES_INSTRUCTIONS", value: "No Savant homes could be found. Make sure Wi-Fi and Bluetooth is enabled on your phone.", comment: "")
    
    func devicesFound(numberOfDevices: Int) -> String {
        if numberOfDevices == 1 {
            return NSLocalizedString("ONE_DEVICE_FOUND_KEY", value: "1 Device Found", comment: "1 device was found")
        } else {
            return String(format: NSLocalizedString("MANY_DEVICES_FOUND_KEY", value: "%d Devices Found", comment: "Many devices were found"), numberOfDevices)
        }
    }
	
	func devicesAdded(numberOfDevices: Int) -> String {
		if numberOfDevices == 1 {
			return NSLocalizedString("ONE_DEVICE_ADDED_KEY", value: "1 Device Added", comment: "1 device was added")
		} else {
			return String(format: NSLocalizedString("MANY_DEVICES_ADDED_KEY", value: "%d Devices Added", comment: "Many devices were added"), numberOfDevices)
		}
	}
	
    func additionalDevicesFound(numberOfDevices: Int) -> String {
        if numberOfDevices == 1 {
            return NSLocalizedString("ONE_ADDITIONAL_DEVICE_FOUND_KEY", value: "1 Additional Device Found", comment: "1 additional device was found")
        } else {
            return String(format: NSLocalizedString("MANY_ADDITIONAL_DEVICES_FOUND_KEY", value: "%d Additional Devices Found", comment: "Many additional devices were found"), numberOfDevices)
        }
    }
	
	let connectYourDevicesTitle = NSLocalizedString("CONNECT_YOUR_DEVICES_TITLE_KEY", value: "Connect Your Devices", comment: "Title for the tutorial screen: Connect Your Devices")
	
	let connectYourDevicesBody = NSLocalizedString("CONNECT_YOUR_DEVICES_BODY_KEY", value: "During setup, the App only recognizes devices within 30 feet, so visit each room with a Savant device and connect them as you go.", comment: "Body for the tutorial screen: Connect Your Devices")
    
    let searchingForDevices = NSLocalizedString("SEARCHING_FOR_DEVICES_KEY", value: "Searching For Savant Devices", comment: "Label for device onboarding label")
    
    let searchingForMoreDevices = NSLocalizedString("SEARCHING_FOR_MORE_DEVICES_KEY", value: "Searching For More Savant Devices", comment: "Label for device onboarding label")
    
    let searchingForDevicesSubtitle = NSLocalizedString("SEARCHING_FOR_DEVICES_SUBTITLE_KEY", value: "Make sure all of your devices are plugged in!", comment: "Subtitle label for device onboarding label")
    
    let searchingForMoreDevicesSubtitle = NSLocalizedString("SEARCHING_FOR_MORE_DEVICES_SUBTITLE_KEY", value: "Make sure you are within 30 feet of your devices so your phone can detect them!", comment: "Subtitle label for device onboarding label")
    
    let devicesFoundSubtitle = NSLocalizedString("DEVICES_FOUND_SUBTITLE_KEY", value: "Is that all of your Savant ready devices?", comment: "Subtitle label for devices found onboarding label")
	
    let additionalDevicesFoundSubtitle = NSLocalizedString("ADDITIONAL_DEVICES_FOUND_SUBTITLE_KEY", value: "Let's add it to your system.", comment: "Subtitle label for devices found onboarding label")

	let scan = NSLocalizedString("SCAN_KEY", value: "Scan", comment: "")
	
    let dimmer = NSLocalizedString("DIMMER_KEY", value: "Dimmer", comment: "Light - dimmer type")
    
    let switchString = NSLocalizedString("SWITCH_KEY", value: "Switch", comment: "Light - switch type")
	
	let addRoom = NSLocalizedString("ADD_ROOM_KEY", value: "Add Room", comment: "")
    
    let blinkingString = NSLocalizedString("LED_BLINKING_KEY", value: "LED is blinking green", comment: "")
    
    func updateHomeNameError(homeName:String) -> String {
        return String(format:NSLocalizedString("ERROR_FAILED_TO_UPDATE_HOME_NAME_FORMAT_KEY", value:"Failed to update home name to %@", comment:"Error message when home rename fails"), homeName)
    }
    
    let updateFailed = NSLocalizedString("UPDATE_FAILED_TITLE_KEY", value: "Update Failed", comment:"Alert title when an update operation fails")
    
    let takePhoto = NSLocalizedString("TAKE_PHOTO_KEY", value:"Take Photo", comment:"Action sheet option to use camera to take a photo")
    
    let chooseExistingPhoto = NSLocalizedString("CHOOSE_EXISTING_PHOTO_KEY", value:"Choose Existing Photo", comment: "Action sheet option to choose an existing photo from the library")
    
    let settings = NSLocalizedString("SETTINGS_KEY", value: "Settings", comment: "Settings title")
    
    let notifications = NSLocalizedString("NOTIFICATIONS_KEY", value: "Notifications", comment: "Notifications title")
    
    let submitDiagnostics = NSLocalizedString("SUBMIT_DIAGNOSTICS_KEY", value: "Submit Diagnostics", comment: "Submit Diagnostics button title")
    
    let switchHomes = NSLocalizedString("SWITCH_HOMES_KEY", value: "Switch Homes", comment: "Switch Homes button title")
    
    let masterVolume = NSLocalizedString("MASTER_VOLUME_KEY", value: "Master Volume", comment: "")
}
