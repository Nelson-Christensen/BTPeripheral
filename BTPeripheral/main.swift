//
//  main.swift
//  BTPeripheral
//
//  Created by Nelson Christensen on 2022-03-02.
//

import Foundation
import CoreBluetooth
import AppKit

struct TransferService {
    static let serviceUUID = CBUUID(string: "1F2AD508-3BD6-485F-A2B1-F96ADBFB93E5")
    // This is for passing changes in the assetId folder to save to
    static let assetIDCharacteristicsUUID = CBUUID(string: "92DEFE82-F9D9-4BAC-AFAB-A82B4C202B0B")
    // This is to send commands for the 2D scanner with the remote control functionality
    static let commandsCharacteristicsUUID = CBUUID(string: "9AE32710-EB03-46CF-A9FB-D4F3536CCDF2")
}

class Peripheral: NSObject, CBPeripheralManagerDelegate
{
    var peripheralManager : CBPeripheralManager!
    
    var transferCharacteristic: CBMutableCharacteristic?
    
    override init(){
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
        if (peripheralManager.state == CBManagerState.poweredOn){
            print("Powered on")
        } else {
            print("Not powered on")
        }
    }
    
    private func setupPeripheral() {
        // Build our service.
        print("Setting up peripheral")
        
        // Start with the CBMutableCharacteristic.
        let assetIdCharacteristic = CBMutableCharacteristic(type: TransferService.assetIDCharacteristicsUUID,
                                                             properties: [.notify, .writeWithoutResponse, .write],
                                                         value: nil,
                                                         permissions: [.readable, .writeable])
        
        let commandCharacteristic = CBMutableCharacteristic(type: TransferService.commandsCharacteristicsUUID,
                                                             properties: [.write],
                                                         value: nil,
                                                         permissions: [.writeable])
        
        // Create a service from the characteristic.
        let transferService = CBMutableService(type: TransferService.serviceUUID, primary: true)
        
        // Add the characteristic to the service.
        transferService.characteristics = [assetIdCharacteristic, commandCharacteristic]
        
        // And add it to the peripheral manager.
        peripheralManager.add(transferService)
        
        // Save the characteristic for later.
        self.transferCharacteristic = assetIdCharacteristic
        
        peripheralManager.startAdvertising([CBAdvertisementDataLocalNameKey : "Quixel macMini app", CBAdvertisementDataServiceUUIDsKey: [TransferService.serviceUUID]])
    }

    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager)
    {
            switch peripheral.state {
            case .poweredOn:
                // ... so start working with the peripheral
                print("CBManager is powered on")
                setupPeripheral()
            case .poweredOff:
                print("CBManager is not powered on")
                // In a real app, you'd deal with all the states accordingly
                return
            case .resetting:
                print("CBManager is resetting")
                // In a real app, you'd deal with all the states accordingly
                return
            case .unauthorized:
                // In a real app, you'd deal with all the states accordingly
                if #available(iOS 13.0, *) {
                    switch peripheral.authorization {
                    case .denied:
                        print("You are not authorized to use Bluetooth")
                    case .restricted:
                        print("Bluetooth is restricted")
                    default:
                        print("Unexpected authorization")
                    }
                } else {
                    // Fallback on earlier versions
                }
                return
            case .unknown:
                print("CBManager state is unknown")
                // In a real app, you'd deal with all the states accordingly
                return
            case .unsupported:
                print("Bluetooth is not supported on this device")
                // In a real app, you'd deal with all the states accordingly
                return
            @unknown default:
                print("A previously unknown peripheral manager state occurred")
                // In a real app, you'd deal with yet unknown cases that might occur in the future
                return
            }
    }
    
    /*
     * This callback comes in when the PeripheralManager received write to characteristics
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for aRequest in requests {
            guard let requestValue = aRequest.value,
                let stringFromData = String(data: requestValue, encoding: .utf8) else {
                    continue
            }
            
            switch aRequest.characteristic.uuid {
            case TransferService.assetIDCharacteristicsUUID:
                print("Attempting to change assetId to: ", stringFromData)
                print(stringFromData)
                peripheralManager.respond(to: aRequest, withResult: .success)
            case TransferService.commandsCharacteristicsUUID:
                print("Sent remote control command: ", stringFromData)
                print(stringFromData)
                peripheralManager.respond(to: aRequest, withResult: .success)
            default:
                print(stringFromData)
                print("Message sent to unknown characteristic")
                peripheralManager.respond(to: aRequest, withResult: .requestNotSupported)
            }
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager,
                             didAdd service: CBService,
                             error: Error?) {
        if (error != nil) {
            print("Could not add service to peripheral")
        } else {
            print ("Successfully added service to peripheral. Ready to receive data")
        }
    }
}

let myPeripheral = Peripheral.init()
RunLoop.main.run()
