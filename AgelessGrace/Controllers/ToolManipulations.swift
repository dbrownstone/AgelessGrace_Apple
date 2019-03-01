//
//  ToolManipulations.swift
//  AgelessGrace
//
//  Created by David Brownstone on 21/12/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit
import Foundation

protocol ToolProtocol {
    func reset7DayPeriod()
    func setSelectionType(_ selectionType:Bool)
    func setManuallyCompletedToolIds(_ ids:Array<Int>)
    func getManuallyCompletedToolIds() -> [Int]
    func saveManuallySelectedTools(_ tools:Array<String>)
    func getManuallySelectedTools() -> Array<String>
    func saveLastCompletedGroup(_ group:Array<String>)
    func getLastCompletedGroup() -> Array<String>
    func selectTools() -> Array<AnyObject>
    func setupArrayForRandomSelection()
    func randomlySelectRemainingArrayOfTools(_ alreadySelected: [Array<String>], selectedTools:[String])
    func isAlreadyInArray(_ tool:NSString) -> Bool
    func setToolCount(_ count:Int)
    func getToolCount() -> Int
    func setSessionPeriod(_ duration:Double)
    func getSessionPeriod() -> Double
    func exercisePeriodHasYetToStart() -> Bool
}

class ToolManipulations: NSObject, ToolProtocol {
    
    var datastore:DatastoreProtocol = SharedUserDefaultsDatastore()
    var selectedGroup:Array<String>!
    var selectionTypeIsManual: Bool!
    var completedManualToolIds:Array<Int>!
    var sevenDayToolSelection:[[String]] = []
    var arrayForRandomSelection = appDelegate.getRequiredArray("AGToolNames")
    var completedTools:[String]!
    var theToolCount = 3
    var timeOfSession:Double!
    
    func reset7DayPeriod() {
        theToolCount = 3
        selectedGroup = [String]()
        datastore.clearSelectedGroup()
        datastore.clearSelectedGroups()
        datastore.resetCompletedToolSets()
        setTheDatesInTheDatastore()
    }
    
    func saveManuallySelectedTools(_ tools:Array<String>) {
        datastore.save("CompletedManualTools", value: tools as NSObject)
        datastore.commitToDisk()
    }
    
    func getManuallySelectedTools() -> Array<String> {
//        if let manuallySelectedTools = datastore.loadArray("CompletedManualTools") as? Array<String> {
//            return manuallySelectedTools
//        }
        return []
    }
    
    func setSelectionType(_ selectionType: Bool) {
        selectionTypeIsManual = selectionType
    }
    
    func setManuallyCompletedToolIds(_ ids: [Int]) {
        completedManualToolIds = ids
    }
    
    func getManuallyCompletedToolIds() -> [Int] {
        return self.completedManualToolIds ?? [Int]()
    }
    
    func saveLastCompletedGroup(_ group:Array<String>) {
        datastore.save("LastCompletedToolsGroup", value: group as NSObject)
    }
    
    func getLastCompletedGroup() ->Array<String> {
        return datastore.loadArray("LastCompletedToolsGroup") as? Array<String> ?? Array<String>()
    }

    func exercisePeriodHasYetToStart() -> Bool {
        //        daysBetweenDate
        if let startDate = userDefaults.object(forKey: "StartingDate") {
            let period = datastore.daysBetweenDate(startDate as! Date, endDate: Date())
            if period < 0 {
                return true
            }
        } else {
            return true
        }
        return false
    }
    
    func setTheDatesInTheDatastore() {
        let firstDay = datastore.loadDate("StartingDate")
        if datastore.shouldExerciseDaily() {
            datastore.save("EndingDate", value:datastore.sevenDaysFrom(firstDay) as NSObject)
        }
    }
    
    func getCompletedTools() -> [String] {
        var theseTools = [String]()
        let completedToolSets = datastore.getCompletedToolSets()
        for theToolSet in completedToolSets {
            for i in 0..<3 {
                theseTools.append(theToolSet[i])
            }
        }
        if theseTools.count > 0 {
            return theseTools
        }
        return []
    }
    
