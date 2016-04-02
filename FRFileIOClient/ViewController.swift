//
//  ViewController.swift
//  FRFileIOClient
//
//  Created by Do Thi Hong Ha on 3/31/16.
//  Copyright © 2016 Fleuve Rouge. All rights reserved.
//

import UIKit
import FontAwesome_swift
import MobileCoreServices

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var mainWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainStack: UIStackView!
    
    private let colors: [Int: UIColor] = [102: UIColor ( red: 0.2039, green: 0.5961, blue: 0.8588, alpha: 1.0 ),
                                         202: UIColor ( red: 0.2039, green: 0.5961, blue: 0.8588, alpha: 1.0 ),
                                         302: UIColor ( red: 0.102, green: 0.7373, blue: 0.6118, alpha: 1.0 ),
                                         402: UIColor ( red: 0.902, green: 0.4941, blue: 0.1333, alpha: 1.0 )]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = ColorTemplate.MainBackground
        
        let fontSize = min(round(UIScreen.scaleFactor * 16), 18)
        for tag in [102, 202, 302, 402] {
            if let label = view.viewWithTag(tag) as? UILabel {
                label.font = UIFont.systemFontOfSize(fontSize);
                label.textColor = colors[tag]
                
            }
            if let iv = view.viewWithTag(tag - 1) as? UIImageView {
                iv.setBorder(colors[tag], width: 2)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        for tag in [101, 201, 301, 401] {
            if let iv = view.viewWithTag(tag) as? UIImageView {
                let imgSize = CGRectInset(iv.frame, 16, 16).size
                if (iv.image == nil || iv.image!.size.height != imgSize.height || iv.image!.size.width != imgSize.width) {
                    switch tag {
                    case 101:
                        iv.image = UIImage.fontAwesomeIconWithName(.FolderO, textColor: colors[tag+1]!, size: imgSize)
                    case 201:
                        iv.image = UIImage.fontAwesomeIconWithName(.Photo, textColor: colors[tag+1]!, size: imgSize)
                    case 301:
                        iv.image = UIImage.fontAwesomeIconWithName(.FolderOpenO, textColor: colors[tag+1]!, size: imgSize)
                    case 401:
                        iv.image = UIImage.fontAwesomeIconWithName(.Download, textColor: colors[tag+1]!, size: imgSize)
                    default: break
                        
                    }
                }
            }
        }
    }
    
    @IBAction func didTapDownload(sender: AnyObject) {
        var inputTextField: UITextField?
        let keyPrompt = UIAlertController(title: "Download", message: "Please enter the file's key", preferredStyle: UIAlertControllerStyle.Alert)
        keyPrompt.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
        keyPrompt.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {[weak self] (action) -> Void in
            if let itf = inputTextField,
                let text = itf.text where text.characters.count != 0 {
                self?.downloadFile(text)
            }
        }))
        keyPrompt.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "Eg: 2ojE41"
            inputTextField = textField
        })
        keyPrompt.view.setNeedsLayout()
        presentViewController(keyPrompt, animated: true, completion: nil)
    }
    
    func downloadFile(key: String) {
        let downloadView = DownloadView.view()
        downloadView.addToView(view)
        FRQueue.UserInitiated.execute {
            APIClient.download(key, fileNameHandler: {[weak downloadView] (fileName) in
                FRQueue.Main.execute(closure: { 
                    if let name = fileName {
                        downloadView?.firstDescLabel.text = "Downloading file \(name)"
                    }
                    else {
                        downloadView?.firstDescLabel.text = "Unable to get the file's name"
                    }
                })
            }, progressHandler: {[weak downloadView] (progress) in
                FRQueue.Main.execute(closure: { 
                    downloadView?.progressView .setProgress(Float(progress), animated: true)
                    downloadView?.secondDescLabel.text = String.localizedStringWithFormat("%.2f downloaded", progress * 100);
                })
                }, completion: {[weak downloadView, weak self] (result) in
                    FRQueue.Main.execute(closure: { 
                        downloadView?.dismiss()
                    })
                    switch result {
                    case .Failure(let error):
                        let message = error?.localizedDescription ?? "Unknown error"
                        FRQueue.Main.execute(closure: { 
                            let alert = UIAlertController(title: "Download failed", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
                             self?.presentViewController(alert, animated: true, completion: nil)
                        })
                    case .Success(_):
                        FRQueue.Main.execute(closure: {
                            if (self?.presentedViewController == nil) {
                                let alert = UIAlertController(title: "Download successful", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
                                alert.addAction(UIAlertAction(title: "Show Documents folder", style: UIAlertActionStyle.Default, handler: {[weak self] (action) -> Void in
                                        self?.showFilesBrowser(nil)
                                    }))
                                alert.view.setNeedsLayout()
                                self?.presentViewController(alert, animated: true, completion: nil)
                            }
                        })
                    }
            })
        }
    }

    //MARK: - Photos picker
    @IBAction func didTapOnPhotos(sender: AnyObject) {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .PhotoLibrary
        imagePicker.delegate = self
        
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        dismissViewControllerAnimated(true, completion: {
            if let url = info[UIImagePickerControllerReferenceURL] as? NSURL,
                let type = info[UIImagePickerControllerMediaType] as? String {
                var ext : String?
                if let comps = NSURLComponents(URL: url, resolvingAgainstBaseURL: false),
                    let items = comps.queryItems {
                    for item in items {
                        if item.name == "ext" {
                            ext = item.value
                            break
                        }
                    }
                }
                var data: NSData?

                if let typeImage = (kUTTypeImage as? NSString) as? String
                    where type == typeImage,
                    let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                    if let lext = ext where lext.lowercaseString.containsString("png") {
                        data = UIImagePNGRepresentation(image)
                    }
                    else {
                        data = UIImageJPEGRepresentation(image, 1.0)
                    }
                }
                else { // It's a video!
                    print("Relative path: \(url.relativePath)")
                    let uploadVC = UploadVC(fileURL: url)
                    uploadVC.showInView(self)
                }
            }
        })
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
//    @IBAction func didTapOnBrowse(sender: AnyObject) {
//        showFilesBrowser()
//    }
    
    //MARK: -
    func showFilesBrowser(sender: AnyObject?) {
        performSegueWithIdentifier("FileBrowser", sender: sender)
//        navigationController?.pushViewController(FilesBrowser(), animated: true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        if let vc = segue.destinationViewController as? FilesBrowser {
            if (segue.identifier == "UploadFromDocuments") {
                vc.action = .SelectFileToUpload
            }
        }
    }
}

