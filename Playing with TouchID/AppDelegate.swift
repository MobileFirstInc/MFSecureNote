//
//  AppDelegate.swift
//  Playing with TouchID
//
//  Created by Varad Pathak on 12/10/16.
//  Copyright © 2016 Varad Pathak. All rights reserved.
//  Copyright © 2016 MobileFirst (http://mobilefirst.in)

//

import UIKit
import IQKeyboardManagerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var isLaunchedFromQuickAction = false
    
    // For reloading tableview after coming from shortcut
    var didComeFromShortcut: Bool = false
    
    enum Shortcut: String {
        case addNote = "AddNote"
    }
    
    var window: UIWindow?
    
    var isShortcut: Bool = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        print("didFinishLaunchingWithOptions called")
        isLaunchedFromQuickAction = false
        
        // Check if it's launched from Quick Action
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            
            isShortcut = true
            
            isLaunchedFromQuickAction = true
            // Handle the sortcutItem
            handleQuickAction(shortcutItem: shortcutItem)
        }
        else {
            
            //self.window?.backgroundColor = UIColor.white
            print("Normal Launching")
        }
        
        // Return false if the app was launched from a shortcut, so performAction... will not be called.
        return !isLaunchedFromQuickAction
        
        IQKeyboardManager.sharedManager().enable = true
        
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
        
        isLaunchedFromQuickAction = false
        
        // Check if it's launched from Quick Action
        
        if (application.applicationState.rawValue == 2) {
            
            isShortcut = true
            
            isLaunchedFromQuickAction = true
            
            //handleQuickAction(shortcutItem: shortcutItem)
        }
        else {
            
            //self.window?.backgroundColor = UIColor.white
            print("Normal Launching")
        }

//        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
//            
//            
//            // Handle the sortcutItem
//            
//        }
        
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        
        completionHandler(handleQuickAction(shortcutItem: shortcutItem))
    }
    
    func handleQuickAction(shortcutItem: UIApplicationShortcutItem) -> Bool {
        
        var quickActionHandled = false
        let type = shortcutItem.type.components(separatedBy: ".").last!
        
        if let shortcutType = Shortcut.init(rawValue: type) {
            
            switch shortcutType {
            case .addNote:
                
                didComeFromShortcut = true
                
                self.window = UIWindow(frame: UIScreen.main.bounds)
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                
                let initialViewController = storyboard.instantiateViewController(withIdentifier: "navVC") as! UINavigationController
                
                let vc = storyboard.instantiateViewController(withIdentifier: "EditNotesViewController") as! EditNotesViewController
                
                initialViewController.pushViewController(vc, animated: true)
                
                
                self.window?.rootViewController = initialViewController
                self.window?.makeKeyAndVisible()

                
                //self.window?.backgroundColor = UIColor(red: 151.0/255.0, green: 187.0/255.0, blue: 255.0/255.0, alpha: 1.0)
                quickActionHandled = true
            }
        }
        
        return quickActionHandled
    }
    
    // MARK: GET DOCUMENTS DIRECTORY PATH AND CHECK FOR ITS PATH
    func getPathOfDataFile() -> String {
        
        let pathArray = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        
        let documentsPath = pathArray[0] as String
        
        // Extension used for below line. See Below...
        let dataFilePath = documentsPath.stringByAppendingPathComponent(path: "notesData")
        
        print(dataFilePath)
        
        return dataFilePath
    }
    
    func checkIfDataFileExists() -> Bool {
        
        if (FileManager.default.fileExists(atPath: getPathOfDataFile())) {
            
            return true
        }
        
        return false
    }
}


// Extension used for stringByAppendingPathComponent
extension String {
    
    func stringByAppendingPathComponent(path: String) -> String {
        
        let nsSt = self as NSString
        
        return nsSt.appendingPathComponent(path)
    }
}

