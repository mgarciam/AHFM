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

class FavoritesTableViewController: UITableViewController, FavoriteToggleDelegate {
    
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    private var context: CoreDataStack!
    let streamViewController = ViewController()
    
    class func newFavoritesVC(context: CoreDataStack) -> FavoritesTableViewController {
        let favorites = UIStoryboard(name: "Favorites", bundle: nil).instantiateInitialViewController() as! FavoritesTableViewController
        favorites.context = context
        return favorites
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SongInfo")
        request.predicate = NSPredicate(format: "favorite == true")
        let nameSort = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [nameSort]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context.mainContext, sectionNameKeyPath: "name", cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError()
        }
        
        streamViewController.favoriteDelegate = self
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let song = self.fetchedResultsController?.object(at: indexPath) as! SongInfo
        cell.textLabel?.text = song.name
        return cell
    }
    
    func changeStateOfSong(state: Bool) {
        self.context.mainContext.perform { 
            
        }
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
