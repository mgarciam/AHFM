//
//  CoreDataStack.swift
//  AHFM
//
//  Created by Marilyn on 5/30/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Core Data stack

class CoreDataStack {
    
    var mainContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
        
    private lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "AHFM")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    func save() {
        save(context: persistentContainer.viewContext)
    }
    
    func save(context: NSManagedObjectContext) {
        
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
}

extension CoreDataStack {
    
    func save(songs: [ParsedSong], context: NSManagedObjectContext, completion: @escaping () -> Void) {
        
        context.perform {
            
            // Before we delete all songs, save the songs marked as favorite or notifications.
            var favorites = [String]()
            var notifications = [String]()
            
            // Fetch all favorites and notifications
            let fetchRequest = NSFetchRequest<SongInfo>(entityName: "SongInfo")
            fetchRequest.predicate = NSPredicate(format: "(favorite == true) OR ((notification == true) AND (beginsAt > %@))", NSDate())
            let favoritesAndNotifications = try! context.fetch(fetchRequest)
            favoritesAndNotifications.forEach { song in
                
                guard let songName = song.name else { return }
                
                if song.favorite {
                    favorites.append(songName)
                }
                
                if song.notification {
                    notifications.append(songName)
                }
            }
            
            // Delete all songs.
            // This is a batch request so we need to send a notification that the context changed.
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: NSFetchRequest<SongInfo>(entityName: "SongInfo") as! NSFetchRequest<NSFetchRequestResult>)
            let _ = try? context.execute(deleteRequest)
            
            for song in songs {
                let newSong = try! SongInfo.newSong(name: song.name,
                                                    initialDate: song.beginsAt,
                                                    endDate: song.endsAt,
                                                    context: context)
                
                newSong.favorite = favorites.contains(song.name)
                newSong.notification = notifications.contains(song.name)
            }
            
            self.save(context: context)
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}
