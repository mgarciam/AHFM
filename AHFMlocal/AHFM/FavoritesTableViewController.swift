//
//  FavoritesTableViewController.swift
//  AHFM
//
//  Created by Marilyn on 5/29/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import UserNotifications

class FavoritesTableViewController: UITableViewController {
    
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    var context: CoreDataStack!
    
    lazy var songDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    class func newFavoritesVC(context: CoreDataStack) -> FavoritesTableViewController {
        let favorites = UIStoryboard(name: "Favorites", bundle: nil).instantiateInitialViewController() as! FavoritesTableViewController
        favorites.context = context
        return favorites
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let now = NSDate()
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SongInfo")
        request.predicate = NSPredicate(format: "(favorite == true) OR ((notification == true) AND (beginsAt > %@))", now)
        let nameSort = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [nameSort]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context.mainContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            
            self.tableView.visibleCells.forEach { (cell) in
                let songCell = cell as! SongCell
                songCell.layoutIfNeeded()
                songCell.leadingHoursSeparatorConstraint.constant = -10
                UIView.animate(withDuration: 0.33) {
                    songCell.layoutIfNeeded()
                }
            }
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(requestUpdateFromDataSource),
                                               name: Notification.Name(schedule: .didUpdate),
                                               object: nil)

    }
    
    func requestUpdateFromDataSource() {
        try? fetchedResultsController?.performFetch()
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let sections = fetchedResultsController.sections else {
            return 0
        }
        
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections else {
            return 0
        }
        
        return sections[section].numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SongCell
        let song = self.fetchedResultsController?.object(at: indexPath) as! SongInfo
        let beginHour = songDateFormatter.string(from: song.beginsAt! as Date)
        let endHour = songDateFormatter.string(from: song.endsAt! as Date)
        
        cell.nameLabel.text = song.name!
        cell.beginHourLabel.text = beginHour
        cell.endHourLabel.text = endHour
        cell.infoDelegate = self
        return cell
    }
}

extension FavoritesTableViewController : SongInfoDelegate {
    func showInfo(_ cell: SongCell) {
        
        guard let managedObjectIndexPath = tableView.indexPath(for: cell) else { return }
        let song = self.fetchedResultsController?.object(at: managedObjectIndexPath) as! SongInfo
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: song.favorite ? "Unfavorite" : "Favorite", style: .default) { action in
            
            guard let songContext = song.managedObjectContext else { return }
            
            songContext.perform {
                song.favorite = !song.favorite
                self.context.save(context: songContext)
            }
        })
        
        alert.addAction(UIAlertAction(title: song.notification ? NSLocalizedString("Unnotify me", comment: "") : NSLocalizedString("Notify me", comment: ""), style: .default) { action in
            
            let request = NSFetchRequest<SongInfo>(entityName: "SongInfo")
            let fetchedSongs = try? self.context.mainContext.fetch(request)
            let now = Date()
            
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
                (granted, error) in
                if !granted {
                    print("error")
                }
            }
            
            var matchingSong: SongInfo!
            fetchedSongs?.forEach { fetchedSong in
                if song.name! == fetchedSong.name! && fetchedSong.beginsAt! as Date > now {
                    matchingSong = fetchedSong
                }
            }
            
            let content = UNMutableNotificationContent()
            let calendar = NSCalendar.current
            let triggerDate = calendar.dateComponents([.month, .day, .year, .hour, .minute], from: matchingSong.beginsAt! as Date)
            content.title = matchingSong.name!
            content.body = "Is playing now!"
            content.sound = UNNotificationSound.default()
            let _ = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            
            guard let songContext = song.managedObjectContext else { return }
            
            songContext.perform {
                song.notification = !song.notification
                self.context.save(context: songContext)
            }

        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true, completion: nil)
    }
}


extension FavoritesTableViewController : NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .move:
            break
        case .update:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
