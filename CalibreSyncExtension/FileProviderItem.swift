//
//  FileProviderItem.swift
//  CalibreSyncExtension
//
//  Created by Sumanth Peddamatham on 12/19/18.
//  Copyright © 2018 Sumanth Peddamatham. All rights reserved.
//

import FileProvider

class FileProviderItem: NSObject, NSFileProviderItem {

    // TODO: implement an initializer to create an item from your extension's backing model
    // TODO: implement the accessors to return the values from your extension's backing model
    
    var itemIdentifier: NSFileProviderItemIdentifier {
        return NSFileProviderItemIdentifier("")
    }
    
    var parentItemIdentifier: NSFileProviderItemIdentifier {
        return NSFileProviderItemIdentifier("")
    }
    
    var capabilities: NSFileProviderItemCapabilities {
        return .allowsAll
    }
    
    var filename: String {
        return ""
    }
    
    var typeIdentifier: String {
        return ""
    }
    
}
