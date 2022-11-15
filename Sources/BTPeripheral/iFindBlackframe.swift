//
//  iFindBlackframe.swift
//  BTPeripheral
//
//  Created by MKIII-49 on 2022-11-15.
//

import Foundation
import SwiftUI

class iFindBlackFrames {
    
    /*
     isBlackFrame()
     intput:
        (String) filepath to image
        (Double) threshold for average brightness component
     output:
        false: If average pixel brightness is higher than threshold, or no image was found
        true : If average pixel brightness is strictly lower than threshold
     */
    static func isBlackFrame(filepath: String, threshold: Double) -> Bool {
        let inputURL = URL(fileURLWithPath: filepath)
        if let image = CIImage(contentsOf: inputURL) {
            let bitmap = NSBitmapImageRep.init(ciImage: image)

            let numPixels = Double(bitmap.pixelsWide + bitmap.pixelsHigh)
            var totalBrightness = 0.0
            
            for x in 0...bitmap.pixelsWide - 1 { //Horizontal pixels
                totalBrightness += Double(bitmap.colorAt(x: x, y: bitmap.pixelsHigh / 2)?.brightnessComponent ?? 0)
            }
            
            for y in 0...bitmap.pixelsHigh - 1 { //Vertical pixels
                totalBrightness += Double(bitmap.colorAt(x: bitmap.pixelsWide / 2, y: y)?.brightnessComponent ?? 0)
            }
            
            let averageBrightness = totalBrightness / numPixels
            
            if(averageBrightness > threshold)  {return false}
            else {return true}
            
        } else { // If no image was found, return false
            return false
        }
    }
}
