//
//  SavedSong.swift
//  AHFM
//
//  Created by Marilyn on 6/20/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import Foundation

class SavedSong : NSObject, NSCoding {
    let beginsAt: NSDate
    let name: String
    
    init?(song: SongInfo) {
        guard let songName = song.name, let songBeginsAt = song.beginsAt else { return nil }
        name = songName
        beginsAt = songBeginsAt
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherSong = object as? SavedSong else {
            return false
        }
        
        return beginsAt == otherSong.beginsAt && name == otherSong.name
    }
    
    override var hash: Int {
        return beginsAt.hash ^ name.hash
    }
    
    static private let BeginsAtKey = "beginsAt"
    static private let NameKey = "name"
    
    required init?(coder aDecoder: NSCoder) {
        beginsAt = aDecoder.decodeObject(forKey: SavedSong.BeginsAtKey) as! NSDate
        name = aDecoder.decodeObject(forKey: SavedSong.NameKey) as! String
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(beginsAt, forKey: SavedSong.BeginsAtKey)
        aCoder.encode(name, forKey: SavedSong.NameKey)
    }
}
