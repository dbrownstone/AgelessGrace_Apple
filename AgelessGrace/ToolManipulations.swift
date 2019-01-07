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
    func reset()
    func setSelectionType(_ selectionType:Bool)
    func setManuallyCompletedToolIds(_ ids:Array<Int>)
    func getManuallyCompletedToolIds() -> [Int]
    func saveManuallySelectedTools(_ tools:Array<String>)
    func getManuallySelectedTools() -> Array<String>
    func saveLastCompletedGroup(_ group:Array<String>)
    func getLastCompletedGroup() ->Array<String>
    func selectTools() -> Array<AnyObject>
    func setupArrayForRandomSelection()
    func randomlySelectRemainingArrayOfTools()
    func isAlreadyInArray(_ tool:NSString) -> Bool
    func setToolCount(_ count:Int)
    func getToolCount() -> Int
    func setSessionPeriod(_ duration:Double)
    func getSessionPeriod() -> Double
}

class ToolManipulations: NSObject, ToolProtocol {
    
    var datastore:DatastoreProtocol = SharedUserDefaultsDatastore()
    var selectedGroup:Array<String>!
    var selectionTypeIsManual: Bool!
    var completedManualToolIds:Array<Int>!
    var sevenDayToolSelection:[[String]] = []
    var arrayForRandomSelection = appDelegate.getRequiredArray("AGToolNames")
    var completedTools:Array<String>!
    var theToolCount = 3
    var timeOfSession:Double!
    
    func reset() {
        //resets all data to begin a new 7-day period
        completedTools = []
        datastore.save("CompletedTools", value:(completedTools as NSObject?)! )
        if theToolCount == 0 {
            theToolCount = 3
        }
        selectedGroup = [String](repeating: "", count: theToolCount)
        datastore.save("SelectedGroup", value:(selectedGroup as NSObject?)!)
        setTheDatesInTheDatastore()
        datastore.commitToDisk()
    }
    
    func saveManuallySelectedTools(_ tools:Array<String>) {
        datastore.save("CompletedManualTools", value: tools as NSObject)
        datastore.commitToDisk()
    }
    
    func getManuallySelectedTools() -> Array<String> {
        if let manuallySelectedTools = datastore.loadArray("CompletedManualTools") as? Array<String> {
            return manuallySelectedTools
        }
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

    func setTheDatesInTheDatastore() {
        var noOfManualDays = 0
        let manuallySelectedTools = getManuallySelectedTools()
        if manuallySelectedTools.count > 0 {
            noOfManualDays = manuallySelectedTools.count / 3
        }
        let firstDay = Date().addingTimeInterval(TimeInterval(-noOfManualDays*24*60*60))
        datastore.save("StartingDate", value:firstDay as NSObject)
        datastore.save("EndingDate", value:datastore.sevenDaysFrom(firstDay) as NSObject)        
    }
    
    func setupArrayForRandomSelection() {
        // remove any tool already used
        completedTools = datastore.loadArray("CompletedTools") as? Array<String>
        arrayForRandomSelection = appDelegate.getRequiredArray("AGToolNames")
        for tool in completedTools {
            if let whichOne = arrayForRandomSelection.index(of: tool) {
                arrayForRandomSelection.remove(at: whichOne)
            }
        }
    }
    
    func randomlySelectRemainingArrayOfTools() {
        if self.selectionTypeIsManual == false {
            self.reset()
        }
        arrayForRandomSelection = appDelegate.getRequiredArray("AGToolNames")
        sevenDayToolSelection = [[String]] ()
        var randomizedList = [Int]()
        var nums = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
        if completedManualToolIds == nil {
            completedManualToolIds = Array<Int>()
        }
        for id in completedManualToolIds.reversed() {
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
        var theGroup = [String]()
        var startId = 0
        if self.completedManualToolIds.count > 0 {
            startId = completedManualToolIds.count - 1
            for indx in 0...completedManualToolIds.count  {
                if indx > 0 && indx%theToolCount == 0 {
                    sevenDayToolSelection.append(theGroup)
                    theGroup = [String]()
                }
                if indx < completedManualToolIds.count {
                    let id = completedManualToolIds[indx]
                    let tool = (appDelegate.getRequiredArray("AGToolNames"))[id]
                    theGroup.append(tool)
                    if completedTools == nil {
                        completedTools = Array<String>()
                    }
                    completedTools.append(tool)
                }
            }
        }
        
        for indx in 0..<randomizedList.count {
            if theGroup.count == theToolCount {
                sevenDayToolSelection.append(theGroup)
                theGroup = [String]()
            }
            if sevenDayToolSelection.count < 7 {
                theGroup.append((appDelegate.getRequiredArray("AGToolNames"))[randomizedList[indx]])
            }
            
        }
        if theGroup.count == theToolCount {
            sevenDayToolSelection.append(theGroup)
            theGroup = [String]()
        }
        setTheDatesInTheDatastore()
        datastore.save("SelectedGroups", value:(sevenDayToolSelection as NSObject?)!)
    }
    
    func isAlreadyInArray(_ tool:NSString) -> Bool {
        completedTools = datastore.loadArray("CompletedTools") as? Array<String>
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
        if theToolCount == nil {
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
