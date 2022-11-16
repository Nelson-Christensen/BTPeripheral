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
import AVFoundation

PythonLibrary.useVersion(3)
print("Python version ")
print(Python.version)

struct Speaker {

    let synthesizer = AVSpeechSynthesizer()
    func say(text :String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        utterance.rate = 0.52
        self.synthesizer.speak(utterance)
    }
}



//synthesizer.speak(speech)
let speaker = Speaker()
//speaker.say(text:"Main started")

let usbWatcher = UsbWatcher()

DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    if(!usbWatcher.IsConnected ())
    {
        speaker.say(text:"Connect Camera")
    }
}


struct TransferService {
    static let serviceUUID = CBUUID(string: "1F2AD508-3BD6-485F-A2B1-F96ADBFB93E5")
    // This is for passing changes in the assetId folder to save to
    static let assetIDCharacteristicsUUID = CBUUID(string: "92DEFE82-F9D9-4BAC-AFAB-A82B4C202B0B")
    // This is to send commands for the 2D scanner with the remote control functionality
    static let commandsCharacteristicsUUID = CBUUID(string: "9AE32710-EB03-46CF-A9FB-D4F3536CCDF2")
    // This characteristic just broadcasts the systems bluetooth macAddress for identification purposes
    static let macAddressCharacteristicsUUID = CBUUID(string: "7C7A74F8-BCC1-4C82-B924-73946338A61C")
    // This characteristic will notify all subscribers when a new photo is added
    static let imgCountCharacteristicUUID = CBUUID(string: "A103AF39-F582-428E-8A67-26CC1770E96C")
}

var dirfolder1 = "folders"
var dirfolder2 = "master"
var dirDestination = "asset_temp"
var stringToWrite = ""
var stringHDName = ""
var mute = 0

public extension NSSound {
    static let basso     = NSSound(named: .basso)
    static let blow      = NSSound(named: .blow)
    static let bottle    = NSSound(named: .bottle)
    static let frog      = NSSound(named: .frog)
    static let funk      = NSSound(named: .funk)
    static let glass     = NSSound(named: .glass)
    static let hero      = NSSound(named: .hero)
    static let morse     = NSSound(named: .morse)
    static let ping      = NSSound(named: .ping)
    static let pop       = NSSound(named: .pop)
    static let purr      = NSSound(named: .purr)
    static let sosumi    = NSSound(named: .sosumi)
    static let submarine = NSSound(named: .submarine)
    static let tink      = NSSound(named: .tink)
}



public extension NSSound.Name {
    static let basso     = NSSound.Name("Basso")
    static let blow      = NSSound.Name("Blow")
    static let bottle    = NSSound.Name("Bottle")
    static let frog      = NSSound.Name("Frog")
    static let funk      = NSSound.Name("Funk")
    static let glass     = NSSound.Name("Glass")
    static let hero      = NSSound.Name("Hero")
    static let morse     = NSSound.Name("Morse")
    static let ping      = NSSound.Name("Ping")
    static let pop       = NSSound.Name("Pop")
    static let purr      = NSSound.Name("Purr")
    static let sosumi    = NSSound.Name("Sosumi")
    static let submarine = NSSound.Name("Submarine")
    static let tink      = NSSound.Name("Tink")
}


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
}

class Peripheral: NSObject, CBPeripheralManagerDelegate
{
    func updateImageCount(count: Int){
        // I could not successfully send it as an int for some reason, so we just convert it to a string for now.
        // var myInt = count;
        // let dataCount = Data(bytes: &myInt, count: MemoryLayout.size(ofValue: myInt));
        // let base64 = dataCount.base64EncodedData();
        let intStringBase64 = String(count).data(using: .utf8);
        // let intData = NSData(bytes: &count, length: sizeof(NSInteger));
        if (intStringBase64 != nil){
            imgCountCharacteristic.value = intStringBase64;
            let updateResult = peripheralManager.updateValue(intStringBase64!, for: imgCountCharacteristic, onSubscribedCentrals: nil);
        }
    }
    var peripheralManager : CBPeripheralManager!
    
    var imgCountCharacteristic : CBMutableCharacteristic!
    var assetIdCharacteristic : CBMutableCharacteristic!

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
        if let deviceName = Host.current().localizedName {
           print("DeviceName: ", deviceName)
        }
        
