//
//  FavoritesTableViewController.swift
//  AHFM
//
//  Created by Marilyn on 5/29/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

class FavoritesTableViewController: UITableViewController, UIGestureRecognizerDelegate {
    
    var favorites = [SavedSong]()
    var notifications = [SavedSong]()
    
    lazy var songDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    class func newFavoritesVC(context: CoreDataStack) -> FavoritesTableViewController {
        let favorites = UIStoryboard(name: "Favorites", bundle: nil).instantiateInitialViewController() as! FavoritesTableViewController
        return favorites
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        favorites = UserDefaults.standard.favorites
        notifications = UserDefaults.standard.notifications
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateContent),
                                               name: Notification.Name.init(notification: .didUpdateFavorites),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateContent),
                                               name: Notification.Name.init(notification: .didUpdateNotifications),
                                               object: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            
            self.tableView.visibleCells.forEach { (cell) in
                let songCell = cell as! SongCell
                songCell.animateCellLabels()
            }
        }
    }
    
    func updateContent() {
        DispatchQueue.main.async {
            self.favorites = UserDefaults.standard.favorites
            self.notifications = UserDefaults.standard.notifications
            UIView.transition(with: self.tableView,
                              duration: 0.35,
                              options: .transitionCrossDissolve,
                              animations: { self.tableView.reloadData() })
        }
    }
    
    fileprivate func array(section: Int) -> [SavedSong] {
        
        guard favorites.isEmpty && !notifications.isEmpty else {
            guard !favorites.isEmpty && notifications.isEmpty else {
                guard section == 0 else {
                    return favorites
                }
                return notifications
            }
            return favorites
        }
        return notifications
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        let favoritesSectionExists = favorites.isEmpty ? 0 : 1
        let notificationsSectionExists = notifications.isEmpty ? 0 : 1
        return favoritesSectionExists + notificationsSectionExists
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if favorites.isEmpty && notifications.isEmpty {
            return 0
        }
        tableView.endUpdates()
        return array(section: section).count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SongCell
        let song = array(section: indexPath.section)[indexPath.row]
        let beginHour = songDateFormatter.string(from: song.beginsAt as Date)
        
        cell.panGesture.delegate = self
        cell.nameLabel.text = song.name
        cell.beginHourLabel.text = beginHour
        cell.infoDelegate = self
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = array(section: section)
        if section == notifications {
            return NSLocalizedString("TO NOTIFY", comment: "")
        } else {
            return NSLocalizedString("FAVORITES", comment: "")
        }
    }
    
    @IBAction func didPressCloseSavedButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension FavoritesTableViewController : SongInfoDelegate {
    func songInfo(for cell: SongCell) -> SavedSong? {
        guard let indexPath = tableView.indexPath(for: cell) else { return nil }
        return array(section: indexPath.section)[indexPath.row]
    }
}
