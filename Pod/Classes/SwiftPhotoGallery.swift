//
//  SwiftPhotoGallery.swift
//  Pods
//
//  Created by Justin Vallely on 8/25/15.
//
//

import Foundation
import UIKit

@objc public protocol SwiftPhotoGalleryDataSource {
    func numberOfImagesInGallery(gallery:SwiftPhotoGallery) -> Int
    func imageInGallery(gallery:SwiftPhotoGallery, forIndex index:Int) -> UIImage?
    func placeHolderInGallery(gallery: SwiftPhotoGallery, forIndex index: Int) -> String?
}

@objc public protocol SwiftPhotoGalleryDelegate {
    func galleryDidTapToClose(gallery:SwiftPhotoGallery)
}

    // MARK: ------ SwiftPhotoGallery ------

public class SwiftPhotoGallery: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet public var dataSource: SwiftPhotoGalleryDataSource?
    @IBOutlet public var delegate: SwiftPhotoGalleryDelegate?

    public lazy var imageCollectionView: UICollectionView = self.setupCollectionView()
    
    public var numberOfImages: Int {
        return collectionView(imageCollectionView, numberOfItemsInSection: 0)
    }

    public var backgroundColor: UIColor {
        get {
            return view.backgroundColor!
        }
        
        set(newBackgroundColor) {
            view.backgroundColor = newBackgroundColor
        }
    }

    public var currentPage: Int {
        set(page) {
            if page < numberOfImages {
                scrollToImage(page, animated: false)
            } else {
                scrollToImage(numberOfImages - 1, animated: false)
            }
            scrollViewDidEndDecelerating(imageCollectionView)
        }
        get {
            return Int((imageCollectionView.contentOffset.x / imageCollectionView.contentSize.width) * CGFloat(numberOfImages))
        }
    }

    private var pageBeforeRotation: Int = 0
    private var currentIndexPath: NSIndexPath = NSIndexPath(forItem: 0, inSection: 0)
    private var pageControl:UIPageControl!
    private var flowLayout:UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    
    private var pageControlBottomConstraint: NSLayoutConstraint?
    private var pageControlCenterXConstraint: NSLayoutConstraint?
    private let showPageControl: Bool

    
    // MARK: Public Interface
    
    public init(delegate: SwiftPhotoGalleryDelegate, dataSource: SwiftPhotoGalleryDataSource, showPageControl: Bool) {
        self.showPageControl = showPageControl
        super.init(nibName: nil, bundle: nil)

        self.dataSource = dataSource
        self.delegate = delegate
    }

    required public init?(coder aDecoder: NSCoder) {
        self.showPageControl = true
        super.init(coder: aDecoder)
    }

    public func reload(imageIndexes:Int...) {

        if imageIndexes.isEmpty {

            imageCollectionView.reloadData()

        } else {

            let indexPaths: [NSIndexPath] = imageIndexes.map({NSIndexPath(forItem: $0, inSection: 0)})

            imageCollectionView.reloadItemsAtIndexPaths(indexPaths)
        }
    }
    

    // MARK: Lifecycle methods

    override public func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        pageBeforeRotation = currentPage

        flowLayout.itemSize = view.bounds.size
    }

    override public func viewDidLayoutSubviews() {
        let desiredIndexPath = NSIndexPath(forItem: pageBeforeRotation, inSection: 0)

        if pageBeforeRotation > 0 {
            scrollToImage(pageBeforeRotation, animated: false)
        }

        imageCollectionView.reloadItemsAtIndexPaths([desiredIndexPath])

        if let currentCell = imageCollectionView.cellForItemAtIndexPath(desiredIndexPath) as? SwiftPhotoGalleryCell {
            currentCell.configureForNewImage(false)
        }
        
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.blackColor()

        setupPageControl()
        setupGestureRecognizer()
    }

    override public func prefersStatusBarHidden() -> Bool {
        return true
    }

    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


    // MARK: Rotation Handling

    override public func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.AllButUpsideDown
    }

    override public func shouldAutorotate() -> Bool {
        return true
    }


    // MARK: UICollectionViewDataSource Methods
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(imageCollectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource?.numberOfImagesInGallery(self) ?? 0
    }

    public func collectionView(imageCollectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: SwiftPhotoGalleryCell = imageCollectionView.dequeueReusableCellWithReuseIdentifier("SwiftPhotoGalleryCell", forIndexPath: indexPath) as! SwiftPhotoGalleryCell
        
        if let image = getImage(indexPath.row) {
            cell.image = image
        } else {
            cell.placeHoderText = getPlaceHolderText(indexPath.row)
        }

        return cell
    }


    // MARK: UICollectionViewDelegate Methods

    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {

        pageControl.alpha = 1.0
    }

    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {

        // If the scroll animation ended, update the page control to reflect the current page we are on
        pageControl?.currentPage = currentPage

        UIView.animateWithDuration(1.0, delay: 2.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.pageControl?.alpha = 0.0
        }, completion: nil)
    }


    // MARK: UIGestureRecognizerDelegate Methods

    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer is UITapGestureRecognizer &&
            gestureRecognizer is UITapGestureRecognizer &&
            otherGestureRecognizer.view is SwiftPhotoGalleryCell &&
            gestureRecognizer.view == imageCollectionView
    }


    // MARK: Gesture Handlers

    private func setupGestureRecognizer() {

        let singleTap = UITapGestureRecognizer(target: self, action: "singleTapAction:")
        singleTap.numberOfTapsRequired = 1
        singleTap.delegate = self
        imageCollectionView.addGestureRecognizer(singleTap)
    }

    public func singleTapAction(recognizer: UITapGestureRecognizer) {
        delegate?.galleryDidTapToClose(self)
    }


    // MARK: Private Methods

    private func setupCollectionView() -> UICollectionView {
        // Set up flow layout
        flowLayout.scrollDirection = UICollectionViewScrollDirection.Horizontal
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0

        // Set up collection view
        let result = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        result.translatesAutoresizingMaskIntoConstraints = false
        result.registerClass(SwiftPhotoGalleryCell.self, forCellWithReuseIdentifier: "SwiftPhotoGalleryCell")
        result.dataSource = self
        result.delegate = self
        result.pagingEnabled = true
        result.backgroundColor = UIColor.clearColor()

        // Set up collection view constraints
        var imageCollectionViewConstraints: [NSLayoutConstraint] = []
        imageCollectionViewConstraints.append(NSLayoutConstraint(item: result, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1, constant: 0))
        imageCollectionViewConstraints.append(NSLayoutConstraint(item: result, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1, constant: 0))
        imageCollectionViewConstraints.append(NSLayoutConstraint(item: result, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1, constant: 0))
        imageCollectionViewConstraints.append(NSLayoutConstraint(item: result, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1, constant: 0))

        view.addSubview(result)
        view.addConstraints(imageCollectionViewConstraints)

        result.contentSize = CGSize(width: 1000.0, height: 1.0)
        
        return result
    }

    private func setupPageControl() {

        pageControl = UIPageControl()
        pageControl.translatesAutoresizingMaskIntoConstraints = false

        pageControl.numberOfPages = numberOfImages
        pageControl.currentPage = 0

        let inspiratoBlue: UIColor = UIColor(red: 0.0, green: 0.66, blue: 0.875, alpha: 1.0)
        pageControl.currentPageIndicatorTintColor = inspiratoBlue

        let dimGray: UIColor = UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 0.35)
        pageControl.pageIndicatorTintColor = dimGray

        pageControl.alpha = 1
        pageControl.hidden = !self.showPageControl

        view.addSubview(pageControl)

        pageControlCenterXConstraint = NSLayoutConstraint(item: pageControl,
            attribute: NSLayoutAttribute.CenterX,
            relatedBy: NSLayoutRelation.Equal,
            toItem: view,
            attribute: NSLayoutAttribute.CenterX,
            multiplier: 1.0,
            constant: 0)

        pageControlBottomConstraint = NSLayoutConstraint(item: view,
            attribute: NSLayoutAttribute.Bottom,
            relatedBy: NSLayoutRelation.Equal,
            toItem: pageControl,
            attribute: NSLayoutAttribute.Bottom,
            multiplier: 1.0,
            constant: 15)

        view.addConstraints([pageControlCenterXConstraint!, pageControlBottomConstraint!])

    }
    
    private func scrollToImage(withIndex:Int, animated:Bool = false) {
        imageCollectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: withIndex, inSection: 0), atScrollPosition: .CenteredHorizontally, animated: animated)
    }

    private func getImage(currentPage: Int) -> UIImage? {
        return dataSource?.imageInGallery(self, forIndex: currentPage)
    }
    
    private func getPlaceHolderText(currentPage: Int) -> String? {
        return dataSource?.placeHolderInGallery(self, forIndex: currentPage)
    }

}

