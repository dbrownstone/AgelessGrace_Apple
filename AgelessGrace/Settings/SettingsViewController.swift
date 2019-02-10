//
//  SettingsViewController.swift
//  AgelessGrace
//
//  Created by David Brownstone on 03/02/2019.
//  Copyright © 2019 David Brownstone. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    let headersArray = [NSLocalizedString("Select when and how you will exercise", comment:""),
                        NSLocalizedString("Pause between tool exercises", comment:""),
                        NSLocalizedString("Pause when telephone rings", comment:"")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
            
            break
        default:
            identifier = "yesNo"
            cell = tableView.dequeueReusableCell(withIdentifier: identifier!, for: indexPath)
            theSwitch = cell!.viewWithTag(10) as? UISwitch
            if indexPath.section == 1 {
                if datastore.pauseBetweenTools() {
                    theSwitch?.isOn = true
                } else {
                    theSwitch?.isOn = false
                }
                theSwitch?.addTarget(self, action: #selector(toolsSwitchClicked), for: .valueChanged)

            } else {
                if datastore.pauseForPhonecall() {
                    theSwitch?.isOn = true
                } else {
                    theSwitch?.isOn = false
                }
//                theSwitch?.addTarget(self, action: #selector(phoneSwitchClicked), for: .valueChanged)
            }
            break
        }
        return cell!
    }
    
    @objc func toolsSwitchClicked(sender:UISwitch!) {
        let theSwitch = sender
        let cell = (sender?.superview?.superview) as! UITableViewCell
        let section = (tableView.indexPath(for: cell))?.section
        if section == 0 {
            if (theSwitch?.isOn)! {
                datastore.save("DailyFromStartDate",value: false as NSObject)
            } else {
                datastore.save("DailyFromStartDate",value: true as NSObject)
            }
        } else {
            if theSwitch!.isOn {
                datastore.save("PauseBetweenTools",value:true as NSObject)
            }
            else {
                datastore.save("PauseBetweenTools",value:false as NSObject)
            }
        }
    }

//    @objc func phoneSwitchClicked(sender:UISwitch!) {
//        let theSwitch = sender
//        if theSwitch!.isOn {
//            datastore.save("PauseForPhonecall",value:true as NSObject)
//        }
//        else {
//            datastore.save("PauseForPhonecall",value:false as NSObject)
//        }
//        datastore.commitToDisk()
//    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
