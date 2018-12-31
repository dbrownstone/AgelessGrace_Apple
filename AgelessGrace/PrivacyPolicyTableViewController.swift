//
//  PrivacyPolicyTableViewController.swift
//  AgelessGrace
//
//  Created by David Brownstone on 31/12/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit

class PrivacyPolicyTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("Privacy Policy", comment: "")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 8
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.white
        
        let sectionLabel = UILabel(frame: CGRect(x: 24, y: 0, width:
            tableView.bounds.size.width, height: tableView.bounds.size.height))
        sectionLabel.font = UIFont(name: "Helvetica-Bold", size: 16)
        sectionLabel.textColor = UIColor.black
        switch section {
        case 0:
            sectionLabel.text = NSLocalizedString("Effective date", comment: "")
        case 1:
            sectionLabel.text = NSLocalizedString("Information Collection And Use", comment: "")
        case 2:
            sectionLabel.text = NSLocalizedString("Personal Data", comment: "")
        case 3:
            sectionLabel.text = NSLocalizedString("Service Providers", comment: "")
        case 4:
            sectionLabel.text = NSLocalizedString("Links To Other Sites", comment: "")
        case 5:
            sectionLabel.text = NSLocalizedString("Children's Privacy", comment: "")
        case 6:
            sectionLabel.text = NSLocalizedString("Changes To This Privacy Policy", comment: "")
        case 7:
            sectionLabel.text = NSLocalizedString("Contact Us", comment: "")
        default:
            break
        }
        sectionLabel.sizeToFit()
        headerView.addSubview(sectionLabel)
        
        return headerView
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! AboutTableViewCell
        
        switch indexPath.section {
        case 0:
            cell.theTextLabel.text = NSLocalizedString("Operation", comment: "")
        case 1:
            cell.theTextLabel.text = NSLocalizedString("Collecting information", comment: "")
        case 2:
            cell.theTextLabel.text = NSLocalizedString("Ageless Grace does not use any personal data in this application", comment: "")
        case 3:
            cell.theTextLabel.text = NSLocalizedString("Third Party Companies", comment: "")
        case 4:
            cell.theTextLabel.text = NSLocalizedString("No Links", comment: "")
        case 5:
            cell.theTextLabel.text = NSLocalizedString("This app can be used by anybody of any age.", comment: "")
        case 6:
            cell.theTextLabel.text = NSLocalizedString("The Changes", comment: "")
        case 7:
            cell.theTextLabel.text = NSLocalizedString("Questions", comment: "")
        default:
            break;
        }
        return cell
    }
}
