//
//  ViewController.swift
//  LightAnchors
//
//  Created by Nick Wilkerson on 12/4/18.
//  Copyright © 2018 Wiselab. All rights reserved.
//

import UIKit
import ARKit
import VideoToolbox

class ViewController: UIViewController {

    let sceneView = ARSCNView()
    let scene = SCNScene()
    
    let trackingStateLabel = UILabel()
    
    let locationView = LocationView(frame: CGRect.zero)
    let colorView = UIView()
    
    var targetPoint3d: SCNVector3?
 //   var lastFrame: ARFrame?
    var sphereNode = SCNNode()
    
    var planes = [ARPlaneAnchor: Plane]()
    
    var lightDecoder = LightDecoder()
    
    let fileNameDateFormatter = DateFormatter()
    
    init () {
        super.init(nibName: nil, bundle: nil)
        
        fileNameDateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss-SSS"
        
        sceneView.scene = scene
        sceneView.delegate = self
        sceneView.session.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = UIView()
        
        view.addSubview(sceneView)
        
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        view.addSubview(locationView)
        locationView.translatesAutoresizingMaskIntoConstraints = false
        locationView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        locationView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        locationView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        locationView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        view.addSubview(trackingStateLabel)
        trackingStateLabel.translatesAutoresizingMaskIntoConstraints = false
        trackingStateLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30).isActive = true
        trackingStateLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10).isActive = true
        trackingStateLabel.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        trackingStateLabel.heightAnchor.constraint(equalToConstant: 50)
        
        view.addSubview(colorView)
        colorView.translatesAutoresizingMaskIntoConstraints = false
        colorView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.25).isActive = true
        colorView.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2).isActive = true
        colorView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
        colorView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30).isActive = true
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(gestureRecognizer:)))
        view.addGestureRecognizer(tapGestureRecognizer)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        configuration.planeDetection = .horizontal//[.horizontal, .vertical]
        configuration.worldAlignment = /*.gravity*/.gravityAndHeading//based on compass
        sceneView.debugOptions = [.showWorldOrigin, .showFeaturePoints/*.showWireframe*/]
        // Run the view's session
        sceneView.session.run(configuration)
        
        let sphere = createSphere(at: SCNVector3(x: 0, y: 0, z: 1), color: UIColor.yellow)
        scene.rootNode.addChildNode(sphere)
        
        trackingStateLabel.textColor = UIColor.red
        
        colorView.backgroundColor = UIColor.red

    }

    
    @objc func handleTap(gestureRecognizer: UITapGestureRecognizer) {
        NSLog("handleTap")
        let tapLocation = gestureRecognizer.location(in: sceneView)
        NSLog("Tap Location x: \(tapLocation.x), y: \(tapLocation.y)")
//        if let frame = lastFrame {
            let results = sceneView.hitTest(tapLocation, types: [/*.existingPlaneUsingGeometry, .existingPlane, */.existingPlaneUsingExtent, .estimatedHorizontalPlane, .estimatedVerticalPlane])
            NSLog("number of hit test results: \(results.count)")
            if let result = results.last {
                
//                let x = result.worldTransform.columns.3[0]
//                let y = result.worldTransform.columns.3[1]
//                let z = result.worldTransform.columns.3[2]
//                let transform = SCNMatrix4.init(result.worldTransform)
                let x = result.worldTransform.columns.3.x//transform.m41
                let y = result.worldTransform.columns.3.y//transform.m42
                let z = result.worldTransform.columns.3.z//transform.m43
                targetPoint3d = SCNVector3(x: x, y: y, z: z)
                NSLog("targetPoint3d x: \(x), y: \(y), z: \(z)")
                if let location = targetPoint3d {
                    sphereNode.removeFromParentNode()
                    sphereNode = createSphere(at: location, color: UIColor.green)
                    scene.rootNode.addChildNode(sphereNode)
                }
            }
 //       }
        
        
        
    }
    
    
    
    func createSphere(at location: SCNVector3, color: UIColor) -> SCNNode{
        let sphereGeometry = SCNSphere(radius: 0.03)
        let sphereMaterial = SCNMaterial()
        sphereMaterial.diffuse.contents = color.cgColor
        sphereMaterial.locksAmbientWithDiffuse = true
        sphereGeometry.materials = [sphereMaterial]
        let sphereNode = SCNNode(geometry: sphereGeometry)
        sphereNode.position = location
        return sphereNode
    }

    func addPlane(node: SCNNode, anchor: ARPlaneAnchor) {
        let plane = Plane(anchor)
        planes[anchor] = plane
        node.addChildNode(plane)
    }
    
    func updatePlane(anchor: ARPlaneAnchor) {
        if let plane = planes[anchor] {
            plane.update(anchor)
        }
    }
    
    
    func savePixelBuffer(_ buffer: CVPixelBuffer) {
        let now = Date()
        let dateString = fileNameDateFormatter.string(from: now)
        let fileName = String(format: "%@.gray", dateString)
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let filePath = paths.first?.appendingPathComponent(fileName) {
            let format = CVPixelBufferGetPixelFormatType(buffer)
            let width = CVPixelBufferGetWidth(buffer)
            let height = CVPixelBufferGetHeight(buffer)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
            
            NSLog("pixelBuffer width: %d, height: %d, format: \(format), bytes per row: \(bytesPerRow) ", width, height)
            
            let grayPlaneHeight = 1920
            let grayPlaneWidth = 1440
            var grayPlaneIndex = 0
            let planeCount = CVPixelBufferGetPlaneCount(buffer)
            for planeIndex in 0..<planeCount {
                let planeHeight = CVPixelBufferGetHeightOfPlane(buffer, planeIndex)
                let planeWidth = CVPixelBufferGetWidthOfPlane(buffer, planeIndex)
                if planeWidth == grayPlaneWidth && planeHeight == grayPlaneHeight {
                    grayPlaneIndex = planeIndex
                }
            }
    
            let numGrayBytes = grayPlaneHeight*grayPlaneWidth
            
            CVPixelBufferLockBaseAddress(buffer, .readOnly)
            //let dataSize = CVPixelBufferGetDataSize(frame.capturedImage)
            NSLog("dataSize: %d", numGrayBytes)
            if let baseAddressGray = CVPixelBufferGetBaseAddressOfPlane(buffer, grayPlaneIndex) {
                NSLog("frame.captureImage: \(buffer)\n\n")
                NSLog("baseAddress: \(baseAddressGray)")
                let bufferData = Data(bytes: baseAddressGray, count: numGrayBytes)
                do {
                    try bufferData.write(to: filePath)
                } catch {
                    NSLog("error writing to file")
                }
            }
            CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
        }
        
    }
    
}




