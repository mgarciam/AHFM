//
//  SongInfo+CoreDataProperties.swift
//  AHFM
//
//  Created by Marilyn on 5/29/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import Foundation
import CoreData


extension SongInfo {

    @nonobjc public class func songInfoRequest() -> NSFetchRequest<SongInfo> {
        return NSFetchRequest<SongInfo>(entityName: "SongInfo")
    }

    @NSManaged public var name: String?
    @NSManaged public var initialDate: NSDate?
    @NSManaged public var endDate: NSDate?

}
