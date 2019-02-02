//
//  LightDecoder.swift
//  LightAnchors
//
//  Created by Nick Wilkerson on 1/31/19.
//  Copyright © 2019 Wiselab. All rights reserved.
//

import UIKit

class CapturedImage {
    
    let image: UIImage
    let name: String
    
    init(image: UIImage, name: String) {
        self.image = image
        self.name = name
       
    }

}

class LightDecoder: NSObject {

    let maxFrameBuffers = 10
    
    var frameBuffers = NSMutableArray()//Array<CVPixelBuffer>()
    
    let fileNameDateFormatter = DateFormatter()
    
    override init() {
        super.init()
        fileNameDateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss-SSS"
    }
    
    func add(image: UIImage) {
      //  frameBuffers.append(buffer)
        let now = Date()
        let dateString = fileNameDateFormatter.string(from: now)
        let fileName = String(format: "%@.png", dateString)
        //MemoryLayout.size(ofValue: coreImage)
        let capturedImage = CapturedImage(image: image, name: fileName)
        NSLog("capturedImage.size width: %f height: %f", capturedImage.image.size.width, capturedImage.image.size.height)
        frameBuffers.add(capturedImage)
        if frameBuffers.count > maxFrameBuffers {
            //frameBuffers.removeObject(at: 0)
            var data = Data()
            for cImage in frameBuffers  {
                let caImage = cImage as! CapturedImage
                NSLog("saving to file")
                //caImage.image.saveToFile(named: caImage.name)
                if let imageData = caImage.image.pngData() {
                    data.append(imageData)
                }
            }
            
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            if let filePath = paths.first?.appendingPathComponent(fileName) {
                // Save image.
                do {
                    try data.write(to: filePath, options: .atomic)
                }
                catch {
                    // Handle the error
                }
            }
            
            frameBuffers.removeAllObjects()
        }
    }
    
}
