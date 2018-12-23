//
//  SharedUserDefaultsDatastore.swift
//  AgelessGrace
//
//  Created by David Brownstone on 21/12/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit

let userDefaults = UserDefaults(suiteName: "group.com.brownstone.AgelessGrace")!

protocol DatastoreProtocol {
    func save(_ key: String, value: NSObject)
    func loadString(_ key: String) -> String
    func loadDate(_ key: String) -> Date
    func loadArray(_ key: String) -> Array<AnyObject>
    func daysBetweenDate(_ startDate: Date, endDate: Date) -> Int
    func sevenDaysFrom(_ date:Date) -> Date
    func computeYesterdaysDate() -> Date
    func updateDate(_ theDate: Date, byDays: Int) -> Date
    func isToday(_ date:Date) -> Bool
    func commitToDisk()
}

class SharedUserDefaultsDatastore: NSObject, DatastoreProtocol {
    
    
    
    func save(_ key: String, value: NSObject) {
        userDefaults.set(value, forKey: key)
    }
    
    func loadDate(_ key: String) -> Date {
        if let thisDate = userDefaults.object(forKey: key) {
            return thisDate as! Date
        } else {
            if key == "StartingDate" {
                return Date()
            } else {
                return sevenDaysFrom(Date())
            }
        }
    }
    
    func loadString(_ key: String) -> String {
        if userDefaults.object(forKey: key) != nil {
            return userDefaults.object(forKey: key) as! String
        } else {
            return "False"
        }
    }
    
    
    func sevenDaysFrom(_ date:Date) -> Date {
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        return (cal as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: 7, to: date, options: NSCalendar.Options(rawValue: 0))!
    }
    
    func computeYesterdaysDate() -> Date {
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        return (cal as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: -1, to: Date(), options: NSCalendar.Options(rawValue: 0))!
    }
    
    func computeDateBefore(_ noDays:Int) -> Date {
        let toDate = Date()
        return Calendar.current.date(byAdding: .day, value: -noDays, to: toDate)!
    }
    
    func daysBetweenDate(_ startDate: Date, endDate: Date) -> Int
    {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)
        let components = (calendar as NSCalendar).components([.day], from: startDay, to: endDay, options: [])
        return components.day!
    }
    
    func updateDate(_ theDate: Date, byDays: Int) -> Date {
        let calendar = Calendar.current
        
        var dateComponent = DateComponents()
        dateComponent.month = 0
        dateComponent.day = byDays
        dateComponent.year = 0
        
        let newDate = calendar.date(byAdding: dateComponent, to: theDate)!
        return newDate
    }
    
    func isToday(_ date:Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(date)
    }
    
    func loadArray(_ key: String) -> Array<AnyObject> {
        if userDefaults.object(forKey: key) != nil {
            if key == "SelectedGroups" {
                return userDefaults.object(forKey: key) as! Array<AnyObject>
            }
            return userDefaults.object(forKey: key) as! Array<String> as Array<AnyObject>
        } else {
            if key == "SelectedGroup" {
                return ["" as AnyObject, "" as AnyObject, "" as AnyObject]
            } else {
                return []
            }
        }
    }
    
    func commitToDisk() {
        userDefaults.synchronize()
    }
    
}
