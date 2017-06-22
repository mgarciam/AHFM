//
//  ShowInfo-Extension.swift
//  AHFM
//
//  Created by Marilyn on 6/19/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

extension SongInfoDelegate where Self: UIViewController {
    func showInfo(_ cell: SongCell) {
        guard let song = songInfo(for: cell) else { return }
        
        var favorites = [SavedSong]()
        var notifications = [SavedSong]()
        favorites = UserDefaults.standard.favorites
        notifications = UserDefaults.standard.notifications
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let isFavorite = favorites.contains(song)
        alert.addAction(UIAlertAction(title: isFavorite ? NSLocalizedString("Unfavorite", comment: "") : NSLocalizedString("Favorite", comment: ""), style: .default) { action in
            
            if isFavorite {
                UserDefaults.standard.remove(favorite: song)
            } else {
                UserDefaults.standard.add(favorite: song)
            }
        })
        
        let isNotification = notifications.contains(song)
        let notificationAction = UIAlertAction(title: isNotification ? NSLocalizedString("Unnotify me", comment: "") : NSLocalizedString("Notify me", comment: ""), style: .default) { action in
            
            if isNotification {
                UserDefaults.standard.remove(notification: song)
            } else {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
                    (granted, error) in
                    if !granted {
                        print("error")
                    }
                }
                
                UserDefaults.standard.add(notification: song)
                let content = UNMutableNotificationContent()
                let calendar = NSCalendar.current
                let triggerDate = calendar.dateComponents([.month, .day, .year, .hour, .minute], from: song.beginsAt as Date)
                content.title = song.name
                content.body = "Is playing now!"
                content.sound = UNNotificationSound.default()
                let _ = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            }
            
        }
        
        notificationAction.isEnabled = Date() < song.beginsAt as Date
        alert.addAction(notificationAction)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        present(alert, animated: true, completion: nil)
    }
}
