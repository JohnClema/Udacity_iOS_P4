//
//  PhotoCell.swift
//  Virtual Tourist
//
//  Created by John Clema on 16/05/2016.
//  Copyright © 2016 JohnClema. All rights reserved.
//

import UIKit

class PhotoCell : UICollectionViewCell {
    
    static let reuseIdentifier: String = "photoCell"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    // MARK: - Selection handling
    
    override var isSelected: Bool {
        get {
            return super.isSelected
        }
        set {
            super.isSelected = newValue
            overlayView.isHidden = !isSelected
        }
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        self.isSelected = false
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        imageView.image = nil
        overlayView.isHidden = true
    }
}
