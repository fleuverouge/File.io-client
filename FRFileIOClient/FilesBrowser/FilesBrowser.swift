//
//  FilesBrowser.swift
//  FRFileIOClient
//
//  Created by Do Thi Hong Ha on 3/31/16.
//  Copyright © 2016 Fleuve Rouge. All rights reserved.
//

import UIKit
import FontAwesome_swift

enum FBAction {
    case Browse
    case SelectFileToUpload
}

enum FBViewOption {
    case Grid
    case List
    
    var cellIdentifier: String {
        get {
            switch self {
            case .Grid:
                return "FileCellGrid"
            case .List:
                return "FileCellList"
            }
        }
    }
    
    var title: String {
        get {
            let awesome : FontAwesome
            switch self {
            case .Grid:
                awesome = .Th
            case .List:
                awesome = .ThList
            }
            return String.fontAwesomeIconWithName(awesome)
        }
    }
}

enum FBFileType {
    case Image
    case Video
    case Audio
    case Archive
    case Text
    case Code
    case Excel
    case Pdf
    case Words
    case PowerPoint
    case Folder
    case Other
    
    static func typeFromExtention(extention: String?) -> FBFileType {
        if extention == nil {
            return .Other
        }
        switch extention!.lowercaseString {
        case "":
            return .Folder
        case "png", "jpg", "jpeg", "tiff", "bmp":
            return .Image
        case "mov", "av", "mp4", "mpeg", "mpg", "mpg4", "3gp", "3g2":
            return .Video
        case "mp3", "m4a", "caf", "caff":
            return .Audio
        case "txt", ".rtf", "wav":
            return .Text
        case "xml", "html", "js", "php", "php3", "php4",
             "c", "cpp", "cp", "c++", "h", "m", "mm", "cs",
             "rb", "sh", "pl", "py", "applescript",
             "java", "jav", "class":
            return .Code
        case "gtar", "tar", "gz", "gzip", "tgz", "zip", "rar":
            return .Archive
        case "doc", "docx":
            return .Words
        case "xls", "xlsx":
            return .Excel
        case "ppt", "pptx":
            return .PowerPoint
        case "pdf":
            return .Pdf
        default:
            return .Other
        }
    }
    
    func icon(color: UIColor, size: CGSize) -> UIImage {
        var text : FontAwesome
        switch self {
        case .Image:
            text = .FileImageO
        case .Video:
            text = .FileMovieO
        case .Audio:
            text = .FileAudioO
        case .Archive:
            text = .FileArchiveO
        case .Text:
            text = .FileTextO
        case .Code:
            text = .FileCodeO
        case .Excel: 
            text = .FileExcelO
        case .Pdf: 
            text = .FilePdfO
        case .Words: 
            text = .FileWordO
        case .PowerPoint: 
            text = .FilePowerpointO
        case .Folder:
            text = .FolderO
        default:
            text = .FileO
        }
        return UIImage.fontAwesomeIconWithName(text, textColor: color, size: size)
    }
}

struct FBFile {
    var name: String
    var extention: String? {
        return url.pathExtension
    }
    var type: FBFileType
    var url: NSURL
    var size: UInt64
    var key: String?
    
    init(fileUrl: NSURL) {
        url = fileUrl
        name = url.lastPathComponent ?? ""
        var rsrc: AnyObject?
        do {
            try url.getResourceValue(&rsrc, forKey: NSURLIsDirectoryKey)
            if let isDirectory = rsrc as? NSNumber where isDirectory == true {
                type = .Folder
            }
            else {
                type = FBFileType.typeFromExtention(url.pathExtension)
            }
            let attr: NSDictionary = try NSFileManager.defaultManager().attributesOfItemAtPath(url.path!)
            size = attr.fileSize()
        }
        catch {
            type = FBFileType.typeFromExtention(url.pathExtension)
            size = 0
            print("Generate file from URL: \(url)\n<ERROR> \(error)")
        }
        
        key = NSUserDefaults.standardUserDefaults().stringForKey(LocalKey.FileKey + name)
    }
}


class FilesBrowser: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    var viewOption = FBViewOption.Grid
    var files = [FBFile]()
    var imageSize = CGSizeZero
    var cellReuseIdentifier = FBViewOption.Grid.cellIdentifier
    var action = FBAction.Browse
    @IBOutlet weak var collectionView: UICollectionView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @IBOutlet weak var emptyView: UIStackView!