extension ViewController: ARSCNViewDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    /*
     Called when a SceneKit node corresponding to a
     new AR anchor has been added to the scene.
     */
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.addPlane(node: node, anchor: planeAnchor)
            }
        }
    }

    
    
    /*
     Called when a SceneKit node's properties have been
     updated to match the current state of its corresponding anchor.
     */
    func renderer(_ renderer: SCNSceneRenderer,
                  didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            updatePlane(anchor: planeAnchor)
        }
    }
    
    /*
     Called when SceneKit node corresponding to a removed
     AR anchor has been removed from the scene.
     */
    func renderer(_ renderer: SCNSceneRenderer,
                  didRemove node: SCNNode, for anchor: ARAnchor) {
        // ...
    }
    
    
    
}



extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        savePixelBuffer(frame.capturedImage)
            
            
//            CVPixelBufferLockBaseAddress(frame.capturedImage, .readOnly)
//            let dataSize = CVPixelBufferGetDataSize(frame.capturedImage)
//            NSLog("dataSize: %d", dataSize)
//            if let baseAddress = CVPixelBufferGetBaseAddress(frame.capturedImage) {
//                NSLog("frame.captureImage: \(frame.capturedImage)\n\n")
//                NSLog("baseAddress: \(baseAddress)")
//                let bufferData = Data(bytes: baseAddress, count: dataSize)
//                do {
//                    try bufferData.write(to: filePath)
//                } catch {
//                    NSLog("error writing to file")
//                }
//            }
//            CVPixelBufferUnlockBaseAddress(frame.capturedImage, .readOnly)
    //    }
      //  let ciImage = CIImage(cvPixelBuffer: frame.capturedImage)
        NSLog("new frame")

//        lightDecoder.add(coreImage: ciImage)
//        if let capturedDepthDataBuffer: AVDepthData = frame.capturedDepthData {
//            
//        }
//        
//        let imageWidth = CVPixelBufferGetWidth(capturedImageBuffer)
//        let imageHeight = CVPixelBufferGetHeight(capturedImageBuffer)
//        let bytesPerRow = CVPixelBufferGetBytesPerRow(capturedImageBuffer)

        
//        let coreImage = CIImage(cvPixelBuffer: capturedImageBuffer)
//        let context = CIContext(options: nil)
//        let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
//        let uiImage = UIImage(cgImage: cgImage!)
        
        

        
        
  

//            var cgImage: CGImage?
//            VTCreateCGImageFromCVPixelBuffer(capturedImageBuffer, options: nil, imageOut: &cgImage)
//            DispatchQueue.global(qos: .background).async {
//                if let cg = cgImage {
//                    NSLog("adding image")
//
//                    
//                
//                    let uiImage = UIImage(cgImage: cg)
//                //lightDecoder.add(image: uiImage)
//                    let croppedImage = uiImage.croppedImage(inRect: CGRect(x: uiImage.size.width/3, y: uiImage.size.height/3, width: uiImage.size.width/3, height: uiImage.size.height/3))
//           
//                    self.lightDecoder.add(image: croppedImage)
//                    //uiImage.saveToFile(named: fileName)
//                    
//                    //croppedImage.saveToFile(named: fileName)
//                }
//            }
        

        
        
        
        //        let image = UIImage(ciImage: coreImage)
    
        
