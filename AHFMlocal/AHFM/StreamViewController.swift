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
import UserNotifications

class StreamViewController: UIViewController {

    let player = AVPlayer(playerItem: AVPlayerItem(url: URL(string: "http://us2.ah.fm:443")!))
    
    var context: CoreDataStack!
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    var streamingSongTitle = "AH.FM"
    
    lazy var songDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
        
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var divisionView: UIView!
    
    enum StreamState {
        case playing
        case paused
        
        var pauseButtonIsHidden: Bool {
            switch self {
            case .playing:
                return false
            case .paused:
                return true
            }
        }
        
        var tableViewIsHidden: Bool {
            switch self {
            case .playing:
                return false
            case .paused:
                return true
            }
        }
        
        var playButtonIsHidden: Bool {
            switch self {
            case .playing:
                return true
            case .paused:
                return false
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateUI(.paused)
        
        let request = NSFetchRequest<SongInfo>(entityName: "SongInfo")
        
        // The "UP NEXT" section displays songs scheduled in the next 24 hours.
        let calendar = NSCalendar(calendarIdentifier: .gregorian)
        calendar?.timeZone = .current
        let date = Date()
        let nextDay = calendar?.startOfDay(for: (calendar?.date(byAdding: .day, value: 1, to: date))!)
        request.predicate = NSPredicate(format: "(beginsAt > %@) AND (beginsAt < %@)", date as NSDate, nextDay! as NSDate)
        
        // Sorts chronologically
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
    
    private func updateUI(_ state: StreamState) {
        pauseButton.isHidden = state.pauseButtonIsHidden
        tableView.isHidden = state.tableViewIsHidden
        playButton.isHidden = state.playButtonIsHidden
        
        if state == .playing {
            // Initially display the song initial and end hour and then moves them offscreen.
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
    }
    
    @IBAction func didTouchPlayButton(_ sender: Any) {
        let parser = Parser.newParser(context: context)
        parser.parseFile()
        guard let streamItem = player.currentItem else { return }
        streamItem.addObserver(self, forKeyPath: "timedMetadata", options: .new, context: nil)
        
        player.play()
        
        updateUI(.playing)
    }
    
    @IBAction func didTouchPauseButton(_ sender: Any) {
        guard let streamItem = player.currentItem else { return }
        streamItem.removeObserver(self, forKeyPath: "timedMetadata")
        
        player.pause()
       
        updateUI(.paused)
    }
    
    @IBAction func didPressCalendarButton(_ sender: Any) {
        let calendarVC = CalendarViewController.newCalendarVC(context: context)
        navigationController?.pushViewController(calendarVC, animated: true)
    }
    
    @IBAction func didPressFavoritesButton(_ sender: Any) {
        let favoritesVC = FavoritesTableViewController.newFavoritesVC(context: context)
        navigationController?.pushViewController(favoritesVC, animated: true)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let givenPath = keyPath,
            givenPath == "timedMetadata",
            let item = object,
            let AVItem = item as? AVPlayerItem else { return }
        
        AVItem.timedMetadata?.forEach { item in
            streamingSongTitle = item.stringValue!
            tableView.reloadData()
        }
    }
}

extension StreamViewController : UITableViewDelegate, UITableViewDataSource {
    
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
        
        return sections[sectionForFetchedResults(section)].numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SongCell
        
        guard indexPath.section == 0 else {
            let song = self.fetchedResultsController?.object(at: indexPathForFetchedResults(indexPath)) as! SongInfo
            let beginHour = songDateFormatter.string(from: song.beginsAt! as Date)
            let endHour = songDateFormatter.string(from: song.endsAt! as Date)
            
            cell.nameLabel.text = song.name!
            cell.beginHourLabel.text = beginHour
            cell.endHourLabel.text = endHour
            cell.infoDelegate = self
            cell.beginHourLabel.isHidden = false
            cell.endHourLabel.isHidden = false
       
            return cell
            
        }
        
        cell.nameLabel.text = streamingSongTitle
        cell.beginHourLabel.isHidden = true
        cell.endHourLabel.isHidden = true
  
        cell.infoDelegate = self
        
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? NSLocalizedString("CURRENTLY", comment: "") : NSLocalizedString("UP NEXT", comment: "")
    }
}

extension StreamViewController : SongInfoDelegate {
    
    func showInfo(_ cell: SongCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let managedObjectIndexPath = indexPathForFetchedResults(indexPath)
        let song = self.fetchedResultsController?.object(at: managedObjectIndexPath) as! SongInfo
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: song.favorite ? NSLocalizedString("Unfavorite", comment: "") : NSLocalizedString("Favorite", comment: ""), style: .default) { action in
            
            guard let songContext = song.managedObjectContext else { return }
            
            songContext.perform {
                song.favorite = !song.favorite
                self.context.save(context: songContext)
            }
        })
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Notify me", comment: ""), style: .default) { action in
            let request = NSFetchRequest<SongInfo>(entityName: "SongInfo")
            let fetchedSongs = try? self.context.mainContext.fetch(request)
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
                (granted, error) in
                if !granted {
                    print("error")
                }
            }
            
            var matchingSong = SongInfo()
            fetchedSongs?.forEach { fetchedSong in
                if song.name! == fetchedSong.name! {
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
        })
    
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        present(alert, animated: true, completion: nil)
    }
}

extension StreamViewController : NSFetchedResultsControllerDelegate {
    
    fileprivate func sectionForFetchedResults(_ section: Int) -> Int {
        return section - 1
    }
    
    fileprivate func indexPathForFetchedResults(_ indexPath: IndexPath) -> IndexPath {
        return IndexPath(row: indexPath.row, section: indexPath.section - 1)
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex + 1), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex + 1), with: .fade)
        case .move:
            break
        case .update:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [indexPathForFetchedResults(newIndexPath!)], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPathForFetchedResults(indexPath!)], with: .fade)
        case .update:
            tableView.reloadRows(at: [indexPathForFetchedResults(indexPath!)], with: .fade)
        case .move:
            tableView.moveRow(at: indexPathForFetchedResults(indexPath!),
                              to: indexPathForFetchedResults(newIndexPath!))
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