//    private let menu = XXXRoundMenuButton()
    
    @IBOutlet weak var menu: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes

        // Do any additional setup after loading the view.
        
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = ColorTemplate.Text
        refreshControl.addTarget(self, action: #selector(FilesBrowser.loadFilesList(_:)), forControlEvents: .ValueChanged)
        collectionView.addSubview(refreshControl)
        collectionView.bounces = true
        collectionView.alwaysBounceVertical = true
        automaticallyAdjustsScrollViewInsets = false
        collectionView.contentInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

        
        let attributes = [NSFontAttributeName: UIFont.fontAwesomeOfSize(22)] as Dictionary!
        let refreshItem = UIBarButtonItem(title: String.fontAwesomeIconWithName(.Refresh), style: .Plain, target: self, action: #selector(FilesBrowser.loadFilesList(_:)))
        refreshItem.setTitleTextAttributes(attributes, forState: .Normal)
        let styleItem = UIBarButtonItem(title: FBViewOption.List.title, style: .Plain, target: self, action: #selector(FilesBrowser.switchViewOption(_:)))
        styleItem.setTitleTextAttributes(attributes, forState: .Normal)
        
//        collectionView.registerNib(UINib(nibName: FBViewOption.Grid.cellXibName, bundle: nil), forCellWithReuseIdentifier: FBViewOption.Grid.cellIdentifier)
//        collectionView.registerNib(UINib(nibName: FBViewOption.List.cellXibName, bundle: nil), forCellWithReuseIdentifier: FBViewOption.List.cellIdentifier)
        
        navigationItem.rightBarButtonItems = [styleItem, refreshItem]
        
        view.backgroundColor = ColorTemplate.MainBackground
        collectionView.backgroundColor = ColorTemplate.MainBackground
        emptyView.backgroundColor = ColorTemplate.MainBackground
        
        for subview in emptyView.subviews {
            if let label = subview as? UILabel {
                label.textColor = ColorTemplate.Text
            }
            else if let iv = subview as? UIImageView {
                iv.image = UIImage.fontAwesomeIconWithName(.Inbox, textColor: ColorTemplate.Text, size: CGSizeMake(UIScreen.width / 4, UIScreen.width / 4))
            }
        }
        
        let items : [FontAwesome] = [FontAwesome.ShareSquareO, FontAwesome.Upload, FontAwesome.Edit, FontAwesome.TrashO, .Hashtag]
        for i in 101...105 {
            if let button = menu.subviewWithTag(i) as? UIButton {
                let item = items[i - 101]
                button.titleLabel?.font = UIFont.fontAwesomeOfSize(20)
                button.setTitle(String.fontAwesomeIconWithName(item), forState: .Normal)
                button.setCornerRadius(22)
                button.backgroundColor = ColorTemplate.MainTint
                button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
                switch item {
                case .ShareSquareO:
                    button.addTarget(self, action: #selector(FilesBrowser.didTapShare), forControlEvents: .TouchUpInside)
                case .Upload:
                    button.addTarget(self, action: #selector(FilesBrowser.didTapUpload), forControlEvents: .TouchUpInside)
                case .Edit:
                    button.addTarget(self, action: #selector(FilesBrowser.didTapRename), forControlEvents: .TouchUpInside)
                case .TrashO:
                    button.addTarget(self, action: #selector(FilesBrowser.didTapDelete), forControlEvents: .TouchUpInside)
                case .Hashtag:
                    button.addTarget(self, action: #selector(FilesBrowser.toggleMenu), forControlEvents: .TouchUpInside)
                default:
                    break
                }
            }
        }
        for i in 101...104 {
            menu.subviewWithTag(i)?.hidden = true
        }
        menu.hidden = true
        updateItemSize()
        loadFilesList(nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource


    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return files.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(viewOption.cellIdentifier, forIndexPath: indexPath) as! FileCell
    
        let file = files[indexPath.item]
        cell.fileNameLabel.text = file.name
        cell.fileImageView.image = FBFileType.Other.icon(cell.fileImageView.tintColor, size: imageSize)
        if (file.type == .Image) {
            if let image = UIImage(contentsOfFile: file.url.path!) {
                cell.fileImageView.image = image
            }
            else {
                cell.fileImageView.image = imageForCell(cell, fileType: .Image)
            }
        }
        else {
            cell.fileImageView.image = imageForCell(cell, fileType: file.type)
        }
        if (file.size < 1000) {
            cell.fileSizeLabel.text = "\(file.size) B"
        }
        else if (file.size < 1000000) {
            cell.fileSizeLabel.text = String.localizedStringWithFormat("%.2f kB", Double(file.size)/1000)
        }
        else if (file.size < 1000000000) {
            cell.fileSizeLabel.text = String.localizedStringWithFormat("%.2f MB", Double(file.size)/1000000)
        }
        else {
            cell.fileSizeLabel.text = String.localizedStringWithFormat("%.2f GB", Double(file.size)/1000000000)
        }
        return cell
    }
    
    func imageForCell(cell: FileCell, fileType: FBFileType) -> UIImage {
        return fileType.icon(cell.fileImageView.tintColor, size: imageSize)
    }

    func imageForCell(cell: FileCell, fileExtension: String?) -> UIImage {
        return imageForCell(cell, fileType: FBFileType.typeFromExtention(fileExtension))
    }
    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if (action == .SelectFileToUpload) {
            performUploadFile(files[indexPath.item])
        }
        else {
            menu.hidden = false
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        if (action == .Browse) {
            if collectionView.visibleCells().count == 0 {
                hideMenu()
                menu.hidden = true
            }
        }
    }
    
    //MARK: -
    func loadFilesList(sender: AnyObject?) {
        defer {
            collectionView.hidden = files.count == 0
            emptyView.hidden = !collectionView.hidden
            
        }
        if let rc = sender as? UIRefreshControl {
            rc.endRefreshing()
        }
        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        
        do {
            
            let directoryContents = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(documentsUrl, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions())
            //            print(files)
            files = [FBFile]()
            for fileURL in directoryContents {
                try fileURL.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)
                files.append(FBFile(fileUrl: fileURL))
            }
            collectionView.reloadData()
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        // if you want to filter the directory contents you can do like this:
        
        
        //        do {
        //            let directoryUrls = try  NSFileManager.defaultManager().contentsOfDirectoryAtURL(documentsUrl, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions())
        //            print(directoryUrls)
        //            let mp3Files = directoryUrls.filter{ $0.pathExtension == "mp3" }.map{ $0.lastPathComponent }
        //            print("MP3 FILES:\n" + mp3Files.description)
        //        } catch let error as NSError {
        //            print(error.localizedDescription)
        //        }
    }
    
    func switchViewOption(sender: UIBarButtonItem) {
        switch viewOption {
        case .Grid:
            viewOption = .List
            sender.title = String.fontAwesomeIconWithName(.Th)
        case .List:
            viewOption = .Grid
            sender.title = String.fontAwesomeIconWithName(.ThList)
        }
        updateItemSize()
        collectionView.reloadData()
    }
    
    func updateItemSize() {
        let cellSize: CGSize
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        switch viewOption {
        case .List:
            let width = UIScreen.width - collectionView.contentInset.left - collectionView.contentInset.right - layout.sectionInset.left - layout.sectionInset.right
            let height = min(120, 90 * UIScreen.scaleFactor)
            cellSize = CGSize(width: round(width), height: round(height))
            let imageHeight = height - 42
            imageSize = CGSize(width: imageHeight, height: imageHeight)
        case .Grid:
            let width = min(150, 130 * UIScreen.scaleFactor)
            let height = width/130 * 180
            cellSize = CGSize(width: round(width), height: round(height))
            let imageWidth = width * 0.7
            imageSize = CGSize(width: imageWidth, height: imageWidth)
        }
        layout.itemSize = cellSize
    }
    
    func performUploadFile(file: FBFile) {
        let uploadVC = UploadVC(file: file)
        uploadVC.showInView(self)
    }
    
    // MARK: - Action
    func didTapUpload() {
        if let indexPath = collectionView.indexPathsForSelectedItems()?.first {
            performUploadFile(files[indexPath.item])
        }
    }
    
    func didTapShare() {
        if let indexPath = collectionView.indexPathsForSelectedItems()?.first {
            let file = files[indexPath.item]
            var activityItems = [AnyObject]()
            if let key = file.key {
                activityItems.append(key)
            }
            var gotData = false
            if (file.type == .Image) {
                if let image = UIImage(contentsOfFile: file.url.path!) {
                    activityItems.append(image)
                    gotData = true
                }
            }
            if (!gotData) {
                if let data = NSData(contentsOfFile: file.url.path!) {
                    activityItems.append(data)
                }
            }
//            let activityItems = [NSURL(string: fileUrl)!]
            let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            if let ppc = activityVC.popoverPresentationController {
                ppc.sourceView = self.menu
            }
            self.presentViewController(activityVC, animated: true, completion: nil)
        }
    }
    
    func didTapRename() {
        if let indexPath = collectionView.indexPathsForSelectedItems()?.first {
            let file = files[indexPath.item]
            var inputTextField: UITextField?
            let namePrompt = UIAlertController(title: "Rename file", message: "Please file name", preferredStyle: UIAlertControllerStyle.Alert)
            namePrompt.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
            namePrompt.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {[weak self] (action) -> Void in
                if let itf = inputTextField,
                    let text = itf.text where text.characters.count != 0 {
                    var newFilename = text
                    if let ext = file.extention {
                        newFilename = text + "." + ext
                    }
                    let newPath = file.url.path!.stringByReplacingOccurrencesOfString(file.name, withString: "").stringByAppendingString(newFilename)

                    do {
                        try  NSFileManager.defaultManager().moveItemAtPath(file.url.path!, toPath: newPath)
                        let urlStr = file.url.absoluteString.stringByReplacingOccurrencesOfString(file.name, withString: "").stringByAppendingString(newFilename)
                        if let url = NSURL(string: urlStr) {
                            self?.files[indexPath.item] = FBFile(fileUrl: url)
                            FRQueue.Main.execute(closure: { 
                                self?.collectionView.reloadItemsAtIndexPaths([indexPath])
                            })
                        }
                        
                    }
                    catch let error as NSError {
                        print("Rename file <ERROR> \(error)")
                        FRQueue.Main.execute(closure: {
                            self?.showError(error.localizedDescription)
                        })
                    }
                }
                }))
            namePrompt.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
                var defaultFilename = file.name
                if let ext = file.extention {
                    defaultFilename = file.name.stringByReplacingOccurrencesOfString("." + ext, withString: "")
                }
                textField.placeholder = defaultFilename
                inputTextField = textField
            })
            namePrompt.view.setNeedsLayout()
            presentViewController(namePrompt, animated: true, completion: nil)
        }
    }
    
    func didTapDelete() {
        if let indexPath = collectionView.indexPathsForSelectedItems()?.first {
            let file = files[indexPath.item]
            let alert = UIAlertController(title: "Delete file", message: "Do you want to delete file \(file.name)?", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { [weak self] (_) in
                if NSFileManager.defaultManager().fileExistsAtPath(file.url.path!) {
                    do {
                        try NSFileManager.defaultManager().removeItemAtPath(file.url.path!)
                        print("Deleted file \(file.url.path!)")
                        if let me = self {
                            try synchronized(me, block: {
                                me.files.removeAtIndex(indexPath.item)
                                FRQueue.Main.execute(closure: {
                                    me.collectionView.deleteItemsAtIndexPaths([indexPath])
                                })
                            })
                        }
                    }
                    catch let error as NSError {
                        print("<ERROR> \(error)")
                        FRQueue.Main.execute(closure: {
                            self?.showError(error.localizedDescription)
                        })
                    }
                }
                }))
            presentViewController(alert, animated: true, completion: nil)
        }

    }
    
    func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    private var isMenuShown = false
    
    func toggleMenu() {
        if (isMenuShown) {
            hideMenu()
        }
        else {
            showMenu()
        }
    }
    
    func hideMenu() {
        if (!isMenuShown) {
            return
        }
        isMenuShown = false
        hideButton(101)
    }
    
    func hideButton(tag: NSNumber) {
//        print("hide button \(tag)")
        let tagInt = tag.integerValue
        if let button = self.menu.viewWithTag(tagInt) {
            UIView.animateWithDuration(0.2, animations: {
                button.hidden = true
            })
        }
        if (tagInt < 104) {
            performSelector(#selector(FilesBrowser.hideButton(_:)), withObject: NSNumber(integer: tagInt+1), afterDelay: 0.1)
        }
    }
    
    func showMenu() {
        if (isMenuShown) {
            return
        }
        isMenuShown = true
        showButton(104)
    }
    
    func showButton(tag: NSNumber) {
//        print("show button \(tag)")
        let tagInt = tag.integerValue
        if let button = self.menu.viewWithTag(tagInt) {
            UIView.animateWithDuration(0.2, animations: {
                button.hidden = false
            })
        }
        if (tagInt > 101) {
            performSelector(#selector(FilesBrowser.showButton(_:)), withObject: NSNumber(integer: tagInt-1), afterDelay: 0.1)
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier.containsString("showImage") {
            return false
        }
        if identifier.containsString("peekImage") {
            if let cell = sender as? FileCell,
                let idxPath = collectionView.indexPathForCell(cell)
            where files[idxPath.item].type == .Image {
                    return true
            }
            return false
        }
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier where identifier.containsString("peekImage"),
            let cell = sender as? FileCell,
            let idxPath = collectionView.indexPathForCell(cell)
            where files[idxPath.item].type == .Image,
            let iv = segue.destinationViewController.view.viewWithTag(101) as? UIImageView{
            iv.image = cell.fileImageView.image
        }
        else {
            super.prepareForSegue(segue, sender: sender)
        }
    }
}
