//
//  NotificationName-Extension.swift
//  AHFM
//
//  Created by Marilyn on 6/23/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import Foundation

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

extension Notification.Name {
    
    enum UpdateDataNotification {
        case didUpdateFavorites
        case didUpdateNotifications
        
        var rawValue: String {
            switch self {
            case .didUpdateFavorites:
                return "UpdateFavorites"
                
            case .didUpdateNotifications:
                return "UpdateNotifications"
            }
        }
    }
    
    init(notification: UpdateDataNotification) {
        self = Notification.Name(rawValue: notification.rawValue)
    }
}
