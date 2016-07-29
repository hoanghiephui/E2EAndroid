//
//  HLBleShareKey.swift
//  HeilOSX
//
//  Created by Sinbad Flyce on 6/17/16.
//  Copyright © 2016 YusufX. All rights reserved.
//

import Foundation
import BluetoothKit

let kDataServiceUUID = NSUUID(UUIDString: "6E6B5C64-FAF7-40AE-9C21-D4933AF45B23")!
let kDataServiceCharacteristicUUID = NSUUID(UUIDString: "477A2967-1FAB-4DC5-920A-DEE5DE685A3D")!
let kLocalName = "Heilamb"
let kDuringScanning : NSTimeInterval = 15

public protocol HLBleShareKeyDelegate: class {
    func shareKey(shareKey: HLBleShareKey, canSendDatafromCentral fromCentral: BKCentral, toPeripheral: BKRemotePeripheral)
    func shareKey(shareKey: HLBleShareKey, didSendDatafromCentral fromCentral: BKCentral, toPeripheral: BKRemotePeripheral, error: NSError?)
    func shareKey(shareKey: HLBleShareKey, didReceivedPublicKey messagePackage: HLMessagePackage)
}

public class HLBleShareKey : BKPeripheralDelegate, BKCentralDelegate, BKRemotePeerDelegate {
    let peripheral = BKPeripheral()
    let central = BKCentral()
    var discoveries = [BKDiscovery]()
 
    public weak var delegate: HLBleShareKeyDelegate?
    
    class var shared: HLBleShareKey {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: HLBleShareKey? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = HLBleShareKey()
        }
        return Static.instance!
    }
 
    func start() {
        HLUltils.executeDelay(1) {
            self.runPeripheral()
        }
        HLUltils.executeDelay(2) {
            self.runCentral()
            HLUltils.executeDelay(1) {
                self.scan()
            }
        }
    }
    
    func stop() {
        self.central.interruptScan()
        _ = try? self.peripheral.stop()
        _ = try? self.central.stop()
    }
    
    deinit {
        self.stop()
    }
    
    private func runPeripheral() {
        peripheral.delegate = self
        do {
            let configuration = BKPeripheralConfiguration(dataServiceUUID: kDataServiceUUID, dataServiceCharacteristicUUID:  kDataServiceCharacteristicUUID, localName: kLocalName)
            try peripheral.startWithConfiguration(configuration)
        } catch let error {
            print("[BLE] Error :\(error)")
        }
    }
    
    private func runCentral() {
        do {
            central.delegate = self
            let configuration = BKConfiguration(dataServiceUUID: kDataServiceUUID, dataServiceCharacteristicUUID: kDataServiceCharacteristicUUID)
            try central.startWithConfiguration(configuration)
        } catch let error {
            print("[BLE] Error while starting: \(error)")
        }
    }
    
    private func scan() {
        central.scanContinuouslyWithChangeHandler({ changes, discoveries in
            self.discoveries = discoveries
            for discovery: BKDiscovery in discoveries {
                self.central.connect(remotePeripheral: discovery.remotePeripheral, completionHandler: { (remotePeripheral, error) in
                    if self.delegate != nil && error != nil {
                        self.delegate?.shareKey(self, canSendDatafromCentral: self.central, toPeripheral: discovery.remotePeripheral)
                    }
                })
            }
        }, stateHandler: { newState in
            if newState == .Scanning {
                print("[BLE] Now next scanning...")
                return
            } else if newState == .Stopped {
                self.discoveries.removeAll()
            }
        },duration: kDuringScanning, errorHandler: { error in
            print("[BLE] Error from scanning: \(error)")
        })
    }
    
    public func peripheral(peripheral: BKPeripheral, remoteCentralDidConnect remoteCentral: BKRemoteCentral) {
        print("[BLE] remoteCentralDidConnect: ")
        remoteCentral.delegate = self
    }
    
    public func peripheral(peripheral: BKPeripheral, remoteCentralDidDisconnect remoteCentral: BKRemoteCentral) {
        print("[BLE] remoteCentralDidDisconnect: ")
        remoteCentral.delegate = nil
    }
    
    public func central(central: BKCentral, remotePeripheralDidDisconnect remotePeripheral: BKRemotePeripheral) {
        print("[BLE] remotePeripheralDidDisconnect: ")
        remotePeripheral.delegate = nil
    }
    
    public func remotePeer(remotePeer: BKRemotePeer, didSendArbitraryData data: NSData) {
        print("[BLE] Received data of length: \(data.length) with hash: \(data.stringUTF8)")
        if self.delegate != nil {
            if let stringValue = data.stringUTF8 {
                if let dict = HLUltils.convertStringToDictionary(stringValue) {
                    if let messagePackage = HLMessagePackage(dictionary: dict) {
                        self.delegate?.shareKey(self, didReceivedPublicKey: messagePackage)
                    }
                }
            }
        }
    }
}