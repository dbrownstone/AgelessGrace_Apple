//
//  ToolsViewController.swift
//  AgelessGrace
//
//  Created by David Brownstone on 26/04/2019.
//  Copyright © 2019 David Brownstone. All rights reserved.
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
    var completedToolIds:[Int]?
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
    let randomBtn = UIButton(type:.custom)
    
    var toolsDescr:Array<String>!

    var segmentedControl: UISegmentedControl!
    var connectSegments: UISegmentedControl!
    var refreshSegments: UISegmentedControl!
    var randomRepeatSegments: UISegmentedControl!
    
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
        prepareButtons()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationItem.rightBarButtonItem = nil
        getDatastoreItems()
        
        var whichDay = self.completedToolSets != nil ? self.completedToolSets!.count: 0
        whichDay += 1
        self.setTheTitle(whichDay)

        if self.completedToolSets != nil {
            self.completedToolIds = self.getIds(fromGrouping: self.completedToolSets ?? [])
            self.lastCompletedGroup = self.completedToolSets?.last
        }
        if self.selectedGroups == nil || self.selectedGroups!.count < 7 {
            self.selectedTools = Array<String>()
            for group in self.selectedGroups! {
                for tool in group {
                    self.selectedTools.append(tool)
                }
            }
            self.selectedToolsIds = self.getIds(fromGrouping: self.selectedGroups ?? [])
            self.toolsDescr = appDelegate.getRequiredArray("AGToolNames")
            self.setTheTitle(0)
            if self.selectedTools!.count % 3 != 0 ||
                (self.completedToolSets != nil && self.selectedGroups!.count == self.completedToolSets!.count){
                if self.exercisingConsecutively! {
                    setRandomButton()
                } else {
                    // allow last exercise to be repeated
                    setRandomRepeatSegments()
                }                
            } else {
                var count = 0
                if self.completedToolIds != nil {
                    count = self.completedToolIds!.count
                }
                if ((self.selectedTools == nil || self.selectedTools!.count == 0) || (self.selectedTools!.count >= count && self.selectedTools!.count % 3 != 0)) {
                    self.setTheTitle(0)
                    if self.exercisingConsecutively! {
                        setRandomButton()
                    } else {
                        setRandomRepeatSegments()
                    }
                } else {
                    whichDay += 1
                    self.setConnectSegments()
                    if self.selectedGroups!.count >= whichDay {
                        selectedGroup = self.selectedGroups?[whichDay - 1]
                        self.toolsDescr = selectedGroup
                        replaceButtonWithMusicSelector()
                    } else {
                        self.toolsDescr = appDelegate.getRequiredArray("AGToolNames")
                        self.setTheTitle(0)
                    }
                }
            }
        } else {
            if datastore.lastCompletedExerciseWasToday() {
//                if !self.exercisingConsecutively! {
//                    whichDay += 1
//                }
                self.setTheTitle(whichDay)
                
                if (self.completedToolSets?.count ?? 1) < 7 {
                    self.selectedGroup = self.selectedGroups![whichDay - 1]
                    if self.selectedGroups!.count == 7 {
                        self.toolsDescr = self.selectedGroup
                    } else {
                        self.toolsDescr = appDelegate.getRequiredArray("AGToolNames")
                        setTheTitle(-1)
                    }
                    if self.exercisingConsecutively ?? false {
                        self.setRefreshSegments()
                    } else {
                        self.reselectWithMusic()
                    }
                } else {
                    self.selectedGroup = nil
                    self.selectedToolsIds = nil
                    self.toolsDescr = appDelegate.getRequiredArray("AGToolNames")
                    setTheTitle(-1)
                }
            } else {
                selectedGroup = self.selectedGroups![whichDay - 1]
                toolsDescr = selectedGroup
                replaceButtonWithMusicSelector()
            }
        }
        theTableView.reloadData()
        if self.returnedFromExercise {
            self.returnedFromExercise = false
            endOfSession()
        }
    }
    
    // MARK: - Actions
    
    func setTheTitle(_ to: Int) {
        switch to {
        case 1...7:
            if self.exercisingConsecutively! {
                self.title = String(format:NSLocalizedString("Day", comment:""), to)
            } else {
                self.title = String(format:NSLocalizedString("Exercise", comment:""), to)
            }
        default: //
            self.title =  NSLocalizedString("Available Tools", comment:"")
        }
    }
    
    func getIds(fromGrouping: [Array<String>]) -> Array<Int> {
        var resultantIdArray = Array<Int>()
        let allTools = appDelegate.getRequiredArray("AGToolNames")
        for group in fromGrouping {
            for tool in group {
                let id = allTools.index(of: tool)! + 1
                resultantIdArray.append(id)
            }
        }
        return resultantIdArray
    }
    
    func getDatastoreItems() {
        self.exercisingConsecutively = datastore.shouldExerciseDaily()
        self.startDate = datastore.loadDate("StartingDate")
        self.dateOfLastCompletedExercise = datastore.loadDate("DateOfLastExercise")
        if self.dateOfLastCompletedExercise != Date.distantPast {
            self.lastCompletedGroup = datastore.getLastCompletedGroup()
            self.completedToolSets = datastore.getCompletedToolSets()
        }
        self.selectedGroups = datastore.getSelectedGroups()
    }
    
    func prepareButtons() {
        var items = [NSLocalizedString("Select", comment: ""),"Refresh"]
        refreshSegments = UISegmentedControl(items : items)
        let newImage = image(with: (UIImage(named: "synch")), scaledTo: CGSize(width: 30, height: 30))
        refreshSegments.setImage(newImage , forSegmentAt: 1)
        refreshSegments.backgroundColor = .clear
        refreshSegments.tintColor = .black
        refreshSegments.addTarget(self, action: #selector(self.refreshTable(_:)), for: .valueChanged)
        refreshSegments.layer.cornerRadius = 5.0
        
        var title = NSLocalizedString("Random", comment:"")
        randomBtn.addTarget(self, action: #selector(self.showActionSheet(_:)), for: UIControl.Event.touchUpInside)
        randomBtn.setTitleColor(UIColor(red: 42/255, green: 22/255, blue: 114/255, alpha: 1), for: UIControl.State())
        randomBtn.setAttributedTitle(NSAttributedString(string: title, attributes:[
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.light)]), for: .normal)
        randomBtn.sizeToFit()
        randomBtn.backgroundColor = .clear
        
        selectBtn.addTarget(self, action: #selector(self.showActionSheet(_:)), for: UIControl.Event.touchUpInside)
        title = NSLocalizedString("Select", comment:"")
        //Select allow addition of new selections - either manually or randomized
        selectBtn.setTitleColor(UIColor(red: 42/255, green: 22/255, blue: 114/255, alpha: 1), for: UIControl.State())
        selectBtn.setAttributedTitle(NSAttributedString(string: title, attributes:[
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.light)]), for: .normal)
        selectBtn.sizeToFit()
        selectBtn.backgroundColor = .clear
        
        items = [NSLocalizedString("Select", comment: ""),NSLocalizedString("Continue", comment:"")]
        connectSegments = UISegmentedControl(items : items)
        connectSegments.backgroundColor = .clear
        connectSegments.tintColor = .black
        connectSegments.addTarget(self, action: #selector(self.connectIndexChanged(_:)), for: .valueChanged)
        connectSegments.layer.cornerRadius = 5.0
        
        items = [NSLocalizedString("Select", comment: ""),NSLocalizedString("Repeat", comment:"")]
        randomRepeatSegments = UISegmentedControl(items : items)
        randomRepeatSegments.backgroundColor = .clear
        randomRepeatSegments.tintColor = .black
        randomRepeatSegments.addTarget(self, action: #selector(self.connectIndexChanged(_:)), for: .valueChanged)
        randomRepeatSegments.layer.cornerRadius = 5.0
    }
    
    func setRandomButton() {
        let rightBarRandomButtonItem: UIBarButtonItem = UIBarButtonItem(customView: randomBtn)
        self.navigationItem.setRightBarButton(rightBarRandomButtonItem, animated: false)
    }
    
    func setSelectButton() {
        let rightBarRandomButtonItem: UIBarButtonItem = UIBarButtonItem(customView: selectBtn)
        self.navigationItem.setRightBarButton(rightBarRandomButtonItem, animated: false)
    }

    func setRefreshButton() {
        let rightBarRefreshButtonItem: UIBarButtonItem = UIBarButtonItem(customView: refreshBtn)
        self.navigationItem.setRightBarButton(rightBarRefreshButtonItem, animated: false)
    }
    
    func setRefreshSegments() {
        let rightBarRefreshSegmentItem: UIBarButtonItem = UIBarButtonItem(customView: refreshSegments)
        self.navigationItem.setRightBarButton(rightBarRefreshSegmentItem, animated: false)
    }
    
    func setRandomRepeatSegments() {
        let rightBarRandomRepeatSegmentItem: UIBarButtonItem = UIBarButtonItem(customView: randomRepeatSegments)
        self.navigationItem.setRightBarButton(rightBarRandomRepeatSegmentItem, animated: false)
    }
    
    @objc func randomRepeatIndexChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex
        {
        case 0: //Random
            print("Random Selected")
            self.showActionSheet(sender)
        case 1: //Repeat
            print("Repeat selected")
            self.selectedGroup = self.lastCompletedGroup
            toolsDescr = self.selectedGroup
            self.setTheTitle(self.completedToolSets!.count)
            theTableView.reloadData()
        default:
            break
        }
        sender.selectedSegmentIndex = -1;
    }
    
    var completedRequirementMessageDisplayed = false
    @objc func refreshTable(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex
        {
        case 0: //Select
            print("Select Selected")
            self.showActionSheet(sender)
        default:
            let titleIndex = Int((self.title!.split(separator: " "))[1])
            if titleIndex == 7 && datastore.yesterdayWasDay7() {
                selectedGroup = nil
                selectedGroups = nil
                userDefaults.removeObject(forKey:"SelectedGroup")
                userDefaults.removeObject(forKey:"SelectedGroups")
                toolsDescr = appDelegate.getRequiredArray("AGToolNames")
//                self.title = NSLocalizedString("Available Tools", comment:"")
                self.setTheTitle(0)
                theTableView.reloadData()
            } else {
                if datastore.getDaysSinceLastExercise() == 0  {
                    completedRequirementMessageDisplayed = true
                    let message = NSLocalizedString("Your exercise requirement for today is complete. You should continue tomorrow!", comment: "")
                    let title = NSLocalizedString("You're done!", comment: "")
                    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .cancel) {(action:UIAlertAction!) in
                        sender.selectedSegmentIndex = -1
                    }
                    alertController.addAction(okAction)
                    present(alertController, animated: true, completion:nil)
                } else {
                    if titleIndex! > selectedGroups!.count {
                        selectedGroup = selectedGroups![titleIndex!]
                    }
                    toolsDescr = selectedGroup
                    theTableView.reloadData()
                }
            }
        }
    }
    
    func setConnectSegments() {
        let rightBarSelectButtonItem: UIBarButtonItem = UIBarButtonItem(customView: connectSegments)
        self.navigationItem.setRightBarButton(rightBarSelectButtonItem, animated: false)
    }
    
    @objc func connectIndexChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex
        {
        case 0: //Select
            print("Select Selected")
            self.showActionSheet(sender)
        case 1: //Continue
            print("Continue Selected")
            self.updateDisplayList()
        default:
            break
        }
        sender.selectedSegmentIndex = -1;
    }
    
    func image(with image: UIImage?, scaledTo newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(newSize)
        image?.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func reselectWithMusic() {
        //Reselect removes any current selections and reselect either manually or randomly or both
        let items = [NSLocalizedString("Reselect", comment: "") , "music"]
        segmentedControl = UISegmentedControl(items : items)
        let newImage = image(with: (UIImage(named: "music_image")), scaledTo: CGSize(width: 30, height: 30))
        
        segmentedControl.setImage(newImage , forSegmentAt: 1)
        segmentedControl.backgroundColor = .clear
        segmentedControl.tintColor = .black
        segmentedControl.addTarget(self, action: #selector(self.indexChanged(_:)), for: .valueChanged)
        segmentedControl.layer.cornerRadius = 5.0
        let rightBarSelectButtonItem: UIBarButtonItem = UIBarButtonItem(customView: segmentedControl)
        self.navigationItem.setRightBarButton(rightBarSelectButtonItem, animated: false)
    }
    
    func replaceButtonWithMusicSelector() {
        //Reselect removes any current selections and reselect either manually or randomly or both
        var items = [NSLocalizedString("Reselect", comment: "") , "music"]
        //Select allow addition of new selections - either manually or randomized
        if self.selectedGroups?.count ?? 0 < 7 {
            items = [NSLocalizedString("Select", comment: ""),"music"]
        }
        segmentedControl = UISegmentedControl(items : items)
        let newImage = image(with: (UIImage(named: "music_image")), scaledTo: CGSize(width: 30, height: 30))
        
        segmentedControl.setImage(newImage , forSegmentAt: 1)
        segmentedControl.backgroundColor = .clear
        segmentedControl.tintColor = .black
        segmentedControl.addTarget(self, action: #selector(self.indexChanged(_:)), for: .valueChanged)
        segmentedControl.layer.cornerRadius = 5.0
        let rightBarSelectButtonItem: UIBarButtonItem = UIBarButtonItem(customView: segmentedControl)
        self.navigationItem.setRightBarButton(rightBarSelectButtonItem, animated: false)
    }
    
    @objc func indexChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex{
        case 0:
            // allows you to add/change your unused tool selections or add randomly selected tools to complete 7 days
            // Reselect removes any current selections and reselect either manually or randomly or both
            // Select allow addition of new selections - either manually or randomized
            
            let title = sender.titleForSegment(at: 0)
            if title == NSLocalizedString("Reselect", comment: "") {
                self.reselectButtonTouched = true
                self.selectedGroups = nil;
                datastore.clearSelectedGroups()
                self.selectedGroup = nil;
                datastore.clearSelectedGroup()
                self.completedToolSets = nil;
                datastore.resetCompletedToolSets()
                self.completedTools = nil;
            } else {
                self.reselectButtonTouched = false
            }
            self.showActionSheet(sender)
        case 1:
            self.selectMusicForGroup()
        default:
            break
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
    
    @objc func showActionSheet(_ control: AnyObject) {
        var title = NSLocalizedString("Select Type of Session", comment:"")
        var noOfDaysRemaining = 7
        if (selectedGroups != nil) {
            noOfDaysRemaining = 7 - (selectedGroups?.count)!
        }
        var message = String( format: NSLocalizedString("Select 10 minute sessions", comment:""),noOfDaysRemaining)
        if self.reselectButtonTouched || self.selectedTools == nil {
            message = NSLocalizedString("Touch 'OK' to randomly select all 7 days worth of 10 minute sessions.", comment: "")
        }
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        title = NSLocalizedString("Random", comment:"")
        let randomAction = UIAlertAction(title: title, style: .default) { (alert: UIAlertAction!) -> Void in
            //assuming 3 tools completed for every 10 minutes
            toolControl.setToolCount(3)
            toolControl.setSessionPeriod(SESSIONPERIOD)
            toolControl.setSelectionType(self.selectionTypeIsManual)
            if self.selectedTools != nil && self.selectedGroups == nil {
                self.setUpExistingToolGroups()
            } else if self.selectedTools == nil && self.selectedGroups != nil {
                self.selectedTools = [String]()
                for aGroup in self.selectedGroups! {
                    for i in 0..<3 {
                        self.selectedTools.append(aGroup[i])
                    }
                }
            }
            toolControl.randomlySelectRemainingArrayOfTools(self.selectedGroups ?? [], selectedTools:self.selectedTools ?? [])
            self.selectedGroups = datastore.getSelectedGroups()
            if self.completedToolSets == nil || self.completedToolSets!.count == 0 {
                self.selectedGroup = self.selectedGroups![0]
            } else {
                self.selectedGroup = self.selectedGroups![self.completedToolSets!.count]
            }
            self.toolsHaveBeenSelected = true
            self.selectedPlaylist = nil
            self.replaceButtonWithMusicSelector()
            self.toolsDescr = self.selectedGroup
            var dayCount = 0
            if self.completedToolSets == nil || self.completedToolSets!.count == 0 {
                dayCount = 1
            } else {
                dayCount = self.completedToolSets!.count + 1
            }
            self.title =  String(format:NSLocalizedString("Day", comment:""), dayCount)
            
            self.theTableView.reloadData()
        }
        alertController.addAction(randomAction)
        if self.selectedTools != nil && self.selectedTools.count > 0 {
            title = NSLocalizedString("Select", comment:"")
            let manuallySelectAction = UIAlertAction(title: title, style: .default) { (alert: UIAlertAction!) -> Void in
                self.reselectButtonTouched = true
                self.updateDisplayList()
                self.theTableView.reloadData()
            }
            alertController.addAction(manuallySelectAction)
        }
        title = NSLocalizedString("Cancel", comment:"")
        let cancelAction = UIAlertAction(title: title, style: .cancel) {(action:UIAlertAction!) in
            if control is UISegmentedControl {
                (control as! UISegmentedControl).selectedSegmentIndex = -1
            }
        }
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion:nil)
    }
    
    @objc func addSelectionToList(_ sender: UIButton) {
        if self.selectedTools == nil {
            self.selectedTools = []
        }
        if self.selectedToolsIds == nil {
            self.selectedToolsIds = []
        }
        if self.selectedGroup == nil {
            self.selectedGroup = []
        }
        if self.selectedGroups == nil {
            self.selectedGroups = [Array<String>]()
        }
        
        let cell = sender.superview?.superview as! UITableViewCell
        let indexPath = theTableView.indexPath(for: cell)
        sender.setImage(UIImage(named: "manuallySelected"), for: .normal)
        let toolName = toolsDescr[indexPath!.row]
        if self.selectedGroup.contains(toolName) {
            var indx = self.selectedGroup.index(of: toolName)
            self.selectedGroup.remove(at:indx!)
            indx = self.selectedTools.index(of: toolName)
            self.selectedTools.remove(at:indx!)
            self.selectedToolsIds.remove(at:indx!)
            sender.setImage(UIImage(named:"selector"), for: .normal)
        } else {
            self.selectedGroup.append(toolName)
            self.selectedTools.append(toolName)
            self.selectedToolsIds.append(indexPath!.row + 1)
        }
        if self.selectedGroup.count % 3 == 0 {
            self.selectedGroups?.append(self.selectedGroup)
            self.selectedGroup = nil
            selectionTypeIsManual = true
            setConnectSegments()
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
    }
    
    @objc func updateDisplayList(_ sender: UIButton) {
        continueBtnTouched = true
        updateDisplayList()
    }
    
    func updateDisplayList() {
        self.toolsHaveBeenSelected = true
        setUpExistingToolGroups()
        if self.selectedTools == nil {
            self.dateOfLastCompletedExercise = nil
            self.selectedGroups = nil
        } else {
            if completedToolSets != nil {
                let whichOne = (completedToolSets!.count) - 1
                self.selectedGroup = self.selectedGroups![whichOne]
            } else {
                self.selectedGroup = self.selectedGroups![0]
            }
            datastore.save("SelectedGroup", value: self.selectedGroup! as NSObject)
        }
        self.selectedPlaylist = nil
        toolsDescr = self.selectedGroup
        let whichDay = self.completedToolSets != nil ? self.completedToolSets!.count: 1
        self.setTheTitle(whichDay)
        replaceButtonWithMusicSelector()
        self.theTableView.reloadData()
        let topIndex = IndexPath(row: 0, section: 0)
        self.theTableView.scrollToRow(at: topIndex, at: .top, animated: true)
}
    
    func getToolNumber(_ tool:String) -> Int {
        return ((appDelegate.getRequiredArray("AGToolNames")).index(of: tool)! + 1)
    }
    
    func updateTheDates() {
        var startDate = datastore.loadDate("StartingDate")
        startDate = datastore.updateDate(startDate, byDays:1)
        var endDate = datastore.loadDate("EndingDate")
        endDate = datastore.updateDate(endDate, byDays:1)
    }
    
    // MARK: -  UITableViewDelegate and DataSelect
    
    func numberOfSections(in tableView: UITableView) -> Int {
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
        titleRow.text = "\(NSLocalizedString("Tool", comment:""))#\(getToolNumber(toolsDescr[indexPath.row])): \(toolsDescr[indexPath.row])"
        let subTitleRow = cell.viewWithTag(11) as! UILabel
        subTitleRow.text = (appDelegate.getRequiredArray("AGToolPrimaryBenefits"))[indexPath.row]
        subTitleRow.textAlignment = .center
        let selectorBtn = cell.viewWithTag(12) as! UIButton
        selectorBtn.addTarget(self, action: #selector(self.addSelectionToList(_:)), for: .touchDown)
        selectorBtn.setImage(UIImage(named:"selector"), for: .normal)
        selectorBtn.isHidden = false
        let theTool = toolsDescr[indexPath.row]
        if toolsDescr.count == 3 {
            selectorBtn.isHidden = true
            return cell
        }
        if self.completedTools != nil && self.completedTools!.contains(theTool) {
            selectorBtn.isHidden = true
        } else if self.selectedTools != nil && self.selectedTools.contains(theTool) && self.toolsDescr.count > 3 {
            selectorBtn.setImage(UIImage(named:"manuallySelected"), for: .normal)
            // compare tool Id and self.completedToolIds
            let theID = indexPath.row + 1
            if self.completedToolIds?.contains(theID) ?? false {
                selectorBtn.isHidden = true
                return cell
            } else {
                selectorBtn.isHidden = false
            }
        } else {
            selectorBtn.setImage(UIImage(named:"selector"), for: .normal)
        }
        return cell
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
//        let endingDate = datastore.loadDate("EndingDate")
//        let calendar = NSCalendar.current
        var completedWeekCount = 0
        if self.completedToolSets!.count == 7 {   //calendar.isDateInToday(endingDate) {
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
            self.title = NSLocalizedString("Available Tools", comment:"")
            setRandomButton()
            datastore.resetLastCompletedExercisDate()
            datastore.resetCompletedToolSets()
            self.completedToolSets = nil
            selectedGroup = nil
            datastore.clearSelectedGroup()
            selectedGroups = nil
            datastore.clearSelectedGroups()
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
    
    // MARK: - Navigation
    
    @IBAction func unwindToMainMenu(_ sender: UIStoryboardSegue) {
        self.selectedGroup = (sender.source as! PlayMusicViewController).selectedGroup!
        toolControl.saveLastCompletedGroup(self.selectedGroup)
        self.returnedFromExercise = true
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
