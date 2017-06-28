//
//  UserDefaults-Extension.swift
//  AHFM
//
//  Created by Marilyn on 6/19/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import Foundation

fileprivate let FavoritesKey = "favorites"
fileprivate let NotificationsKey = "notifications"

extension UserDefaults {
    var favorites: [SavedSong] {
        get {
            guard let unarchivedFavorites = object(forKey: FavoritesKey) as? Data,
                let favorites = NSKeyedUnarchiver.unarchiveObject(with: unarchivedFavorites) as? [SavedSong]
                else {
                set([], forKey: FavoritesKey)
                synchronize()
                return []
            }
            
            return favorites
        }
        
        set {
            let archivedFavorites = NSKeyedArchiver.archivedData(withRootObject: newValue)
            set(archivedFavorites, forKey: FavoritesKey)
            synchronize()
            NotificationCenter.default.post(name: Notification.Name(notification: .didUpdateFavorites),
                                            object: nil)
        }
    }
    
    var notifications: [SavedSong] {
        get {
            guard let unarchivedNotifications  = object(forKey: NotificationsKey) as? Data,
            let notifications = NSKeyedUnarchiver.unarchiveObject(with: unarchivedNotifications) as? [SavedSong]
                else {
                set([], forKey: NotificationsKey)
                synchronize()
                return []
            }
            
            return notifications
        }
        
        set {
            let archivedNotifications = NSKeyedArchiver.archivedData(withRootObject: newValue)
            set(archivedNotifications, forKey: NotificationsKey)
            synchronize()
            NotificationCenter.default.post(name: Notification.Name(notification: .didUpdateNotifications), object: nil)
        }
    }

    func add(favorite: SavedSong) {
        var currentFavorites = favorites
        currentFavorites.append(favorite)
        favorites = currentFavorites
    }
    
    func remove(favorite: SavedSong) {
        var currentFavorites = favorites
        guard let index = currentFavorites.index(of: favorite) else { return }
        currentFavorites.remove(at: index)
        favorites = currentFavorites
    }
    
    func add(notification: SavedSong) {
        var currentNotifications = notifications
        currentNotifications.append(notification)
        notifications = currentNotifications
    }
    
    func remove(notification: SavedSong) {
        var currentNotifications = notifications
        guard let index = currentNotifications.index(of: notification) else { return }
        currentNotifications.remove(at: index)
        notifications = currentNotifications
    }
}
