//
//  main.swift
//  BTPeripheral
//
//  Created by Nelson Christensen on 2022-03-02. Code added on by Tobias Forsén
//

import Foundation
import CoreBluetooth
import AppKit
import PythonKit
PythonLibrary.useVersion(3)
print("Python version ")
print(Python.version)

struct TransferService {
    static let serviceUUID = CBUUID(string: "1F2AD508-3BD6-485F-A2B1-F96ADBFB93E5")
    // This is for passing changes in the assetId folder to save to
    static let assetIDCharacteristicsUUID = CBUUID(string: "92DEFE82-F9D9-4BAC-AFAB-A82B4C202B0B")
    // This is to send commands for the 2D scanner with the remote control functionality
    static let commandsCharacteristicsUUID = CBUUID(string: "9AE32710-EB03-46CF-A9FB-D4F3536CCDF2")
}

var dirfolder1 = "folders"
var dirfolder2 = "master"
var dirDestination = "root"
var stringToWrite = ""
var mute = 0

func runPythonCode(){
    guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
        return
    }
    let folderPathPython = url.appendingPathComponent("Github").appendingPathComponent("BTPeripheral").appendingPathComponent("Sources").appendingPathComponent("BTPeripheral")
    let sys = Python.import("sys")
    sys.path.append(folderPathPython.path)
    let example = Python.import("sendArduino")
    let response = example.write(stringToWrite)
    let str = String(response)
    print (str)
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
        
        peripheralManager.startAdvertising([CBAdvertisementDataLocalNameKey : "QuixelmacMiniapp", CBAdvertisementDataServiceUUIDsKey: [TransferService.serviceUUID]])
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
                print("Received write request of ", requestValue.count, " recived bytes ", stringFromData)
                peripheralManager.respond(to: aRequest, withResult: .success)
                guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    return
                }
                
                let folderPath = url.appendingPathComponent(dirfolder1).appendingPathComponent(stringFromData)
                
                
                let xdirPath = "/Volumes/T7/folders/"
                
                let xdirPath2 = "/"
                let HDfolderPath = xdirPath + stringFromData + xdirPath2
                
                if FileManager.default.fileExists(atPath: xdirPath) {
                    print ("H-D")
                    do {
                        try FileManager.default.createDirectory(atPath: HDfolderPath, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        print(error)
                    }
                } else {
                    print ("MAC")
                    do {
                        try FileManager.default.createDirectory(atPath: folderPath.path, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        print(error)
                    }

                }
                dirDestination = stringFromData
              
                
                
                
                
            case TransferService.commandsCharacteristicsUUID:
                print("Sent remote control command: ", stringFromData)
                print(stringFromData)
                peripheralManager.respond(to: aRequest, withResult: .success)
                stringToWrite = stringFromData
                runPythonCode()
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


let concurrentQueue = DispatchQueue(label: "swiftlee.concurrent.queue", attributes: .concurrent)



concurrentQueue.async {
    // Perform the data request and JSON decoding on the background queue.
    DispatchQueue.global(qos: .background).async {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        let dirMasterPath = url.appendingPathComponent(dirfolder1).appendingPathComponent(dirfolder2)
        
        print(dirMasterPath.path)
        
        

        NSSound(named: "Glass")?.play()
        
        while(true){
            
            if FileManager.default.fileExists(atPath: dirMasterPath.path) {
                                
                
                var stringitem = ""
                do {
                    let items = try FileManager.default.contentsOfDirectory(atPath: dirMasterPath.path)

                    for item in items {
                        print("Found \(item)")
                        stringitem = item
                        stringitem.removeLast(4)
                        //print("Found items \(items.count)")
                        
                        if item.contains(".ARW") || item.contains(".JPG") || item.contains(".raf") {
                            //Date------ START
                            let date = NSDate()
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH-mm-ss "
                            var stringName = dateFormatter.string(from: date as Date)
                            
                            print(date)
                            stringName.append(contentsOf: stringitem)
                            if item.contains(".ARW"){
                                
                                stringName.append(contentsOf: ".ARW")
                            } else if item.contains(".JPG"){
                                
                                stringName.append(contentsOf: ".JPG")
                            } else if item.contains(".raf"){
                                
                                stringName.append(contentsOf: ".raf")
                            }
                            
                            
                            print(stringName)
                            //Date------ END
                            
                            let oldFile = dirMasterPath.appendingPathComponent(item).path
                            
                            let dirPath = url.appendingPathComponent(dirfolder1).appendingPathComponent(dirDestination).appendingPathComponent(stringName).path // (item).path
                            let xdirPath = "/Volumes/T7/folders/"
                            
                            let xdirPath2 = "/"
                            let HDfolderPath = xdirPath + dirDestination + xdirPath2 + stringName + xdirPath2
                            
                            if FileManager.default.fileExists(atPath: xdirPath) {
                                print ("H-D")
                                do{
                                    try FileManager.default.moveItem(atPath: oldFile, toPath: HDfolderPath)
                                    if mute == 0{
                                        NSSound.beep()
                                    }
                                } catch   {
                                    print("error")
                                }
                            } else {
                                print ("MAC")
                                do{
                                    try FileManager.default.moveItem(atPath: oldFile, toPath: dirPath)
                                    if mute == 0{
                                        NSSound.beep()
                                    }
                                    
                                } catch   {
                                    print("error")
                                }

                            }
                            
                           

                            
                        } else if item.contains(".DS_Store"){ // Remove ds_store
                            do{
                                
                                try FileManager.default.removeItem(atPath: dirMasterPath.appendingPathComponent(item).path)
                                print("Removed \(item)")
                            } catch {
                                print(error)
                            }
                        }
                    }
                } catch {
                    // failed to read directory – bad permissions, perhaps?
                    
                }
                

                //NSSound(named: "Funk")?.play()
            } else {
                print ("No master folder")
            }
            //sleep(1) //will sleep for 1 second
            usleep(100000)//will sleep for 0.1 seconds
        }
    }

    DispatchQueue.main.async {
        /// Access and reload the UI back on the main queue.
        print("Task 1 started")
    }
}


RunLoop.main.run()

