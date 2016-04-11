//
//  ViewController.swift
//  SwiftPhotoGallery
//
//  Created by Justin Vallely on 08/25/2015.
//  Copyright (c) 2015 Justin Vallely. All rights reserved.
//

import UIKit
import SwiftPhotoGallery

class HeaderViewController: UIViewController {

    @IBAction func unwindToMainMenu(sender: UIStoryboardSegue)
    {
        let _: AnyObject = sender.sourceViewController
        // Pull any data from the view controller which initiated the unwind segue.
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}

class ViewController: PortraitOnlyViewController, SwiftPhotoGalleryDataSource, SwiftPhotoGalleryDelegate {

    let imageNames = ["image1.jpeg", "image2.jpeg", "image3.jpeg"]

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func didPressShowMeButton(sender: AnyObject) {
        let gallery = SwiftPhotoGallery(delegate: self, dataSource: self)

        gallery.backgroundColor = UIColor.blackColor()
        gallery.pageIndicatorTintColor = UIColor.grayColor().colorWithAlphaComponent(0.5)
        gallery.currentPageIndicatorTintColor = UIColor.whiteColor()

        presentViewController(gallery, animated: true, completion: nil)
    }

    // MARK: SwiftPhotoGalleryDataSource Methods

    func numberOfImagesInGallery(gallery: SwiftPhotoGallery) -> Int {
        return imageNames.count
    }

    func imageInGallery(gallery: SwiftPhotoGallery, forIndex index: Int) -> UIImage? {
        if index == 1 {
            // use for test placeholder
            return nil
        }
        return UIImage(named: imageNames[index])
    }
    
    func placeHolderInGallery(gallery: SwiftPhotoGallery, forIndex index: Int) -> String? {
        return "Image Not Found"
    }
    
    // MARK: SwiftPhotoGalleryDelegate Methods

    func galleryDidTapToClose(gallery: SwiftPhotoGallery) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}

