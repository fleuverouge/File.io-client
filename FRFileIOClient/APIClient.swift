//
//  APIClient.swift
//  FRFileIOClient
//
//  Created by Do Thi Hong Ha on 3/31/16.
//  Copyright © 2016 Fleuve Rouge. All rights reserved.
//

import Foundation
import Alamofire

enum RequestResult {
    case Success(AnyObject?)
    case Failure(NSError?)
}

class APIClient: NSObject {
    static let baseHost = "https://file.io"
    
    class func download(fileKey: String, fileNameHandler: ((String?) -> ())? = nil, progressHandler: ((Double) ->())? = nil, completion: ((result: RequestResult) ->())? = nil) -> Request? {
        var correctKey = fileKey
        if (fileKey.containsString(baseHost)) {
            correctKey = fileKey.stringByReplacingOccurrencesOfString(baseHost + "/", withString: "")
        }
        let path = baseHost + "/" + correctKey
        var localPath: NSURL?
        
//        let request = Alamofire.request(.GET, path)
//            .response {(_,response, data, error) in
//                print(response)
//                if let error = error {
//                    completion?(result: .Failure(error))
//                    return
//                }
//                
//                guard let response = response else {
//                    completion?(result: .Failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Response not found"])))
//                    return
//                }
//                
//                print("expectedContentLength: \(response.expectedContentLength)")
//                
//                guard let data = data else {
//                    completion?(result: .Failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Data not found"])))
//                    return
//                }
//                
//                if (response.statusCode != 200) {
//                    do {
//                        let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
//                        if let message = json.valueForKey("message") {
//                            let code = (json.valueForKey("error") as? Int) ?? 0
//                            completion?(result: .Failure(NSError(domain: "file.io", code: code, userInfo: [NSLocalizedDescriptionKey: message])))
//                        }
//                        else {
//                            completion?(result: .Failure(nil))
//                        }
//                    }
//                    catch (let error) {
//                        print("<ERROR> \(error)")
//                        completion?(result: .Failure(nil))
//                        
//                    }
//                    
//                    return
//                }
//                
//                if var pathComponent = response.suggestedFilename {
//                    fileNameHandler?(pathComponent)
//                    let directoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
//                    localPath = directoryURL.URLByAppendingPathComponent(pathComponent)
//                    var fileName = localPath!.URLByDeletingPathExtension?.lastPathComponent
//                    let fileExtention = localPath!.pathExtension
//                    while NSFileManager.defaultManager().fileExistsAtPath(localPath!.path!) {
//                        fileName = fileName! + "_"
//                        pathComponent = fileName! + "." + fileExtention!
//                        localPath = directoryURL.URLByAppendingPathComponent(pathComponent)
//                    }
//                    data.writeToURL(localPath!, atomically: true)
//                    completion?(result: .Success(nil))
//                }
//                else {
//                     completion?(result: .Failure(nil))
//                }
//        }
////        request.progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
//            //            print(totalBytesRead)
////            print("Read: \(bytesRead)")
////            print("Total read: \(bytesRead)")
////            print("Expected to read: \(totalBytesExpectedToRead)")
////            let progress = Double(totalBytesRead) / Double(totalBytesExpectedToRead)
////            print("Progress: \(progress)")
////            if (progress >= 0 && progress <= 1) {
////                progressHandler?(progress)
////            }
//            
////        }
//        request.progress { (_,_,_) in
//            let fraction = request.progress.fractionCompleted
//            print("Fraction completed: \(fraction)")
//            if (fraction >= 0 && fraction <= 1) {
//                progressHandler?(fraction)
//            }
//        }
   
