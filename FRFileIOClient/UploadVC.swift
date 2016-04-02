//
//  UploadVC.swift
//  FRFileIOClient
//
//  Created by Do Thi Hong Ha on 4/1/16.
//  Copyright © 2016 Fleuve Rouge. All rights reserved.
//

import UIKit
import Alamofire
import FontAwesome_swift

enum ULFileType {
    case File(file: FBFile)
    case Data(data: NSData, extention: String)
}

class UploadVC: UIViewController {

    @IBOutlet weak var fileLabel: UILabel!
    @IBOutlet weak var uploadBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var timeSC: UISegmentedControl!
    @IBOutlet weak var timeTF: UITextField!
    @IBOutlet weak var progressView: UIProgressView!
    
    @IBOutlet weak var prompt: UIView!
    
    var currentRequest: Request?
    var fileType: ULFileType!
    
    init(fileType: ULFileType) {
        super.init(nibName: "UploadVC", bundle: nil)
        self.fileType = fileType
    }
    convenience init(file: FBFile) {
        self.init(fileType: ULFileType.File(file: file))
    }
    
    convenience init(fileURL: NSURL) {
        self.init(file: FBFile(fileUrl: fileURL))
    }
    
    convenience init(data: NSData, extention: String) {
        self.init(fileType: ULFileType.Data(data: data, extention: extention))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let type = fileType {
            switch type {
            case .File(let file):
                fileLabel.text = "About to upload file: " + file.name
            default:
                fileLabel.text = "About to upload file"
                break
            }

        }
        
        for subview in fileLabel.superview!.subviews {
            if let label = subview as? UILabel {
                label.textColor = ColorTemplate.Text
            }
        }
        timeTF.textColor = ColorTemplate.Text
        timeSC.tintColor = ColorTemplate.MainTint
        progressView.tintColor = ColorTemplate.MainTint
        timeTF.setBorder(ColorTemplate.MainTint)
        timeTF.setCornerRadius(4)
        prompt.setCornerRadius(4)
        
        let uploadTitle = NSMutableAttributedString(string: String.fontAwesomeIconWithName(.Upload), attributes: [NSFontAttributeName: UIFont.fontAwesomeOfSize(16),
            NSForegroundColorAttributeName: ColorTemplate.Blue])
        uploadTitle.appendAttributedString(NSAttributedString(string: "  Upload", attributes: [NSFontAttributeName : UIFont.systemFontOfSize(16), NSForegroundColorAttributeName: ColorTemplate.Blue]))
        uploadBtn.setAttributedTitle(uploadTitle, forState: .Normal)
        
        let cancelTitle = NSMutableAttributedString(string: String.fontAwesomeIconWithName(.TimesCircleO), attributes: [NSFontAttributeName: UIFont.fontAwesomeOfSize(16),
            NSForegroundColorAttributeName: ColorTemplate.Red])
        cancelTitle.appendAttributedString(NSAttributedString(string: "  Cancel", attributes: [NSFontAttributeName : UIFont.systemFontOfSize(16), NSForegroundColorAttributeName: ColorTemplate.Red]))
        cancelBtn.setAttributedTitle(cancelTitle, forState: .Normal)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func didTapUpload(sender: AnyObject) {
        uploadBtn.enabled = false
        var expire = 2
        if let text = timeTF.text,
           let time = Int(text) where time > 0 {
            expire = time
        }
        let expireExt: String
        switch timeSC.selectedSegmentIndex {
        case 1:
            expireExt = "m"
        case 2:
            expireExt = "y"
        default:
            expireExt = "w"
        }
        FRQueue.UserInitiated.execute { 
            APIClient.upload(self.fileType, expireIn: "\(expire)\(expireExt)", progressHandler: {[weak self] (progress) in
                FRQueue.Main.execute(closure: {
                    self?.progressView.setProgress(Float(progress), animated: true)
                })
                },
                requestHandler:  {[weak self] (request) in
                    self?.currentRequest = request
//                    debugPrint(request)

                },
                completion: { [weak self] (result) in
                    FRQueue.Main.execute(closure: { 
                        self?.prompt.hidden = true
                    })
                    var errorMessage : String?
                    switch result {
                    case .Success(let info as [String: String]):
                        if let key = info["key"] {
                            if let type = self?.fileType {
                                switch type {
                                case ULFileType.File(let file):
                                    NSUserDefaults.standardUserDefaults().setObject(key, forKey: LocalKey.FileKey + (file.name ?? ""))
                                default:
                                    break
                                }
                            }
                            
                            FRQueue.Main.execute(closure: {
                                let fileUrl = "https://file.io/" + key
                                var message = "Share the link " + fileUrl + " to your receiver"
                                if let expiry = info["expiry"] {
                                    message = "Your file will be expired in " + expiry + ". " + message
                                }
                                let keyPrompt = UIAlertController(title: "Upload successful", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                                keyPrompt.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: {(_) in
                                    self?.dismiss()
                                }))
                                keyPrompt.addAction(UIAlertAction(title: "Share", style: UIAlertActionStyle.Default, handler: {[weak self] (action) -> Void in
                                    let activityItems = [NSURL(string: fileUrl)!]
                                    let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                                    if let ppc = activityVC.popoverPresentationController {
                                        ppc.sourceView = self?.prompt
                                    }
                                    self?.presentViewController(activityVC, animated: true, completion: {
                                        self?.dismiss()
                                    })
                                    }))
                                keyPrompt.view.setNeedsLayout()
                                self?.presentViewController(keyPrompt, animated: true, completion: nil)
                            })
                        }
                    case .Failure(let error):
                        errorMessage = error?.localizedDescription ?? "Unknown error"
                    default:
                        errorMessage = "Unknown error"
                    }
                    
                    if let errorMessage = errorMessage {
                        FRQueue.Main.execute(closure: { 
                            let alert = UIAlertController(title: "Upload failed", message: errorMessage, preferredStyle: .Alert)
                            alert.addAction(UIAlertAction(title: "Dismiss", style: .Cancel, handler: { (_) in
                                self?.dismiss()
                            }))
                            alert.view.setNeedsLayout()
                            self?.presentViewController(alert, animated: true, completion: nil)
                        })
                    }
            })
            
        }
    
    }

    @IBAction func didTapCancel(sender: AnyObject) {
        currentRequest?.cancel()
        dismiss()
    }
    
    func showInView(parent: UIViewController) {
        parent.definesPresentationContext = true
        modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
        parent.presentViewController(self, animated: true, completion: nil)
    }
    
    func dismiss() {
        if let parent = presentingViewController {
            parent.dismissViewControllerAnimated(true, completion: { 
                parent.definesPresentationContext = false
            })
        }
    }
}