        // Read the bluetooth macAddress of the system. It can't be done through swift, so we open up a
        // terminal process and run the command from there and pass the result back to the swift program
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["system_profiler", "SPBluetoothDataType"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as! String
        let log = output;
        let logArray = output.components(separatedBy: "Address: ");
        let firstAddress = logArray[1];
        let bluetoothAddress = firstAddress.prefix(17);
        print("MAC Address: ", bluetoothAddress);
        
        
        // Start with the CBMutableCharacteristic.
        assetIdCharacteristic = CBMutableCharacteristic(type: TransferService.assetIDCharacteristicsUUID,
                                                            properties: [.notify, .writeWithoutResponse, .write, .read],
                                                            value: nil,
                                                         permissions: [.readable, .writeable])
        
        let commandCharacteristic = CBMutableCharacteristic(type: TransferService.commandsCharacteristicsUUID,
                                                            properties: [.writeWithoutResponse, .write],
                                                         value: nil,
                                                         permissions: [.writeable])
        
        let macAddressCharacteristic = CBMutableCharacteristic(type: TransferService.macAddressCharacteristicsUUID,
                                                               properties: [.read],
                                                               value: bluetoothAddress.data(using: .utf8),
                                                         permissions: [.readable])
        
        imgCountCharacteristic = CBMutableCharacteristic(type: TransferService.imgCountCharacteristicUUID,
                                                                     properties: [.read, .notify, .indicate],
                                                                     value: nil,
                                                         permissions: [.readable, .readEncryptionRequired])
        
        // Create a service from the characteristic.
        let transferService = CBMutableService(type: TransferService.serviceUUID, primary: true)
        
        // Add the characteristic to the service.
        transferService.characteristics = [assetIdCharacteristic, commandCharacteristic, macAddressCharacteristic, imgCountCharacteristic]
        
        // And add it to the peripheral manager.
        peripheralManager.add(transferService)
        
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
     * This callback comes in when the PeripheralManager received read requests to characteristics
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("Received a single read request.");
        
        switch request.characteristic.uuid {
        case TransferService.assetIDCharacteristicsUUID:
            request.value = assetIdCharacteristic.value;
            print("Received read request for assetId: ");
            peripheralManager.respond(to: request, withResult: .success);
        case TransferService.imgCountCharacteristicUUID:
            request.value = imgCountCharacteristic.value;
            print("Received read request for img count.");
            peripheralManager.respond(to: request, withResult: .success)
        default:
            peripheralManager.respond(to: request, withResult: .unlikelyError)
            return;
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
                
                print("Received write request of ", requestValue.count, " recived bytes ", stringFromData)
                guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    print("Could not get documentDirectory")
                    peripheralManager.respond(to: aRequest, withResult: .unlikelyError)
                    return
                }
                
                let folderPath = url.appendingPathComponent(dirfolder1).appendingPathComponent(stringFromData)
                
                
                do {
                    let items = try FileManager.default.contentsOfDirectory(atPath: "/Volumes/")

                    for item in items {
                        if item != "Macintosh HD"{
                            stringHDName = item
                        }
                    }
                } catch {
                    print(error)
                    print("Failed to read directory")
                    peripheralManager.respond(to: aRequest, withResult: .unlikelyError)
                    // failed to read directory – bad permissions, perhaps?
                }
                let xdirPath = "/Volumes/" + stringHDName + "/folders/"
                
                let xdirPath2 = "/"
                let HDfolderPath = xdirPath + stringFromData + xdirPath2
                
                var assetFolder = folderPath;
                if FileManager.default.fileExists(atPath: xdirPath) {
                    print("H-D")
                    assetFolder = URL(fileURLWithPath: HDfolderPath);
                } else {
                    print("MAC")
                }
                do {
                    try FileManager.default.createDirectory(atPath: assetFolder.path, withIntermediateDirectories: true, attributes: nil)
                    
                    let numberOfItems = try FileManager.default.contentsOfDirectory(at: assetFolder, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles).count;
                    print("Number of images in folder: " + String(numberOfItems));
                    myPeripheral.updateImageCount(count: numberOfItems);
                } catch {
                    print(error)
                    print("Could not create new directory")
                    peripheralManager.respond(to: aRequest, withResult: .unlikelyError)
                }
                dirDestination = stringFromData
                assetIdCharacteristic.value = requestValue;
                
                peripheralManager.respond(to: aRequest, withResult: .success)
                
            case TransferService.commandsCharacteristicsUUID:
                print("Sent remote control command: ", stringFromData)
                print(stringFromData)
                
                if (stringFromData == "clear") {
                    // Handle Clear MacMini Storage
                    guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                        peripheralManager.respond(to: aRequest, withResult: .unlikelyError)
                        return
                    }
                    
                    let folderPath = url.appendingPathComponent(dirfolder1)
                    
                    do {
                        let fileName = try FileManager.default.contentsOfDirectory(atPath: folderPath.path)

                        for file in fileName {
                            if (file != "master"){
                                // For each file in the directory, create full path and delete the file
                                let filePath = URL(fileURLWithPath: folderPath.path).appendingPathComponent(file).absoluteURL
                                try FileManager.default.removeItem(at: filePath)
                            }
                        }
                    } catch {
                        print(error)
                        peripheralManager.respond(to: aRequest, withResult: .unlikelyError)
                    }
                } else {
                    // Handle Remote Control Commands
                    stringToWrite = stringFromData
                    runPythonCode()
                }
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
                        var isJPG = false
                        
