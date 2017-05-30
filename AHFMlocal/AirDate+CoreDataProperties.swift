//
//  AirDate+CoreDataProperties.swift
//  AHFM
//
//  Created by Marilyn on 5/30/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import Foundation
import CoreData


extension AirDate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AirDate> {
        return NSFetchRequest<AirDate>(entityName: "AirDate")
    }

    @NSManaged public var initialDate: NSDate?
    @NSManaged public var endDate: NSDate?

}
