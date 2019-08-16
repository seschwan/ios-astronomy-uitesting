//
//  PhotosCollectionViewController.swift
//  Astronomy
//
//  Created by Andrew R Madsen on 9/5/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit

class PhotosCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        client.fetchMarsRover(named: "curiosity") { (rover, error) in
            if let error = error {
                NSLog("Error fetching info for curiosity: \(error)")
                return
            }
            
            self.roverInfo = rover
        }
        
        configureTitleView()
        updateViews()
    }
    
    @IBAction func goToPreviousSol(_ sender: Any?) {
        guard let solDescription = solDescription else { return }
        guard let solDescriptions = roverInfo?.solDescriptions else { return }
        guard let index = solDescriptions.firstIndex(of: solDescription) else { return }
        guard index > 0 else { return }
        self.solDescription = solDescriptions[index-1]
    }
    
    @IBAction func goToNextSol(_ sender: Any?) {
        guard let solDescription = solDescription else { return }
        guard let solDescriptions = roverInfo?.solDescriptions else { return }
        guard let index = solDescriptions.firstIndex(of: solDescription) else { return }
        guard index < solDescriptions.count - 1 else { return }
        self.solDescription = solDescriptions[index+1]
    }
    
    // UICollectionViewDataSource/Delegate
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        NSLog("num photos: \(photoReferences.count)")
        return photoReferences.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as? ImageCollectionViewCell ?? ImageCollectionViewCell()
        
        loadImage(forCell: cell, forItemAt: indexPath)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if photoReferences.count > 0 {
            let photoRef = photoReferences[indexPath.item]
            operations[photoRef.id]?.cancel()
        } else {
            for (_, operation) in operations {
                operation.cancel()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        var totalUsableWidth = collectionView.frame.width
        let inset = self.collectionView(collectionView, layout: collectionViewLayout, insetForSectionAt: indexPath.section)
        totalUsableWidth -= inset.left + inset.right
        
        let minWidth: CGFloat = 150.0
        let numberOfItemsInOneRow = Int(totalUsableWidth / minWidth)
        totalUsableWidth -= CGFloat(numberOfItemsInOneRow - 1) * flowLayout.minimumInteritemSpacing
        let width = totalUsableWidth / CGFloat(numberOfItemsInOneRow)
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10.0, bottom: 0, right: 10.0)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail" {
            guard let indexPath = collectionView.indexPathsForSelectedItems?.first else { return }
            let detailVC = segue.destination as! PhotoDetailViewController
            detailVC.photo = photoReferences[indexPath.item]
        }
    }
    
    // MARK: - Private
    
    private func configureTitleView() {
        
//        let font = UIFont.systemFont(ofSize: 30)
//        let attrs = [NSAttributedStringKey.font: font]

//        let prevTitle = NSAttributedString(string: "<", attributes: attrs)
//        let prevButton = UIButton(type: .system)
//        prevButton.accessibilityIdentifier = "PhotosCollectionViewController.PreviousSolButton"
//        prevButton.setAttributedTitle(prevTitle, for: .normal)
//        prevButton.addTarget(self, action: #selector(goToPreviousSol(_:)), for: .touchUpInside)
        
        let prevItem = UIBarButtonItem(title: "<", style: .plain, target: self, action: #selector(goToPreviousSol(_:)))
        prevItem.accessibilityIdentifier = "PhotosCollectionViewController.PreviousSolButton"
        
//        let nextTitle = NSAttributedString(string: ">", attributes: attrs)
//        let nextButton = UIButton(type: .system)
//        nextButton.setAttributedTitle(nextTitle, for: .normal)
//        nextButton.addTarget(self, action: #selector(goToNextSol(_:)), for: .touchUpInside)
//        nextButton.accessibilityIdentifier = "PhotosCollectionViewController.NextSolButton"
        
        let nextItem = UIBarButtonItem(title: ">", style: .plain, target: self, action: #selector(goToNextSol(_:)))
        nextItem.accessibilityIdentifier = "PhotosCollectionViewController.NextSolButton"
        
//        let stackView = UIStackView(arrangedSubviews: [prevButton, solLabel, nextButton])
//        stackView.axis = .horizontal
//        stackView.alignment = .fill
//        stackView.distribution = .fill
//        stackView.spacing = UIStackView.spacingUseSystem
        
        navigationItem.setLeftBarButton(prevItem, animated: false)
        navigationItem.setRightBarButton(nextItem, animated: false)
    }
    
    private func updateViews() {
        guard isViewLoaded else { return }
        title = "Sol \(solDescription?.sol ?? 0)"
    }
    
    private func loadImage(forCell cell: ImageCollectionViewCell, forItemAt indexPath: IndexPath) {
        let photoReference = photoReferences[indexPath.item]
        // Check for image in cache
        if let cachedImage = cache.value(for: photoReference.id) {
            cell.imageView.image = cachedImage
            return
        }
        
        if isUITesting {
            self.loadLocalImage(for: cell, for: indexPath)
            return
        }
        
        // Start an operation to fetch image data
        let fetchOp = FetchPhotoOperation(photoReference: photoReference)
        let filterOp = FilterImageOperation(fetchOperation: fetchOp)
        filterOp.completionBlock = {
            NSLog("Filter op finished")
        }
        let cacheOp = BlockOperation {
            if let image = filterOp.image {
                self.cache.cache(value: image, for: photoReference.id)
            }
        }
        let completionOp = BlockOperation {
            NSLog("Completed")
            defer { self.operations.removeValue(forKey: photoReference.id) }
            
            if let currentIndexPath = self.collectionView?.indexPath(for: cell),
                currentIndexPath != indexPath {
                return // Cell has been reused
            }
            
            if let image = filterOp.image {
                cell.imageView.image = image
            }
        }
        
        filterOp.addDependency(fetchOp)
        cacheOp.addDependency(filterOp)
        completionOp.addDependency(filterOp)
        
        photoFetchQueue.addOperation(fetchOp)
        photoFetchQueue.addOperation(cacheOp)
        imageFilteringQueue.addOperation(filterOp)
        OperationQueue.main.addOperation(completionOp)
        
        operations[photoReference.id] = fetchOp
    }
    
    // MARK: - UI Testing Methods
    
    func loadLocalImage(for cell: ImageCollectionViewCell, for indexPath: IndexPath) {
        
        let photoRef = photoReferences[indexPath.row]
        
        guard let url = Bundle.main.url(forResource: "\(photoRef.id)", withExtension: "jpg", subdirectory: "Sol\(photoRef.sol)Photos") else { return }
        
        do {
            let imageData = try Data(contentsOf: url)
            
            let image = UIImage(data: imageData)
            
            cell.imageView.image = image
        } catch {
            NSLog("Unable to initialize data with URL: \(url), error: \(error)")
        }
    }
    
    // Properties
    
    private let client = MarsRoverClient()
    private let cache = Cache<Int, UIImage>()
    private let photoFetchQueue = OperationQueue()
    private let imageFilteringQueue = OperationQueue()
    private var operations = [Int : Operation]()
    
    private var roverInfo: MarsRover? {
        didSet {
            solDescription = roverInfo?.solDescriptions[1]
        }
    }
    
    private var solDescription: SolDescription? {
        didSet {
            if let rover = roverInfo,
                let sol = solDescription?.sol {
                photoReferences = []
                client.fetchPhotos(from: rover, onSol: sol) { (photoRefs, error) in
                    if let e = error { NSLog("Error fetching photos for \(rover.name) on sol \(sol): \(e)"); return }
                    self.photoReferences = photoRefs ?? []
                    DispatchQueue.main.async { self.updateViews() }
                }
            }
        }
    }
    
    private var photoReferences = [MarsPhotoReference]() {
        didSet {
            cache.clear()
            DispatchQueue.main.async { self.collectionView?.reloadData() }
        }
    }
    
    @IBOutlet var collectionView: UICollectionView!
    let solLabel = UILabel()
}
