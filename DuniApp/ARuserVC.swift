//
//  ARuserVC.swift
//  DuniApp
//
//  Created by 파디오 on 2020/06/08.
//  Copyright © 2020 파디오. All rights reserved.
//


import ARCL
import ARKit
import MapKit
import SceneKit
import UIKit

@available(iOS 11.0, *)
/// Displays Points of Interest in ARCL
class ARuserVC: UIViewController {
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet weak var nodePositionLabel: UILabel!
    
    @IBOutlet var contentView: UIView!
    let sceneLocationView = SceneLocationView()
    
    var userAnnotation: MKPointAnnotation?
    var locationEstimateAnnotation: MKPointAnnotation?
    
    var updateUserLocationTimer: Timer?
    var updateInfoLabelTimer: Timer?
    
    var centerMapOnUserLocation: Bool = true
    var routes: [MKRoute]?
    
    var showMap = true {
        didSet {
            guard let mapView = mapView else {
                return
            }
            mapView.isHidden = !showMap
        }
    }
    
    /// Whether to display some debugging data
    /// This currently displays the coordinate of the best location estimate
    /// The initial value is respected
    let displayDebugging = true
    
    let adjustNorthByTappingSidesOfScreen = false
    let addNodeByTappingScreen = true
    
    var testArLocationData : arLocationData?
    
    
    class func loadFromStoryboard() -> ARuserVC {
        return UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "ARCLViewController") as! ARuserVC
        // swiftlint:disable:previous force_cast
    }
    
    func  testInData() {
        let JSON  : [String:Any] = [
            "clientid" : "gunman97@naver.com",
            "data": [
                [
                    "alt": 199,
                    "dtimestamp": 1583459992182,
                    "etc": [
                        "battery": 64,
                        "marked": true
                    ],
                    "lat": 33.28941141450674,
                    "lng": 126.6202576039546
                ],
                [
                    "alt": 199,
                    "dtimestamp": 1583459996784,
                    "etc": [
                        "battery": 64,
                        "marked": true
                    ],
                    "lat": 33.28945025523972,
                    "lng": 126.6202408518713
                ],
                [
                    "alt": 199,
                    "dtimestamp": 1583460042608,
                    "etc": [
                        "battery": 61,
                        "marked": true
                    ],
                    "lat": 33.28935553409127,
                    "lng": 126.62040925364578
                ],
                [
                    "alt": 199,
                    "dtimestamp": 1583460112744,
                    "etc": [
                        "battery": 57,
                        "marked": true
                    ],
                    "lat": 33.289069632802885,
                    "lng": 126.62036280135614
                ]
            ],
            "dname": "이슬농원이상포인트MARKED-2020-03-06_11-02-27",
            "dtime": "Fri Mar 06 2020 02:09:20 GMT+0000 (Coordinated Universal Time)",
            "dtimestamp": 1583460560289,
            "youtube_data_id": "-"
        ]
        do{
            let dataJson = try JSONSerialization.data(withJSONObject:JSON, options: .prettyPrinted)
            self.testArLocationData = try JSONDecoder().decode(arLocationData.self, from: dataJson)
            print(testArLocationData)
        }catch{
            print(error)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        testInData()
        
        
        // swiftlint:disable:next discarded_notification_center_observer
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification,
                                               object: nil,
                                               queue: nil) { [weak self] _ in
                                                self?.pauseAnimation()
        }
        // swiftlint:disable:next discarded_notification_center_observer
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                               object: nil,
                                               queue: nil) { [weak self] _ in
                                                self?.restartAnimation()
        }
        
        updateInfoLabelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateInfoLabel()
        }
        
        // Set to true to display an arrow which points north.
        // Checkout the comments in the property description and on the readme on this.
        //        sceneLocationView.orientToTrueNorth = false
        //        sceneLocationView.locationEstimateMethod = .coreLocationDataOnly
        
        sceneLocationView.showAxesNode = true
        sceneLocationView.showFeaturePoints = displayDebugging
        sceneLocationView.locationNodeTouchDelegate = self
        //        sceneLocationView.delegate = self // Causes an assertionFailure - use the `arViewDelegate` instead:
        sceneLocationView.arViewDelegate = self
        sceneLocationView.locationNodeTouchDelegate = self
        
        // Now add the route or location annotations as appropriate
        addSceneModels()
        setPinUsingMKPlacemark()
        
        contentView.addSubview(sceneLocationView)
        sceneLocationView.frame = contentView.bounds
        
        mapView.isHidden = !showMap
        
        if showMap {
            updateUserLocationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                self?.updateUserLocation()
            }
            
            routes?.forEach { mapView.addOverlay($0.polyline) }
        }
        
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        restartAnimation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print(#function)
        pauseAnimation()
        super.viewWillDisappear(animated)
    }
    
    func pauseAnimation() {
        print("pause")
        sceneLocationView.pause()
    }
    
    func restartAnimation() {
        print("run")
        sceneLocationView.run()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneLocationView.frame = contentView.bounds
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first,
            let view = touch.view else { return }
        
        if mapView == view || mapView.recursiveSubviews().contains(view) {
            centerMapOnUserLocation = false
        } else {
            let location = touch.location(in: self.view)
            
            if location.x <= 40 && adjustNorthByTappingSidesOfScreen {
                print("left side of the screen")
                sceneLocationView.moveSceneHeadingAntiClockwise()
            } else if location.x >= view.frame.size.width - 40 && adjustNorthByTappingSidesOfScreen {
                print("right side of the screen")
                sceneLocationView.moveSceneHeadingClockwise()
            } else if addNodeByTappingScreen {
                let image = UIImage(named: "pin")!
                let annotationNode = LocationAnnotationNode(location: nil, image: image)
                annotationNode.scaleRelativeToDistance = false
                annotationNode.scalingScheme = .normal
                DispatchQueue.main.async {
                    // If we're using the touch delegate, adding a new node in the touch handler sometimes causes a freeze.
                    // So defer to next pass.
                    //self.sceneLocationView.addLocationNodeForCurrentPosition(locationNode: annotationNode)
                }
            }
        }
    }
    
    
    func setPinUsingMKPlacemark() {
        
        for (index,location) in testArLocationData!.data.enumerated(){
            
            let loc = CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
            let pin = MKPlacemark(coordinate: loc)
            let coordinateRegion = MKCoordinateRegion(center: pin.coordinate, latitudinalMeters: 800, longitudinalMeters: 800)
            mapView.setRegion(coordinateRegion, animated: true)
            mapView.addAnnotation(pin)
        }
        
    }
    @IBAction func testAddNode(_ sender: Any) {
        
        /*let myhome1 = buildNode(latitude: 35.2500739, longitude: 126.8122055, altitude: 10, imageName: "pin")
         sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: myhome1)
         
         */
        
        let alert = UIAlertController(title: "테스트", message: "좌표를 입력해주세요.", preferredStyle: .alert)
        
        alert.addTextField {(textfield) in
            textfield.placeholder = "latitude"
        }
        
        alert.addTextField {(textfield) in
            textfield.placeholder = "longitude"
        }
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: {
            _ in
            let lat = Double((alert.textFields?[0].text)!)
            let lon = Double((alert.textFields?[1].text)!)
            let myhome1 = self.buildNode(latitude: lat!, longitude: lon!, altitude: 10, imageName: "pin")
            DispatchQueue.main.async {
                self.sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: myhome1)
            }
        }))
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }
    
}

