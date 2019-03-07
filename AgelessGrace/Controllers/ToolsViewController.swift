//
//  ToolsViewController.swift
//  AgelessGrace
//
//  Created by David Brownstone on 21/12/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit
import MediaPlayer

var SESSIONPERIOD = 1.00//10.0
let toolControl:ToolProtocol = ToolManipulations()

class ToolsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MPMediaPickerControllerDelegate, UITabBarControllerDelegate {
    
    @IBOutlet weak var theTableView: UITableView!
    @IBOutlet weak var completedNotice: UIView!
    
    var exercisingConsecutively:Bool?
    var exercisePeriodHasYetToStart = true
    var completedToolSets:[Array<String>]?
    var completedTools:[String]?
    var lastCompletedGroup:[String]?
    var dateOfLastCompletedExercise:Date?
    var selectedGroups:[Array<String>]?
    var startDate:Date!
    
    var musicForSelectedGroup:Array<[String: Any]>!
    var selectedPlaylist:MPMediaItemCollection!
    
    var selectedGroup:Array<String>!
    var selectedTools:Array<String>!
    var selectedToolsIds:Array<Int>!
    var returnedFromExercise = false
    var selectionTypeIsManual = false;
    var continueBtnTouched = false
    var reselectButtonTouched = false
    var toolsHaveBeenSelected = false
    
    var returningFromDescriptionVC = false
    var returningFromPlayMusicVC = false
    var toolGroupHasBeenCompleted = false
    var exerciseDay = 0
    var completedNoticeVisible = false
    
    let selectBtn = UIButton(type:.custom)
    let reSelectBtn = UIButton(type:.custom)
    let continueBtn = UIButton(type:.custom)
    let refreshBtn = UIButton(type:.custom)
    
