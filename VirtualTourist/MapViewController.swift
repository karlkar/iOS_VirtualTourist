
import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    private let mapStateStore = MapStateStore()
    
    @IBOutlet weak var mapViewOutlet: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupInitialPosition()
        
        setupLongPressRecognizer()
        
        mapViewOutlet.delegate = self
    }
    
    private func setupInitialPosition() {
        if let mapState = mapStateStore.getStoredState() {
            let region = MKCoordinateRegion(center: mapState.location, span: mapState.zoomLevel)
            mapViewOutlet.setRegion(region, animated: false)
        }
    }
    
    private func setupLongPressRecognizer() {
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress(recognizer:)))
        mapViewOutlet.addGestureRecognizer(longGesture)
    }
    
    @objc func onLongPress(recognizer: UIGestureRecognizer) {
        let touchPoint = recognizer.location(in: mapViewOutlet)
        let pointOnMap = mapViewOutlet.convert(touchPoint, toCoordinateFrom: mapViewOutlet)
        let touchLocation = CLLocation(latitude: pointOnMap.latitude, longitude: pointOnMap.longitude)
        
        let pin = MKPointAnnotation()
        pin.coordinate = touchLocation.coordinate
        mapViewOutlet.addAnnotation(pin)
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
            vc.location = view.annotation?.coordinate
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

