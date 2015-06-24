
//
//  WifiProvisioner.swift
//  SavantWifiProvisioner
//
//  Created by Joseph Ross on 01/03/2015.
//  Copyright (c) 2014 Savant Systems LLC. All rights reserved.
//

import CoreBluetooth

@objc public enum DeviceType : Int32 {
    case Unknown       = 0
    case Host          = 1
    case Lighting      = 2
    case LampModule    = 3
    case Camera        = 4
    case Controller    = 5
}

/**
ProvisionableDevice represents a Savant device in need of Wifi credentials
*/
public class ProvisionableDevice : NSObject, CBPeripheralDelegate {
    
    public var scanLives:Int = 0
    
    var peripheral:CBPeripheral? = nil
    var provisioner:WifiProvisioner? = nil
    public var name:String?
    private(set) public var uid:String?
    
    private(set) public var savantDeviceType:DeviceType?
    
    private(set) public var deviceClass:Int?
    private(set) public var deviceSubclass:Int? 
    
    public var intDeviceClass:Int {
        if let dc = deviceClass {
            return dc
        } else {
            return -1
        }
    }
    
    public var intDeviceSubclass:Int {
        if let dsc = deviceSubclass {
            return dsc
        } else {
            return -1
        }
    }
    
    var state:State
    var intState:Int {
        if let sc = stateCharacteristic {
            updateRemoteStateFromCharacteristic(sc)
            updateCurrentState()
        }
        
        return state.rawValue
    }
    
    var remoteState:RemoteState = RemoteState.Unknown
    var intRemoteState:Int {
        switch remoteState {
        case .Unknown:       return -1
        case .Idle:          return 0
        case .Provisioning:  return 1
        case .Provisioned:   return 2
        case .Declined:      return 3
        }
    }
    
    var pendingCredentials:WifiCredentials? = nil
    
    var service:CBService? = nil
    var stateCharacteristic:CBCharacteristic? 
    var controlPointCharacteristic:CBCharacteristic?
    var ssidCharacteristic:CBCharacteristic?
    var presharedKeyCharacteristic:CBCharacteristic?
    var authTypeCharacteristic:CBCharacteristic?
    var provisioningResultCharacteristic:CBCharacteristic?
    var characteristicsToWrite:[CBCharacteristic]?
    var consecutiveWriteErrors:Int = 0
    var consecutiveProvisioningErrors: Int = 0;

    var previousProvisioningResult:Int = 0
    var previousState:State = State.Querying
    
    weak var provisioningTimeOutTimer: NSTimer?
    
    let remoteStatePollTime = 0.5
    
    public init(peripheral:CBPeripheral!, name aName:String?, provisioner:WifiProvisioner, uid aUid:String?, deviceClass aDeviceClass:Int?, deviceSubclass aDeviceSubclass:Int?, savantDeviceType aSavantDeviceType:DeviceType?) {
        state = State.Querying
        super.init()
        
        savantDeviceType = aSavantDeviceType
        uid = aUid
        deviceClass = aDeviceClass
        deviceSubclass = aDeviceSubclass
        name = aName
        
        self.peripheral = peripheral
        self.peripheral?.delegate = self
        self.provisioner = provisioner
    }
    
    public func deviceType() -> DeviceType {
        return savantDeviceType!;
    }
    
    func peripheralConnected(peripheral aPeripheral:CBPeripheral) {
        dlog("peripheral connected: \(peripheral)")
        
        fetchRemoteState()
        
        peripheral = aPeripheral
        peripheral?.delegate = self
        peripheral?.discoverServices(kTargetServiceUuids)
        provisioner?.delegate?.provisioner(provisioner!, connectedTo: self);
    }
    
    func peripheralDisconnected(peripheral:CBPeripheral) {
        if (state == State.Triggering) {
            let error = NSError(domain: SAVWifiProvisionerErrorDomain, code: 5, userInfo: ["description":"ProvisionableDevice disconnected during provisioning."])

            if state == State.Triggering || state == State.Writing {
                provisioner?.delegate?.provisioner(provisioner!, failedToProvisionDevice: self, error: error)
            }
            provisioner?.delegate?.provisioner(provisioner!, disconnectedFrom: self)
        }
        
        enterErroredState()
    }
    
