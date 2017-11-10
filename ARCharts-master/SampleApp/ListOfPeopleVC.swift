//
//  ListOfPeopleVC.swift
//  ARChartsSampleApp
//
//  Created by D.Bystranovskyy on 11/10/17.
//  Copyright © 2017 Boris Emorine. All rights reserved.
//

import Foundation
import UIKit

class ListOfPeopleVC: UITableViewController {
    let peopleList: [String] = ["Andriy Kupich",
                                "Viktor Malieichyk",
        "Vitaliy Obertynskyi",
        "Andriy Scherba",
        "Dmytro Bystranovskyy",
        "Vasyl Fedasyuk",
        "Oleksandr Harmatiuk",
        "Ostap Horbach",
        "Dmytro Khludkov"]

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(CustomCell.self, forCellReuseIdentifier: CustomCell.identifier())
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CustomCell.identifier(), for: indexPath)
        cell.textLabel?.text = peopleList[indexPath.row]
        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peopleList.count
    }
}

class CustomCell: UITableViewCell {
    static func identifier() -> String {
        return "CustomCell"
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
