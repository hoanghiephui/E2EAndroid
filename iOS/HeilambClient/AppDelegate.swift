//
//  AppDelegate.swift
//  HeilambClient
//
//  Created by Sinbad Flyce on 5/11/16.
//  Copyright © 2016 YusufX. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var navigation : UINavigationController!
    var window: UIWindow?

    func checkHaveEverSignedUp() -> Bool {
        return (DyUser.currentUser != nil)
    }
    
    func initNavigation() -> Bool {
        if let w = self.window {
            if let nvc = w.rootViewController {
                self.navigation = nvc as? UINavigationController;
            } else {
                return false;
            }
        } else {
            return false;
        }
        return true;
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        if self.initNavigation() == false {
            return false;
        }
        
        if let rvc = self.navigation.viewControllers.first {
            if self.checkHaveEverSignedUp() {
                DyUser.currentUser?.fetch({ (object) in
                    rvc.performSegueWithIdentifier("root_to_login", sender: self.navigation);
                })
            } else {
                rvc.performSegueWithIdentifier("root_to_signup", sender: self.navigation);
            }
        } else {
            return false
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

