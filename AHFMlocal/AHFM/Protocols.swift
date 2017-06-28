//
//  Protocols.swift
//  AHFM
//
//  Created by Marilyn on 6/23/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import Foundation
import CoreData
import UIKit

protocol UpdateCoreDataSourceDelegate {
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> { get }
    var tableView: UITableView { get }
    
    func reloadDataSource()
}

extension UpdateCoreDataSourceDelegate {
    func reloadDataSource() {
        try? fetchedResultsController.performFetch()
        tableView.reloadData()
    }
}
