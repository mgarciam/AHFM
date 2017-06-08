//
//  ViewController.swift
//  AHFM
//
//  Created by Marilyn on 5/23/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData

protocol FavoriteToggleDelegate: class {
    func changeStateOfSong(state: Bool)
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    
    var context: CoreDataStack!
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    let player = AVPlayer(playerItem: AVPlayerItem(url: URL(string: "http://us2.ah.fm:443")!))
    var name = "AH.FM"
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var divisionView: UIView!

    var calendar: CalendarViewController!
    var favoritesList: FavoritesTableViewController!
    var favoriteDelegate: FavoriteToggleDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pauseButton.isHidden = true
        tableView.isHidden = true
        
        let calendar = NSCalendar(calendarIdentifier: .gregorian)
        calendar?.timeZone = .current
        let date = Date()
        let nextDay = calendar?.startOfDay(for: (calendar?.date(byAdding: .day, value: 1, to: date))!)
        
        let request = NSFetchRequest<SongInfo>(entityName: "SongInfo")
        request.predicate = NSPredicate(format: "(beginsAt > %@) AND (beginsAt < %@)", date as NSDate, nextDay! as NSDate)
        let dateSort = NSSortDescriptor(key: "beginsAt", ascending: true)
        request.sortDescriptors = [dateSort]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult>, managedObjectContext: context.mainContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController?.delegate = self as NSFetchedResultsControllerDelegate
        
        do {
            try fetchedResultsController?.performFetch()
            tableView.reloadData()
        } catch {
            fatalError()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTouchPlayButton(_ sender: Any) {
        pauseButton.isHidden = false
        player.currentItem?.addObserver(self, forKeyPath: "timedMetadata", options: .new, context: nil)
        player.play()
        playButton.isHidden = true
        tableView.isHidden = false
        divisionView.isHidden = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            
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
    
    @IBAction func didTouchPauseButton(_ sender: Any) {
        playButton.isHidden = false
        player.currentItem?.removeObserver(self, forKeyPath: "timedMetadata")
        player.pause()
        pauseButton.isHidden = true
        tableView.isHidden = true
        divisionView.isHidden = false
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let givenPath = keyPath,
            givenPath == "timedMetadata",
            let item = object,
            let AVItem = item as? AVPlayerItem else { return }
        AVItem.timedMetadata?.forEach { (item) in
            print(item)
            name = item.stringValue!
            tableView.reloadData()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let sections = fetchedResultsController?.sections else {
            return 0
        }
        
        return sections.count + 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController?.sections else {
            return 0
        }
        
        if section == 0 {
            return 1
        }
        
        return sections[section - 1].numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SongCell
        
        if indexPath.section == 0 {
            cell.nameLabel.text = name
            return cell
        }
        
        let song = self.fetchedResultsController?.object(at: IndexPath(row: indexPath.row, section: indexPath.section-1)) as! SongInfo
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let beginHour = formatter.string(from: song.beginsAt! as Date)
        let endHour = formatter.string(from: song.endsAt! as Date)
        cell.nameLabel.text = song.name!
        cell.beginHourLabel.text = beginHour
        cell.endHourLabel.text = endHour
        return cell
    }
    
    @IBAction func didPressInfoButton(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Favorite", style: .default) { action in
            self.favoriteDelegate?.changeStateOfSong(state: true)
        })
        alert.addAction(UIAlertAction(title: "Notify me", style: .default))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func didPressCalendarButton(_ sender: Any) {
        let calendarVC = CalendarViewController.newCalendarVC(context: context)
        navigationController?.pushViewController(calendarVC, animated: true)
    }
    
    @IBAction func didPressFavoritesButton(_ sender: Any) {
        let favoritesVC = FavoritesTableViewController.newFavoritesVC(context: context)
        navigationController?.pushViewController(favoritesVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "CURRENTLY" : "UP NEXT"
    }
}

extension ViewController  {
    
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
