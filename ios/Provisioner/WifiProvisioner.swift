//
//  WifiProvisioner.swift
//  SavantWifiProvisioner
//
//  Created by Joseph Ross on 01/03/2015.
//  Copyright (c) 2014 Savant Systems LLC. All rights reserved.
//

import CoreBluetooth

/**
The WifiProvisionerDelegate protocol defines the methods that a delegate of a WifiProvisioner object must adopt. The methods of the protocol allow the delegate to monitor the discovery and provisioning events of nearby Savant devices.
*/
@objc public protocol WifiProvisionerDelegate : NSObjectProtocol {
    /**
    The delegate is notified when the WifiProvisioner instance detects a new Savant Device in need of provisioning.  After this delegate method is called, the newly-detected device will become available in the WifiProvisioner's devices collection
    
    :param: provisioner The WifiProvisioner instance that detected the Savant device
    :param: device The detected Savant device
    */
    func provisioner(provisioner:WifiProvisioner!, foundDevice device:ProvisionableDevice!)
    
    /**
    The delegate is notified when the WifiProvisioner instance loses a Savant Device.
    
    :param: provisioner The WifiProvisioner instance that detected the Savant device
    :param: device The detected Savant device
    */
    func provisioner(provisioner:WifiProvisioner!, disconnectedFrom device:ProvisionableDevice!)
    
    /**
    The delegate is notified when the WifiProvisioner connect to a Savant Device.
    
    :param: provisioner The WifiProvisioner instance that connected to the Savant device
    :param: device The connected Savant device
    */
    func provisioner(provisioner:WifiProvisioner!, connectedTo device:ProvisionableDevice!)
    
    /**
    The delegate is notified when the WifiProvisioner fails to connect to a Savant Device.
    
    :param: provisioner The WifiProvisioner instance that failed to connect to the Savant device
    :param: device The Savant device
    */
    func provisioner(provisioner:WifiProvisioner!, failedToConnectTo device:ProvisionableDevice!)
    
    /**
    The delegate is notified when the WifiProvisioner instance successfully configures a Savant Device with Wifi credentials
    
    :param: provisioner The WifiProvisioner instance that performed the provisioning work
    :param: device The provisioned Savant device
    */
    func provisioner(provisioner:WifiProvisioner!, provisionedDevice device:ProvisionableDevice!)
    
    /**
    The delegate is notified if the WifiProvisioner instance fails to provision Wifi credentials for a device because something went wrong during provisioning (e.g. the provisionable device disconnected during the provisioning process.
    
    :param: provisioner The WifiProvisioner instance that attempted to provision the device
    :param: device The Savant device which failed to provision correctly
    :param: error An error object indicating why provisioning failed.
    */
    func provisioner(provisioner:WifiProvisioner!, failedToProvisionDevice device:ProvisionableDevice!, error:NSError)
    
    /**
    The delegate is notified if the WifiProvisioner instance fails to provision a device because the Wifi credentials were declined.
    
    :param: provisioner The WifiProvisioner instance that attempted to provision the device
    :param: credentials The credentials which were declined
    :param: device The Savant device for which Wifi credentials were declined
    */
    func provisioner(provisioner:WifiProvisioner!, declinedCredentials credentials:WifiCredentials, forDevice device:ProvisionableDevice!)
    
    /**
    The delegate is notified if the WifiProvisioner failed to start due to having been started on a device that does not support BTLE.
    
    :param: provisioner The WifiProvisioner instance that attempted to start
    */
    func provisionerIsUnsupported(provisioner:WifiProvisioner!)
}

/**
WifiProvisioner uses BLE to discover Savant devices and configure WiFi credentials.
*/
public class WifiProvisioner : NSObject, CBCentralManagerDelegate {
    
    public weak var delegate:WifiProvisionerDelegate?
    var central:CBCentralManager?
    var deviceMap:[CBPeripheral : ProvisionableDevice] = [:]
    
    public override convenience init() {
        self.init(delegate:nil)
    }
    
    public init(delegate:WifiProvisionerDelegate?) {
        super.init()
        self.delegate = delegate
        central = CBCentralManager(delegate:self, queue:nil)
        dlog("Created new CBCentralManager")
    }
    
