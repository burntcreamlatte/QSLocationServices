//
//  SpotAnnotation.swift
//  TestMap
//
//  Created by Aaron Shackelford on 1/16/20.
//  Copyright © 2020 Aaron Shackelford. All rights reserved.
//

import Foundation
import MapKit

class SpotAnnotation: NSObject, MKAnnotation {
    
    let title: String?
    var subtitle: String?
    let locationName: String //might not need?
    let discipline: String
    let postedDate: Date
    let coordinate: CLLocationCoordinate2D
    
    init(title: String, subtitle: String, locationName: String, discipline: String, postedDate: Date = Date(), coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.locationName = locationName
        self.discipline = discipline
        self.postedDate = postedDate
        self.coordinate = coordinate
        
        super.init()
        
        
    }
    
    var markerTintColor: UIColor {
        switch discipline {
        case "A":
            return .red
        case "B":
            return .blue
        default:
            return .black
        }
    }
    
    var imageName: String? {
        return "spotMarker"
    }

    
}
