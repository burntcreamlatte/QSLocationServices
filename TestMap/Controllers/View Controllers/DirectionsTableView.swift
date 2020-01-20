//
//  DirectionsTableView.swift
//  TestMap
//
//  Created by Aaron Shackelford on 1/14/20.
//  Copyright © 2020 Aaron Shackelford. All rights reserved.
//

import UIKit
import MapKit

class DirectionsTableView: UITableView {

    var directions: MKRoute?

    override init(frame: CGRect, style: UITableView.Style) {
      super.init(frame: frame, style: style)
    }
    
    required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
    }
    
}

extension DirectionsTableView: UITableViewDelegate {
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
      return 54
    }
    
}

extension DirectionsTableView: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return directions?.steps.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueReusableCell(withIdentifier: "directionsCell", for: indexPath)
        
        let step = directions?.steps[indexPath.row]
        let instructions = step?.instructions
        
        cell.textLabel?.text = "\(instructions ?? "")"

        return cell
    }
    
    
    
    
}

extension Float {
    func format(f: String) -> String {
        return NSString(format: "%\(f)f" as NSString, self) as String
    }
}

extension CLLocationDistance {
    func miles() -> String {
        let miles = Float(self)/1609.344
        return miles.format(f: ".2")
    }
}

extension Date {
    
    func formatted() -> String {
        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .short
        return df.string(from: self)
    }
}
