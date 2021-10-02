
import Foundation

class FlickrApiHelper {
    
    private let baseUrl = "https://www.flickr.com/services/rest/?method="
    private let apiKey = "e8fcebdbc72429d718b774c66fe38c8a"
    private let formatJson = "format=json&nojsoncallback=1"
    
    func searchPhotos(latitude: Double, longitude: Double) {
        "\(baseUrl)flickr.photos.search&api_key=\(apiKey)&lat=23&lon=24&\(formatJson)"
    }
    
    func getImage(id: String) {
        
    }
}