        let destination : (NSURL, NSHTTPURLResponse) -> NSURL = {
            (temporaryURL, response) in
            let directoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
            var pathComponent = response.suggestedFilename
            fileNameHandler?(pathComponent)
            localPath = directoryURL.URLByAppendingPathComponent(pathComponent!)
            var fileName = localPath!.URLByDeletingPathExtension?.lastPathComponent
            let fileExtention = localPath!.pathExtension
            while NSFileManager.defaultManager().fileExistsAtPath(localPath!.path!) {
                fileName = fileName! + "_"
                pathComponent = fileName! + "." + fileExtention!
                localPath = directoryURL.URLByAppendingPathComponent(pathComponent!)
            }
            print("File will be downloaded to \(localPath!.absoluteString)")
            return localPath!
        }
        let request = Alamofire.download(.GET, path, destination: destination)
//            .progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
//                //            print(totalBytesRead)
//                print("Read: \(bytesRead)")
//                print("Total read: \(bytesRead)")
//                print("Expected to read: \(totalBytesExpectedToRead)")
//                let progress = Double(totalBytesRead) / Double(totalBytesExpectedToRead)
//                print("Progress: \(progress)")
//                if (progress >= 0 && progress <= 1) {
//                    progressHandler?(progress)
//                }
//                
//            }
        request.response { (_,response, data, error) in
                print(response)
                var success = false
                defer {
                    if (!success) {
                        if let filePath = localPath?.path
                            where NSFileManager.defaultManager().fileExistsAtPath(filePath) {
                            do {
                                try NSFileManager.defaultManager().removeItemAtPath(filePath)
                                print("Deleted file \(filePath)")
                            }
                            catch let error as NSError {
                                print("<ERROR> \(error)")
                            }
                        }
                    }
                }
                if let error = error {
                    print("<ERROR> \(error)")
                    if (error.domain == Alamofire.Error.Domain && error.code == Alamofire.Error.Code.StatusCodeValidationFailed.rawValue) {
                        if let filePath = localPath?.path
                            where NSFileManager.defaultManager().fileExistsAtPath(filePath),
                            let data = NSData(contentsOfFile: filePath){
                            do {
                                let attStr = try NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType,NSCharacterEncodingDocumentAttribute:NSUTF8StringEncoding], documentAttributes: nil)
                                if let data = attStr.string.dataUsingEncoding(NSUTF8StringEncoding) {
                                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
                                    if let message = json.valueForKey("message") {
                                        let code = (json.valueForKey("error") as? Int) ?? 0
                                        completion?(result: .Failure(NSError(domain: "file.io", code: code, userInfo: [NSLocalizedDescriptionKey: message])))
                                        return
                                    }
                                }
                            }
                            catch (let err) {
                                print("<ERROR> \(err)")
                                completion?(result: .Failure(error))
                                return
                            }
                        }
                    }

                    completion?(result: .Failure(error))
                    return
                }

                if let response = response {
                    if let data = data {
                        if (response.statusCode != 200) {
                            do {
                                let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
                                if let message = json.valueForKey("message") {
                                    let code = (json.valueForKey("error") as? Int) ?? 0
                                    completion?(result: .Failure(NSError(domain: "file.io", code: code, userInfo: [NSLocalizedDescriptionKey: message])))
                                }
                                else {
                                    completion?(result: .Failure(nil))
                                }
                            }
                            catch (let error) {
                                print("<ERROR> \(error)")
                                completion?(result: .Failure(nil))
                                
                            }
                        }
                        else {
                            success = true
                        }
                    }
                    else {
                        completion?(result: .Failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Data not found"])))
                    }
                }
                else {
                    completion?(result: .Failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Response not found"])))
                }

            }
        request.progress { (_,_,_) in
            let fraction = request.progress.fractionCompleted
            print("Fraction completed: \(fraction)")
            if (fraction >= 0 && fraction <= 1) {
                progressHandler?(fraction)
            }
        }
        request.validate(statusCode: [200])
        debugPrint(request)
        return request
    }
    
    class func upload(fileURL: NSURL, name: String? = nil, extention: String? = nil, expireIn: String, progressHandler: ((Double) ->())? = nil, requestHandler: (Request?)->(), completion: ((result: RequestResult) ->())? = nil) {
        guard let data = NSData(contentsOfFile: fileURL.path!) else {
            completion?(result: .Failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid file data"])))
            return
        }
        upload(name ?? fileURL.lastPathComponent, data: data, extention: extention ?? fileURL.pathExtension, expireIn: expireIn, progressHandler: progressHandler, requestHandler: requestHandler, completion: completion)
    }
    
    class func upload(file: FBFile, expireIn: String, progressHandler: ((Double) ->())? = nil, requestHandler: (Request?)->(), completion: ((result: RequestResult) ->())? = nil) {
        upload(file.url, name: file.name, extention: file.extention, expireIn: expireIn, progressHandler: progressHandler, requestHandler: requestHandler, completion: completion)

    }
    
