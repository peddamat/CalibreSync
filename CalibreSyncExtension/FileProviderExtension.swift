//
//  FileProviderExtension.swift
//  CalibreSyncExtension
//
//  Created by Sumanth Peddamatham on 12/19/18.
//  Copyright © 2018 Sumanth Peddamatham. All rights reserved.
//

import FileProvider

class FileProviderExtension: NSFileProviderExtension {
    
    var fileManager = FileManager()
    let downloader: Downloader
    
    lazy var fileCoordinator: NSFileCoordinator = {
        let fileCoordinator = NSFileCoordinator()
        fileCoordinator.purposeIdentifier = NSFileProviderManager.default.providerIdentifier
        return fileCoordinator
    }()

    override init() {
        let poo = URLSessionConfiguration.background(withIdentifier: "test")
        poo.sharedContainerIdentifier = "group.io.technologystrategy.CalibreSync"
        
        downloader = Downloader(configuration: poo)

        super.init()
    }
    
    override func item(for identifier: NSFileProviderItemIdentifier) throws -> NSFileProviderItem {
        if identifier == .rootContainer || identifier == .workingSet {
            return FileProviderItem(asRootContainer: identifier.rawValue)
        }
        else {
            let model = FileProviderBackingModel.shared
            return model.fromIdentifier(identifier)
        }
    }
    
    override func urlForItem(withPersistentIdentifier identifier: NSFileProviderItemIdentifier) -> URL? {
        // resolve the given identifier to a file on disk
        guard let item = try? item(for: identifier) else {
            return nil
        }
//        print("urlForItem: " + identifier.rawValue)
        
        // in this implementation, all paths are structured as <base storage directory>/<item identifier>/<item file name>
        let manager = NSFileProviderManager.default
        let perItemDirectory = manager.documentStorageURL.appendingPathComponent(identifier.rawValue, isDirectory: true)
        
        return perItemDirectory.appendingPathComponent(item.filename, isDirectory:false)
    }
    
    override func persistentIdentifierForItem(at url: URL) -> NSFileProviderItemIdentifier? {
        // resolve the given URL to a persistent identifier using a database
        let pathComponents = url.pathComponents
        print("persistentIdentifierForItem: " + url.absoluteString)
        // exploit the fact that the path structure has been defined as
        // <base storage directory>/<item identifier>/<item file name> above
        assert(pathComponents.count > 2)
        
        return NSFileProviderItemIdentifier(pathComponents[pathComponents.count - 2])
    }

    override func providePlaceholder(at url: URL, completionHandler: @escaping (Error?) -> Void) {
        guard let identifier = persistentIdentifierForItem(at: url) else {
            completionHandler(NSFileProviderError(.noSuchItem))
            return
        }
        
        let placeholderURL = NSFileProviderManager.placeholderURL(for: url)
        print("providePlaceholder: " + url.path)

        // TODO: Remove this fileCoordinator if it's not needed (I'm not sure what overhead it has)
        fileCoordinator.coordinate(writingItemAt: placeholderURL, options: [], error: nil, byAccessor: { newURL in
            do {
                let fileProviderItem = try item(for: identifier)
                try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                try NSFileProviderManager.writePlaceholder(at: placeholderURL, withMetadata: fileProviderItem)
                completionHandler(nil)
            } catch let error {
                completionHandler(error)
            }
        })
    }
    
    override func startProvidingItem(at url: URL, completionHandler: @escaping ((_ error: Error?) -> Void)) {
        // Should ensure that the actual file is in the position returned by URLForItemWithIdentifier:, then call the completion handler
        
        guard let identifier = persistentIdentifierForItem(at: url) else {
            completionHandler(NSFileProviderError(.noSuchItem))
            return
        }
        
        do {
            let fileProviderItem = try item(for: identifier) as! FileProviderItem
            let documentsURL = NSFileProviderManager.placeholderURL(for: url)
            let fuckme = documentsURL.deletingLastPathComponent()
            let fileURL = fuckme.appendingPathComponent(fileProviderItem.filename)
            let url2 = URL(string: (fileProviderItem.downloadURL?.path)!, relativeTo: fileProviderItem.hostURL!)!
            
            if FileManager.default.fileExists(atPath: fileURL.path) {
                completionHandler(nil)
                return
            }
//            let poo = URLSessionConfiguration.background(withIdentifier: identifier.rawValue)
//            poo.sharedContainerIdentifier = "group.io.technologystrategy.CalibreSync"
//
//            let downloader = Downloader(configuration: poo)
            downloader.download(url: url2, identifier: identifier) { url in
//                print("Need to move the file now")
                if url != nil {
                    do {
                        print("Moving item: " + url!.path)
                        try FileManager.default.createDirectory(atPath: fileURL.deletingLastPathComponent().path, withIntermediateDirectories: true, attributes: nil)
                        if FileManager.default.fileExists(atPath: fileURL.path) {
                            try! FileManager.default.removeItem(at: fileURL)
                        }
                        try self.fileManager.moveItem(at: url!, to: fileURL)
                        completionHandler(nil)
                    } catch let error {
                        print("An error occurred while moving file to destination url: " + fileURL.path)
                        completionHandler(error)
                    }
                }
            }
        }
        catch let error {
            print("startProvidingItem error! " + error.localizedDescription)
            completionHandler(error)
        }
        //completionHandler(NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
    }
    
    
    override func itemChanged(at url: URL) {
        // Called at some point after the file has changed; the provider may then trigger an upload
        
        /* TODO:
         - mark file at <url> as needing an update in the model
         - if there are existing NSURLSessionTasks uploading this file, cancel them
         - create a fresh background NSURLSessionTask and schedule it to upload the current modifications
         - register the NSURLSessionTask with NSFileProviderManager to provide progress updates
         */
    }
    
