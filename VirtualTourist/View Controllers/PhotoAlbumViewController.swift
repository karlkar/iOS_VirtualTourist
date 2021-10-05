
import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var pin: Pin!
    var dataController: DataController!

    private var allImagesDownloaded = false
    
    var photos = [Photo]()
    
    private let reuseIdentifier = "PhotoAlbumCellView"
    
    private let flickrApiHelper = FlickrApiHelper()
    
    @IBOutlet weak var mapViewOutlet: MKMapView!
    @IBOutlet weak var collectionViewOutlet: UICollectionView!
    @IBOutlet weak var labelOutlet: UILabel!
    @IBOutlet weak var buttonOutlet: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.isHidden = false
        collectionViewOutlet.delegate = self
        collectionViewOutlet.dataSource = self
        
        displayImagesLoadingLayout()
        startLoadingImages()
        setupMapView()
    }
    
    private func startLoadingImages() {
        if pin.photoPageCount < 0 {
            fetchImagesFromNetwork()
        } else {
            fetchImagesFromStore()
        }
    }
    
    private func fetchImagesFromStore() {
        allImagesDownloaded = false
        
        let request = Photo.fetchRequest()
        request.predicate = NSPredicate(format: "pin == %@", pin)
        if let result = try? dataController.viewContext.fetch(request) {
            photos = result
            collectionViewOutlet.reloadData()
            
            displayImagesLoadedLayout()
            
            allImagesDownloaded = true
        }
    }
    
    private func fetchImagesFromNetwork(page: Int = 0) {
        allImagesDownloaded = false
        
        flickrApiHelper.searchPhotos(latitude: pin.latitude, longitude: pin.longitude, page: page, resultHandler: { success, data in
            if success {
                self.handlePhotoListAcquired(response: data!)
            }
        })
    }
    
    private func handlePhotoListAcquired(response: FlickrSearchResponse) {
        pin.photoPageCount = response.pageCount
        for flickrPhoto in response.photos {
            let photo = flickrPhoto.toPhoto(dataController: dataController, parentPin: pin)
            photos.append(photo)
            fetchImageData(photo: photo, flickrPhoto: flickrPhoto)
        }
        collectionViewOutlet.reloadData()
        try? dataController.viewContext.save()
        
        displayImagesLoadedLayout()
    }
    
    private func fetchImageData(photo: Photo, flickrPhoto: FlickrPhoto) {
        flickrApiHelper.getImage(flickrPhoto: flickrPhoto, resultHandler: { success, data in
            if success {
                photo.image = data
                try? self.dataController.viewContext.save()
                self.collectionViewOutlet.reloadData()
                
                self.allImagesDownloaded = self.photos.allSatisfy { $0.image != nil }
            }
        })
    }
    
    private func displayNoImageLayout() {
        collectionViewOutlet.isHidden = true
        labelOutlet.isHidden = false
        buttonOutlet.isEnabled = false
        labelOutlet.text = "No Images... :("
    }
    
    private func displayImagesLoadingLayout() {
        collectionViewOutlet.isHidden = false
        labelOutlet.isHidden = false
        buttonOutlet.isEnabled = true
        labelOutlet.text = "Loading..."
    }
    
    private func displayImagesLoadedLayout() {
        collectionViewOutlet.isHidden = false
        labelOutlet.isHidden = true
        buttonOutlet.isEnabled = true
    }
    
    private func setupMapView() {
        mapViewOutlet.centerCoordinate.latitude = pin.latitude
        mapViewOutlet.centerCoordinate.longitude = pin.longitude
        mapViewOutlet.region.span = MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
        
        let pointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        mapViewOutlet.addAnnotation(pointAnnotation)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoAlbumCellView
        
        if photos[indexPath.row].image == nil {
            cell.imageOutlet.image = UIImage(systemName: "slowmo")
        } else {
            cell.imageOutlet.image = UIImage(data: photos[indexPath.row].image!)
        }
    
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if allImagesDownloaded {
            removePhoto(indexPath: indexPath)
        }
    }
    
    private func removePhoto(indexPath: IndexPath) {
        removePhotoFromStore(indexPath: indexPath)
        removePhotoFromView(indexPath: indexPath)
    }
    
    private func removePhotoFromStore(indexPath: IndexPath) {
        let photoToBeDeleted = photos[indexPath.row]
        dataController.viewContext.delete(photoToBeDeleted)
        try? dataController.viewContext.save()
    }
    
    private func removePhotoFromView(indexPath: IndexPath) {
        photos.remove(at: indexPath.row)
        collectionViewOutlet.deleteItems(at: [indexPath])
    }
    
    @IBAction func newCollectionButtonAction(_ sender: Any) {
        displayImagesLoadingLayout()
        
        clearPhotosInStore()
        clearPhotosInView()
        
        let upperBoundary = min(Int(pin.photoPageCount), 4000/FlickrApiHelper.PER_PAGE_COUNT)
        let randomPage = Int.random(in: 1...upperBoundary)
        fetchImagesFromNetwork(page: randomPage)
    }
    
    private func clearPhotosInStore() {
        photos.forEach { dataController.viewContext.delete($0) }
    }
    
    private func clearPhotosInView() {
        photos = []
        collectionViewOutlet.reloadData()
    }
}

extension FlickrPhoto {
    
    func toPhoto(dataController: DataController, parentPin: Pin) -> Photo {
        let photo = Photo(context: dataController.viewContext)
        photo.identifier = self.id
        photo.secret = self.secret
        photo.server = Int32(self.server)
        photo.image = nil
        photo.pin = parentPin
        return photo
    }
}
