//
//  AlbumViewController+CollectionView.swift
//  VirtualTourist
//
//  Created by Khalil Kum on 6/29/21.
//

import Foundation
import UIKit
import CoreData

extension AlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    // MARK: Collection View Setup
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResultsController.sections?[section].numberOfObjects ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoImageViewCell", for: indexPath) as! PhotoCollectionViewCell
        cell.activityIndicator.startAnimating()
        cell.photoImageView.image = UIImage(named: "imageLoading")
        
        guard !(fetchResultsController.fetchedObjects?.isEmpty)! else {
            cell.activityIndicator.stopAnimating()
            return cell
        }

        let photo = fetchResultsController.object(at: indexPath)

        if let imageData = photo.imageData {
            cell.activityIndicator.stopAnimating()
            cell.photoImageView.image = UIImage(data: imageData)!
        } else {
            let backgroundContext: NSManagedObjectContext! = dataStackHandler.backgroundContext
            let imageUrl = photo.imageUrl!
            let photoID = photo.objectID

            backgroundContext.perform {
                let backgroundPhoto = backgroundContext.object(with: photoID) as! Photo
                FlickrClient.downloadPhoto(imageUrl) { data, error in
                    guard let imageData = data else {
                        print("Error downloading image data. Errors: \(error!.localizedDescription)")
                        return
                    }
                    
                    backgroundPhoto.imageData = imageData

                    cell.activityIndicator.stopAnimating()
                    cell.photoImageView.image = UIImage(data: imageData)
                }
                
                do {
                    try backgroundContext.save()
                } catch {
                    print("Error saving background photo. Errors: \(error.localizedDescription)")
                }
            }
        }

        refreshCollectionButton.isEnabled = true
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        deleteButton.isEnabled = true
    }

    // MARK: Functions
    func setupFlowLayout() {
         let space:CGFloat = 3.0
         let dimension = (view.frame.size.width - (2 * space)) / 3.0
         flowLayout.minimumInteritemSpacing = space
         flowLayout.minimumLineSpacing = space
         flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    func deleteSelectedPhotos() {
        if let indexPathsForSelectedPhotos = collectionView.indexPathsForSelectedItems {
            for indexPath in indexPathsForSelectedPhotos {
                let photoToDelete = fetchResultsController.object(at: indexPath)
                dataStackHandler.viewContext.delete(photoToDelete)

                do {
                    try dataStackHandler.viewContext.save()
                } catch {
                    print("Failed to delete an image")
                }
            }
        }
    }
}
