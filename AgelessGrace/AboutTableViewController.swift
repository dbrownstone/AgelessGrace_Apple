//
//  AboutTableViewController.swift
//  AgelessGrace
//
//  Created by David Brownstone on 27/12/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit

class AboutTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("About Title", comment: "")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 7
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.white
        
        if (section == 0) { return nil }
        let sectionLabel = UILabel(frame: CGRect(x: 24, y: 0, width:
            tableView.bounds.size.width, height: tableView.bounds.size.height))
        sectionLabel.font = UIFont(name: "Helvetica-Bold", size: 16)
        sectionLabel.textColor = UIColor.black
        switch section {
        case 2:
            sectionLabel.text = NSLocalizedString("Who", comment: "")
        case 3:
            sectionLabel.text = NSLocalizedString("What", comment: "")
        case 4:
            sectionLabel.text = NSLocalizedString("Why", comment: "")
        case 5:
            sectionLabel.text = NSLocalizedString("Where", comment: "")
        case 6:
            sectionLabel.text = NSLocalizedString("How", comment: "")
        default:
            break
        }
        sectionLabel.sizeToFit()
        headerView.addSubview(sectionLabel)
        
        return headerView
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44 //UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
        
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! AboutTableViewCell
        cell.theTextLabel.font = UIFont(name:"HelveticaNeue-Regular", size: 16.0)
        if indexPath.section == 1 {
            cell = tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath) as! AboutTableViewCell
        }
        switch indexPath.section {
        case 0:
            cell.theTextLabel?.text = NSLocalizedString("About Ageless Grace Info", comment: "")
        case 1:
            cell.titleLabel?.text = NSLocalizedString("In a nutshell", comment: "")
        case 2:
            cell.theTextLabel?.text = NSLocalizedString("Who Description", comment: "")
        case 3:
            cell.theTextLabel?.text = NSLocalizedString("What Description", comment: "")
        case 4:
            cell.theTextLabel?.text = NSLocalizedString("Why Description", comment: "")
        case 5:
            cell.theTextLabel?.text = NSLocalizedString("Where Description", comment: "")
        case 6:
            cell.theTextLabel?.text = NSLocalizedString("How Description", comment: "")
        default:
            break;
        }

        return cell
    }
}
