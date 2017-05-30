//
//  SongInfo+CoreDataProperties.swift
//  AHFM
//
//  Created by Marilyn on 5/30/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import Foundation
import CoreData


extension SongInfo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SongInfo> {
        return NSFetchRequest<SongInfo>(entityName: "SongInfo")
    }

    @NSManaged public var name: String?
    @NSManaged public var airDates: NSSet?

}

// MARK: Generated accessors for airDates
extension SongInfo {

    @objc(addAirDatesObject:)
    @NSManaged public func addToAirDates(_ value: AirDate)

    @objc(removeAirDatesObject:)
    @NSManaged public func removeFromAirDates(_ value: AirDate)

    @objc(addAirDates:)
    @NSManaged public func addToAirDates(_ values: NSSet)

    @objc(removeAirDates:)
    @NSManaged public func removeFromAirDates(_ values: NSSet)

}
