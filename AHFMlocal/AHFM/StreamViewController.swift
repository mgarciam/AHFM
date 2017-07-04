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

class StreamViewController: SongsViewController {

    let player = AVPlayer(playerItem: AVPlayerItem(url: URL(string: "http://www.ah.fm/192k.m3u")!))
    
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var divisionView: UIView!
    @IBOutlet weak var currentSongView: UIView!
    @IBOutlet weak var currentSongTitleLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    
    override var requestSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "beginsAt", ascending: true)]
    }
    
    override var requestPredicate: NSPredicate {
        // The "TODAY" section displays songs scheduled for the rest of the day.
        let calendar = NSCalendar(calendarIdentifier: .gregorian)
        calendar?.timeZone = .current
        let date = Date()
        let nextDay = calendar?.startOfDay(for: (calendar?.date(byAdding: .day, value: 1, to: date))!)
        return NSPredicate(format: "(beginsAt > %@) AND (beginsAt < %@)", date as NSDate, nextDay! as NSDate)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
    
        updateUI(.paused)
    }
    
    fileprivate func updateUI(_ state: StreamState) {
        pauseButton.isHidden = state.pauseButtonIsHidden
        tableView.isHidden = state.tableViewIsHidden
        playButton.isHidden = state.playButtonIsHidden
        currentSongView.isHidden = state.currentSongViewIsHidden
        currentSongTitleLabel.isHidden = state.currentSongTitleLabelIsHidden
        logoImageView.isHidden = state.logoImageViewIsHiden
        
        if state == .playing {
            title = NSLocalizedString("NOW PLAYING", comment: "")
            requestUpdateFromDataSource()
        } else {
            title = NSLocalizedString("AH.FM", comment: "")
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // FIXME: Explain
        guard let givenPath = keyPath,
            givenPath == "timedMetadata",
            let item = object,
            let AVItem = item as? AVPlayerItem else { return }
        
        UIView.animate(withDuration: 0.33) { 
            AVItem.timedMetadata?.forEach { item in
                self.currentSongTitleLabel.text = item.stringValue!
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("TODAY", comment: "")
    }
}

// MARK: - Actions
extension StreamViewController {
    
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
    
    @IBAction func didPressFavoritesButton(_ sender: Any) {
        let favoritesVC = FavoritesTableViewController.newFavoritesVC(context: context)
        present(UINavigationController(rootViewController: favoritesVC), animated: true, completion: nil)
    }
    
    @IBAction func didPressCalendarButton(_ sender: Any) {
        let calendarVC = CalendarViewController.newCalendarVC(context: context)
        present(UINavigationController(rootViewController: calendarVC), animated: true, completion: nil)
    }
}

// MARK: - Enum State
fileprivate enum StreamState {
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
    
    var currentSongTitleLabelIsHidden: Bool {
        switch self {
        case .playing:
            return false
        case .paused:
            return true
        }
    }
    
    var logoImageViewIsHiden: Bool {
        switch self {
        case .playing:
            return true
        case .paused:
            return false
        }
    }
}
