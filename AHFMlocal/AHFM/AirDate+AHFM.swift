//
//  AirDate+AHFM.swift
//  AHFM
//
//  Created by Marilyn on 5/30/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import Foundation
import CoreData

extension AirDate {
    
    convenience init?(initialDate: Date, endDate: Date, context: NSManagedObjectContext) {
        
        guard let entity = NSEntityDescription.entity(forEntityName: "AirDate", in: context) else {
            return nil
        }
        
        self.init(entity: entity, insertInto: context)
        self.initialDate = initialDate as NSDate
        self.endDate = endDate as NSDate
    }

}
