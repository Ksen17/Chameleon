//
//  ViewController.swift
//  Chameleon
//
//  Created by Ilia on 13/07/2018.
//  Copyright © 2018 Ilia Stukalov. All rights reserved.
//

import UIKit
import ALCameraViewController
import ZoomImageView
import PDColorPicker
import PKHUD
import PaintBucket

class ViewController: UIViewController {
    
    @IBOutlet weak var imageScrollView: ZoomImageView!
    
    var image: UIImage? {
        didSet {
            imageScrollView.image = self.image
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.imageTapped(recognizer:)))
        self.imageScrollView.addGestureRecognizer(tapGestureRecognizer)
        self.imageScrollView.isUserInteractionEnabled = true
        
    }
    
    @objc func imageTapped(recognizer : UIGestureRecognizer) {
        
        if image == nil {
            openCamera()
        }else{
            let tappedPoint: CGPoint = recognizer.location(in: self.imageScrollView.imageView)
            guard let pointInImage = self.convertTapToImg(tappedPoint) else {
                print("Not in picture")
                return
            }
            print(pointInImage)
            let color = self.image?.getColor(Int(pointInImage.x), Int(pointInImage.y))
            self.openColorEditorForPoint(point: pointInImage, color: color!)
            print("\(color?.description)")
        }
    }
    
    func openColorEditorForPoint(point: CGPoint, color: UIColor) {
        
        let colorPickerVC = PDColorPickerViewController(initialColor: color, tintColor: .black)
        
        colorPickerVC.completion = {
            [weak self] newColor in
            
            
            //self?.undim()
            
            PKHUD.sharedHUD.contentView = PKHUDProgressView()
            PKHUD.sharedHUD.show()
            
            guard let new = newColor else {
                print("The user tapped cancel, no color was selected.")
                PKHUD.sharedHUD.hide()
                self?.imageScrollView.image = self?.image
                return
            }
            
            DispatchQueue.main.async {
                
                self?.image = self?.image!.pbk_imageByReplacingColorAt(Int(point.x), Int(point.y), withColor: new.uiColor, tolerance: 4000, antialias: true)
                
                PKHUD.sharedHUD.hide()
                
            }
            
        }
        
        present(colorPickerVC, animated: true)
    }
    
    
    @IBAction func getPhoto(_ sender: Any) {
        openCamera()
    }
    
    func openCamera(){
        let cameraViewController = CameraViewController { [weak self] image, asset in
            self?.image = image
            self?.dismiss(animated: true, completion: nil)
        }
        
        present(cameraViewController, animated: true, completion: nil)
    }
    
    
    
    @IBAction func sharePhoto(_ sender: Any) {
        if let img = self.image {
            //Create new instance of UIActivityViewController wich is used to share passed UIImage
            let activityViewController : UIActivityViewController = UIActivityViewController(
                activityItems: [img], applicationActivities: nil)
            
            // This lines is for the popover you need to show in iPad
            activityViewController.popoverPresentationController?.sourceView = self.view
            
            // This line remove the arrow of the popover to show in iPad
            activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.any
            activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 150, y: 150, width: 0, height: 0)
            
            //Finally present activityViewController
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    func convertTapToImg(_ point: CGPoint) -> CGPoint? {
        
        let xRatio = self.imageScrollView.imageView.frame.width / (image?.size.width)!
        let yRatio = self.imageScrollView.imageView.frame.height / (image?.size.height)!
        let ratio = min(xRatio, yRatio)
        
        let imgWidth = (image?.size.width)! * ratio
        let imgHeight = (image?.size.height)! * ratio
        
        var tap = point
        var borderWidth: CGFloat = 0
        var borderHeight: CGFloat = 0
        // detect border
        if ratio == yRatio {
            // border is left and right
            borderWidth = (self.imageScrollView.imageView.frame.size.width - imgWidth) / 2
            if point.x < borderWidth || point.x > borderWidth + imgWidth {
                return nil
            }
            tap.x -= borderWidth
        } else {
            // border is top and bottom
            borderHeight = (self.imageScrollView.imageView.frame.size.height - imgHeight) / 2
            if point.y < borderHeight || point.y > borderHeight + imgHeight {
                return nil
            }
            tap.y -= borderHeight
        }
        
        let xScale = tap.x / (self.imageScrollView.imageView.frame.width - 2 * borderWidth)
        let yScale = tap.y / (self.imageScrollView.imageView.frame.height - 2 * borderHeight)
        let pixelX = (image?.size.width)! * xScale
        let pixelY = (image?.size.height)! * yScale
        if pixelY > (image?.size.height)! {
            return nil
        }
        return CGPoint(x: pixelX, y: pixelY)
    }
    
}

