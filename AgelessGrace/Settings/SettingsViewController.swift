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
    
    var exerciseTitleLine: UILabel!
    var currentStartDate: Date?
    var exerciseSetting: Bool?
    var pauseSetting: Bool?
    
    var exerciseSettingSw: UISwitch?
    var pauseSettingSw: UISwitch?
    
    let headersArray = [NSLocalizedString("Select when and how you will exercise after you have started", comment:""),
                        NSLocalizedString("Pause between tool exercises", comment:""),
                        NSLocalizedString("Pause when telephone rings", comment:"")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    @IBAction func saveCurrentSelections(_ sender: UIBarButtonItem) {
            datastore.setDates(datePicker.date)
        datastore.setShouldExerciseDaily(self.exerciseSettingSw!.isOn)
        datastore.setNoPauseBetweenTools(self.pauseSettingSw!.isOn)
        tabBarController?.selectedIndex = 0
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 100
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
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
        if indexPath.section == 0 {
            return 230
        }
        return 60
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var identifier: String?
        var cell: UITableViewCell?

        switch indexPath.section {
        case 0:
            identifier = "onOff"
            cell = tableView.dequeueReusableCell(withIdentifier: identifier!, for: indexPath)
            exerciseTitleLine = cell!.viewWithTag(50) as? UILabel
            exerciseSettingSw = cell!.viewWithTag(10) as? UISwitch
            exerciseSettingSw?.isOn = datastore.shouldExerciseDaily()
            datePicker = cell?.viewWithTag(100) as? UIDatePicker
            
            if datastore.shouldExerciseDaily() {
                datePicker.isHidden = false
                exerciseTitleLine.isHidden = false
                self.currentStartDate = datastore.loadDate("StartingDate")
                datePicker.date = self.currentStartDate!
            } else {
                datePicker.isHidden = true
                exerciseTitleLine.isHidden = true
            }
            break
        default:
            identifier = "yesNo"
            cell = tableView.dequeueReusableCell(withIdentifier: identifier!, for: indexPath)
            pauseSettingSw = cell!.viewWithTag(20) as? UISwitch
            pauseSettingSw?.isOn = datastore.noPauseBetweenTools()
            break
        }
        return cell!
    }
    
//        var dateStr = ""
//        let components = Calendar.current.dateComponents([.year, .month, .day], from: datePicker.date)
//        if let day = components.day, let month = components.month, let year = components.year {
//            dateStr = String(format:"%4d-%02d-%02d",year,month,day)
//            print(dateStr)
//        }
}
