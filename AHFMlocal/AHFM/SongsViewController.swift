//
//  FetchedResultsTableViewController.swift
//  AHFM
//
//  Created by Marilyn on 6/23/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import UserNotifications

class SongsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, UNUserNotificationCenterDelegate {
    
    var context: CoreDataStack!
    
    @IBOutlet weak var tableView: UITableView!
    
    var requestPredicate: NSPredicate {
        return NSPredicate()
    }
    
    var requestSortDescriptors: [NSSortDescriptor] {
        return []
    }

    lazy var songFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        let request = NSFetchRequest<SongInfo>(entityName: "SongInfo")
        request.predicate = self.requestPredicate
        request.sortDescriptors = self.requestSortDescriptors
        return NSFetchedResultsController(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult>, managedObjectContext: self.context.mainContext, sectionNameKeyPath: nil, cacheName: nil)
    }()
  
    lazy var songDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(requestUpdateFromDataSource),
                                               name: Notification.Name(schedule: .didUpdate),
                                               object: nil)
        
        UNUserNotificationCenter.current().delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        requestUpdateFromDataSource()
    }
    
    func requestUpdateFromDataSource() {
        do {
            songFetchedResultsController.fetchRequest.predicate = requestPredicate
            try songFetchedResultsController.performFetch()
            tableView.reloadData()
        } catch {
            fatalError()
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let sections = songFetchedResultsController.sections else {
            return 0
        }
        
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = songFetchedResultsController.sections else {
            return 0
        }
        
        return sections[section].numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SongCell
        let song = self.songFetchedResultsController.object(at: indexPath) as! SongInfo
        let beginHour = songDateFormatter.string(from: song.beginsAt! as Date)
        let endHour = songDateFormatter.string(from: song.endsAt! as Date)
        
        cell.panGesture.delegate = self
        cell.nameLabel.text = song.name!
        cell.beginHourLabel.text = beginHour
        cell.endHourLabel.text = endHour
        cell.infoDelegate = self
        return cell
    }
}

extension SongsViewController : SongInfoDelegate {
    func songInfo(for cell: SongCell) -> SavedSong? {
        guard let indexPath = tableView.indexPath(for: cell) else { return nil }
        
        return SavedSong(song: self.songFetchedResultsController.object(at: indexPath) as! SongInfo)
    }
}
