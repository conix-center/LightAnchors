//
//  AppDelegate.swift
//  LightAnchors
//
//  Created by Nick Wilkerson on 12/4/18.
//  Copyright © 2018 Wiselab. All rights reserved.
//

import UIKit
import ARKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow()
        let viewController = ViewController()
        let navController = UINavigationController(rootViewController: viewController)
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
        

        let intrinsics = simd_float3x3(float3(900, 0, 0), float3(0, 900, 0), float3(640, 360, 1))
        let cameraTransform = simd_float4x4(float4(0,0,1,0), float4(0,1,0,0), float4(-1,0,0,0), float4(0,0,1,1))
        
//        let anchorPoints = [AnchorPoint(location3d: SCNVector3(1,1,-5), location2d: CGPoint(x: 820,y: 360)),
//                            AnchorPoint(location3d: SCNVector3(2,1,-5), location2d: CGPoint(x: 1000, y: 360)),
//                            AnchorPoint(location3d: SCNVector3(3,0,-5), location2d: CGPoint(x: 1180, y: 540)),
//                            AnchorPoint(location3d: SCNVector3(2,0,-3), location2d: CGPoint(x: 1240,y: 660))]
 
        let anchorPoints = [AnchorPoint(location3d: SCNVector3(1,1,-5), location2d: CGPoint(x: 838.3,y: 378.6)),
                            AnchorPoint(location3d: SCNVector3(2,1,-5), location2d: CGPoint(x: 986.3, y: 378.8)),
                            AnchorPoint(location3d: SCNVector3(3,0,-5), location2d: CGPoint(x: 1198.3, y: 539.4)),
                            AnchorPoint(location3d: SCNVector3(2,0,-3), location2d: CGPoint(x: 1252.0,y: 645.7))]
        
        let locSolver = LocationSolver()
        locSolver.solveForLocation(intrinsics: intrinsics, cameraTransform: cameraTransform, anchorPoints: anchorPoints) { (transform, success) in
            NSLog("transform success: %@", success ? "true" : "false")
            for i in 0..<4 {
                print(String(transform.columns.0[i]) + "\t\t" + String(transform.columns.1[i]) + "\t\t" + String(transform.columns.2[i]) + "\t\t" + String(transform.columns.3[i]))
            }
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

