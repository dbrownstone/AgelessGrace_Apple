//
//  AppDelegate.swift
//  AgelessGrace
//
//  Created by David Brownstone on 21/12/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit
import AVFoundation

var appDelegate = (UIApplication.shared).delegate as! AppDelegate
var standardDefaults = UserDefaults.standard
var datastore:DatastoreProtocol = SharedUserDefaultsDatastore()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var mediaAuthorized = false
    var backgroundEntryDate:Date!
    var toolInfoPath: String!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        var config : SwiftActivity.Config = SwiftActivity.Config()
        config.size = 200
        config.spinnerColor = .magenta
        config.spinnerLineWidth = 3
        config.backgroundColor = .clear
        SwiftActivity.setConfig(config: config)
        
        self.toolInfoPath = Bundle.main.path(forResource: "Localizable", ofType: "plist")
        
        if let tabBarController = self.window!.rootViewController as? UITabBarController {
            //Note that if this is the initial use, we will set the settings defaults
            if userDefaults.object(forKey: "StartingDate")  == nil && datastore.shouldExerciseDaily() {
                datastore.setShouldExerciseDaily(true)
                datastore.setPauseBetweenTools(true)
                datastore.setShouldNotStartExerciseImmediately(true)
                tabBarController.selectedIndex = 1
            }
        }
        
        return true
    }
    
    func getRequiredArray(_ array: String) -> [String] {
        var result: Array<String> = []
        if let plistDictionary = NSDictionary(contentsOfFile: self.toolInfoPath) {
            let toolInfo = plistDictionary.value(forKeyPath: "ToolInfo") as! Dictionary<String, Any>
            result = toolInfo[array] as! Array<String>
        }
        return result
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        if audioPlayer.isCurrentlyPlaying {
            audioPlayer.pauseTheMusicPlayer()
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        if audioPlayer.isCurrentlyPaused {
            audioPlayer.resumeTheMusicPlayer()
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:
        if audioPlayer.isCurrentlyPlaying {
            audioPlayer.stopMusicPlayerNotifications()
            audioPlayer.stopPlayingAudio()
        }
    }
}

extension UIDevice {
    static var isSimulator: Bool = {
        var isSimulator = false
        #if targetEnvironment(simulator)
        isSimulator = true
        #endif
        return isSimulator
    }()
}

