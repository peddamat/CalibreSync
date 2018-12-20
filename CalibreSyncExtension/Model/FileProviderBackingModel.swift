//
//  FileProviderBackingModel.swift
//  CalibreSyncExtension
//
//  Created by Sumanth Peddamatham on 12/19/18.
//  Copyright © 2018 Sumanth Peddamatham. All rights reserved.
//

import Foundation
import FileProvider

final class FileProviderBackingModel {
    static let shared = FileProviderBackingModel(files: [String: FileProviderItem]())
    
    var files: [String: FileProviderItem]
    
    private init(files: [String: FileProviderItem]) {
        self.files = files
    }
    
    public func fromIdentifier(_ identifier: NSFileProviderItemIdentifier) -> NSFileProviderItem {
        return files[identifier.rawValue]!
    }
}

