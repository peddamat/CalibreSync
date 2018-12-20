//
//  FileProviderItem.swift
//  CalibreSyncExtension
//
//  Created by Sumanth Peddamatham on 12/19/18.
//  Copyright © 2018 Sumanth Peddamatham. All rights reserved.
//

import FileProvider

class FileProviderItem: NSObject, NSFileProviderItem, Codable {

    // Required
    let id: String
    let parentID: String
    let name: String
    let type: String
    
    // Optional
    let size: Int64
    let lastUsedDate: Date?
    
    // Internal
    let hostURL: URL?
    let downloadURL: URL?
    let coverURL: URL?
    let thumbURL: URL?
    
    // Initialize as a rootContainer
    init(asRootContainer withID: String) {
        id = withID
        parentID = withID
        name = "Root Folder"
        type = "public.folder"
        size = 0
        lastUsedDate = nil
        self.hostURL = nil
        self.downloadURL = nil
        self.coverURL = nil
        self.thumbURL = nil
        super.init()
    }
    
    init(itemIdentifier: String, parentIdentifier: String,
         filename: String, typeIdentifier: String, fileSize: Int64, createDate: Date, downloadURL: URL, coverURL: URL, thumbURL: URL, host: URL) {
        id = itemIdentifier
        parentID = parentIdentifier
        name = filename
        type = typeIdentifier
        size = fileSize
        lastUsedDate = createDate
        self.hostURL = host
        self.downloadURL = downloadURL
        self.coverURL = coverURL
        self.thumbURL = thumbURL
        super.init()
    }
    
    // Required
    var itemIdentifier: NSFileProviderItemIdentifier {
        return NSFileProviderItemIdentifier.init(self.id)
    }
    
    var parentItemIdentifier: NSFileProviderItemIdentifier {
        return NSFileProviderItemIdentifier.init(self.parentID)
    }
    
    var filename: String {
        // TODO: Add file extension?
        let filext = { (type: String) -> String in
            switch type {
            case "application/epub+zip":
                return ".epub"
            case "application/pdf":
                return ".pdf"
            default:
                return ""
            }
        }
        return name + filext(type)
    }
    
    var typeIdentifier: String {
        switch type {
        case "application/epub+zip":
            return "org.idpf.epub-container"
        case "application/pdf":
            return "com.adobe.pdf"
        default:
            return type
        }
    }
    
    // Optional
    var documentSize: NSNumber? {
        return NSNumber(value: Int(self.size))
    }
    
    var capabilities: NSFileProviderItemCapabilities {
        return .allowsAll
    }
    
    var versionIdentifier: Data? {
        return "2".data(using: .utf8)
    }
    
    var isDownloaded: Bool {
        return false
//        let temp = FileProviderExtension()
//        if FileManager.default.fileExists(atPath: (temp.urlForItem(withPersistentIdentifier:itemIdentifier)?.path)!) {
//            return true
//        }
//        else {
//            return false
//        }
    }
}
