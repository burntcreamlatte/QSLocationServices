//
//  DateExtension.swift
//  TestMap
//
//  Created by Aaron Shackelford on 1/17/20.
//  Copyright © 2020 Aaron Shackelford. All rights reserved.
//

import Foundation

extension Date {
    func formattedString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        return formatter.string(from: self)
    }
    
    func timeAgo() -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .dropAll
        formatter.maximumUnitCount = 1
        //let dateTarget = Date()
        return String(format: formatter.string(from: self, to: Date()) ?? "", locale: .current)
    }
    
}
