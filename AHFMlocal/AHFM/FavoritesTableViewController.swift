//
//  FavoritesTableViewController.swift
//  AHFM
//
//  Created by Marilyn on 5/29/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import Foundation
import UIKit

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
                songCell.layoutIfNeeded()
                songCell.leadingHoursSeparatorConstraint.constant = -10
                UIView.animate(withDuration: 0.33) {
                    songCell.layoutIfNeeded()
                }
            }
        }
    }
    
    fileprivate func array(section: Int) -> [SavedSong] {
        if favorites.isEmpty && !notifications.isEmpty {
            return notifications
        } else if !favorites.isEmpty && notifications.isEmpty {
            return favorites
        } else if section == 0 {
            return notifications
        } else {
            return favorites
        }
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
            return "TO NOTIFY"
        } else {
            return "FAVORITES"
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension FavoritesTableViewController : SongInfoDelegate {
    func songInfo(for cell: SongCell) -> SavedSong? {
        guard let indexPath = tableView.indexPath(for: cell) else { return nil }
        return array(section: indexPath.section)[indexPath.row]
    }
}
