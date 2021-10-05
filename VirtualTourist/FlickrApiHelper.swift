
import Foundation

class FlickrApiHelper {
    
    static let PER_PAGE_COUNT = 50
    
    private let baseUrl = "https://www.flickr.com/services/rest/?method="
    private let apiKey = "e8fcebdbc72429d718b774c66fe38c8a"
    private let per_page = "per_page=\(PER_PAGE_COUNT)"
    private let formatJson = "format=json&nojsoncallback=1"
    
    private func doOnMainThread<T>(success: Bool, data: T?, resultHandler: @escaping (Bool, T?) -> ()) {
        DispatchQueue.main.async {
            resultHandler(success, data)
        }
    }
    
    func searchPhotos(latitude: Double, longitude: Double, page: Int, resultHandler: @escaping (Bool, FlickrSearchResponse?) -> ()) {
        let urlString = "\(baseUrl)flickr.photos.search&api_key=\(apiKey)&lat=\(latitude)&lon=\(longitude)&\(formatJson)&\(per_page)&page=\(page)"
        let url = URL(string: urlString)!
        let request = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: [searchPhotos] error != nil")
                self.doOnMainThread(success: false, data: nil, resultHandler: resultHandler)
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                print("ERROR: [searchPhotos] Your request returned a status code other than 2xx!")
                self.doOnMainThread(success: false, data: nil, resultHandler: resultHandler)
                return
            }
            
            //            print("SUCCESS: [searchPhotos] data = \(String(data: data!, encoding: .utf8)!)")
            
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String:AnyObject]
            } catch {
                print("Could not parse the data as JSON: '\(data!)'")
                self.doOnMainThread(success: false, data: nil, resultHandler: resultHandler)
                return
            }
            
            guard let parsedCheckedResult = parsedResult else {
                print("Parsing failed")
                self.doOnMainThread(success: false, data: nil, resultHandler: resultHandler)
                return
            }
            
            let flickrSearchResponse = self.parseJson(json: parsedCheckedResult)
            
            print("SUCCESS: [searchPhotos] response = \(flickrSearchResponse)")
            
            self.doOnMainThread(success: true, data: flickrSearchResponse, resultHandler: resultHandler)
        }
        
        task.resume()
    }
    
    private func parseJson(json: [String: AnyObject]) -> FlickrSearchResponse {
        let totalCount = json["photos"]!["total"] as! Int
        let pageCount = json["photos"]!["pages"] as! Int64
        let photoArray = (json["photos"]!["photo"] as! NSArray)
            .map { $0 as! NSDictionary }
            .map { FlickrPhoto(id: $0["id"] as! String, secret: $0["secret"] as! String, server: $0["farm"] as! Int) }
        
        return FlickrSearchResponse(totalCount: totalCount, pageCount: pageCount, photos: photoArray)
    }
    
    func getImage(flickrPhoto: FlickrPhoto, resultHandler: @escaping (Bool, Data?) -> ()) {
        let imageUrlString = "https://live.staticflickr.com/\(flickrPhoto.server)/\(flickrPhoto.id)_\(flickrPhoto.secret)_w.jpg"
        let imageURL = URL(string: imageUrlString)
        DispatchQueue.global(qos: .userInitiated).async {
            if let imageData = try? Data(contentsOf: imageURL!) {
                self.doOnMainThread(success: true, data: imageData, resultHandler: resultHandler)
            }
        }
    }
}