// MARK: - MKMapViewDelegate

@available(iOS 11.0, *)
extension ARuserVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.lineWidth = 3
        renderer.strokeColor = UIColor.blue.withAlphaComponent(0.5)
        
        return renderer
    }
    
 
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation),
            let pointAnnotation = annotation as? MKPointAnnotation else { return nil }
        
        let marker = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
        
        if pointAnnotation == self.userAnnotation {
            marker.displayPriority = .required
             marker.markerTintColor = UIColor(hue: 0.267, saturation: 0.67, brightness: 0.77, alpha: 1.0)
            marker.glyphImage = UIImage(named: "user")
        }/* else {
            marker.displayPriority = .required
            marker.markerTintColor = UIColor(hue: 0.267, saturation: 0.67, brightness: 0.77, alpha: 1.0)
            marker.glyphImage = UIImage(named: "compass")
        }*/
        
        return marker
    }
}

// MARK: - Implementation

@available(iOS 11.0, *)
extension ARuserVC {
    
    /// Adds the appropriate ARKit models to the scene.  Note: that this won't
    /// do anything until the scene has a `currentLocation`.  It "polls" on that
    /// and when a location is finally discovered, the models are added.
    func addSceneModels() {
      
   
          guard sceneLocationView.sceneLocationManager.currentLocation != nil else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.addSceneModels()
                    }
                    return
                }

                let box = SCNBox(width: 1, height: 0.2, length: 5, chamferRadius: 0.25)
                box.firstMaterial?.diffuse.contents = UIColor.gray.withAlphaComponent(0.5)

                // 2. If there is a route, show that
                if let routes = routes {
                    sceneLocationView.addRoutes(routes: routes) { distance -> SCNBox in
                        let box = SCNBox(width: 1.75, height: 0.5, length: distance, chamferRadius: 0.25)

        //                // Option 1: An absolutely terrible box material set (that demonstrates what you can do):
        //                box.materials = ["box0", "box1", "box2", "box3", "box4", "box5"].map {
        //                    let material = SCNMaterial()
        //                    material.diffuse.contents = UIImage(named: $0)
        //                    return material
        //                }

                        // Option 2: Something more typical
                        box.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.7)
                        return box
                    }
                } else {
                    // 3. If not, then show the
                    buildDemoData().forEach {
                        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: $0)
                    }
                }

                // There are many different ways to add lighting to a scene, but even this mechanism (the absolute simplest)
                // keeps 3D objects fron looking flat
                sceneLocationView.autoenablesDefaultLighting = true
    }
        
        /// Builds the location annotations for a few random objects, scattered across the country
        ///
        /// - Returns: an array of annotation nodes.
        func buildDemoData() -> [LocationAnnotationNode] {
            var nodes: [LocationAnnotationNode] = []
            
            for (index,location) in testArLocationData!.data.enumerated(){
               /* let pin = buildNode(latitude:  CLLocationDegrees(location.lat), longitude: CLLocationDegrees(location.lng), altitude: CLLocationDistance(location.alt), imageName: "pin")
                nodes.append(pin)*/
                let label = buildViewNode(latitude: CLLocationDegrees(location.lat), longitude: CLLocationDegrees(location.lng), altitude: CLLocationDistance(location.alt), text: "maker-\(index)" , color: .green)
                nodes.append(label)
            }
      
            
            let aply = buildViewNode(latitude: CLLocationDegrees(37.4964496), longitude: CLLocationDegrees(127.0297105), altitude: CLLocationDistance(15), text: "Aply", color: .systemBlue )
            nodes.append(aply)
            /*
            let pikesPeakLayer = CATextLayer()
            pikesPeakLayer.frame = CGRect(x: 0, y: 0, width: 200, height: 40)
            pikesPeakLayer.cornerRadius = 4
            pikesPeakLayer.fontSize = 14
            pikesPeakLayer.alignmentMode = .center
            pikesPeakLayer.foregroundColor = UIColor.black.cgColor
            pikesPeakLayer.backgroundColor = UIColor.white.cgColor
            
            // This demo uses a simple periodic timer to showcase dynamic text in a node.  In your implementation,
            // the view's content will probably be changed as the result of a network fetch or some other asynchronous event.
            
            _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                pikesPeakLayer.string = "Pike's Peak\n" + Date().description
            }
            
            let pikesPeak = buildLayerNode(latitude: 38.8405322, longitude: -105.0442048, altitude: 4705, layer: pikesPeakLayer)
            nodes.append(pikesPeak)
            */
            
            return nodes
        }
        
        @objc
        func updateUserLocation() {
            print("updateUserLocation")
            guard let currentLocation = sceneLocationView.sceneLocationManager.currentLocation else {
                return
            }
            
            DispatchQueue.main.async { [weak self ] in
                guard let self = self else {
                    return
                }
                
                if self.userAnnotation == nil {
                    self.userAnnotation = MKPointAnnotation()
                    self.mapView.addAnnotation(self.userAnnotation!)
                }
                
                UIView.animate(withDuration: 0.5, delay: 0, options: .allowUserInteraction, animations: {
                    self.userAnnotation?.coordinate = currentLocation.coordinate
                }, completion: nil)
                
                if self.centerMapOnUserLocation {
                    UIView.animate(withDuration: 0.45,
                                   delay: 0,
                                   options: .allowUserInteraction,
                                   animations: {
                                    self.mapView.setCenter(self.userAnnotation!.coordinate, animated: false)
                    }, completion: { _ in
                        self.mapView.region.span = MKCoordinateSpan(latitudeDelta: 0.0005, longitudeDelta: 0.0005)
                    })
                }
                
                if self.displayDebugging {
                    if let bestLocationEstimate = self.sceneLocationView.sceneLocationManager.bestLocationEstimate {
                        if self.locationEstimateAnnotation == nil {
                            self.locationEstimateAnnotation = MKPointAnnotation()
                            self.mapView.addAnnotation(self.locationEstimateAnnotation!)
                        }
                        self.locationEstimateAnnotation?.coordinate = bestLocationEstimate.location.coordinate
                    } else if self.locationEstimateAnnotation != nil {
                        self.mapView.removeAnnotation(self.locationEstimateAnnotation!)
                        self.locationEstimateAnnotation = nil
                    }
                }
            }
        }
        
        @objc
        func updateInfoLabel() {
            if let position = sceneLocationView.currentScenePosition {
                infoLabel.text = " x: \(position.x.short), y: \(position.y.short), z: \(position.z.short)\n"
            }
            
            if let eulerAngles = sceneLocationView.currentEulerAngles {
                infoLabel.text!.append(" Euler x: \(eulerAngles.x.short), y: \(eulerAngles.y.short), z: \(eulerAngles.z.short)\n")
            }
            
            if let eulerAngles = sceneLocationView.currentEulerAngles,
                let heading = sceneLocationView.sceneLocationManager.locationManager.heading,
                let headingAccuracy = sceneLocationView.sceneLocationManager.locationManager.headingAccuracy {
                let yDegrees = (((0 - eulerAngles.y.radiansToDegrees) + 360).truncatingRemainder(dividingBy: 360) ).short
                infoLabel.text!.append(" Heading: \(yDegrees)° • \(Float(heading).short)° • \(headingAccuracy)°\n")
            }
            
            let comp = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: Date())
            if let hour = comp.hour, let minute = comp.minute, let second = comp.second, let nanosecond = comp.nanosecond {
                let nodeCount = "\(sceneLocationView.sceneNode?.childNodes.count.description ?? "n/a") ARKit Nodes"
                infoLabel.text!.append(" \(hour.short):\(minute.short):\(second.short):\(nanosecond.short3) • \(nodeCount)")
            }
        }
    
        //AR 세팅 마커
        func buildNode(latitude: CLLocationDegrees, longitude: CLLocationDegrees,
                       altitude: CLLocationDistance, imageName: String) -> LocationAnnotationNode {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let location = CLLocation(coordinate: coordinate, altitude: altitude)
            let image = UIImage(named: imageName)!
            return LocationAnnotationNode(location: location, image: image)
        }
        
        func buildViewNode(latitude: CLLocationDegrees, longitude: CLLocationDegrees,
                           altitude: CLLocationDistance, text: String, color:UIColor) -> LocationAnnotationNode {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let location = CLLocation(coordinate: coordinate, altitude: altitude)
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            label.text = text
            label.backgroundColor = color
            label.textAlignment = .center
            return LocationAnnotationNode(location: location, view: label)
        }
        
        func buildLayerNode(latitude: CLLocationDegrees, longitude: CLLocationDegrees,
                            altitude: CLLocationDistance, layer: CALayer) -> LocationAnnotationNode {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let location = CLLocation(coordinate: coordinate, altitude: altitude)
            return LocationAnnotationNode(location: location, layer: layer)
        }
        
    }
    
    // MARK: - LNTouchDelegate
    @available(iOS 11.0, *)
    extension ARuserVC: LNTouchDelegate {
        
        func annotationNodeTouched(node: AnnotationNode) {
            if let node = node.parent as? LocationNode {
                let coords = "\(node.location.coordinate.latitude.short)° \(node.location.coordinate.longitude.short)°"
                let altitude = "\(node.location.altitude.short)m"
                let tag = node.tag ?? ""
                nodePositionLabel.text = " Annotation node at \(coords), \(altitude) - \(tag)"
            }
        }
        
        func locationNodeTouched(node: LocationNode) {
            print("Location node touched - tag: \(node.tag ?? "")")
            let coords = "\(node.location.coordinate.latitude.short)° \(node.location.coordinate.longitude.short)°"
            let altitude = "\(node.location.altitude.short)m"
            let tag = node.tag ?? ""
            nodePositionLabel.text = " Location node at \(coords), \(altitude) - \(tag)"
        }
        
    }
    
    // MARK: - Helpers
    
    extension DispatchQueue {
        func asyncAfter(timeInterval: TimeInterval, execute: @escaping () -> Void) {
            self.asyncAfter(
                deadline: DispatchTime.now() + Double(Int64(timeInterval * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
                execute: execute)
        }
    }
    
    extension UIView {
        func recursiveSubviews() -> [UIView] {
            var recursiveSubviews = self.subviews
            
            subviews.forEach { recursiveSubviews.append(contentsOf: $0.recursiveSubviews()) }
            
            return recursiveSubviews
        }
    }
    
    @available(iOS 11.0, *)
    extension ARuserVC: ARSCNViewDelegate {
        
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            print("Added SCNNode: \(node)")    // you probably won't see this fire
        }
        
        func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
            print("willUpdate: \(node)")    // you probably won't see this fire
        }
        
        func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
            print("Camera: \(camera)")
        }
        
}
