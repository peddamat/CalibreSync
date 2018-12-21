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
    static let shared = FileProviderBackingModel()
    let docsBaseURL: URL
    let customPlistURL: URL

    var files: [String: FileProviderItem]
    
    private init() {
        docsBaseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        customPlistURL = docsBaseURL.appendingPathComponent("feedList.plist")

        if FileManager.default.fileExists(atPath: customPlistURL.path) {
            let decoder = JSONDecoder()
            do {
                let moo = FileManager.default.contents(atPath: customPlistURL.path)
                try self.files = decoder.decode([String: FileProviderItem].self, from:moo!)
            } catch {
                self.files = [String: FileProviderItem]()
            }
//            self.files = NSKeyedUnarchiver.unarchiveObject(withFile: customPlistURL.path) as! [String: FileProviderItem]
        }
        else {
            self.files = [String: FileProviderItem]()
        }
    }
    
    public func fromIdentifier(_ identifier: NSFileProviderItemIdentifier) -> NSFileProviderItem {
        return files[identifier.rawValue]!
    }
    
    public func save() {
        do {
            let encoder = JSONEncoder()
            let encodedBookItem = try encoder.encode(files)
            try encodedBookItem.write(to: customPlistURL)
        }
        catch let error {
            print("Error writing book list: " + error.localizedDescription)
        }
    }
}

