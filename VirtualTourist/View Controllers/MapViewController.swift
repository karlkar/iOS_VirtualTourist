
import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {
    
    private let mapStateStore = MapStateStore()
    
    var dataController: DataController!
    
    @IBOutlet weak var mapViewOutlet: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupInitialPosition()
        
        setupLongPressRecognizer()
        
        loadStoredPinData()
        
        mapViewOutlet.delegate = self
    }
    
    private func setupInitialPosition() {
        if let mapState = mapStateStore.getStoredState() {
            let region = MKCoordinateRegion(center: mapState.location, span: mapState.zoomLevel)
            mapViewOutlet.setRegion(region, animated: true)
        }
    }
    
    private func setupLongPressRecognizer() {
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress(recognizer:)))
        mapViewOutlet.addGestureRecognizer(longGesture)
    }
    
    @objc func onLongPress(recognizer: UIGestureRecognizer) {
        if recognizer.state != .began{
            return
        }
        let touchCoordinate = getTouchCoordinates(mapView: mapViewOutlet, recognizer: recognizer)
        
        let pin = addPinToDataStore(coordinate: touchCoordinate)
        addPinToMap(mapView: mapViewOutlet, pin: pin, coordinate: touchCoordinate)
    }
    
    private func getTouchCoordinates(mapView: MKMapView, recognizer: UIGestureRecognizer) -> CLLocationCoordinate2D {
        let touchPoint = recognizer.location(in: mapView)
        let pointOnMap = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let touchLocation = CLLocation(latitude: pointOnMap.latitude, longitude: pointOnMap.longitude)
        return touchLocation.coordinate
    }
    
    private func addPinToMap(mapView: MKMapView, pin: Pin, coordinate: CLLocationCoordinate2D) {
        let pointAnnotation = CustomPointAnnotation()
        pointAnnotation.coordinate = coordinate
        pointAnnotation.tag = pin
        mapView.addAnnotation(pointAnnotation)
        
        // Hack to deselect added pin
        mapView.setCenter(mapView.centerCoordinate, animated: false)
    }
    
    private func addPinToDataStore(coordinate: CLLocationCoordinate2D) -> Pin {
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        pin.photoPageCount = -1
        try? dataController.viewContext.save()
        return pin
    }
    
    private func loadStoredPinData() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            result.reduce(into: [Pin: CLLocationCoordinate2D]()) {
                $0[$1] = CLLocationCoordinate2D(latitude: $1.latitude, longitude: $1.longitude)
            }.forEach { addPinToMap(mapView: mapViewOutlet, pin: $0, coordinate: $1) }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        storeCurrentMapState()
    }
    
    private func storeCurrentMapState() {
        let currentLocation = mapViewOutlet.centerCoordinate
        let currentZoom = mapViewOutlet.region.span
        
        mapStateStore.updateState(state: MapState(location: currentLocation, zoomLevel: currentZoom))
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as? PhotoAlbumViewController {
            vc.pin = (view.annotation as! CustomPointAnnotation).tag
            vc.dataController = dataController
            navigationController?.pushViewController(vc, animated: true)
        }
        
        self.mapViewOutlet.selectedAnnotations.forEach({ mapViewOutlet.deselectAnnotation($0, animated: false) })
    }
}

