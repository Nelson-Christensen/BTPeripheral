//
//  main.swift
//  BTPeripheral
//
//  Created by Nelson Christensen on 2022-03-02. Code added on by Tobias Forsén
//

import Foundation
import AVFoundation
import AppKit


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

