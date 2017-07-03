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

class FavoritesTableViewController: UITableViewController, UIGestureRecognizerDelegate, UNUserNotificationCenterDelegate {
    
    enum SavedSection {
        case notifications([SavedSong])
        case favorites([SavedSong])
    }
    
    var favorites = [SavedSong]()
    var notifications = [SavedSong]()
    
    let now = Date()
    
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
                                               name: Notification.Name(notification: .didUpdateFavorites),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateContent),
                                               name: Notification.Name(notification: .didUpdateNotifications),
                                               object: nil)
        
        UNUserNotificationCenter.current().delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        notifications = notifications.filter { savedSong -> Bool in
            savedSong.beginsAt as Date > now
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
    
    fileprivate func array(section: Int) -> SavedSection {
        
        if notifications.isEmpty && favorites.isEmpty {
            assert(false, "requestedArrayOfSavedSong")
            return .favorites([])
        } else if !notifications.isEmpty && favorites.isEmpty {
            return .notifications(notifications)
        } else if notifications.isEmpty && !favorites.isEmpty {
            return .favorites(favorites)
        } else if !notifications.isEmpty && !favorites.isEmpty {
            if section == 0 {
                return .notifications(notifications)
            } else {
                return .favorites(favorites)
            }
        }
        return .favorites([])
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
        
        switch array(section: section) {
        case .favorites(let favorites):
            return favorites.count
        case .notifications(let notifications):
            return notifications.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SongCell
        
        let song: SavedSong
        switch array(section: indexPath.section) {
        case .favorites(let favorites):
            song = favorites[indexPath.row]
        case .notifications(let notifications):
            song = notifications[indexPath.row]
        }
        
        let beginHour = songDateFormatter.string(from: song.beginsAt as Date)
        
        cell.panGesture.delegate = self
        cell.nameLabel.text = song.name
        cell.beginHourLabel.text = beginHour
        cell.endHourLabel.text = ""
        cell.infoDelegate = self
        return cell
    }
    
    /// This functions solves the scrolling problem in the table view
    ///
    /// - Parameters:
    ///   - gestureRecognizer: <#gestureRecognizer description#>
    ///   - otherGestureRecognizer: <#otherGestureRecognizer description#>
    /// - Returns: <#return value description#>
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        switch array(section: section) {
        case .favorites:
            return NSLocalizedString("FAVORITES", comment: "")
        case .notifications:
            return NSLocalizedString("TO NOTIFY", comment: "")
        }
    }
    
    @IBAction func didPressCloseSavedButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension FavoritesTableViewController : SongInfoDelegate {
    func songInfo(for cell: SongCell) -> SavedSong? {
        guard let indexPath = tableView.indexPath(for: cell) else { return nil }
        
        switch array(section: indexPath.section) {
        case .favorites(let favorites):
            return favorites[indexPath.row]
        case .notifications(let notifications):
            return notifications[indexPath.row]
        }
    }
}
