//
//  WifiSurvey.swift
//  Pods
//
//  Created by Joseph Ross on 1/7/15.
//
//

import CoreBluetooth


class WifiSurvey : NSObject, CBCentralManagerDelegate {

    func centralManagerDidUpdateState(central: CBCentralManager!) {
        if (central.state == CBCentralManagerState.PoweredOn) {

        }
    }
    
}