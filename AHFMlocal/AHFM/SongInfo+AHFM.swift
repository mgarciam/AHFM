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

    convenience init(name: String, initialDate: Date, endDate: Date, context: NSManagedObjectContext) throws {
        
        guard let entity = NSEntityDescription.entity(forEntityName: "SongInfo", in: context) else {
            throw "Entity could not be inserted in context"
        }
        
        self.init(entity: entity, insertInto: context)
        self.name = name
        self.initialDate = initialDate as NSDate
        self.endDate = endDate as NSDate
    }
}
