//
//  AppDelegate.swift
//  Virtual Tourist
//
//  Created by John Clema on 27/04/2016.
//  Copyright © 2016 JohnClema. All rights reserved.
//

import UIKit



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let dataStack = CoreDataStackManager(modelName: "Model")!


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
}

