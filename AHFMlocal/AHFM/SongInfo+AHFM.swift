//
//  SongInfo+AHFM.swift
//  AHFM
//
//  Created by Marilyn on 5/29/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import Foundation
import CoreData

extension String : Error { }

extension SongInfo {

    class func newSong(name: String, initialDate: Date, endDate: Date, context: NSManagedObjectContext) throws -> SongInfo {
        
        let newSong = NSEntityDescription.insertNewObject(forEntityName: "SongInfo", into: context) as! SongInfo
        newSong.name = name
        
        let airDate = AirDate(initialDate: initialDate, endDate: endDate, context: context)
        
        newSong.addToAirDates(airDate!)
        
        return newSong
    }
}