    public func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        dlog("discovered services: \(peripheral.services)")
        if (peripheral.services != nil) {
            for service in peripheral.services as! [CBService] {
                if service.UUID.isEqual(kWifiProvisiongServiceUuid) {
                    self.service = service
                    peripheral.discoverCharacteristics(kTargetCharacteristicUuids, forService: service)
                    break
                }
            }
        }
    }
    
    public func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        dlog("discovered characteristics: \(service.characteristics)")
        for characteristic in service.characteristics as! [CBCharacteristic] {
            if characteristic.UUID.isEqual(kProvisioningStateCharacteristicUuid) {
                stateCharacteristic = characteristic
            } else if characteristic.UUID.isEqual(kControlPointCharacteristicUuid) {
                controlPointCharacteristic = characteristic
            } else if characteristic.UUID.isEqual(kWifiSSIDCharacteristicUuid) {
                ssidCharacteristic = characteristic
            } else if characteristic.UUID.isEqual(kWifiPresharedKeyCharacteristicUuid) {
                presharedKeyCharacteristic = characteristic
            } else if characteristic.UUID.isEqual(kWifiAuthTypeCharacteristicUuid) {
                authTypeCharacteristic = characteristic
            } else if characteristic.UUID.isEqual(kProvisioningResultCharacteristicUuid) {
                provisioningResultCharacteristic = characteristic
                peripheral.setNotifyValue(true, forCharacteristic: provisioningResultCharacteristic)
            }
        }
        updateCurrentState()
    }
    
    public func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        dlog("value for characteristic \(characteristic) updated to \(characteristic.value)")
        
        if characteristic != nil && characteristic.UUID.isEqual(kProvisioningStateCharacteristicUuid) {
            previousState = state;
            updateRemoteStateFromCharacteristic(characteristic)
        }
        if characteristic != nil && characteristic.UUID.isEqual(kProvisioningResultCharacteristicUuid) {
            
            let data = characteristic.value
            var value:Int8 = 0
            
            if let d = data {
                data.getBytes(&value, length:1)
            }
            
            updateCurrentState()
            
            if ((state == State.Triggering) && (Int32(previousProvisioningResult) == ProvisioningResult.NotAvailable.rawValue)) {
                if (Int32(value) == ProvisioningResult.NotAvailable.rawValue){
                    
                } else if (Int32(value) == ProvisioningResult.Success.rawValue){
                    enterProvisionedState()
                } else {
                    provisioner?.delegate?.provisioner(provisioner!, failedToProvisionDevice: self, error: NSError(domain: "Provisioner", code: Int(value), userInfo: nil))
                    enterErroredState()
                }
            }
            
            previousProvisioningResult = Int(value)
        }
    }
    
    public func peripheral(peripheral: CBPeripheral!, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic!, error: NSError!){
        fetchRemoteState()
        if (error != nil) {
            dlog("SUBSCRIPTION ERROR!!!___!!!___!!! for characteristic: \(characteristic), error: \(error)")
        }
        else {
            dlog("subscription success for characteristic: \(characteristic), error: \(error)")
        }
        //TODO: handle subscription error
    }
    
    public func peripheral(peripheral: CBPeripheral!, didWriteValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        dlog("wrote value for characteristic: \(characteristic), error: \(error)")
        if (error == nil && characteristic != nil && characteristicsToWrite != nil) {
            consecutiveWriteErrors = 0
            
            let index = find(characteristicsToWrite!,characteristic!)
            if (index != nil) {
                characteristicsToWrite!.removeAtIndex(index!)
                if (characteristicsToWrite!.count == 0) {
                    enterTriggeringState()
                } else {
                    dlog("Waiting for write confirmation for characteristics: \(characteristicsToWrite)")
                }
            }
        } else {
            consecutiveWriteErrors++
            if (consecutiveWriteErrors > 30) {
                provisioner?.delegate?.provisioner(provisioner!, failedToProvisionDevice: self, error: NSError(domain: "Provisioner", code: 5, userInfo: nil))
                enterErroredState()
                updateCurrentState()
            }
            else if (characteristicsToWrite?.contains(characteristic) ?? false){
                dlog("CONECUTIVE WRITE ERROR___   ___\(consecutiveWriteErrors)")
                doWrites([characteristic])
            }
        }
    }
    
    func updateRemoteStateFromCharacteristic(characteristic:CBCharacteristic) {
        dlog("update remote state")
        let data = characteristic.value
        var value:Int32 = 0
        
        if let d = data {
            d.getBytes(&value, length:4)
            var newState:RemoteState = RemoteState(rawValue: value) ?? RemoteState.Unknown
            self.remoteState = newState
        }
        
        updateCurrentState()
    }
    
    func fetchRemoteState() {
        dlog("fetch remote state")
        if let peripheral = peripheral {
            if let stateCharacteristic = stateCharacteristic {
                if peripheral.state == .Connected {
                    peripheral.readValueForCharacteristic(stateCharacteristic)
                }
            }
        }
    }
    
    func cancelTimeout() {
        if let oldTimer = provisioningTimeOutTimer {
            oldTimer.invalidate()
            provisioningTimeOutTimer = nil
        }
    }
    
    func updateCurrentState() {
        if stateCharacteristic == nil
            || controlPointCharacteristic == nil
            || ssidCharacteristic == nil
            || presharedKeyCharacteristic == nil
            || authTypeCharacteristic == nil
            || remoteState == RemoteState.Unknown {
                enterQueryingState()
        } else if (remoteState == RemoteState.Provisioned) {
            enterProvisionedState()
        } else if (remoteState == RemoteState.Declined && state == State.Triggering) {
            notifyDeclined()
            enterReadyState()
        } else if remoteState == RemoteState.Idle || remoteState == RemoteState.Declined {
            enterReadyState()
        }
        dlog("entered \(state.description) state self: \(self)")
    }
    
    func notifyDeclined() {
        if (pendingCredentials != nil) {
            provisioner?.delegate?.provisioner(provisioner!, declinedCredentials:pendingCredentials!, forDevice:self)
        }
    }
    
    func enterQueryingState() {
        if state != State.Querying {
            dlog("entered querying state")
            state = State.Querying
            if (service == nil) {
                peripheral?.discoverServices(kTargetServiceUuids)
            } else {
                peripheral?.discoverCharacteristics(kTargetCharacteristicUuids, forService: service)
                if stateCharacteristic != nil && remoteState == RemoteState.Unknown {
                    fetchRemoteState()
                }
            }
        }
    }
    
    func enterReadyState() {
        if state == State.Querying || state == State.Errored {
            dlog("entered ready state")
            consecutiveWriteErrors = 0
            
            let previousState = state
            state = State.Ready
            
            provisioner?.delegate?.provisioner(provisioner, foundDevice: self)
        }
    }
    
    func enterWritingState() {
        if (state != State.Ready) {
            dlog("Warning!  Entering Writing state from non-Ready state \(state),\(state.rawValue)")
        }
        dlog("entered Writing state")
        state = State.Writing
        
        if (pendingCredentials?.presharedKey == "")
        {
            characteristicsToWrite = [ssidCharacteristic!, authTypeCharacteristic!]
        }
        else
        {
            characteristicsToWrite = [ssidCharacteristic!, presharedKeyCharacteristic!, authTypeCharacteristic!]
        }
        
        doWrites(characteristicsToWrite!)
    }
    
    func enterTriggeringState() {
        if (state != State.Writing) {
            dlog("Warning!  Entering Triggering state from non-Writing state \(state),\(state.rawValue)")
        }
        dlog("entered triggering state")
        state = State.Triggering
        
        var command:Int32 = ControlPointCommand.StartProvisioning.rawValue
        let intData = NSData(bytes:&command, length:1)
        peripheral?.writeValue(intData, forCharacteristic:controlPointCharacteristic, type:CBCharacteristicWriteType.WithResponse)
        
        if let oldTimer = provisioningTimeOutTimer {
            oldTimer.invalidate()
            provisioningTimeOutTimer = nil
        }
    }
    
    func enterProvisionedState() {
        if state != State.Provisioned {
            dlog("entered provisioned state")
            let previousState = state
            if (previousState != State.Triggering && previousState != State.Querying) {
                dlog("Warning!  Entering Provisioned state from state not in (Querying, Triggering) \(state),\(state.rawValue)")
            }
            state = State.Provisioned
            if (previousState == State.Triggering) {
                provisioner?.delegate?.provisioner(provisioner!, provisionedDevice: self)
            }
        }
        cancelTimeout()
    }
    
    func provisioningTimedOut() {
        if let oldTimer = provisioningTimeOutTimer {
            oldTimer.invalidate()
            provisioningTimeOutTimer = nil
        }
        
        provisioner?.central?.cancelPeripheralConnection(peripheral)
        provisioner?.delegate?.provisioner(provisioner!, failedToProvisionDevice: self, error: NSError(domain: "Provisioner", code: 0, userInfo: nil))
        enterErroredState()
    }
    
    func enterErroredState() {
        state = State.Errored
        stateCharacteristic = nil
        presharedKeyCharacteristic = nil
        controlPointCharacteristic = nil
        ssidCharacteristic = nil
        service = nil
        remoteState = RemoteState.Unknown
        characteristicsToWrite = nil
        provisioner?.central?.cancelPeripheralConnection(peripheral)
        cancelTimeout()
        
        provisioner?.delegate?.provisioner(provisioner, disconnectedFrom: self)
    }
    

    
    func provisionWithCredentials(credentials:WifiCredentials) {
        pendingCredentials = credentials
        
        provisioningTimeOutTimer?.invalidate()
        provisioningTimeOutTimer = nil
        
        provisioningTimeOutTimer = NSTimer.scheduledTimerWithTimeInterval(20.0, target: self, selector: Selector("provisioningTimedOut"), userInfo: nil, repeats: false)
        provisionWithCredentialsHelper(credentials)
    }
    
    private func provisionWithCredentialsHelper(credentials:WifiCredentials) {
        if state != State.Ready
        {
            println("Consecutive provisioning errors \(consecutiveProvisioningErrors)")
            
            if (consecutiveProvisioningErrors < 12)
            {
                dispatch_after( dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC))),
                    dispatch_get_main_queue(),
                {
                    if ((self.state != State.Errored) && (self.state != State.Provisioned)){
                        //self.peripheral?.discoverServices(kTargetServiceUuids)
                        self.consecutiveProvisioningErrors++
                        if let pc = self.pendingCredentials {
                            self.provisionWithCredentials(pc);
                        }
                    }
                })
            }
            else
            {
                provisioningTimedOut()
            }
        } else {
            enterWritingState()
        }
    }
    
    func doWrites(characteristics:[CBCharacteristic]) {
        let shouldWriteSSID = pendingCredentials?.SSID != nil
            && ssidCharacteristic != nil
            && characteristics.contains(ssidCharacteristic!)
        if shouldWriteSSID {
            let stringData = pendingCredentials?.SSID?.dataUsingEncoding(NSASCIIStringEncoding)
            peripheral?.writeValue(stringData, forCharacteristic:ssidCharacteristic, type:CBCharacteristicWriteType.WithResponse)
        }
        let shouldWritePresharedKey = pendingCredentials?.presharedKey != nil
            && presharedKeyCharacteristic != nil
            && characteristics.contains(presharedKeyCharacteristic!)
        if shouldWritePresharedKey {
            let stringData = pendingCredentials?.presharedKey?.dataUsingEncoding(NSASCIIStringEncoding)
            peripheral?.writeValue(stringData, forCharacteristic:presharedKeyCharacteristic, type:CBCharacteristicWriteType.WithResponse)
        }
        let shouldWriteAuthType = pendingCredentials?.authType != nil
            && authTypeCharacteristic != nil
            && characteristics.contains(authTypeCharacteristic!)
        if shouldWriteAuthType {
            var authTypeByte:UInt8 = (pendingCredentials?.authType)!.rawValue
            peripheral?.writeValue(NSData(bytes: [authTypeByte] as [UInt8], length:1), forCharacteristic:authTypeCharacteristic, type:CBCharacteristicWriteType.WithResponse)
        }
    }
    
    enum State : Int {
        case Querying       = 0
        case Ready          = 1
        case Writing        = 2
        case Triggering     = 3
        case Provisioned    = 4
        case Errored        = 5
        
        var description: String {
            get {
                switch self {
                case .Querying:
                    return "Querying"
                case .Ready:
                    return "Ready"
                case .Writing:
                    return "Writing"
                case .Triggering:
                    return "Triggering"
                case .Provisioned:
                    return "Provisioned"
                default:
                    return "Errored"
                }
            }
        }
    }
}

