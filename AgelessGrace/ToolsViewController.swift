//
//  ToolsViewController.swift
//  AgelessGrace
//
//  Created by David Brownstone on 21/12/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit
import MediaPlayer

var SESSIONPERIOD = 10.00

let toolControl:ToolProtocol = ToolManipulations()

class ToolsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var theTableView: UITableView!
    @IBOutlet weak var completedNotice: UIView!
    
    var selectedGroup:Array<String>!
    var completedManualTools:Array<String>!
    var completedManualToolIds:Array<Int>!
    var returnedFromExercise = false
    var selectionTypeIsManual = false;
    var selectedGroups: Array<[String]>!
    var musicForSelectedGroup:Array<[String: Any]>!
    var toolsHaveBeenSelected = false
    
    var returningFromDescriptionVC = false
    var returningFromPlayMusicVC = false
    var showingNextToolInSimulator = false
    var startDate:Date!
    var selectedPlaylist:MPMediaItemCollection!
    var toolGroupHasBeenCompleted = false
    var exerciseDay = 0
    
    let selectBtn = UIButton(type:.custom)
    let reSelectBtn = UIButton(type:.custom)
    let continueBtn = UIButton(type:.custom)
    let nextToolButton = UIButton(type: .custom) // used only for simulator
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.theTableView.delegate = self
        self.theTableView.dataSource = self
        if UIDevice.isSimulator {
            SESSIONPERIOD = 0.25 //1.0
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.rightBarButtonItem = nil
        
        if selectedPlaylist == nil {
            if returningFromDescriptionVC || returningFromPlayMusicVC {
                self.returningFromDescriptionVC = false
                self.returningFromPlayMusicVC = false
                if self.completedNotice.isHidden == false {
                    self.navigationItem.rightBarButtonItem = nil
                } else {
                    replaceButtonWithMusicSelector()
                }
            } else {
                selectBtn.addTarget(self, action: #selector(self.showActionSheet), for: UIControl.Event.touchUpInside)
                var title = NSLocalizedString("Select", comment:"")
                //            selectBtn.setTitle(title, for: UIControl.State())
                selectBtn.setTitleColor(UIColor(red: 42/255, green: 22/255, blue: 114/255, alpha: 1), for: UIControl.State())
                selectBtn.setAttributedTitle(NSAttributedString(string: title, attributes:[
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.light)]), for: .normal)
                selectBtn.sizeToFit()
                selectBtn.backgroundColor = .clear
                //            selectBtn.layer.borderWidth = 1
                //            selectBtn.layer.borderColor = UIColor.gray.cgColor
                title = NSLocalizedString("Continue", comment:"")
                //            continueBtn.setTitle(title, for: UIControl.State())
                continueBtn.setTitleColor(UIColor(red: 42/255, green: 22/255, blue: 114/255, alpha: 1), for: UIControl.State())
                continueBtn.setAttributedTitle(NSAttributedString(string: title, attributes:[
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.light)]), for: .normal)
                continueBtn.sizeToFit()
                continueBtn.backgroundColor = .clear
                //            continueBtn.layer.borderWidth = 1
                //            continueBtn.layer.borderColor = UIColor.gray.cgColor
                continueBtn.addTarget(self, action: #selector(self.updateDisplayList(_:)), for: .touchDown)
                if UIDevice.isSimulator {
                    nextToolButton.addTarget(self, action: #selector(self.showNextTool), for: UIControl.Event.touchUpInside)
                    nextToolButton.setTitleColor(UIColor(red: 42/255, green: 22/255, blue: 114/255, alpha: 1), for: UIControl.State())
                    nextToolButton.setImage(UIImage(named:"next"), for: .normal)
                    nextToolButton .backgroundColor = .clear
                }
                if self.completedNotice.isHidden == true {
                    let rightBarSelectButtonItem: UIBarButtonItem = UIBarButtonItem(customView: selectBtn)
                    self.navigationItem.setRightBarButton(
                        rightBarSelectButtonItem, animated: false)
                }
            }
        } else {
            if toolGroupHasBeenCompleted {
                let rightBarSelectButtonItem: UIBarButtonItem = UIBarButtonItem(customView: selectBtn)
                self.navigationItem.setRightBarButton(
                    rightBarSelectButtonItem, animated: false)
            }
        }
    }
    
    @objc func showNextTool() {
        showingNextToolInSimulator = true
        let currentIndex = selectedGroups.index(of: selectedGroup)! + 1
        self.exerciseDay += 1
        selectedGroup = nil
        selectedGroup = selectedGroups![currentIndex]
        self.title = ""
        self.title = String(format: "Day %d", self.exerciseDay)
        self.theTableView.reloadData()
        showingNextToolInSimulator = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.toolGroupHasBeenCompleted {
            endOfSession()
            self.toolGroupHasBeenCompleted = false
        }
    }
    
    // MARK: - Actions
    var toolsDescr:Array<String>!
    
    // manual selection
    @objc func addSelectionToList(_ sender: UIButton) {
        let cell = sender.superview?.superview as! UITableViewCell
        let indexPath = theTableView.indexPath(for: cell)
        sender.setImage(UIImage(named: "manuallySelected"), for: .normal)
        if self.selectedGroup == nil {
            self.selectedGroup = []
        }
        let toolName = toolsDescr[indexPath!.row]
        if self.selectedGroup.contains(toolName) {
            let indx = self.selectedGroup.index(of: toolName)
            self.selectedGroup.remove(at:indx!)
            sender.setImage(UIImage(named:"selector"), for: .normal)
        } else {
            self.selectedGroup.append(toolName)
        }
        if self.selectedGroup.count >= 3 {
            selectionTypeIsManual = true
            let rightBarContinueButtonItem: UIBarButtonItem = UIBarButtonItem(customView: continueBtn)
            self.navigationItem.setRightBarButton(
                rightBarContinueButtonItem, animated: false)
        } else {
            let rightBarSelectButtonItem: UIBarButtonItem = UIBarButtonItem(customView: selectBtn)
            self.navigationItem.setRightBarButton(
                rightBarSelectButtonItem, animated: false)
        }
    }
    
    @objc func updateDisplayList(_ sender: UIButton) {
        self.toolsHaveBeenSelected = true
        self.selectionTypeIsManual = true
        self.selectedPlaylist = nil
        self.theTableView.reloadData()
        let topIndex = IndexPath(row: 0, section: 0)
        self.theTableView.scrollToRow(at: topIndex, at: .top, animated: true)
    }
    
    @objc func showActionSheet() {
        var title = NSLocalizedString("Select Type of Session", comment:"")
        let noOfDaysRemaining = 7 - (completedManualTools.count / 3)
        let message = String( format: NSLocalizedString("Touch 'OK' to randomly select %d days worth of 10 minute sessions.", comment:""),noOfDaysRemaining)
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        title = NSLocalizedString("OK", comment:"")
        let randomAction = UIAlertAction(title: title, style: .default) { (alert: UIAlertAction!) -> Void in
            //assuming 3 tools completed for every 10 minutes
            toolControl.setToolCount(3)
            toolControl.setSessionPeriod(SESSIONPERIOD)
            toolControl.setSelectionType(self.selectionTypeIsManual)
            self.completedManualToolIds = toolControl.getManuallyCompletedToolIds()
            if self.completedManualToolIds.count == 0 && self.completedManualTools.count > 0 {
                self.completedManualToolIds = [Int]()
                for i in 0..<self.completedManualTools!.count {
                    let tool = self.completedManualTools[i]
                    let index = (appDelegate.getRequiredArray("AGToolNames")).index(of: tool)!
                    self.completedManualToolIds.append(index)
                }
                if self.completedManualToolIds.count > 0 {
                    toolControl.setManuallyCompletedToolIds(self.completedManualToolIds)
                }
            }
            toolControl.randomlySelectRemainingArrayOfTools()
            let selectedGroups = datastore.loadArray("SelectedGroups")
            self.selectedGroup = selectedGroups[0] as? Array<String>
            self.toolsHaveBeenSelected = true
            self.selectedPlaylist = nil
            self.theTableView.reloadData()
        }
        alertController.addAction(randomAction)
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
        case 0: // allows you to redo your tool selections
            self.toolsHaveBeenSelected = false
            self.selectionTypeIsManual = false
            self.selectedGroup = nil
            self.theTableView.reloadData()
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
        if self.selectedPlaylist != nil  || UIDevice.isSimulator {
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
        if calendar.isDateInToday(endingDate) ||
            (UIDevice.isSimulator && selectedGroups.index(of: toolControl.getLastCompletedGroup()) == 6) {
            selectedGroup = nil
            let completedWeekCount = datastore.setCompletedWeeks()
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
        } else  {
            message =  NSLocalizedString("Congratulations on doing your 10 minutes of Ageless Grace Brain. See you tomorrow!", comment:"")
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
        if showingNextToolInSimulator {
            self.replaceButtonWithMusicSelector()
            return 1
        }
        self.selectedGroups = (datastore.loadArray("SelectedGroups") as! Array<[String]>)
//        print(self.selectedGroups!)
        var index = -1
        if  datastore.lastCompletedExerciseWasYesterday() ||
            self.toolsHaveBeenSelected ||
            self.selectedGroups.count == 7 {
            self.completedManualTools = toolControl.getManuallySelectedTools()
            if selectedGroups.count == 7 {
                if UIDevice.isSimulator {
                    index = (self.selectedGroups.index(of: toolControl.getLastCompletedGroup()) ?? -1) + 1
                } else {
                    index = datastore.daysBetweenDate(datastore.loadDate("StartingDate"),endDate: Date())
                }
                if (index < 7) {
                    selectedGroup = self.selectedGroups?[index]
                } else {
                    selectedGroup = nil
                }
            }
            if selectedGroup != nil && selectedGroup.count == 3 {
                if selectedGroups.contains(selectedGroup)  {
                    if UIDevice.isSimulator {
                        self.exerciseDay = (self.selectedGroups.index(of:toolControl.getLastCompletedGroup()) ?? -1) + 2
                        if toolControl.getLastCompletedGroup() == selectedGroup {
                            let rightBarSelectButtonItem: UIBarButtonItem = UIBarButtonItem(customView: nextToolButton)
                            self.navigationItem.setRightBarButton(
                                rightBarSelectButtonItem, animated: false)
                        }
                    } else {
                        var startDate = Date()
                        if let theDate = userDefaults.object(forKey: "StartingDate") {
                            startDate = (theDate as? Date)!
                        }
                        self.exerciseDay = calculateDaysBetweenTwoDates(start: startDate, end: Date()) + 1
                        if toolControl.getLastCompletedGroup() == selectedGroup {
                            self.completedNotice.isHidden = false
                            self.navigationItem.rightBarButtonItem = nil
                        }

                    }
                    self.title = String(format: "Day %d", self.exerciseDay)
                } else {
                    self.title = NSLocalizedString("Selected Tools", comment:"")
                }
                toolsDescr = selectedGroup
                self.toolsHaveBeenSelected = true
                if selectedPlaylist == nil && self.completedNotice.isHidden == true && toolControl.getLastCompletedGroup() != selectedGroup {
                    self.replaceButtonWithMusicSelector()
                }
                if self.toolGroupHasBeenCompleted {
                    if UIDevice.isSimulator {
                        let rightBarSelectButtonItem: UIBarButtonItem = UIBarButtonItem(customView: nextToolButton)
                        self.navigationItem.setRightBarButton(
                            rightBarSelectButtonItem, animated: false)
                    } else {
                        self.navigationItem.rightBarButtonItem = nil
                        self.completedNotice.isHidden = false
                    }
                }
            } else {
                self.title = NSLocalizedString("Available Tools", comment:"")
                toolsDescr = appDelegate.getRequiredArray("AGToolNames")
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: selectBtn)
            }
        } else {
            self.title = NSLocalizedString("Available Tools", comment:"")
            toolsDescr = appDelegate.getRequiredArray("AGToolNames")
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: selectBtn)
            datastore.resetLastCompletedExercisDate()
            datastore.resetManuallyCompletedTools()
            self.completedManualTools = []
            toolControl.reset()
        }
        return 1
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "toolCell", for: indexPath)
        
        // Configure the cell...
        let titleRow = cell.viewWithTag(10) as! UILabel
        titleRow.text = "\(NSLocalizedString("Tool", comment:""))#\(indexPath.row + 1): \(toolsDescr[indexPath.row])"
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
        if self.completedManualTools == nil {
            self.completedManualTools = []
        }
        
        let theTool = toolsDescr[indexPath.row]
        if self.completedManualTools.contains(theTool) {
            selectorBtn.isHidden = true
        } else if self.selectedGroup.contains(theTool) {
            selectorBtn.setImage(UIImage(named:"manuallySelected"), for: .normal)
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
        self.toolGroupHasBeenCompleted = true
        toolControl.saveLastCompletedGroup(self.selectedGroup)
        if self.selectionTypeIsManual {
            // save to datastore
            selectedGroup = nil
            self.returnedFromExercise = true
            toolControl.saveManuallySelectedTools(completedManualTools)
//            self.completedNotice.isHidden = false
        } else {
            self.selectedGroup = nil
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
            selectedGroups.remove(at:index)
            selectedGroups.append(selectedGroup)
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
        } else if segue.identifier == "showToolDescr" {
            let cell = sender as! UITableViewCell
            let indexPath = self.theTableView.indexPath(for: cell)
            let controller = segue.destination as! ToolDescriptionViewController
            let selectedTool = self.toolsDescr[indexPath!.row]
//            if self.title == NSLocalizedString("Selected Tools", comment:"") {
                self.returningFromDescriptionVC = true
//            }
            controller.selectedToolIndex = (appDelegate.getRequiredArray("AGToolNames")).index(of:selectedTool)
        }
    }
}

