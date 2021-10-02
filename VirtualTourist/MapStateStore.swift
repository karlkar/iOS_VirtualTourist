
import Foundation
import CoreLocation
import MapKit

class MapStateStore {
    
    private static let PREF_START_LAT = "PREF_START_LAT"
    private static let PREF_START_LNG = "PREF_START_LNG"
    private static let PREF_START_ZOOM_LAT = "PREF_START_ZOOM_LAT"
    private static let PREF_START_ZOOM_LNG = "PREF_START_ZOOM_LNG"
    
    func getStoredState() -> MapState? {
        let startLat = UserDefaults.standard.double(forKey: MapStateStore.PREF_START_LAT)
        let startLng = UserDefaults.standard.double(forKey: MapStateStore.PREF_START_LNG)
        
        let startZoomLat = UserDefaults.standard.double(forKey: MapStateStore.PREF_START_ZOOM_LAT)
        let startZoomLng = UserDefaults.standard.double(forKey: MapStateStore.PREF_START_ZOOM_LNG)
        
        if (startLat == 0 && startLng == 0) || (startZoomLat == 0 && startZoomLng == 0) {
            return nil
        } else {
            let location = CLLocationCoordinate2D(latitude: startLat, longitude: startLng)
            let zoom = MKCoordinateSpan(latitudeDelta: startZoomLat, longitudeDelta: startZoomLng)
            return MapState(location: location, zoomLevel: zoom)
        }
    }
    
    func updateState(state: MapState) {
        storeLocation(state)
        storeZoom(state)
    }
    
    private func storeLocation(_ state: MapState) {
        UserDefaults.standard.set(state.location.latitude, forKey: MapStateStore.PREF_START_LAT)
        UserDefaults.standard.set(state.location.longitude, forKey: MapStateStore.PREF_START_LNG)
    }
    
    private func storeZoom(_ state: MapState) {
        UserDefaults.standard.set(state.zoomLevel.latitudeDelta, forKey: MapStateStore.PREF_START_ZOOM_LAT)
        UserDefaults.standard.set(state.zoomLevel.longitudeDelta, forKey: MapStateStore.PREF_START_ZOOM_LNG)
    }
}
