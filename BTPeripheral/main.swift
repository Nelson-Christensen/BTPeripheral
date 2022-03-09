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
    static let characteristicUUID = CBUUID(string: "92DEFE82-F9D9-4BAC-AFAB-A82B4C202B0B")
}

var dirPathmaster = "/Users/tobiasforsen/Documents/folders/master/"
var dirCurrentPath = "/Users/tobiasforsen/Documents/folders/test1/"
var dirDestination = "root"


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
        let transferCharacteristic = CBMutableCharacteristic(type: TransferService.characteristicUUID,
                                                             properties: [.notify, .writeWithoutResponse, .write],
                                                         value: nil,
                                                         permissions: [.readable, .writeable])
        
        // Create a service from the characteristic.
        let transferService = CBMutableService(type: TransferService.serviceUUID, primary: true)
        
        // Add the characteristic to the service.
        transferService.characteristics = [transferCharacteristic]
        
        // And add it to the peripheral manager.
        peripheralManager.add(transferService)
        
        // Save the characteristic for later.
        self.transferCharacteristic = transferCharacteristic
        
        peripheralManager.startAdvertising([CBAdvertisementDataLocalNameKey : "QuixelmacMiniapp2", CBAdvertisementDataServiceUUIDsKey: [TransferService.serviceUUID]])
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
            
            print("Received write request of ", requestValue.count, " recived bytes ", stringFromData)
            peripheralManager.respond(to: aRequest, withResult: .success)
            //NSSound.Ping?.play()
            
            
            let dirPath = "/Users/tobiasforsen/Documents/folders/"          //Need to find tobiasforsen folder for all
            
            let dirPath2 = "/"
            let folderPath = dirPath + stringFromData + dirPath2
            do {
                try FileManager.default.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
            }
            dirDestination = stringFromData
            /*if FileManager.default.fileExists(atPath: folderPath) {
                do{
                try FileManager.default.removeItem(atPath: folderPath)
                } catch {
                    print(error)
                }
                print ("exists")
                NSSound.beep()
                do{
                try FileManager.default.copyItem(atPath: dirPathmaster, toPath: folderPath)
                } catch (let error) {
                    print("Cannot copy item at \(dirPathmaster) to \(folderPath): \(error)")
                    
                }
            }*/
                
            
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


let concurrentQueue = DispatchQueue(label: "swiftlee.concurrent.queue", attributes: .concurrent)



concurrentQueue.async {
    // Perform the data request and JSON decoding on the background queue.
    DispatchQueue.global(qos: .background).async {
        while(true){
            
            if FileManager.default.fileExists(atPath: dirPathmaster) {
                
                print ("exists")
                print(FileManager.default.contents(atPath: dirPathmaster))
                

                guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    return
                }
                
                let dirMasterPath = url.appendingPathComponent("folders").appendingPathComponent("master")
                print(dirMasterPath.path)
                let dirPath = url.appendingPathComponent("folders").appendingPathComponent(dirDestination)
                print(dirPath.path)
                
                var stringitem = ""
                do {
                    let items = try FileManager.default.contentsOfDirectory(atPath: dirMasterPath.path)

                    for item in items {
                        print("Found \(item)")
                        print("Found \(item.suffix(4))")
                        stringitem = item
                        stringitem.removeLast(4)
                        print("Found \(stringitem)")
                        print("Found items \(items.count)")
                    }
                } catch {
                    // failed to read directory – bad permissions, perhaps?
                }
                
                var dirPathPhoto = dirPath.path + "/" + stringitem
                print ("Found items \(dirPathPhoto)")
                do{
                    try FileManager.default.moveItem(atPath: dirMasterPath.path, toPath: dirPathPhoto)
                } catch (let error) {
                    print("Cannot copy item at \( dirPathmaster) to \(dirCurrentPath): \(error)")
                    
                }
                NSSound.beep()
                //NSSound(named: "Funk")?.play()
            }
            sleep(1)
        }
    }

    DispatchQueue.main.async {
        /// Access and reload the UI back on the main queue.
        print("Task 1 started")
    }
}
RunLoop.main.run()
