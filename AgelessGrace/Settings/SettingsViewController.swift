//
//  SettingsViewController.swift
//  AgelessGrace
//
//  Created by David Brownstone on 03/02/2019.
//  Copyright © 2019 David Brownstone. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {
    
    var datePicker:UIDatePicker!
    var doneBtn:UIButton!
    
    var currentStartDate: Date?
    var exerciseSetting: Bool?
    var pauseSetting: Bool?
    
    
    let headersArray = [NSLocalizedString("Select when and how you will exercise after you have started", comment:""),
                        NSLocalizedString("Pause between tool exercises", comment:""),
                        NSLocalizedString("Pause when telephone rings", comment:"")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        datastore.setDates(datePicker.date)
        datastore.setShouldExerciseDaily(self.exerciseSetting!)
        datastore.setPauseBetweenTools(self.pauseSetting!)
        datastore.commitToDisk()
        super.viewDidDisappear(animated)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 100
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        //Need to create a label with the text we want in order to figure out height
        let label: UILabel = createHeaderLabel(section)
        let size = label.sizeThatFits(CGSize(width: view.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        let padding: CGFloat = 20.0
        return size.height + padding
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UITableViewHeaderFooterView()
        let label = createHeaderLabel(section)
        label.autoresizingMask = [.flexibleHeight]
        headerView.addSubview(label)
        headerView.layer.borderColor = UIColor.black.cgColor
        headerView.layer.borderWidth = 1.0
        return headerView
    }
    
    func createHeaderLabel(_ section: Int)->UILabel {
        let widthPadding: CGFloat = 8.0
        let label: UILabel = UILabel(frame: CGRect(x: widthPadding, y: 0, width: self.view.frame.size.width - widthPadding, height: 0))
        label.text = headersArray[section]// Your text here
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignment.center
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        return label
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 200
        }
        return 40
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var identifier: String?
        var cell: UITableViewCell?
        var theSwitch: UISwitch?

        switch indexPath.section {
        case 0:
            identifier = "onOff"
            cell = tableView.dequeueReusableCell(withIdentifier: identifier!, for: indexPath)
            theSwitch = cell!.viewWithTag(10) as? UISwitch
            theSwitch?.isOn = datastore.shouldExerciseDaily()
            self.exerciseSetting = theSwitch?.isOn
            theSwitch?.addTarget(self, action: #selector(exerciseSwitchClicked), for: .valueChanged)
            datePicker = cell?.viewWithTag(100) as? UIDatePicker
            datePicker.addTarget(self, action: #selector(dateChanged(_ :)), for: .valueChanged)
            if let startDate = userDefaults.object(forKey: "StartingDate") {
                datePicker.date = startDate as! Date
            } else {
                datePicker.date = Date()
            }
            self.currentStartDate = datePicker.date
            doneBtn = cell?.viewWithTag(101) as? UIButton
            doneBtn.addTarget(self, action:#selector(donePressed(_:)), for: .touchDown)
            break
        default:
            identifier = "yesNo"
            cell = tableView.dequeueReusableCell(withIdentifier: identifier!, for: indexPath)
            theSwitch = cell!.viewWithTag(20) as? UISwitch
            if indexPath.section == 1 {
                theSwitch?.isOn = datastore.pauseBetweenTools()
                self.pauseSetting = theSwitch?.isOn
                theSwitch?.addTarget(self, action: #selector(toolsSwitchClicked), for: .valueChanged)
            }
            break
        }
        return cell!
    }
    
    @objc func exerciseSwitchClicked(sender:UISwitch) {
        self.exerciseSetting = sender.isOn
    }
    
    @objc func toolsSwitchClicked(sender:UISwitch!) {
        self.pauseSetting = sender.isOn
    }
    
    @objc func dateChanged(_ sender: Any) {
        doneBtn.isHidden = false
    }
    
    @objc func donePressed(_ sender: UIButton) {
        self.currentStartDate = datePicker.date
        var dateStr = ""
        let components = Calendar.current.dateComponents([.year, .month, .day], from: datePicker.date)
        if let day = components.day, let month = components.month, let year = components.year {
            dateStr = String(format:"%4d-%02d-%02d",year,month,day)
            print(dateStr)
        }
        doneBtn.isHidden = true
    }
}
