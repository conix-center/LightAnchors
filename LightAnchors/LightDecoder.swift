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
    
    //var imageDataArray: [Data] = []
    var imageBufferArray = [MTLBuffer]()
    var processingImageBuffers = false
    
    var width = 1440
    
    var device:MTLDevice?
    var library:MTLLibrary?
    var commandQueue:MTLCommandQueue?
    
    override init() {
        super.init()
        NSLog("LightDecoder init")
        fileNameDateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss-SSS"
        
        initializeMetal()
    }
    
    
    func initializeMetal() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        NSLog("documents: %@", documentsPath)
        device = MTLCreateSystemDefaultDevice()
        let libraryPath = Bundle.main.path(forResource: "kernels", ofType: "metal")
        NSLog("libraryPath: \(libraryPath)")
        if  let lPath = libraryPath{
            
            do {
                if let device = self.device {
                    try library = device.makeLibrary(source: lPath, options: nil)
                }
            } catch {
                NSLog("error making a library")
            }
        } else {
            NSLog("Cannot find library path")
            if let device = self.device {
           
                library = device.makeDefaultLibrary()
   
            }
        }
        if let device = self.device {
            commandQueue = device.makeCommandQueue()
        }
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
    
    
    

    class DataFile {
        let data: Data
        let fileName: String
        
        init(data: Data, fileName: String) {
            self.data = data
            self.fileName = fileName
        }
    }
    
    var dataFileArray = [DataFile]()
    var processingDataFiles = false
    var savingFiles = false
    var shouldSave = false
    
    func addToArrayForSaving(imageBytes: UnsafeRawPointer, length: Int) {
        let data = Data(bytes: imageBytes, count: length)
        let now = Date()
        let dateString = fileNameDateFormatter.string(from: now)
        let fileName = String(format: "%@.data", dateString)
        let dataFile = DataFile(data: data, fileName: fileName)
        if savingFiles == false {
            if shouldSave == true {
                dataFileArray.append(dataFile)
            
                if dataFileArray.count >= 90 {
                    savingFiles = true
                    DispatchQueue.global(qos: .userInitiated).async {
                        
                        for dataFile in self.dataFileArray {
                            NSLog("Saving file")
                            self.write(imageData: dataFile.data, to: dataFile.fileName)
                        }
                        self.dataFileArray.removeAll()
                        self.savingFiles = false
                        self.shouldSave = false
                    }
                }
            }
        } else {
            shouldSave = false
        }
    }
    
    
    
    func write(imageData: Data, to fileName: String) {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let filePath = paths.first?.appendingPathComponent(fileName) {
            // Save image.
            do {
                try imageData.write(to: filePath, options: .atomic)
            }
            catch {
                // Handle the error
            }
        }
        
    }
    

    
  
   
    
    func add(imageBytes: UnsafeRawPointer, length: Int) {
        
        guard let device = self.device else {
            NSLog("no device")
            return
        }
        
        guard let imageBuffer:MTLBuffer = device.makeBuffer(bytes: imageBytes, length: length, options: .storageModeShared) else {
            NSLog("Cannot create image buffer")
            return
        }
        if processingImageBuffers == false {
            imageBufferArray.append(imageBuffer)
        
            if imageBufferArray.count >= 90 {
                processingImageBuffers = true
                DispatchQueue.global(qos: .userInitiated).async {
                    let startTime = Date().timeIntervalSince1970
                    var prevBuffer = self.imageBufferArray[0]
                    for bufferIndex in 1..<self.imageBufferArray.count {
                        let buffer = self.imageBufferArray[bufferIndex]
                        self.compare( buffer, to: prevBuffer)
                        prevBuffer = buffer
                    }
                    self.imageBufferArray.removeAll()
                    let endTime = Date().timeIntervalSince1970
                    let runTime = endTime-startTime
                    NSLog("run time: %lf", runTime)
                    self.processingImageBuffers = false
                }
            }
        }
        
        

    }
    
    
    func compare(_ imageBuffer: MTLBuffer, to prevImageBuffer: MTLBuffer) {

        
        guard let device = self.device else {
            NSLog("no device")
            return
        }
        

        
        if imageBuffer.length != prevImageBuffer.length {
            NSLog("buffers do not match")
            return
        }
        let length = imageBuffer.length
        
        guard let diffBuffer = device.makeBuffer(length: length, options: .storageModePrivate) else {
            NSLog("Cannot make result buffer")
            return
        }
        
        guard let commandQueue = self.commandQueue else {
            NSLog("No command queue")
            return
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            NSLog("Cannot make command buffer")
            return
        }
        
        guard let library = self.library else {
            NSLog("No library")
            return
        }
        
        guard let differenceFunction = library.makeFunction(name: "difference") else {
            NSLog("Cannot make difference function")
            return
        }
        
        guard let differenceComputeCommandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            NSLog("Cannot make compute command encoder")
            return
        }
        
        var differenceComputePipelineState: MTLComputePipelineState?
        do {
            differenceComputePipelineState = try device.makeComputePipelineState(function: differenceFunction)
        } catch {
            NSLog("Error making compute pipeline state")
            differenceComputeCommandEncoder.endEncoding()
            return
        }
        
        guard let differencePipelineState = differenceComputePipelineState else {
            NSLog("No compute pipeline state")
            differenceComputeCommandEncoder.endEncoding()
            return
        }
        
        differenceComputeCommandEncoder.setBuffer(prevImageBuffer, offset: 0, index: 0)
        differenceComputeCommandEncoder.setBuffer(imageBuffer, offset: 0, index: 1)
        differenceComputeCommandEncoder.setBuffer(diffBuffer, offset: 0, index: 2)
        differenceComputeCommandEncoder.setComputePipelineState(differencePipelineState)
        
        let differenceThreadExecutionWidth = differencePipelineState.threadExecutionWidth
        NSLog("threadExecutionWidth: %d", differenceThreadExecutionWidth)
        let differenceThreadsPerGroup = MTLSize(width: differenceThreadExecutionWidth, height: 1, depth: 1)
        
        let differenceNumThreadGroups = MTLSize(width: /*1*/(length/4/*+threadExecutionWidth*/)/differenceThreadExecutionWidth, height: 1, depth: 1)
        differenceComputeCommandEncoder.dispatchThreadgroups(differenceNumThreadGroups, threadsPerThreadgroup: differenceThreadsPerGroup)
        differenceComputeCommandEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        
        
        let maxNumThreads = 128
        
        guard let maxValueBuffer = device.makeBuffer(length: maxNumThreads, options: .storageModeShared) else {
            NSLog("Cannot make result buffer")
            return
        }
        
        guard let maxIndexBuffer = device.makeBuffer(length: maxNumThreads*4, options: .storageModeShared) else {
            NSLog("Cannot make result buffer")
            return
        }
        
        guard let maxFunction = library.makeFunction(name: "max") else {
            NSLog("Cannot make max function")
            return
        }
        
        guard let maxCommandBuffer = commandQueue.makeCommandBuffer() else {
            NSLog("Cannot make command buffer")
            return
        }
        
        guard let maxComputeCommandEncoder = maxCommandBuffer.makeComputeCommandEncoder() else {
            NSLog("Cannot make max compute command encoder")
            return
        }
        
        var maxComputePipelineState: MTLComputePipelineState?
        do {
            maxComputePipelineState = try device.makeComputePipelineState(function: maxFunction)
        } catch {
            NSLog("Error making compute pipeline state")
            maxComputeCommandEncoder.endEncoding()
            return
        }
        
        guard let maxPipelineState = maxComputePipelineState else {
            NSLog("No compute pipeline state")
            maxComputeCommandEncoder.endEncoding()
            return
        }
        
        maxComputeCommandEncoder.setBuffer(diffBuffer, offset: 0, index: 0)
        maxComputeCommandEncoder.setBuffer(maxValueBuffer, offset: 0, index: 1)
        maxComputeCommandEncoder.setBuffer(maxIndexBuffer, offset: 0, index: 2)
        maxComputeCommandEncoder.setComputePipelineState(maxPipelineState)
        
        let maxThreadExecutionWidth = maxPipelineState.threadExecutionWidth
        NSLog("threadExecutionWidth: %d", maxThreadExecutionWidth)
        let maxThreadsPerGroup = MTLSize(width: differenceThreadExecutionWidth, height: 1, depth: 1)
        
        let maxNumThreadGroups = MTLSize(width: 4, height: 1, depth: 1)
        maxComputeCommandEncoder.dispatchThreadgroups(maxNumThreadGroups, threadsPerThreadgroup: maxThreadsPerGroup)
        maxComputeCommandEncoder.endEncoding()
        
        maxCommandBuffer.commit()
        maxCommandBuffer.waitUntilCompleted()
        
        var maxValue: UInt8 = 0
        var maxIndex = 0
        let maxValueArray: UnsafeMutablePointer<UInt8> = maxValueBuffer.contents().assumingMemoryBound(to: UInt8.self)
        let maxIndexArray: UnsafeMutablePointer<Int> = maxIndexBuffer.contents().assumingMemoryBound(to: Int.self)
        for i in 0..<maxNumThreads {
            if maxValueArray[i] > maxValue {
                maxValue = maxValueArray[i]
                maxIndex = maxIndexArray[i]
            }
        }
        
        NSLog("max value: %d at index: %d", maxValue, maxIndex)
        


    }
    
    
    
    
    
    
    
    
    

