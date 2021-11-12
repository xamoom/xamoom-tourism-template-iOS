//
//  MapAnnotation.swift
//  klagenfurttourism
//
//  Created by Raphael Seher on 25/04/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import XamoomSDK
import Mapbox

class MapAnnotation: NSObject, MGLAnnotation {
  let identifier = "MapAnnotation"
  let spot: XMMSpot
  
  var userLocation: CLLocation? {
    didSet {
      if let userLocation = userLocation {
        subtitle = locationStringBetween(location: userLocation, coordinates: coordinate)
      }
    }
  }
  var coordinate: CLLocationCoordinate2D
  var title: String?
  var subtitle: String?
  
  init(spot: XMMSpot, userLocation: CLLocation?) {

    self.spot = spot
    coordinate = CLLocationCoordinate2D.init(latitude: spot.latitude,
                                             longitude: spot.longitude)
    
    self.title = spot.name
    self.userLocation = userLocation
    
    super.init()
    
    if let userLocation = userLocation {
      subtitle = locationStringBetween(location: userLocation, coordinates: coordinate)
    }
  }
  
  func locationStringBetween(location location1: CLLocation,
                             coordinates: CLLocationCoordinate2D) -> String? {
    let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    let distance = location1.distance(from: location2)
    
    if distance < 1000.0 {
      return String.localizedStringWithFormat(
        "%@: %0.0f %@",
        NSLocalizedString("mapannotation.distance", comment: ""),
        distance,
        NSLocalizedString("mapannotation.meter", comment: ""))
    }
    
    let kilometer = distance/1000
    return String.localizedStringWithFormat(
      "%@: %0.1f %@",
      NSLocalizedString("mapannotation.distance", comment: ""),
      kilometer,
      NSLocalizedString("mapannotation.kilometer", comment: ""))
  }
}
