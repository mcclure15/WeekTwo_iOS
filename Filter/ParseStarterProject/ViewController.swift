//
//  ViewController.swift
//
//  Copyright 2011-present Parse Inc. All rights reserved.
//

import UIKit
import Parse

class ViewController: UIViewController {
  

  @IBOutlet weak var equalWidthsConstrait80Percent: NSLayoutConstraint!
  
  let kThumbnailSize = CGSize(width: 100, height: 100)
  
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var collectionViewVerticalSpace: NSLayoutConstraint!
  
  @IBOutlet weak var yConstraintForImageView: NSLayoutConstraint!
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var alertButton: UIButton!
  @IBAction func buttonPressed(sender: UIButton) {
    alert.modalPresentationStyle = UIModalPresentationStyle.Popover
    
    if let popover = alert.popoverPresentationController {
      popover.sourceView = view
      popover.sourceRect = alertButton.frame
    }
    self.presentViewController(alert, animated: true, completion: nil)
    
    
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "ShowGallery" {
      if let galleryViewController = segue.destinationViewController as? GalleryViewController {
        galleryViewController.delegate = self
        galleryViewController.desiredFinalImageSize = imageView.frame.size
      }
    }
  }
  
  func enterFilterMode() {
    collectionViewVerticalSpace.constant = 16
   yConstraintForImageView.constant = 74
    
    UIView.animateWithDuration(0.3, animations: { () -> Void in
      self.view.layoutIfNeeded()
    })
    
    let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: "closeFilterMode")
    navigationItem.rightBarButtonItem = doneButton
  }
  
  func closeFilterMode() {
    collectionViewVerticalSpace.constant = -180
    yConstraintForImageView.constant = 0
    
    UIView.animateWithDuration(0.3, animations: { () -> Void in
      self.view.layoutIfNeeded()
    })
    navigationItem.rightBarButtonItem = nil
  }
  
  let picker: UIImagePickerController = UIImagePickerController()
  
  var filters : [(UIImage, CIContext) -> (UIImage!)] = [FilterService.sepiaFromOriginalImage, FilterService.noirFromOriginalImage, FilterService.chromeFromOriginalImage, FilterService.processFromOriginalImage, FilterService.fadeFromOriginalImage, FilterService.maxComponentFromOriginalImage]
  
  let context = CIContext(options: nil)
  var thumbnail : UIImage!
  
  let alert = UIAlertController(title: "Choose an Action", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
  
  var displayImage : UIImage! {
    didSet {
      imageView.image = displayImage
      thumbnail = ImageResizer.resizeImage(displayImage, size:kThumbnailSize)
      collectionView.reloadData()
      println("did set displayImage")
    }
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    collectionView.dataSource = self
    collectionView.delegate = self
//    var sectionInset = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
    
    let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (alert) -> Void in
      println("alert cancelled")
    }
    
    let choosePhotoAction = UIAlertAction(title: "Choose a Photo", style: UIAlertActionStyle.Default) { (alert) -> Void in
      self.performSegueWithIdentifier("ShowGallery", sender: self)
    }
    
    let takeAPhotoAction = UIAlertAction(title: "Take a Photo", style: UIAlertActionStyle.Default) {
      (alert) -> Void in
      println("point zero")
      self.picker.sourceType = .Camera
      self.picker.allowsEditing = true
      println("point one")
      if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
        self.presentViewController(self.picker, animated: true, completion: nil)
        println("point two")
      }
    }
    
    if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
      let filterAction = UIAlertAction(title: "Filter", style: UIAlertActionStyle.Default) { (alert) -> Void in
        self.enterFilterMode()
      }
      alert.addAction(filterAction)
    }
    
    let uploadAction = UIAlertAction(title: "Upload", style: UIAlertActionStyle.Default) { (alert) -> Void in
      let post = PFObject(className: "Post")
      post["text"] = "friday"
      println("image to upload: \(self.imageView.image?.description)"
      )
      if let image = self.imageView.image,
        data = UIImageJPEGRepresentation(image, 1.0)
      {
        let file = PFFile(name: "post.jpeg", data: data)
        post["image"] = file
      }
      post.saveInBackgroundWithBlock({ (succeeded, error) -> Void in
        
      })
    }
    
    alert.addAction(uploadAction)
    alert.addAction(cancelAction)
    alert.addAction(choosePhotoAction)
    alert.addAction(takeAPhotoAction)

    self.picker.delegate = self
    self.picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary

    displayImage = UIImage(named: "bunny.jpg")
//    imageView.image = displayImage
//
//    let testObject = PFObject(className: "TestObject")
//    testObject["foo"] = "bar"
//    testObject.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
//      println("Object has been saved.")
//    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}



extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
    let image: UIImage = (info[UIImagePickerControllerEditedImage] as? UIImage)!
    displayImage = image 
    self.imageView.image = image
    self.picker.dismissViewControllerAnimated(true, completion: nil)
    
  }
  
  func imagePickerControllerDidCancel(picker: UIImagePickerController) {
    self.picker.dismissViewControllerAnimated(true, completion: nil)
    println("Picker Cancelled")
  }
  
  
}

//MARK: UICollectionViewDataSource
extension ViewController : UICollectionViewDataSource {
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return filters.count
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ThumbnailCell", forIndexPath: indexPath) as! ThumbnailCell
    
    let filter = filters[indexPath.row]
    let filteredImage = filter(thumbnail,context)
    cell.imageView.image = filteredImage
    
    return cell
  }
}

//MARK: UICollectionViewDelegate
extension ViewController : UICollectionViewDelegate {
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath){
    
    let selectedFilter = filters[indexPath.row]

    let newDisplayImage = selectedFilter(displayImage, context)
    self.imageView.image = newDisplayImage

  }
}

//MARK: ImageSelectedDelegate
extension ViewController : ImageSelectedDelegate {
  func controllerDidSelectImage(newImage: UIImage) {
    println(newImage)
    displayImage = newImage
  }
}


