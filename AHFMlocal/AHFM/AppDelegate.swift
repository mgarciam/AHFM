//
//  AppDelegate.swift
//  AHFM
//
//  Created by Marilyn on 5/23/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import UIKit
import CoreData

extension NSNotification.Name {
    
    enum ScheduleNotifications {
        case didUpdate
        
        var rawValue: String {
            switch self {
            case .didUpdate:
                return "ScheduleNotificationDidUpdate"
            }
        }
    }
    
    init(schedule: ScheduleNotifications) {
        self = NSNotification.Name(rawValue: schedule.rawValue)
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let coreDataStack = CoreDataStack()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        let controller = window!.rootViewController as! UINavigationController
        let streamingVC = controller.topViewController as! StreamViewController
        
        streamingVC.context = coreDataStack
        
        ScheduleViewModel.download(URL(string: "http://ah.fm/stats/mobileschedule.txt")!) { status in
            switch status {
                
            case .failureDataIsNil, .failureDataIsNotString:
                print("Data error")
                
            case .failureNetworkError(let downloadError):
                print("Download Error: \(downloadError)")
                
            case .success(let schedule):
                DispatchQueue.global(qos: .userInteractive).async {
                    guard let parsedSongs = try? ScheduleViewModel.parse(schedule: schedule as NSString) else { return }
                    self.coreDataStack.save(songs: parsedSongs, context: self.coreDataStack.mainContext) {
                        NotificationCenter.default.post(name: NSNotification.Name.init(schedule: .didUpdate),
                                                        object: nil)
                    }
                }
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
        // Saves changes in the application's managed object context before the application terminates.
    }
}

