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
                return "GridCell"
            case .List:
                return "ListCell"
            }
        }
    }
    
    var cellXibName: String {
        get {
            switch self {
            case .Grid:
                return "FileCell"
            case .List: 
                return "FileListCell"
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
    var cellReuseIdentifier = "GridCell"
    var action = FBAction.Browse
    @IBOutlet weak var collectionView: UICollectionView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @IBOutlet weak var emptyView: UIStackView!
    
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
        let styleItem = UIBarButtonItem(title: viewOption.title, style: .Plain, target: self, action: #selector(FilesBrowser.switchViewOption(_:)))
        styleItem.setTitleTextAttributes(attributes, forState: .Normal)
        
        collectionView.registerNib(UINib(nibName: FBViewOption.Grid.cellXibName, bundle: nil), forCellWithReuseIdentifier: FBViewOption.Grid.cellIdentifier)
        collectionView.registerNib(UINib(nibName: FBViewOption.List.cellXibName, bundle: nil), forCellWithReuseIdentifier: FBViewOption.List.cellIdentifier)
        
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
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if (action == .SelectFileToUpload) {
            performUploadFile(files[indexPath.item])
        }
    }
    
    func performUploadFile(file: FBFile) {
        let uploadVC = UploadVC(file: file)
        uploadVC.showInView(self)
    }
}