                        if item.contains(".ARW") || item.contains(".JPG") || item.contains(".raf") || item.contains(".RAF"){
                            //Date------ START
                            let date = NSDate()
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH-mm-ss "
                            var stringName = dateFormatter.string(from: date as Date)
                            
                            stringName.append(contentsOf: stringitem)
                            if item.contains(".ARW"){
                                
                                stringName.append(contentsOf: ".ARW")
                            } else if item.contains(".JPG"){
                                isJPG = true
                                stringName.append(contentsOf: ".JPG")
                            } else if item.contains(".raf"){
                                
                                stringName.append(contentsOf: ".raf")
                            } else if item.contains(".RAF"){
                                
                                stringName.append(contentsOf: ".RAF")
                            }
                            print(stringName)
                            //Date------ END
                            
                            let oldFile = dirMasterPath.appendingPathComponent(item).path
                            
                            let dirFolderPath = url.appendingPathComponent(dirfolder1).appendingPathComponent(dirDestination)
                            let dirPath = dirFolderPath.appendingPathComponent(stringName).path // (item).path
                            do {
                                let items = try FileManager.default.contentsOfDirectory(atPath: "/Volumes/")

                                for item in items {
                                    if item != "Macintosh HD"{
                                        stringHDName = item
                                    }
                                }
                            } catch {
                                // failed to read directory – bad permissions, perhaps?
                            }
                            let xdirPath = "/Volumes/" + stringHDName + "/folders/"
                            let xdirPath2 = "/"
                            let HDfolder = xdirPath + dirDestination + xdirPath2
                            let HDfolderPath = xdirPath + dirDestination + xdirPath2 + stringName + xdirPath2
                            
                            if FileManager.default.fileExists(atPath: xdirPath) {
                                print ("H-D")
                                if !FileManager.default.fileExists(atPath: HDfolder) {
                                    do {
                                        try FileManager.default.createDirectory(atPath: HDfolder, withIntermediateDirectories: true, attributes: nil)
                                    } catch {
                                        print(error)
                                    }
                                }
                                do{
                                    try FileManager.default.moveItem(atPath: oldFile, toPath: HDfolderPath)
                                    
                                    let numberOfItems = try FileManager.default.contentsOfDirectory(at: dirFolderPath, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles).count;
                                    print("Number of images in folder: " + String(numberOfItems));
                                    
                                    myPeripheral.updateImageCount(count: numberOfItems);
                                    
                                    if mute == 0{
                                        NSSound.beep()
                                    }
                                } catch   {
                                    print("Move H-D error")
                                }
                            } else {
                                print ("MAC")
                                if !FileManager.default.fileExists(atPath: url.appendingPathComponent(dirfolder1).appendingPathComponent(dirDestination).path) {
                                    do {
                                        try FileManager.default.createDirectory(atPath: url.appendingPathComponent(dirfolder1).appendingPathComponent(dirDestination).path, withIntermediateDirectories: true, attributes: nil)
                                    } catch {
                                        print(error)
                                    }
                                }
                                
                                do{
                                    if (isJPG && iFindBlackFrames.isBlackFrame(filepath: oldFile, threshold: 0.02))
                                    {
                                        speaker.say(text: "Black Frame")
                                        print("FOUND BLACKFRAME")
                                    }
                                    try FileManager.default.moveItem(atPath: oldFile, toPath: dirPath)
                                    
                                    let numberOfItems = try FileManager.default.contentsOfDirectory(at: dirFolderPath, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles).count;
                                    print("Number of images in folder: " + String(numberOfItems));
                                    
                                    myPeripheral.updateImageCount(count: numberOfItems);
                                    
                                    if mute == 0{
                                        NSSound.submarine?.stop()
                                        NSSound.submarine?.play()
                                        
                                    }
                                    
                                } catch   {
                                    print("Move Mac error")
                                    print("Unexpected error: \(error).")
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

