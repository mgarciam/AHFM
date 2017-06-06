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

class ViewController: UIViewController {
    
    var context: CoreDataStack!
    
    let player = AVPlayer(playerItem: AVPlayerItem(url: URL(string: "http://us2.ah.fm:443")!))
    
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var playButton: UIButton!

    var calendar: CalendarViewController!
    var favoritesList: FavoritesTableViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pauseButton.isHidden = true
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
    }
    
    @IBAction func didTouchPauseButton(_ sender: Any) {
        playButton.isHidden = false
        player.currentItem?.removeObserver(self, forKeyPath: "timedMetadata")
        player.pause()
        pauseButton.isHidden = true
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let givenPath = keyPath,
            givenPath == "timedMetadata",
            let item = object,
            let AVItem = item as? AVPlayerItem else { return }
        AVItem.timedMetadata?.forEach { (item) in
            print(item)
        }
    }
    
    @IBAction func didPressCalendarButton(_ sender: Any) {
        let calendarVC = CalendarViewController.newCalendarVC(context: context)
        let navController = UINavigationController(rootViewController: calendarVC)
        self.present(navController, animated: true) { }
    }
    
    @IBAction func didPressFavoritesButton(_ sender: Any) {
        let favoritesVC = FavoritesTableViewController.newFavoritesVC(context: context)
        self.present(UINavigationController.init(rootViewController: favoritesVC), animated: true, completion: nil)
    }
}
