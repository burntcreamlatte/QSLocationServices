//
//  CustomAnnotation.swift
//  TestMap
//
//  Created by Aaron Shackelford on 1/16/20.
//  Copyright © 2020 Aaron Shackelford. All rights reserved.
//

import Foundation
import MapKit

//would name anntationVIEW
class CustomAnnotation: MKMarkerAnnotationView {
    override var annotation: MKAnnotation? {
        willSet {
            guard let spotAnnotation = newValue as? SpotAnnotation else { return }
            canShowCallout = true
            calloutOffset = CGPoint(x: 0, y: 0)
            
            let viewButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 30, height: 30)))
            viewButton.setBackgroundImage(UIImage(named: "moreInfo"), for: UIControl.State())
            viewButton.addTarget(self, action: #selector(viewButtonTapped), for: .touchUpInside)
            
            rightCalloutAccessoryView = viewButton
            
            if let imageName = spotAnnotation.imageName {
                glyphImage = UIImage(named: imageName)
            } else {
                glyphImage = nil
            }
            

            //markerTintColor = spotAnnotation.markerTintColor
            //glyphText = String(spotAnnotation.discipline.first!)
            
            
        }
    }
    
    @objc func viewButtonTapped() {
        print("view button tapped")
    }
}
