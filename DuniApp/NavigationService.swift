//
//  NavigationService.swift
//  DuniApp
//
//  Created by 파디오 on 2020/06/08.
//  Copyright © 2020 파디오. All rights reserved.
//
import MapKit
import CoreLocation

struct NavigationService {
    
    func getDirections(destinationLocation: CLLocationCoordinate2D, request: MKDirections.Request, completion: @escaping ([MKRoute.Step]) -> Void) {
    var steps: [MKRoute.Step] = []
    
        let placeMark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: destinationLocation.latitude, longitude: destinationLocation.longitude))
       
        request.destination = MKMapItem.init(placemark: placeMark)
        request.source = MKMapItem.forCurrentLocation()
        request.requestsAlternateRoutes = false
        request.transportType = .walking

        let directions = MKDirections(request: request)
        
        directions.calculate { response, error in
            if error != nil {
                print("Error getting directions")
            } else {
                guard let response = response else { return }
                for route in response.routes {
                    steps.append(contentsOf: route.steps)
                }
                completion(steps)
            }
        }
    }
}