    // MARK: - TabBarControllerDelegate
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let tabBarIndex = tabBarController.selectedIndex
        if tabBarIndex > 0 {
            self.returningFromDescriptionVC = true
        }
    }
    
    // MARK: - Basic Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.theTableView.delegate = self
        self.theTableView.dataSource = self
        self.tabBarController?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationItem.rightBarButtonItem = nil
        
        self.exercisingConsecutively = datastore.shouldExerciseDaily()
        self.exercisePeriodHasYetToStart = toolControl.exercisePeriodHasYetToStart()
        self.startDate = datastore.loadDate("StartingDate")
        self.dateOfLastCompletedExercise = datastore.loadDate("DateOfLastExercise")
        self.completedToolSets = datastore.getCompletedToolSets()
        self.selectedGroups = datastore.getSelectedGroups()
        self.selectedGroup = datastore.getSelectedGroup()
        self.lastCompletedGroup = self.completedToolSets?.last//datastore.getLastCompletedGroup()

        if self.selectedTools != nil &&
           self.selectedGroups != nil &&
            self.selectedTools!.count > (self.selectedGroups!.count * 3) {
            setUpExistingToolGroups()
            theTableView.reloadData()
            return
        }
        
        prepareButtons()
 
        if datastore.lastCompletedExerciseWasToday() {
            self.selectedGroup = self.lastCompletedGroup
            self.completedNotice.isHidden = false
            let rightBarSelectButtonItem: UIBarButtonItem = UIBarButtonItem(customView: refreshBtn)
            self.navigationItem.setRightBarButton(
                rightBarSelectButtonItem, animated: false)
        } else if datastore.lastCompletedExerciseWasYesterday() {
            print("lastCompletedExerciseWasYesterday = true")
            //display the next selected tool if it exists
            let indx = self.selectedGroups!.index(of:self.lastCompletedGroup!)
            if self.selectedGroups!.count > (indx! + 1) {
                selectedGroup = self.selectedGroups![indx! + 1]
            } else if self.selectedGroups!.count == 7 {
                datastore.resetCompletedWeeks()
                datastore.clearSelectedGroup()
                datastore.clearSelectedGroups()
                datastore.resetLastCompletedExercisDate()
                datastore.resetCompletedToolSets()
                datastore.resetDates()
                self.toolsDescr = appDelegate.getRequiredArray("AGToolNames")
            }
            
        }
        
        if self.dateOfLastCompletedExercise != nil && datastore.isToday(self.dateOfLastCompletedExercise!) {
            self.completedNotice.isHidden = false
            let theCount = self.completedToolSets!.count
            self.title = String(format:"Day %d", theCount)
        } else if selectedPlaylist == nil || self.returnedFromExercise {
            if returningFromDescriptionVC ||
                returningFromPlayMusicVC  {
                self.returningFromDescriptionVC = false
                self.returningFromPlayMusicVC = false
                if self.completedNotice.isHidden {
                    self.title = "Day 1"
                    replaceButtonWithMusicSelector()
                }
            } else {
                if self.returnedFromExercise  && self.toolGroupHasBeenCompleted {
                    if datastore.lastCompletedExerciseWasToday() {
                        self.completedNotice.isHidden = false
                        let rightBarSelectButtonItem: UIBarButtonItem = UIBarButtonItem(customView: refreshBtn)
                        self.navigationItem.setRightBarButton(
                            rightBarSelectButtonItem, animated: false)
                    }
                }
                if self.completedNotice.isHidden {
                    if datastore.isToday(self.startDate){
                        replaceButtonWithMusicSelector()
                    } else {
                        let rightBarSelectButtonItem: UIBarButtonItem = UIBarButtonItem(customView: selectBtn)
                        self.navigationItem.setRightBarButton(
                        rightBarSelectButtonItem, animated: false)
                    }
                }
            }
        } else {
            if toolGroupHasBeenCompleted {
                let rightBarSelectButtonItem: UIBarButtonItem = UIBarButtonItem(customView: selectBtn)
                self.navigationItem.setRightBarButton(
                    rightBarSelectButtonItem, animated: false)
            }
        }
        theTableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.toolGroupHasBeenCompleted {
            endOfSession()
            self.toolGroupHasBeenCompleted = false
        }
        
        let diffInDays = datastore.getDaysSinceLastExercise()
        if self.exercisingConsecutively! && diffInDays > 1 {
            showWarningMessage(diffInDays)
        }
    }
 
    // MARK: - Actions

    func prepareButtons() {
        refreshBtn.addTarget(self, action: #selector(self.refreshTable(_:)), for: .touchDown)
        refreshBtn.setImage(UIImage(named: "synch"), for: UIControl.State.normal)
        selectBtn.sizeToFit()
        refreshBtn.setTitleColor(UIColor(red: 42/255, green: 22/255, blue: 114/255, alpha: 1), for: UIControl.State())
        refreshBtn.backgroundColor = .clear
        
        selectBtn.addTarget(self, action: #selector(self.showActionSheet), for: UIControl.Event.touchUpInside)
        var title = NSLocalizedString("Select", comment:"")
        selectBtn.setTitleColor(UIColor(red: 42/255, green: 22/255, blue: 114/255, alpha: 1), for: UIControl.State())
        selectBtn.setAttributedTitle(NSAttributedString(string: title, attributes:[
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.light)]), for: .normal)
        selectBtn.sizeToFit()
        selectBtn.backgroundColor = .clear
        
        title = NSLocalizedString("Continue", comment:"")
        continueBtn.addTarget(self, action: #selector(self.updateDisplayList(_:)), for: .touchDown)
        continueBtn.setTitleColor(UIColor(red: 42/255, green: 22/255, blue: 114/255, alpha: 1), for: UIControl.State())
        continueBtn.setAttributedTitle(NSAttributedString(string: title, attributes:[
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.light)]), for: .normal)
        continueBtn.sizeToFit()
        continueBtn.backgroundColor = .clear
    }
    
    func setRefreshButton() {
        let rightBarRefreshButtonItem: UIBarButtonItem = UIBarButtonItem(customView: refreshBtn)
        self.navigationItem.setRightBarButton(rightBarRefreshButtonItem, animated: false)
    }
    
    func showWarningMessage(_ days: Int) {
        var title = String(format: NSLocalizedString("You last exercised %d days ago", comment:""), days)
        let message = NSLocalizedString("Touch 'Reset Start' to change  your 7 day sessions to begin today, or 'Go Ahead' to change your setting to exercise intermittenly.", comment:"")
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        title = NSLocalizedString("Reset Start", comment:"")
        let resetStartDate = UIAlertAction(title: title, style: .cancel) { (alert: UIAlertAction!) -> Void in
            datastore.setDates(Date())
            let lastCompletedGroup = datastore.getLastCompletedGroup()
            if lastCompletedGroup.count > 0 {
                let indx = self.selectedGroups!.index(of: lastCompletedGroup)
                var temp = self.selectedGroups
                self.selectedGroups = [Array<String>]()
                for i in 0..<temp!.count {
                    if i > indx! {
                        self.selectedGroups?.append(temp![i])
                    }
                }
                self.selectedGroup = self.selectedGroups![0]
            }
        }
        alertController.addAction(resetStartDate)
        title = NSLocalizedString("Go Ahead", comment:"")
        let intermittentAction = UIAlertAction(title: title, style: .default) { (alert: UIAlertAction!)-> Void in
            datastore.setShouldExerciseDaily(false)
        }
        alertController.addAction(intermittentAction)
        present(alertController, animated: true, completion:nil)
    }
    
    var toolsDescr:Array<String>!
    
    // manual selection
    @objc func addSelectionToList(_ sender: UIButton) {
        if self.selectedTools == nil {
            self.selectedTools = Array<String>()
        }
        let cell = sender.superview?.superview as! UITableViewCell
        let indexPath = theTableView.indexPath(for: cell)
        sender.setImage(UIImage(named: "manuallySelected"), for: .normal)
        if self.selectedGroup == nil {
            self.selectedGroup = []
        }
        let toolName = toolsDescr[indexPath!.row]
        if self.selectedGroup.contains(toolName) {
            var indx = self.selectedGroup.index(of: toolName)
            self.selectedGroup.remove(at:indx!)
            indx = self.selectedTools.index(of: toolName)
            self.selectedTools.remove(at:indx!)
            sender.setImage(UIImage(named:"selector"), for: .normal)
        } else {
            self.selectedGroup.append(toolName)
            self.selectedTools.append(toolName)
        }
        if self.selectedGroup.count % 3 == 0 {
            if self.selectedGroups == nil {
                self.selectedGroups = [Array<String>]()
            }
            self.selectedGroups?.append(self.selectedGroup)
            self.selectedGroup = nil
            selectionTypeIsManual = true
            let rightBarContinueButtonItem: UIBarButtonItem = UIBarButtonItem(customView: continueBtn)
            self.navigationItem.setRightBarButton(
                rightBarContinueButtonItem, animated: false)
        } else {
//            let rightBarSelectButtonItem: UIBarButtonItem = UIBarButtonItem(customView: selectBtn)
//            self.navigationItem.setRightBarButton(
//                rightBarSelectButtonItem, animated: false)
            self.navigationItem.rightBarButtonItem = nil
        }
    }
    
    var completedRequirementMessageDisplayed = false
    @objc func refreshTable(_ sender: UIButton) {
        let titleIndex = Int((self.title!.split(separator: " "))[1])
        if titleIndex == 7 && datastore.yesterdayWasDay7() {
            selectedGroup = nil
            selectedGroups = nil
            userDefaults.removeObject(forKey:"SelectedGroup")
            userDefaults.removeObject(forKey:"SelectedGroups")
            self.completedNotice.isHidden = true
            self.completedNoticeVisible = false
            theTableView.reloadData()
        } else {
            if selectedGroups!.index(of: selectedGroup) == titleIndex! - 1 {
                if datastore.getDaysSinceLastExercise() == 0  {
                    completedRequirementMessageDisplayed = true
                    let message = NSLocalizedString("Your exercise requirement for today is complete. You should continue tomorrow!", comment: "")
                    let title = NSLocalizedString("You're done!", comment: "")
                    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .cancel) {
                        (action) -> Void in
                        self.completedNotice.isHidden = false
                        self.completedNoticeVisible = true
                    }
                    alertController.addAction(okAction)
                    present(alertController, animated: true, completion:nil)
                } else {
                    selectedGroup = selectedGroups![titleIndex! - 1]
                    if completedRequirementMessageDisplayed == false {
                        self.completedNotice.isHidden = true
                        self.completedNoticeVisible = false
                    }
                }
            } else {
                selectedGroup = selectedGroups![titleIndex! - 1]
                if completedRequirementMessageDisplayed == false {
                    self.completedNotice.isHidden = true
                    self.completedNoticeVisible = false
                }
                theTableView.reloadData()
            }
        }
    }
    
    func setUpExistingToolGroups() {
        selectedGroups = [Array<String>]()
        selectedGroup = [String]()
        if selectedTools != nil {
            let noOfGroups = (selectedTools!.count) / 3
            for i in 0..<noOfGroups {
                selectedGroups!.append([selectedTools[0 + (i * 3)],
                                        selectedTools[1 + (i * 3)],
                                        selectedTools[2 + (i * 3)] ])
                datastore.save("SelectedGroups", value: self.selectedGroups! as NSObject)
            }
            
            for group in selectedGroups! {
                if completedToolSets != nil && completedToolSets!.contains(group) == false {
                    selectedGroup = group
                    break
                }
            }
        }
    }
    
    @objc func updateDisplayList(_ sender: UIButton) {
        continueBtnTouched = true
        updateDisplayList()
    }
    
    func updateDisplayList() {
        self.toolsHaveBeenSelected = true
        setUpExistingToolGroups()
        self.selectedGroup = self.selectedGroups![0]
        datastore.save("SelectedGroup", value: self.selectedGroup! as NSObject)
        self.selectedPlaylist = nil
        self.theTableView.reloadData()
        let topIndex = IndexPath(row: 0, section: 0)
        self.theTableView.scrollToRow(at: topIndex, at: .top, animated: true)
    }
    
    @objc func showActionSheet() {
        var title = NSLocalizedString("Select Type of Session", comment:"")
        let noOfDaysRemaining = 7 - (selectedGroups?.count)!
        let message = String( format: NSLocalizedString("Touch 'Random' to randomly select %d days worth of 10 minute sessions or 'Select' to manually add tool groups.", comment:""),noOfDaysRemaining)
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        title = NSLocalizedString("Random", comment:"")
        let randomAction = UIAlertAction(title: title, style: .default) { (alert: UIAlertAction!) -> Void in
            //assuming 3 tools completed for every 10 minutes
            toolControl.setToolCount(3)
            toolControl.setSessionPeriod(SESSIONPERIOD)
            toolControl.setSelectionType(self.selectionTypeIsManual)
            if self.selectedTools != nil && self.selectedGroups == nil {
                self.setUpExistingToolGroups()
            } else if self.selectedTools == nil {
                self.selectedTools = [String]()
                for aGroup in self.selectedGroups! {
                    for i in 0..<3 {
                        self.selectedTools.append(aGroup[i])
                    }
                }
            }
            toolControl.randomlySelectRemainingArrayOfTools(self.selectedGroups ?? [], selectedTools:self.selectedTools ?? [])
            self.selectedGroups = datastore.getSelectedGroups()
            self.toolsHaveBeenSelected = true
            self.selectedPlaylist = nil
            self.theTableView.reloadData()
        }
        alertController.addAction(randomAction)
        title = NSLocalizedString("Select", comment:"")
        let manuallySelectAction = UIAlertAction(title: title, style: .default) { (alert: UIAlertAction!) -> Void in
            self.reselectButtonTouched = true
            self.updateDisplayList()
            self.theTableView.reloadData()
        }
        alertController.addAction(manuallySelectAction)
        title = NSLocalizedString("Cancel", comment:"")
        let cancelAction = UIAlertAction(title: title, style: .cancel)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion:nil)
    }
    
    func image(with image: UIImage?, scaledTo newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(newSize)
        image?.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func replaceButtonWithMusicSelector() {
        self.completedNotice.isHidden = true
        self.completedNoticeVisible = true
        let items = [NSLocalizedString("Reselect", comment: "") , "music"]
        let segmentedControl = UISegmentedControl(items : items)
        let newImage = image(with: (UIImage(named: "music_image")), scaledTo: CGSize(width: 30, height: 30))
        segmentedControl.setImage(newImage , forSegmentAt: 1)
        segmentedControl.backgroundColor = .clear
        segmentedControl.tintColor = .black
        segmentedControl.addTarget(self, action: #selector(ToolsViewController.indexChanged(_:)), for: .valueChanged)
        segmentedControl.layer.cornerRadius = 5.0
        let rightBarSelectButtonItem: UIBarButtonItem = UIBarButtonItem(customView: segmentedControl)
        self.navigationItem.setRightBarButton(rightBarSelectButtonItem, animated: false)
    }
    
    @objc func indexChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex{
        case 0: // allows you to add/change your unused tool selections or add randomly selected tools to complete 7 days
            self.showActionSheet()
        case 1:
            self.selectMusicForGroup()
        default:
            break
        }
    }
    
    func startTheSession() {
        if #available(iOS 9.3, *) {
            let authorizationStatus = MPMediaLibrary.authorizationStatus()
            switch authorizationStatus {
            case .notDetermined:
                // Show the permission prompt.
                MPMediaLibrary.requestAuthorization({[weak self] (newAuthorizationStatus: MPMediaLibraryAuthorizationStatus) in
                    // Try again after the prompt is dismissed.
                    self?.startTheSession()
                })
            case .denied, .restricted:
                // Do not use MPMediaQuery.
                return
            default:
                appDelegate.mediaAuthorized = true
                break
            }
        } else {
            appDelegate.mediaAuthorized = true
        }
        
        if self.selectedPlaylist != nil {
            // if all the music has been selected for this group
            if appDelegate.mediaAuthorized {
                self.performSegue(withIdentifier: "Countdown", sender: self)
            }
        }
    }
    
    func endOfSession() {
        var message = ""
        let endingDate = datastore.loadDate("EndingDate")
        let calendar = NSCalendar.current
        var completedWeekCount = 0
        if calendar.isDateInToday(endingDate) {
            selectedGroup = nil
            completedWeekCount = datastore.setCompletedWeeks()
            switch completedWeekCount {
            case 3:
                message = NSLocalizedString("You are a champion! Your brain is getting stronger every day -- you did your Ageless Grace tools for 21 days in a row!", comment: "")
                datastore.resetCompletedWeeks()
                break
            default:
                message = NSLocalizedString("Wow! You have done your Ageless Grace Brain Health tools every day for a week now!", comment: "")
                break
            }
            toolsDescr = appDelegate.getRequiredArray("AGToolNames")
            selectedGroups = nil
        } else  {
            if self.exercisingConsecutively! {
                message =  NSLocalizedString("Congratulations on doing your 10 minutes of Ageless Grace Brain. See you tomorrow!", comment:"")
            } else {
                message =  NSLocalizedString("Congratulations on doing your 10 minutes of Ageless Grace Brain. See you next time!", comment:"")
            }
        }
        var theTitle = NSLocalizedString("Well Done!", comment:"")
        let alert = UIAlertController(title: theTitle, message: message, preferredStyle: .alert)
        theTitle =  NSLocalizedString("OK", comment:"")
        let actionOK = UIAlertAction(title: theTitle, style: .cancel, handler: {
            (action) -> Void in
            self.theTableView.reloadData()
        })
        alert.addAction(actionOK)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func calculateDaysBetweenTwoDates(start: Date, end: Date) -> Int {
        
        let currentCalendar = Calendar.current
        guard let start = currentCalendar.ordinality(of: .day, in: .era, for: start) else {
            return 0
        }
        guard let end = currentCalendar.ordinality(of: .day, in: .era, for: end) else {
            return 0
        }
        return end - start
    }
    
    // MARK: -  UITableViewDelegate and DataSelect
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.dateOfLastCompletedExercise != nil && datastore.isToday(self.dateOfLastCompletedExercise!) {
            toolsDescr = self.lastCompletedGroup
            self.setRefreshButton()
        } else if (self.toolsHaveBeenSelected && continueBtnTouched) ||
            (self.selectedGroup != nil && self.selectedGroup.count == 3 && !self.reselectButtonTouched) {
            // display only the selected group
            self.continueBtnTouched = false
            self.title = "Day \(selectedGroups!.index(of: selectedGroup)! + 1)"
            self.replaceButtonWithMusicSelector()
            toolsDescr = self.selectedGroup
        } else if self.selectedGroups != nil && self.selectedGroups!.count == 7 {
            for aGroup in self.selectedGroups! {
                if self.completedToolSets != nil && self.completedToolSets!.contains(aGroup) {
                    continue
                } else {
                    self.selectedGroup = aGroup
                    break
                }
            }
            toolsDescr = self.selectedGroup
        } else {
            self.title = NSLocalizedString("Available Tools", comment:"")
            toolsDescr = appDelegate.getRequiredArray("AGToolNames")
            if selectedTools != nil && selectedTools.count > 0 {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: continueBtn)
                reselectButtonTouched = false
                selectedGroup = nil
                selectedGroups = nil
            } else {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: selectBtn)
//              if datastore.isToday(startDate) {
//                toolControl.reset7DayPeriod()
//              }
            }
        }
        return 1
    }
    
    func getDateString(fromDate: Date) -> String{
        let components = Calendar.current.dateComponents([.year, .month, .day], from: fromDate)
        if let day = components.day, let month = components.month {
            return String(format: "(%02d/%02d)", day,month)
        }
        return ""
    }
    
    func tableView(_ tableView:UITableView, willDisplay cell:UITableViewCell, forRowAt indexPath:IndexPath) {
        if (indexPath.row%2 != 0) {
            let altCellColor = UIColor(white:0.7, alpha:0.1)
            cell.backgroundColor = altCellColor;
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return toolsDescr.count
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
        
    }
    
    func getToolNumber(_ tool:String) -> Int {
        return ((appDelegate.getRequiredArray("AGToolNames")).index(of: tool)! + 1)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "toolCell", for: indexPath)
        
        // Configure the cell...
        let titleRow = cell.viewWithTag(10) as! UILabel
        titleRow.text = "\(NSLocalizedString("Tool", comment:""))#\(getToolNumber(toolsDescr[indexPath.row])): \(toolsDescr[indexPath.row])"
        let subTitleRow = cell.viewWithTag(11) as! UILabel
        subTitleRow.text = (appDelegate.getRequiredArray("AGToolPrimaryBenefits"))[indexPath.row]
        subTitleRow.textAlignment = .center
        let selectorBtn = cell.viewWithTag(12) as! UIButton
        selectorBtn.addTarget(self, action: #selector(self.addSelectionToList(_:)), for: .touchDown)
        selectorBtn.setImage(UIImage(named:"selector"), for: .normal)
        selectorBtn.isHidden = false
        if self.selectedGroup == nil {
            self.selectedGroup = []
        }
        
        let theTool = toolsDescr[indexPath.row]
        if self.completedTools != nil && self.completedTools!.contains(theTool) {
            selectorBtn.isHidden = true
        } else if self.selectedTools != nil && self.selectedTools.contains(theTool) && self.toolsDescr.count > 3 {
            selectorBtn.setImage(UIImage(named:"manuallySelected"), for: .normal)
        } else {
            selectorBtn.setImage(UIImage(named:"selector"), for: .normal)
        }
        
        if toolsHaveBeenSelected && indexPath.row < selectedGroup.count {
            let indx = (appDelegate.getRequiredArray("AGToolNames")).index(of: selectedGroup[indexPath.row])
            titleRow.text = "\(NSLocalizedString("Tool", comment:""))#\(indx! + 1): \(selectedGroup[indexPath.row])"
            subTitleRow.text = (appDelegate.getRequiredArray("AGToolPrimaryBenefits"))[indx!]
            selectorBtn.isHidden = true
        }
        return cell
    }
    
    func getTheNameOnly(toolName: String) -> String {
        // Find index of space.
        if let space = toolName.index(of: ":") {
            // Return substring.
            // ... Use "after" to avoid including the space in the substring.
            let result = String(toolName[toolName.index(after: space)..<toolName.endIndex])
            return String(result[result.index(result.startIndex, offsetBy: 1)..<result.endIndex])
        }
        return toolName
    }
    func updateTheDates() {
        var startDate = datastore.loadDate("StartingDate")
        startDate = datastore.updateDate(startDate, byDays:1)
        var endDate = datastore.loadDate("EndingDate")
        endDate = datastore.updateDate(endDate, byDays:1)
    }
    
    // MARK: - Navigation
    
    @IBAction func unwindToMainMenu(_ sender: UIStoryboardSegue) {
        toolControl.saveLastCompletedGroup(self.selectedGroup)
        
        if self.toolGroupHasBeenCompleted {
            let indx = self.selectedGroups!.index(of:self.selectedGroup)
            if self.selectedGroups!.count < 7 && (indx == self.selectedGroups!.count - 1) {
                selectedGroup = nil
            }  else {
                self.completedNotice.isHidden = false
                self.completedNoticeVisible = true
                let rightBarSelectButtonItem: UIBarButtonItem = UIBarButtonItem(customView: refreshBtn)
                self.navigationItem.setRightBarButton(
                    rightBarSelectButtonItem, animated: false)
            }
        }
    }
    
    @IBAction func unwindForLaterPlay(_ sender: UIStoryboardSegue) {
        let selectedAction = (sender.source as! PlayMusicViewController).selectedAction
        switch selectedAction!.rawValue {
        case 0: //deferred
            break;
        case 1: //tomorrow
            self.toolsHaveBeenSelected = false
            self.navigationItem.rightBarButtonItem = nil
            updateTheDates()
        case 2: //postpone
            self.toolsHaveBeenSelected = false
            self.navigationItem.rightBarButtonItem = nil
            let startDate = datastore.loadDate("StartingDate")
            let index = datastore.daysBetweenDate(startDate, endDate: Date())
            selectedGroups?.remove(at:index)
            selectedGroups?.append(selectedGroup)
            updateTheDates()
        default:
            break
        }
        self.returningFromPlayMusicVC = true
        self.toolsHaveBeenSelected = false
        selectedPlaylist = nil
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Countdown" {
            let navControl = segue.destination as! UINavigationController
            let controller = navControl.topViewController as! PlayMusicViewController
            controller.selectedPlayList = selectedPlaylist
            controller.selectedGroup = selectedGroup
//            controller.selectionTypeIsManual = self.selectionTypeIsManual
            if self.completedToolSets == nil {
                self.completedToolSets = [Array<String>]()
            }
        } else if segue.identifier == "showToolDescr" {
            let cell = sender as! UITableViewCell
            let indexPath = self.theTableView.indexPath(for: cell)
            let controller = segue.destination as! ToolDescriptionViewController
            let selectedTool = self.toolsDescr[indexPath!.row]
            self.returningFromDescriptionVC = true
            controller.completedNoticeVisible = self.completedNoticeVisible
            controller.selectedToolIndex = (appDelegate.getRequiredArray("AGToolNames")).index(of:selectedTool)
        }
    }
    
    @objc func selectMusicForGroup() {
        musicForSelectedGroup = Array<[String: Any]> ()
        let mediaPicker = MPMediaPickerController(mediaTypes: .music)
        
        mediaPicker.delegate = self
        mediaPicker.allowsPickingMultipleItems = true
        mediaPicker.showsCloudItems = true
        let prompt = NSLocalizedString("Select 3 songs", comment:"")
        mediaPicker.prompt = prompt
        present(mediaPicker, animated: true, completion: nil)
        
    }
    
    func validateTheTotalPlayingTime(_ totalPlayingTime: Double) {
        
    }
    
    // MARK: - Media Picker
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        
        selectedPlaylist = mediaItemCollection
        for thisItem in mediaItemCollection.items {
            let persistentID = thisItem.value(forProperty: MPMediaItemPropertyPersistentID) as! NSNumber
            let title = thisItem.value(forProperty: MPMediaItemPropertyTitle) as! String
            let album = thisItem.albumTitle!
            let artist = thisItem.artist!
            let genre = thisItem.genre
            let duration = thisItem.value(forProperty: MPMediaItemPropertyPlaybackDuration) as? Double
            musicForSelectedGroup.append(["ID": persistentID as Any,
                                          "title": title as Any,
                                          "album": album as Any,
                                          "artist": artist as Any,
                                          "genre": genre as Any,
                                          "duration": duration as Any]
            )
        }
        self.navigationItem.rightBarButtonItem = nil
        self.dismiss(animated: true, completion:nil);
        self.startTheSession()
    }
    
    func mediaPickerDidCancel(_ mediaPicker:MPMediaPickerController) {
        
        self.dismiss(animated: true, completion:nil);
    }
}
