//
//  ViewController.swift
//  MapViewExamples
//
//  Created by Kamalpreet Kaur on 2020-06-17.
//  Copyright © 2020 Kamalpreet Kaur. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit


class ViewController: UIViewController,CLLocationManagerDelegate, MKMapViewDelegate, UISearchBarDelegate {

    private let locationManager = CLLocationManager()
    var currentLocation = CLLocationCoordinate2D();
    @IBOutlet weak var mapView: MKMapView!
    
 
    var startLocation = CLLocation()
    var endLocatiion = CLLocation()
    var myAnnotations = [CLLocation]()
    var index = 0
    var steps = [MKRoute.Step]()
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locationManager.requestWhenInUseAuthorization()
                locationManager.startUpdatingLocation()
                mapView.showsUserLocation = true
                mapView.delegate = self
                let longGesture = UILongPressGestureRecognizer(target: self,
                action: #selector(addPin(longGesture:)))
                     //longGesture.minimumPressDuration = 2
                mapView.addGestureRecognizer(longGesture)
                     // Do any additional setup after loading the view.
    }
        // trying to draw lines
        func getDirections(to Destination : MKMapItem){
            
            let source = MKPlacemark(coordinate: currentLocation)
            let sourceMapItem = MKMapItem(placemark: source)
            
            let directionrequest = MKDirections.Request()
            directionrequest.source = sourceMapItem
            directionrequest.destination = Destination
            directionrequest.transportType = .automobile
            
            let directions = MKDirections(request: directionrequest)
            directions.calculate{(response, _ ) in
                guard let response = response else {return}
                guard let mainRoute = response.routes.first else { return }
                self.steps = mainRoute.steps
                
                self.mapView.addOverlay(mainRoute.polyline)
                
                for i in 0..<mainRoute.steps.count
                {
                    let step = mainRoute.steps[i]
                    let region = CLCircularRegion(center: step.polyline.coordinate, radius: 20, identifier: "\(i)")
                    self.locationManager.startMonitoring(for: region)
                }
            }
            
        func mapView(_mapView: MKMapView, rendererFor overlay: MKOverlay)-> MKOverlayRenderer{
             
            if overlay is MKPolyline{
            let renderer = MKPolylineRenderer(overlay: overlay)
              renderer.strokeColor = UIColor.green
              renderer.lineWidth = 5.0
              return renderer
          }
            return MKOverlayRenderer()
        }
        
    }
    /*func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        let span : MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.5,longitudeDelta: 0.5)
        let myLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude,location.coordinate.longitude)
        
        let region:MKCoordinateRegion = MKCoordinateRegion(center: myLocation, span: span)
        mapView.setRegion(region, animated: true)
        self.mapView.showsUserLocation = true
    }*/
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        guard let newLocation = locations.first else {return}
        currentLocation = newLocation.coordinate
        mapView.userTrackingMode = .followWithHeading
        
    }
    //used search controller to search location with help of bar button
    @IBAction func searchLocation(_ sender: UIBarButtonItem) {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        present(searchController, animated: true, completion: nil)
    }
    
    // to clear the searches
    
    @IBAction func clearSearchLocation(_ sender: UIBarButtonItem) {
        let myAnnotaion = self.mapView.annotations
        self.mapView.removeAnnotations(myAnnotaion)
    }
   
    // to search the location entered by user
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        // UIApplication.shared.beginIgnoringInteractionEvents()
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.startAnimating()
        self.view.addSubview(activityIndicator)
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchBar.text
        
        let activeSearch = MKLocalSearch(request: searchRequest)
        
        activeSearch.start {(response, error) in
        activityIndicator.stopAnimating()
            //UIApplication.shared.endIgnoringInteractionEvents()

            if(response == nil)
            {
                print("Error")
            }
            else
            {
                // here we have to add the annotaion on searched places
                
                //let annotations = self.mapView.annotations
                let lat = response?.boundingRegion.center.latitude
                let long = response?.boundingRegion.center.longitude
                
                let myAnnotation = MKPointAnnotation()
                myAnnotation.title = searchBar.text
                myAnnotation.coordinate = CLLocationCoordinate2DMake(lat!,long!)
                self.mapView.addAnnotation(myAnnotation)
                
                let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat!,long!)
                let span = MKCoordinateSpan(latitudeDelta: 0.5,longitudeDelta: 0.5)
                let region = MKCoordinateRegion(center: coordinate, span: span)
                self.mapView.setRegion(region, animated: true)
            //    print("\(coordinate)")
                
                var coordinates = Array<CLLocationCoordinate2D>()
                coordinates.append(CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude))
                print("\(coordinates)")
        
            }
            guard let firstLocation = response?.mapItems.first else {return}
            self.getDirections(to: firstLocation)
        }
    }
   
    // to zoom the mapview area
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
    let zoomArea = MKCoordinateRegion(center:
    self.mapView.userLocation.coordinate, span: MKCoordinateSpan (latitudeDelta: 0.015, longitudeDelta: 0.015))
    self.mapView.setRegion(zoomArea, animated: true)
    }
    
   
    // adding points using long gestures
    
    @objc func addPin(longGesture: UIGestureRecognizer) {
        
        let touchPoint = longGesture.location(in: mapView)
        if(index < 10)
        {
        let touchLocation = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let location = CLLocation(latitude: touchLocation.latitude, longitude: touchLocation.longitude)
        //let titles : [String] = ["A","B","C","D","E"]
        let myAnnotation = MKPointAnnotation()
        myAnnotation.coordinate = touchLocation
        myAnnotations.append(location)
            myAnnotation.title = "\(touchLocation.latitude) \(touchLocation.longitude)"
        self.mapView.addAnnotation(myAnnotation)
        index = index+1
            
        }
    }
  
  

}