    class func upload(fileType: ULFileType, expireIn: String, progressHandler: ((Double) ->())? = nil, requestHandler: (Request?)->(), completion: ((result: RequestResult) ->())? = nil) {
        switch fileType {
        case .File(let file):
            upload(file.url, name: file.name, extention: file.extention, expireIn: expireIn, progressHandler: progressHandler, requestHandler: requestHandler, completion: completion)
        case .Data(let data, let ext):
            upload(nil, data: data, extention: ext, expireIn: expireIn, progressHandler: progressHandler, requestHandler: requestHandler, completion: completion)
        }
    }
    
    class func upload(fileName: String?, data:NSData, extention: String? = nil, expireIn: String, progressHandler: ((Double) ->())? = nil, requestHandler: (Request?)->(), completion: ((result: RequestResult) ->())? = nil) {
        var name = fileName
        if name == nil {
            let noname = "noname"
            if let ext = extention {
                name = noname + "." + ext
            }
            else {
                name = noname
            }
        }
        
        let path = baseHost + "/" + "?expires=" + expireIn
        
        Alamofire.upload(.POST, path, multipartFormData: { (multipartFormData) in
            multipartFormData.appendBodyPart(
                data: data,
                name: "file",
                fileName: name!,
                mimeType: APIClient.mimeTypes(extention)
            )
            },
             encodingCompletion: { (encodingResult) in
                switch encodingResult {
                case .Success(let upload, _, _):
                    let req = upload.responseJSON { JSON in
                        print("JSON: \(JSON)")
                        switch JSON.result {
                        case .Success(let value):
                            if let success = value.valueForKey("success") as? Bool {
                                if (success) {
                                    let info: [String:String] = ["key": (value.valueForKey("key") as? String) ?? "", "expiry": (value.valueForKey("expiry") as? String) ?? ""]
                                    completion?(result: .Success(info))
                                }
                                else if let message = value.valueForKey("message") {
                                    let code = (value.valueForKey("error") as? Int) ?? 0
                                    completion?(result: .Failure(NSError(domain: "file.io", code: code, userInfo: [NSLocalizedDescriptionKey: message])))
                                }
                                else {
                                    completion?(result: .Failure(nil))
                                }
                            }
                            else {
                                completion?(result: .Failure(nil))
                            }
                        case .Failure(let error):
                            completion?(result: .Failure(error))
                        }
                        
                        }
                        .progress { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite ) in
                            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                            print("Progress: \(progress)")
                            progressHandler?(progress)
                    }
                    requestHandler(req)
                case .Failure(let encodingError):
                    print(encodingError)
                }
        })

//        Alamofire.upload(.POST, path, multipartFormData: { (multipartFormData) in
//            multipartFormData.appendBodyPart(
//                data: data,
//                name: "file",
//                fileName: name ?? fileURL.lastPathComponent ?? "noname",
//                mimeType: APIClient.mimeTypes(extention ?? fileURL.pathExtension)
//            )
//            },
//             encodingCompletion: { (encodingResult) in
//                switch encodingResult {
//                case .Success(let upload, _, _):
//                    let req = upload.responseJSON { JSON in
//                        print("JSON: \(JSON)")
//                        switch JSON.result {
//                        case .Success(let value):
//                            if let success = value.valueForKey("success") as? Bool {
//                                if (success) {
//                                    let info: [String:String] = ["key": (value.valueForKey("key") as? String) ?? "", "expiry": (value.valueForKey("expiry") as? String) ?? ""]
//                                    completion?(result: .Success(info))
//                                }
//                                else if let message = value.valueForKey("message") {
//                                    let code = (value.valueForKey("error") as? Int) ?? 0
//                                    completion?(result: .Failure(NSError(domain: "file.io", code: code, userInfo: [NSLocalizedDescriptionKey: message])))
//                                }
//                                else {
//                                    completion?(result: .Failure(nil))
//                                }
//                            }
//                            else {
//                                completion?(result: .Failure(nil))
//                            }
//                        case .Failure(let error):
//                            completion?(result: .Failure(error))
//                        }
//                        
//                        }
//                        .progress { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite ) in
//                            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
//                            print("Progress: \(progress)")
//                            progressHandler?(progress)
//                    }
//                    requestHandler(req)
//                case .Failure(let encodingError):
//                    print(encodingError)
//                }
//        })

    }
    