//        NSLog("imageWidth: \(imageWidth)")
//        NSLog("imageHeight: \(imageHeight)")
//        NSLog("bytes per row: \(bytesPerRow)")
//
//  //      lastFrame = frame
//        if let point3d = targetPoint3d {
//            let point2dV = sceneView.projectPoint(point3d)
//            //NSLog("x: %f, y: %f, z: %f", point2dV.x, point2dV.y, point2dV.z)
//            let point2dInView = CGPoint(x: CGFloat(point2dV.x), y: CGFloat(point2dV.y))
//
//            var currentDevice: UIDevice = UIDevice.current
//            var orientation: UIDeviceOrientation = currentDevice.orientation
//
//
//            if let image = cgImage {
//
//                let imageWidth = image.width
//                let imageHeight = image.height
//
//                let pointInImage = CGPoint(x: point2dInView.x/sceneView.frame.size.width*CGFloat(imageWidth), y: point2dInView.y/sceneView.frame.size.height*CGFloat(imageHeight))
//
//                NSLog("cgImage width: \(image.width)")
//                NSLog("cgImage height: \(image.height)")
//
//
//
//                let bytesPerPixel = 4
//                let bytesPerRow = bytesPerPixel * imageWidth
//                let bitsPerComponent = 8
//
//                let pixelSizeInBytes:Int = 4
//                let pixels: UnsafeMutablePointer<UInt32> = calloc(imageHeight*imageWidth, pixelSizeInBytes).assumingMemoryBound(to: UInt32.self)
//               // let pixels = UnsafeMutablePointer<UInt32>.allocate(capacity: height*width)
//
//                let colorSpace = CGColorSpaceCreateDeviceRGB()
//                let context = CGContext(data: pixels, width: imageWidth, height: imageHeight, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)//kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big
//
//                context?.draw(image, in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
//                var pixel:UInt32 = 0
//                if orientation == .portrait || orientation == .portraitUpsideDown {
//                    pixel = pixels[Int(pointInImage.y*CGFloat(imageWidth))+Int(pointInImage.x)]
//                } else {
//                    pixel = pixels[Int(pointInImage.x*CGFloat(imageWidth))+Int(pointInImage.y)]
//                }
//                let red = (pixel >> 24) & 0xFF
//                let green = (pixel >> 16) & 0xFF
//                let blue = (pixel >> 8) & 0xFF
//                let alpha = pixel & 0xFF
//
//                NSLog("red: \(red) green: \(green) blue: \(blue) alpha: \(alpha)")
//
//                free(pixels)
//
//            }
//
//            DispatchQueue.main.async {
//                self.locationView.move(to: point2dInView)
//            }
//        }
    }
    
    
    /**
     This is called when new anchors are added to the session.
     
     @param session The session being run.
     @param anchors An array of added anchors.
     */
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        
    }
    
    
    /**
     This is called when anchors are updated.
     
     @param session The session being run.
     @param anchors An array of updated anchors.
     */
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        
    }
    
    
    /**
     This is called when anchors are removed from the session.
     
     @param session The session being run.
     @param anchors An array of removed anchors.
     */
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        let trackingState = camera.trackingState
        let cameraTrackingState = camera.trackingState
                switch (trackingState) {
                case .normal:
                    trackingStateLabel.text = "Normal"
                   // NSLog("ARTrackingStateNormal")
                case.limited(let reason):
                    trackingStateLabel.text = "Limited: \(reason)"
                    //NSLog("ARTrackingStateLimited: \(reason)")
                case.notAvailable:
                    trackingStateLabel.text = "Not Available"
                    //NSLog("ARTrackingStateNotAvailable")
        
                }
        
    }
    

}



extension UIImage {
    func saveToFile(named fileName: String) {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let filePath = paths.first?.appendingPathComponent(fileName) {
            // Save image.
            do {
                try self.pngData()?.write(to: filePath, options: .atomic)
            }
            catch {
                // Handle the error
            }
        }
    }
    
    
    func croppedImage(inRect rect: CGRect) -> UIImage {
        let rad: (Double) -> CGFloat = { deg in
            return CGFloat(deg / 180.0 * .pi)
        }
        var rectTransform: CGAffineTransform
        switch imageOrientation {
        case .left:
            let rotation = CGAffineTransform(rotationAngle: rad(90))
            rectTransform = rotation.translatedBy(x: 0, y: -size.height)
        case .right:
            let rotation = CGAffineTransform(rotationAngle: rad(-90))
            rectTransform = rotation.translatedBy(x: -size.width, y: 0)
        case .down:
            let rotation = CGAffineTransform(rotationAngle: rad(-180))
            rectTransform = rotation.translatedBy(x: -size.width, y: -size.height)
        default:
            rectTransform = .identity
        }
        rectTransform = rectTransform.scaledBy(x: scale, y: scale)
        let transformedRect = rect.applying(rectTransform)
        let imageRef = cgImage!.cropping(to: transformedRect)!
        let result = UIImage(cgImage: imageRef, scale: scale, orientation: imageOrientation)
        return result
    }
    
}

