
import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var location: CLLocationCoordinate2D? = nil
    
    private let reuseIdentifier = "AlbumCell"
    
    private let flickrApiHelper = FlickrApiHelper()
    
    @IBOutlet weak var mapViewOutlet: MKMapView!
    @IBOutlet weak var collectionViewOutlet: UICollectionView!
    @IBOutlet weak var labelOutlet: UILabel!
    @IBOutlet weak var buttonOutlet: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.isHidden = false
        
        collectionViewOutlet.delegate = self
        
        displayNoImageLayout()
        setupMapView()
    }
    
    private func displayNoImageLayout() {
        collectionViewOutlet.isHidden = true
        labelOutlet.isHidden = false
        buttonOutlet.isEnabled = false
    }
    
    private func displayImagesLoadingLayout() {
        collectionViewOutlet.isHidden = false
        labelOutlet.isHidden = true
        buttonOutlet.isEnabled = false
    }
    
    private func displayImagesLoadedLayout() {
        collectionViewOutlet.isHidden = false
        labelOutlet.isHidden = true
        buttonOutlet.isEnabled = true
    }
    
    private func setupMapView() {
        if let location = location {
            mapViewOutlet.centerCoordinate.latitude = location.latitude
            mapViewOutlet.centerCoordinate.longitude = location.longitude
            
            mapViewOutlet.region.span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoAlbumCellView
        
        cell.imageOutlet.image = UIImage()
        
        return cell
    }
}