extension ToolsViewController: MPMediaPickerControllerDelegate {
    
    @objc func selectMusicForGroup() {
        if UIDevice.isSimulator {
            print("running on simulator")
            self.startTheSession()
        } else {
            let mediaPicker = MPMediaPickerController(mediaTypes: .music)
            
            mediaPicker.delegate = self
            mediaPicker.allowsPickingMultipleItems = true
            mediaPicker.showsCloudItems = true
            let prompt = NSLocalizedString("Select 3 songs.", comment:"")
            mediaPicker.prompt = prompt
            
            //        replaceButtonWithPlayButton()
            
            present(mediaPicker, animated: true, completion: nil)
        }
    }
    
    // MARK: - Media Picker
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        
        var musicForSelectedGroup = Array<[String: Any]> ()//Array<NSURL> ()
        selectedPlaylist = mediaItemCollection
        for thisItem in mediaItemCollection.items {
            let persistentID = thisItem.value(forProperty: MPMediaItemPropertyPersistentID) as! NSNumber
            let title = thisItem.value(forProperty: MPMediaItemPropertyTitle) as! String
            let album = thisItem.albumTitle!
            let artist = thisItem.artist!
            let genre = thisItem.genre
            //            let itemUrl = thisItem.value(forProperty: MPMediaItemPropertyAssetURL) as? NSURL
            musicForSelectedGroup.append(["ID": persistentID as Any,
                                          "title": title as Any,
                                          "album": album as Any,
                                          "artist": artist as Any,
                                          "genre": genre as Any]
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
