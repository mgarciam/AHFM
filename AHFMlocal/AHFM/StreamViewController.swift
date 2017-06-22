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

class StreamViewController: UIViewController {

    let player = AVPlayer(playerItem: AVPlayerItem(url: URL(string: "http://www.ah.fm/192k.m3u")!))

    var context: CoreDataStack!
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    
    lazy var songDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
        
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var divisionView: UIView!
    @IBOutlet weak var currentSongView: UIView!
    @IBOutlet weak var currentlyLabel: UILabel!
    @IBOutlet weak var currentSongTitleLabel: UILabel!
    
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
        
        var currentSongViewIsHidden: Bool {
            switch self {
            case .playing:
                return false
            case .paused:
                return true
            }
        }
        
        var currentlyLabelIsHidden: Bool {
            switch self {
            case .playing:
                return false
            case .paused:
                return true
            }
        }
        
        var currentSongTitleLabelIsHidden: Bool {
            switch self {
            case .playing:
                return false
            case .paused:
                return true
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateUI(.paused)
        
        let request = NSFetchRequest<SongInfo>(entityName: "SongInfo")
        
        // The "UP NEXT" section displays songs scheduled for the rest of the day.
        let calendar = NSCalendar(calendarIdentifier: .gregorian)
        calendar?.timeZone = .current
        let date = Date()
        let nextDay = calendar?.startOfDay(for: (calendar?.date(byAdding: .day, value: 1, to: date))!)
        request.predicate = NSPredicate(format: "(beginsAt > %@) AND (beginsAt < %@)", date as NSDate, nextDay! as NSDate)
        
        // Sorts chronologically
        let dateSort = NSSortDescriptor(key: "beginsAt", ascending: true)
        request.sortDescriptors = [dateSort]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult>, managedObjectContext: context.mainContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultsController?.performFetch()
            tableView.reloadData()
        } catch {
            fatalError()
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(requestUpdateFromDataSource),
                                               name: Notification.Name(schedule: .didUpdate),
                                               object: nil)
    }
    
    func requestUpdateFromDataSource() {
        try? fetchedResultsController?.performFetch()
        tableView.reloadData()
    }
    
    private func updateUI(_ state: StreamState) {
        pauseButton.isHidden = state.pauseButtonIsHidden
        tableView.isHidden = state.tableViewIsHidden
        playButton.isHidden = state.playButtonIsHidden
        currentSongView.isHidden = state.currentSongViewIsHidden
        currentlyLabel.isHidden = state.currentlyLabelIsHidden
        currentSongTitleLabel.isHidden = state.currentSongTitleLabelIsHidden
        
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
            currentSongTitleLabel.text = item.stringValue!
        }
    }
}

extension StreamViewController : UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let sections = fetchedResultsController?.sections else {
            return 0
        }
        
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController?.sections else {
            return 0
        }

        return sections[section].numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SongCell
        
        let song = self.fetchedResultsController?.object(at: indexPath) as! SongInfo
        let beginHour = songDateFormatter.string(from: song.beginsAt! as Date)
        let endHour = songDateFormatter.string(from: song.endsAt! as Date)
            
        cell.nameLabel.text = song.name!
        cell.beginHourLabel.text = beginHour
        cell.endHourLabel.text = endHour
        cell.infoDelegate = self
       
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "UP NEXT"
    }
}

extension StreamViewController : SongInfoDelegate {
    func songInfo(for cell: SongCell) -> SavedSong? {
        guard let indexPath = tableView.indexPath(for: cell) else { return nil }
        
        return SavedSong(song: self.fetchedResultsController?.object(at: indexPath) as! SongInfo)
    }
}