    /**
    Resets the provisioner instance, discarding all old provisionable devices and starting a new search.
    */
    public func restartWithAlert(alert: Bool) {
        dlog("Created new CBCentralManager")
        
        for (peripheral, device) in deviceMap {
            central?.cancelPeripheralConnection(peripheral)
        }
        
        deviceMap = [:]
        central?.stopScan()
        central?.delegate = nil
        
        if alert == true {
            central = CBCentralManager(delegate:self, queue:nil, options: [CBCentralManagerOptionShowPowerAlertKey:false])
        } else {
            central = CBCentralManager(delegate:self, queue:nil, options: [CBCentralManagerOptionShowPowerAlertKey:true])
        }
    }
    
    /**
    Begin the scan for targetted services
    */
    public func scan () {
        central?.scanForPeripheralsWithServices(kTargetServiceUuids, options: nil)
        dlog("CBCentralManager scanned")
    }
    
    /**
    Stop the central scan for targetted services
    */
    public func stopScan () {
        central?.stopScan()
        dlog("CBCentralManager stopped scan")
    }
    
    /**
    Instructs the provisioner to start connecting to a ProvisionableDevice instance.
    
    :param: device      ProvisionableDevice to connect
    */
    public func connectToProvisionableDevice(device:ProvisionableDevice) {
        //JRL Note: may need to use peripheralsForIds if this is unreliable
        central?.connectPeripheral(device.peripheral, options: nil);
    }
    
    /**
    Instructs the provisioner to start disconnecting from a ProvisionableDevice instance.
    
    :param: device      ProvisionableDevice to disconnect
    */
    public func disconnectFromProvisionableDevice(device:ProvisionableDevice) {
        central?.cancelPeripheralConnection(device.peripheral);
    }
    
    /**
    Description
    
    :param: identifiers CBUUIDS
    
    :returns: devices for CBUUIDS
    */
    public func peripheralsForIds(identifiers: [CFUUID!]) -> NSArray! {
        return (central?.retrievePeripheralsWithIdentifiers(identifiers))! as NSArray!
    }
    
    /**
    Currently visible provisionable devices
    
    :return: collection of provisionable devices
    */
    public func devices() -> NSArray {
        let result = Array(deviceMap.values) as NSArray
        return result
    }
    
    /**
    Instructs the provisioner to start provisioning ProvisionableDevice instance with the provided WifiCredentials.
    
    :param: device      ProvisionableDevice to provision
    :param: credentials credentials to use for target device
    */
    public func provisionDevice(device:ProvisionableDevice, credentials:WifiCredentials!) {
        device.provisionWithCredentials(credentials)
    }
    
    public func centralManagerDidUpdateState(central: CBCentralManager!) {
        switch central.state {
        case .PoweredOn:
            central.scanForPeripheralsWithServices(kTargetServiceUuids, options: nil)
            dlog("CBCentralManager powered on, scanning for services: \(kTargetServiceUuids)")
        case .Unsupported:
            delegate?.provisionerIsUnsupported(self)
        default:
            break;
        }
    }
    
    public func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        let deviceData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? NSData
        
        var deviceClass:Int8 = 5
        var deviceSubclass:Int8 = 0
        var deviceUID:UInt64 = 0
        var UIDString = ""
        
        if let dD = deviceData {
            
            let deviceClassRange: NSRange = NSMakeRange(2, 1)
            let deviceSubclassRange: NSRange = NSMakeRange(3, 1)
            let deviceUIDRange: NSRange = NSMakeRange(6, 8)
            
            dD.getBytes(&deviceClass, range: deviceClassRange)
            
            dD.getBytes(&deviceSubclass, range: deviceSubclassRange)
            
            dD.getBytes(&deviceUID, range: deviceUIDRange)
            let byteFlippedDeviceUID = CFSwapInt64(deviceUID);
            
            UIDString = String(byteFlippedDeviceUID, radix:16, uppercase: true)
            
            //JRL: <hack>
            var zeroPadding = ""
            
            while count(zeroPadding + UIDString) < 16 {
                zeroPadding += "0"
            }
            
            UIDString = zeroPadding + UIDString
            //JRL: </hack>
            
            dlog("discovered peripheral \(peripheral.name):\(UIDString)")
        }
        
        var name:String?
        var savantDeviceType:DeviceType?
        