    override func stopProvidingItem(at url: URL) {
        // Called after the last claim to the file has been released. At this point, it is safe for the file provider to remove the content file.
        // Care should be taken that the corresponding placeholder file stays behind after the content file has been deleted.
        
        // Called after the last claim to the file has been released. At this point, it is safe for the file provider to remove the content file.
        
        // TODO: look up whether the file has local changes
        let fileHasLocalChanges = false
        
        if !fileHasLocalChanges {
            // remove the existing file to free up space
            do {
                _ = try FileManager.default.removeItem(at: url)
            } catch {
                // Handle error
            }
            
            // write out a placeholder to facilitate future property lookups
            self.providePlaceholder(at: url, completionHandler: { error in
                // TODO: handle any error, do any necessary cleanup
            })
        }
    }
    
    // MARK: - Actions
    
    /* TODO: implement the actions for items here
     each of the actions follows the same pattern:
     - make a note of the change in the local model
     - schedule a server request as a background task to inform the server of the change
     - call the completion block with the modified item in its post-modification state
     */
    
    // MARK: - Enumeration
    
    override func enumerator(for containerItemIdentifier: NSFileProviderItemIdentifier) throws -> NSFileProviderEnumerator {
        var maybeEnumerator: NSFileProviderEnumerator?
        if (containerItemIdentifier == NSFileProviderItemIdentifier.rootContainer) {
            // TODO: instantiate an enumerator for the container root
            maybeEnumerator = FileProviderEnumerator(enumeratedItemIdentifier: containerItemIdentifier)
        } else if (containerItemIdentifier == NSFileProviderItemIdentifier.workingSet) {
            // TODO: instantiate an enumerator for the working set
            maybeEnumerator = FileProviderEnumerator(enumeratedItemIdentifier: containerItemIdentifier)
        } else {
            // TODO: determine if the item is a directory or a file
            // - for a directory, instantiate an enumerator of its subitems
            // - for a file, instantiate an enumerator that observes changes to the file
            maybeEnumerator = FileProviderEnumerator(enumeratedItemIdentifier: containerItemIdentifier)
        }
        guard let enumerator = maybeEnumerator else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:])
        }
        return enumerator
    }
    
    override func fetchThumbnails(for itemIdentifiers: [NSFileProviderItemIdentifier], requestedSize size: CGSize, perThumbnailCompletionHandler: @escaping (NSFileProviderItemIdentifier, Data?, Error?) -> Void, completionHandler: @escaping (Error?) -> Void) -> Progress {
        
        let urlSession = URLSession(configuration: URLSessionConfiguration.default)
        let progress = Progress(totalUnitCount: Int64(itemIdentifiers.count))
        print("FileProviderExtension: fetchThumbnails")
        for identifier in itemIdentifiers {
            
            if identifier.rawValue == "" {
                continue
            }
            // resolve the given identifier to a file on disk
            guard let bookItem = try? item(for: identifier) as! FileProviderItem else {
                return progress
            }
            
            // Create a request for the thumbnail from your server.
            let request = bookItem.hostURL?.appendingPathComponent((bookItem.thumbURL?.path)!)
            
            // Download the thumbnail to disk
            // For simplicity, this sample downloads each thumbnail separately;
            // however, if possible, you should batch download all the thumbnails at once.
            let downloadTask = urlSession.downloadTask(with: request!, completionHandler: { (tempURL, response, error) in
                
                guard progress.isCancelled != true else {
                    return
                }
                
                var myErrorOrNil = error
                var mappedDataOrNil: Data? = nil
                
                // If the download succeeds, map a data object to the file
                if let fileURL = tempURL  {
                    do {
                        mappedDataOrNil = try Data(contentsOf:fileURL, options: Data.ReadingOptions.alwaysMapped)
                    }
                    catch let mappingError {
                        myErrorOrNil = mappingError
                    }
                }
                
                // Call the per thumbnail completion handler for each thumbnail requested.
                perThumbnailCompletionHandler(identifier, mappedDataOrNil, myErrorOrNil)
                
                DispatchQueue.main.async {
                    
                    if progress.isFinished {
                        
                        // Call this completion handler once all thumbnails are complete
                        completionHandler(nil)
                    }
                }
            })
            
            // Add the download task's progress as a child to the overall progress.
            progress.addChild(downloadTask.progress, withPendingUnitCount: 1)
            
            // Start the download task.
            downloadTask.resume()
        }
        
        return progress
    }
}