enum RemoteState : Int32 {
    case Unknown        = -1
    case Idle           = 0
    case Provisioning   = 1
    case Provisioned    = 2
    case Declined       = 3
    
    var description: String {
        get {
            switch self {
            case .Idle:
                return "Idle"
            case .Provisioning:
                return "Provisioning"
            case .Provisioning:
                return "Provisioned"
            case .Declined:
                return "Declined"
            default:
                return "Unknown"
            }
        }
    }
}

enum ProvisioningResult : Int32 {
    case NotAvailable     = 0
    case Success          = 1
    case InvalidConfig    = 2
    case OutOfRange       = 3
    case InvalidKey       = 4
    case Error            = 5
    
    var description: String {
        get {
            switch self {
            case .NotAvailable:
                return "Not Available"
            case .Success:
                return "Success"
            case .InvalidConfig:
                return "Invalid Config"
            case .OutOfRange:
                return "Out Of Range"
            case .InvalidKey:
                return "Invalid Key"
            default:
                return "Error"
            }
        }
    }
}

enum ControlPointCommand : Int32 {
    case Initial = 0
    case StartProvisioning = 1
    case dDeclineProvisioning = 2
}

extension Array {
    func contains<T where T : Equatable>(obj: T) -> Bool {
        return self.filter({$0 as? T == obj}).count > 0
    }
}

let SAVWifiProvisionerErrorDomain = "SAVWifiProvisionerErrorDomain"
