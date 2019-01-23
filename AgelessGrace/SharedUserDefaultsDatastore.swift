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
    func yesterdayWasDay7() -> Bool
    func setDateOfLastCompletedExercise()
    func lastCompletedExerciseWasYesterday() -> Bool
    func resetLastCompletedExercisDate()
    func resetManuallyCompletedTools()
    func getCompletedWeeks() -> Int
    func setCompletedWeeks() -> Int
    func resetCompletedWeeks()
    func commitToDisk()
}

class SharedUserDefaultsDatastore: NSObject, DatastoreProtocol {
    
    func getCompletedWeeks() -> Int {
        if  let count = userDefaults.object(forKey: "CompletedWeeks") {
            return count as! Int
        }
        return 0
    }
    
    func setCompletedWeeks() -> Int {
        var result = 0
        if  let count = userDefaults.object(forKey: "CompletedWeeks") {
            result = (count as! Int) + 1
        } else {
            result = 1
        }
        userDefaults.set(result, forKey: "CompletedWeeks")
        self.commitToDisk()
        return result
    }
    
    func resetCompletedWeeks() {
        userDefaults.removeObject(forKey:"CompletedWeeks")
        self.commitToDisk()
    }
    
    func getLastCompletedGroup() ->Array<String> {
        return userDefaults.object(forKey: "LastCompletedToolGroup") as! Array<String>
    }
    
    func setDateOfLastCompletedExercise() {
        userDefaults.set(Date(), forKey: "DateOfLastExercise")
        self.commitToDisk()
    }
    
    func lastCompletedExerciseWasYesterday() -> Bool {
        if userDefaults.object(forKey: "DateOfLastExercise") != nil {
            return (self.computeYesterdaysDate() == userDefaults.object(forKey: "DateOfLastExercise") as! Date)
        }
        return false
    }
    
    func lastCompletedExerciseWasToday() -> Bool {
        if userDefaults.object(forKey: "DateOfLastExercise") != nil {
            let theDate = userDefaults.object(forKey: "DateOfLastExercise") as! Date
            return self.compareDate(date1: theDate, date2: Date())
        }
        return false
    }
    
    func resetLastCompletedExercisDate() {
        userDefaults.removeObject(forKey:"DateOfLastExercise")
        self.commitToDisk()
    }
    
    func resetManuallyCompletedTools() {
        userDefaults.removeObject(forKey:"CompletedManualTools")
    }
    
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
        //note that seven days must include the first date - i.e. date
        return (cal as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: 6, to: date, options: NSCalendar.Options(rawValue: 0))!
    }
    
    func fourteenDaysFrom(cal:Calendar, date:Date) -> Date {
        return (cal as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: 14, to: date, options: NSCalendar.Options(rawValue: 0))!
    }
    
    func twentyoneDaysFrom(cal:Calendar, date:Date) -> Date {
        return (cal as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: 21, to: date, options: NSCalendar.Options(rawValue: 0))!
    }
    
    func computeYesterdaysDate() -> Date {
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        return (cal as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: -1, to: Date(), options: NSCalendar.Options(rawValue: 0))!
    }
    
    func computeDateBefore(_ noDays:Int) -> Date {
        let toDate = Date()
        return Calendar.current.date(byAdding: .day, value: -noDays, to: toDate)!
    }
    
    func compareDate(date1:Date, date2:Date) -> Bool {
        let order = NSCalendar.current.compare(date1, to: date2, toGranularity: .day)
        switch order {
        case .orderedSame:
            return true
        default:
            return false
        }
    }
    
    func daysBetweenDate(_ startDate: Date, endDate: Date) -> Int {
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
    
    func yesterdayWasDay7() -> Bool {
        let yesterday = computeYesterdaysDate()
        let day7 = loadDate("EndingDate")
        return compareDate(date1: day7, date2: yesterday)
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
