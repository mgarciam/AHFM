//
//  SongInfo+CoreDataProperties.swift
//  AHFM
//
//  Created by Marilyn on 6/13/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import Foundation
import CoreData


extension SongInfo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SongInfo> {
        return NSFetchRequest<SongInfo>(entityName: "SongInfo")
    }

    @NSManaged public var beginsAt: NSDate?
    @NSManaged public var endsAt: NSDate?
    @NSManaged public var favorite: Bool
    @NSManaged public var name: String?
    @NSManaged public var notification: Bool

}
