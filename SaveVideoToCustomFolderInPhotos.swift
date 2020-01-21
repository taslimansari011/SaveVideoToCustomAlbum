//
//  Created by Taslim Ansari on 21/01/20.
//  Copyright © 2020. All rights reserved.
//

import UIKit
import Photos
import AVFoundation

extension UIViewController {
    
    // 1: Call this method and pass your video's url and the name of the cutom album you want to create in Photos
    func save(url: URL, toAlbum titled: String, completionHandler: @escaping (Bool, Error?) -> Void) {
        // Get album for Scribble videos from photos if not found then create a new album named "Scibble Video"
        getAlbum(title: titled) { (album) in
            DispatchQueue.global(qos: .background).async {
                PHPhotoLibrary.shared().performChanges({
                    let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                    let assets = assetRequest?.placeholderForCreatedAsset.map { [$0] as NSArray } ?? NSArray()
                    let albumChangeRequest = album.flatMap { PHAssetCollectionChangeRequest(for: $0) }
                    albumChangeRequest?.addAssets(assets)
                }, completionHandler: { (success, error) in
                    completionHandler(success, error)
                })
            }
        }
    }
    
    // 2: Try to get this album from photos, if not found create a new album using createAlbum method below
    func getAlbum(title: String, completionHandler: @escaping (PHAssetCollection?) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", title)
            let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

            if let album = collections.firstObject {
                completionHandler(album)
            } else {
                self?.createAlbum(withTitle: title, completionHandler: { (album) in
                    completionHandler(album)
                })
            }
        }
    }
    
    // 3: Create new album named Scribble Video in photos
    func createAlbum(withTitle title: String, completionHandler: @escaping (PHAssetCollection?) -> Void) {
        var albumPlaceholder: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            // Request creating an album with parameter name
            let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
            // Get a placeholder for the new album
            albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
        }, completionHandler: { success, error in
            if success {
                guard let placeholder = albumPlaceholder else {
                    fatalError("Album placeholder is nil")
                }

                let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
                guard let album: PHAssetCollection = fetchResult.firstObject else {
                    // FetchResult has no PHAssetCollection
                    return
                }

                // Successfully saved ...
                completionHandler(album)
            } else if let error = error {
                // Save album failed with error
                debugPrint("\(error.localizedDescription)")
            } else {
                // Save album failed with no error
            }
        })
    }
}