    func setupArrayForRandomSelection() {
        // remove any tool already used
        completedTools = getCompletedTools()
        arrayForRandomSelection = appDelegate.getRequiredArray("AGToolNames")
        for tool in completedTools {
            if let whichOne = arrayForRandomSelection.index(of: tool) {
                arrayForRandomSelection.remove(at: whichOne)
            }
        }
    }
    
    func randomlySelectRemainingArrayOfTools(_ alreadySelectedGroups: [Array<String>], selectedTools: [String]) {
        let selectedGroups = alreadySelectedGroups
        if selectedGroups.count == 7 {
            return
        }
        arrayForRandomSelection = appDelegate.getRequiredArray("AGToolNames")
        sevenDayToolSelection = [[String]] ()
        var randomizedList = [Int]()
        var nums = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
        var idsToBeRemoved = [Int]()
//        for toolGroup in selectedGroups {
            for i in 0..<selectedTools.count {
                idsToBeRemoved.append(arrayForRandomSelection.index(of: selectedTools[i])!)
            }
//        }
        for id in idsToBeRemoved.reversed() {
            print(id)
            nums.remove(at: (id))
        }
        
        while nums.count > 0 {
            // random key from array
            let arrayKey = Int(arc4random_uniform(UInt32(nums.count)))
            // random number
            let randNum = nums[arrayKey]
            // make sure the number isnt repeated
            nums.remove(at: arrayKey)
            randomizedList.append(randNum)
        }
        sevenDayToolSelection = selectedGroups
        var theGroup = [String]()
        
        for indx in 0..<randomizedList.count {
            if theGroup.count == theToolCount {
                sevenDayToolSelection.append(theGroup)
                theGroup = [String]()
            }
            if sevenDayToolSelection.count < 7 {
                theGroup.append((appDelegate.getRequiredArray("AGToolNames"))[randomizedList[indx]])
            }
            
        }
        sevenDayToolSelection.append(theGroup)
        setTheDatesInTheDatastore()
        datastore.save("SelectedGroups", value:(sevenDayToolSelection as NSObject?)!)
    }
    
    func isAlreadyInArray(_ tool:NSString) -> Bool {
        completedTools = datastore.getLastCompletedGroup()
        if completedTools != nil {
            if let _ = completedTools.first(where: { $0 == tool as String })  {
                // item is the first matching array element
                return true
            }
            return false
        } else {
            return false
        }
    }
    
    func randInRange() -> Int {
        return Int(arc4random_uniform(UInt32(21)))
    }
    
    func selectTools() -> Array<AnyObject> {
        if theToolCount == 0 {
            theToolCount = 3
        }
        selectedGroup = [String](repeating: "", count: theToolCount)
        setupArrayForRandomSelection()
        var i:Int = 0
        while i < theToolCount {
            let selectedNumber = randInRange()
            if isAlreadyInArray((appDelegate.getRequiredArray("AGToolNames"))[selectedNumber] as NSString) != true && selectedGroup.contains((appDelegate.getRequiredArray("AGToolNames"))[selectedNumber]) != true {
                //select
                
                selectedGroup?[i] = (appDelegate.getRequiredArray("AGToolNames"))[selectedNumber]
                i = i + 1
                if i >= theToolCount {
                    break
                }
            }
        }
        //        print("\(selectedGroup)")
        return selectedGroup! as Array<AnyObject>
    }
    
    func setToolCount(_ count:Int) {
        theToolCount = count
    }
    
    func getToolCount() -> Int {
        if theToolCount <= 0 {
            theToolCount = 3
        }
        return theToolCount
    }
    
    func setSessionPeriod(_ duration:Double) {
        timeOfSession = duration
    }
    
    func getSessionPeriod() -> Double {
        if timeOfSession == nil {
            timeOfSession = SESSIONPERIOD
        }
        return timeOfSession //minutes
    }
    
}