    class func mimeTypes(extention: String?) -> String {
        let mimeTypes = [
            "html": "text/html",
            "htm": "text/html",
            "shtml": "text/html",
            "css": "text/css",
            "xml": "text/xml",
            "gif": "image/gif",
            "jpeg": "image/jpeg",
            "jpg": "image/jpeg",
            "js": "application/javascript",
            "atom": "application/atom+xml",
            "rss": "application/rss+xml",
            "mml": "text/mathml",
            "txt": "text/plain",
            "jad": "text/vnd.sun.j2me.app-descriptor",
            "wml": "text/vnd.wap.wml",
            "htc": "text/x-component",
            "png": "image/png",
            "tif": "image/tiff",
            "tiff": "image/tiff",
            "wbmp": "image/vnd.wap.wbmp",
            "ico": "image/x-icon",
            "jng": "image/x-jng",
            "bmp": "image/x-ms-bmp",
            "svg": "image/svg+xml",
            "svgz": "image/svg+xml",
            "webp": "image/webp",
            "woff": "application/font-woff",
            "jar": "application/java-archive",
            "war": "application/java-archive",
            "ear": "application/java-archive",
            "json": "application/json",
            "hqx": "application/mac-binhex40",
            "doc": "application/msword",
            "pdf": "application/pdf",
            "ps": "application/postscript",
            "eps": "application/postscript",
            "ai": "application/postscript",
            "rtf": "application/rtf",
            "m3u8": "application/vnd.apple.mpegurl",
            "xls": "application/vnd.ms-excel",
            "eot": "application/vnd.ms-fontobject",
            "ppt": "application/vnd.ms-powerpoint",
            "wmlc": "application/vnd.wap.wmlc",
            "kml": "application/vnd.google-earth.kml+xml",
            "kmz": "application/vnd.google-earth.kmz",
            "7z": "application/x-7z-compressed",
            "cco": "application/x-cocoa",
            "jardiff": "application/x-java-archive-diff",
            "jnlp": "application/x-java-jnlp-file",
            "run": "application/x-makeself",
            "pl": "application/x-perl",
            "pm": "application/x-perl",
            "prc": "application/x-pilot",
            "pdb": "application/x-pilot",
            "rar": "application/x-rar-compressed",
            "rpm": "application/x-redhat-package-manager",
            "sea": "application/x-sea",
            "swf": "application/x-shockwave-flash",
            "sit": "application/x-stuffit",
            "tcl": "application/x-tcl",
            "tk": "application/x-tcl",
            "der": "application/x-x509-ca-cert",
            "pem": "application/x-x509-ca-cert",
            "crt": "application/x-x509-ca-cert",
            "xpi": "application/x-xpinstall",
            "xhtml": "application/xhtml+xml",
            "xspf": "application/xspf+xml",
            "zip": "application/zip",
            "bin": "application/octet-stream",
            "exe": "application/octet-stream",
            "dll": "application/octet-stream",
            "deb": "application/octet-stream",
            "dmg": "application/octet-stream",
            "iso": "application/octet-stream",
            "img": "application/octet-stream",
            "msi": "application/octet-stream",
            "msp": "application/octet-stream",
            "msm": "application/octet-stream",
            "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
            "mid": "audio/midi",
            "midi": "audio/midi",
            "kar": "audio/midi",
            "mp3": "audio/mpeg",
            "ogg": "audio/ogg",
            "m4a": "audio/x-m4a",
            "ra": "audio/x-realaudio",
            "3gpp": "video/3gpp",
            "3gp": "video/3gpp",
            "ts": "video/mp2t",
            "mp4": "video/mp4",
            "mpeg": "video/mpeg",
            "mpg": "video/mpeg",
            "mov": "video/quicktime",
            "webm": "video/webm",
            "flv": "video/x-flv",
            "m4v": "video/x-m4v",
            "mng": "video/x-mng",
            "asx": "video/x-ms-asf",
            "asf": "video/x-ms-asf",
            "wmv": "video/x-ms-wmv",
            "avi": "video/x-msvideo"
        ]
        
        if let ext = extention,
            let mt = mimeTypes[ext.lowercaseString] {
            return mt
        }
        return "application/octet-stream"
    }
}
