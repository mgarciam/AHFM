//
//  AppDelegate.swift
//  AHFM
//
//  Created by Marilyn on 5/23/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let coreDataStack = CoreDataStack()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // Initializes the StreamVC to set its context as an instance of CoreDataStack.
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
                        NotificationCenter.default.post(name: NSNotification.Name(schedule: .didUpdate),
                                                        object: nil)
                    }
                }
            }
        }
        application.applicationIconBadgeNumber = 0
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}
