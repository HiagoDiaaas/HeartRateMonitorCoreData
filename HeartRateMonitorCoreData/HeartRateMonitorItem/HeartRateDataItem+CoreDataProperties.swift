//
//  HeartRateDataItem+CoreDataProperties.swift
//  HeartRateMonitorCoreData
//
//  Created by Hiago Santos Martins Dias on 27/01/23.
//
//

import Foundation
import CoreData


extension HeartRateDataItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HeartRateDataItem> {
        return NSFetchRequest<HeartRateDataItem>(entityName: "HeartRateDataItem")
    }

    @NSManaged public var bpm: String?

}

extension HeartRateDataItem : Identifiable {

}