//    lazy var imageQueue = DispatchQueue(label: "imagequeue", qos: .utility, attributes: [], autoreleaseFrequency: .workItem, target: nil)
//    let numImageWorkPartitions = 20
//    func add(imageData: Data) {
//
//
//        let bufferSize = 2
//        imageDataArray.append(imageData)
//        while imageDataArray.count > bufferSize {
//            imageDataArray.remove(at: 0)
//        }
//        imageQueue.sync {
//            let imageGroup = DispatchGroup()
//        if self.imageDataArray.count >= bufferSize {
////            let imageDataArrayCopy = imageDataArray.map { (data) -> Data in
////                return data
////            }
//
//                let byteCount = self.imageDataArray[0].count
//                var diffData = Data(count: byteCount)//Data(count: byteCount)
//                for imageIndex in 1..<self.imageDataArray.count {
//                    let currentImageData = self.imageDataArray[imageIndex]
//                    let partitionSize = currentImageData.count / numImageWorkPartitions
//                    let prevImageData = self.imageDataArray[imageIndex-1]
//                    //for pixelIndex in 0..<currentImageData.count {
//                    for partitionIndex in 0..<2/*numImageWorkPartitions*/ {
//                        imageGroup.enter()
//                        DispatchQueue.global(qos: .userInitiated).async {
//                            for pixelIndex in partitionIndex*partitionSize..<(partitionIndex+1)*partitionSize {
//
//                                let prevPixel = prevImageData[pixelIndex]
//                                let currPixel = currentImageData[pixelIndex]
//                                let diff:UInt8 = UInt8(abs(Int(currPixel) - Int(prevPixel)))
//                       // if diff > diffData[pixelIndex] {
//
//
//                                NSLog("%d pixelIndex: %d", partitionIndex, pixelIndex)
//                                NSLog("%d diffData.count: %d", partitionIndex, diffData.count)
//
//                                diffData[pixelIndex] = diff
//                            }
//                            imageGroup.leave()
//                        }
//                       // }
//                    }
//                }
//                imageGroup.wait()
//
//                var largestDiffValue:UInt8 = 0
//                var largestDiffIndex = 0
//                for pixelIndex in 0..<byteCount {
//                    if diffData[pixelIndex] > largestDiffValue {
//                        largestDiffIndex = pixelIndex
//                        largestDiffValue = diffData[pixelIndex]
//                    }
//                }
//
//                let x = largestDiffIndex % self.width
//                let y = largestDiffIndex / self.width
//
//                NSLog("largest diff x: \(x), y: \(y)")
//
//
//            }
//        }
//
//    }
    
}