        switch (deviceClass, deviceSubclass) {
        case (1, 1):
            name = "Smart Host"
            savantDeviceType = DeviceType.Host
        case (1, 2):
            name = "Simple Host"
            savantDeviceType = DeviceType.Host
        case (2, 1):
            name = "Metropolitan Keypad"
            savantDeviceType = DeviceType.Lighting
        case (2, 2):
            name = "Metropolitan Dimmer"
            savantDeviceType = DeviceType.Lighting
        case (2, 3):
            name = "Metropolitan Switch"
            savantDeviceType = DeviceType.Lighting
        case (2, 4):
            name = "Metropolitan Fanspeed"
            savantDeviceType = DeviceType.Lighting
            //Lamp module subclass is incorrect, this is because our current hardware is wrong. Change this when the hardware changes.
        case (2, 0):
            name = "Lamp Module"
            savantDeviceType = DeviceType.LampModule
        case (2, 6):
            name = "Keypad"
            savantDeviceType = DeviceType.Lighting
        case (3, 1):
            name = "Camera"
            savantDeviceType = DeviceType.Camera
        case (4, 1):
            name = "IR Blaster"
            savantDeviceType = DeviceType.Controller
        case (4, 2):
            name = "Remote Base"
            savantDeviceType = DeviceType.Controller
            
        default:
            name = nil
            println("\(deviceClass)---\(deviceSubclass)---\(UIDString)")
        }
        
        if let n = name {
            let device = ProvisionableDevice(peripheral: peripheral, name:n, provisioner: self, uid: UIDString, deviceClass: Int(deviceClass), deviceSubclass: Int(deviceSubclass), savantDeviceType: savantDeviceType)
            
            self.delegate?.provisioner(self, foundDevice: device)
            deviceMap[peripheral] = device;
        }
    }
    
    public func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        dlog("connected peripheral \(peripheral.name):\(peripheral.identifier)")
        if let device = deviceMap[peripheral] {
            device.peripheralConnected(peripheral: peripheral)
        }
    }
    
    public func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        dlog("disconnected peripheral \(peripheral.name):\(peripheral.identifier); error: \(error)")
        let device = deviceMap[peripheral]
        device?.peripheralDisconnected(peripheral)
    }
}

/**
WifiCredentials is a data class used to specify the Wifi credentials used to provision a device
*/
public class WifiCredentials : NSObject {
    public var SSID:String? = nil
    public var presharedKey:String? = nil
    public var authType:WifiAuthType? = nil
}

@objc public class WifiAuthType : NSObject {
    public let rawValue:UInt8
    
    init(_ value:UInt8) {
        rawValue = value
        super.init()
    }
    
    class public func Any()  -> WifiAuthType { return WifiAuthType(0) }
    class public func Open() -> WifiAuthType { return WifiAuthType(1) }
    class public func WEP()  -> WifiAuthType { return WifiAuthType(2) }
    class public func WPA()  -> WifiAuthType { return WifiAuthType(3) }
    class public func WPA2() -> WifiAuthType { return WifiAuthType(4) }
    class public func WAPI() -> WifiAuthType { return WifiAuthType(5) }
}

func dlog(message:String, filename:String = __FILE__, lineNumber:Int = __LINE__) {
    #if DEBUG
        println("\(filename.lastPathComponent):\(lineNumber) \(message)")
    #endif
}


let kWifiProvisiongServiceUuid              = CBUUID(string: "FEA9")
let kProvisioningStateCharacteristicUuid    = CBUUID(string: "CC831880-03E3-4DFE-8ED8-DC2757000001")
let kControlPointCharacteristicUuid         = CBUUID(string: "CC831880-03E3-4DFE-8ED8-DC2757000002")
let kProvisioningResultCharacteristicUuid   = CBUUID(string: "CC831880-03E3-4DFE-8ED8-DC2757000003")
let kWifiSSIDCharacteristicUuid             = CBUUID(string: "CC831880-03E3-4DFE-8ED8-DC2757000004")
let kWifiPresharedKeyCharacteristicUuid     = CBUUID(string: "CC831880-03E3-4DFE-8ED8-DC2757000005")
let kWifiAuthTypeCharacteristicUuid         = CBUUID(string: "CC831880-03E3-4DFE-8ED8-DC2757000006")
let kTargetServiceUuids                     = [kWifiProvisiongServiceUuid]
let kTargetCharacteristicUuids              = [kProvisioningStateCharacteristicUuid, kWifiSSIDCharacteristicUuid, kWifiPresharedKeyCharacteristicUuid, kControlPointCharacteristicUuid, kWifiAuthTypeCharacteristicUuid, kProvisioningResultCharacteristicUuid]