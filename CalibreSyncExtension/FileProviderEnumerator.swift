//
//  FileProviderEnumerator.swift
//  CalibreSyncExtension
//
//  Created by Sumanth Peddamatham on 12/19/18.
//  Copyright © 2018 Sumanth Peddamatham. All rights reserved.
//

import FileProvider
import FeedKit

class FileProviderEnumerator: NSObject, NSFileProviderEnumerator {
    
    var enumeratedItemIdentifier: NSFileProviderItemIdentifier
    let fileModel = FileProviderBackingModel.shared
    
    init(enumeratedItemIdentifier: NSFileProviderItemIdentifier) {
        self.enumeratedItemIdentifier = enumeratedItemIdentifier
        super.init()
    }

    func invalidate() {
        // TODO: perform invalidation of server connection if necessary
    }

    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        /* TODO:
         - inspect the page to determine whether this is an initial or a follow-up request
         
         If this is an enumerator for a directory, the root container or all directories:
         - perform a server request to fetch directory contents
         If this is an enumerator for the active set:
         - perform a server request to update your local database
         - fetch the active set from your local database
         
         - inform the observer about the items returned by the server (possibly multiple times)
         - inform the observer that you are finished with this page
         */
        
//        if fileModel.files.count != 0 {
//            let booksItems = Array(fileModel.files.values) as [FileProviderItem]
//            // TODO: Enable sorting
//            observer.didEnumerate(booksItems)
//            observer.finishEnumerating(upTo: nil)
//            return
//        }
        
        let feedHost = URL(string: "http://10.0.1.60:8080")!
        var feedURL: URL
        
        if page == NSFileProviderPage.initialPageSortedByDate as NSFileProviderPage {
            print("Initial by date!")
            feedURL = URL(string: "/opds/navcatalog/4f6e6577657374?offset=0", relativeTo: feedHost)!
        }
        else if page == NSFileProviderPage.initialPageSortedByName as NSFileProviderPage {
            print("Initial by name!")
            feedURL = URL(string: "/opds/navcatalog/4f7469746c65?offset=0", relativeTo: feedHost)!
        }
        else {
//            print("Loading feed")
            feedURL = URL(string: String(data: page.rawValue, encoding: .utf8)!, relativeTo: feedHost)!
        }
        
        let parser = FeedParser(URL: feedURL)
        
        // Parse asynchronously, not to block the UI.
        parser.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
            // Do your thing, then back to the Main thread
            guard let feed = result.atomFeed, result.isSuccess else {
                print(result.error)
                return
            }
            
            // This function is throttled to prevent slamming Calibre
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                var booksItems = [FileProviderItem]()
                
                for book in feed.entries! {
                    let bookID = book.id!.components(separatedBy: ":").last!
                    var type: String?
                    var size: Int64?
                    var downloadURL: String?
                    var coverURL: String?
                    var thumbURL: String?
                    
                    downloadURL = nil
                    
                    for link in book.links! {
                        if link.attributes!.rel!.contains("acquisition") {
                            type = link.attributes!.type
                            size = link.attributes!.length
                            downloadURL = link.attributes!.href!
                        }
                        else if link.attributes!.rel!.contains("cover") {
                            coverURL = link.attributes!.href!
                        }
                        else if link.attributes!.rel!.contains("thumbnail") {
                            thumbURL = link.attributes!.href!
                        }
                    }

                    let bookItem = FileProviderItem(itemIdentifier: bookID,
                                                    parentIdentifier: self.enumeratedItemIdentifier.rawValue,
                                                    filename: book.title!,
                                                    typeIdentifier: type ?? "Unsupported Type",
                                                    fileSize: size ?? 0,
                                                    createDate: book.updated!,
                                                    downloadURL: URL(string: downloadURL ?? "/")!,
                                                    coverURL: URL(string: coverURL!)!,
                                                    thumbURL: URL(string: thumbURL!)!,
                                                    host: feedHost)
                
                    booksItems.append(bookItem)
                    self.fileModel.files[bookID] = bookItem
                }
                
                observer.didEnumerate(booksItems)
                
                // Parse out "Next" page link (if it exists)
                for link in feed.links! {
                    if link.attributes!.rel! == "next" {
                        let nextPage = URL(string: link.attributes!.href!, relativeTo: feedHost)!
                        observer.finishEnumerating(upTo: NSFileProviderPage(nextPage.dataRepresentation))
                        return
                    }
                }
                observer.finishEnumerating(upTo: nil)
//                self.fileModel.save()
                print("Loading complete!")
            }
        }
    }
    
    func enumerateChanges(for observer: NSFileProviderChangeObserver, from anchor: NSFileProviderSyncAnchor) {
        /* TODO:
         - query the server for updates since the passed-in sync anchor
         
         If this is an enumerator for the active set:
         - note the changes in your local database
         
         - inform the observer about item deletions and updates (modifications + insertions)
         - inform the observer when you have finished enumerating up to a subsequent sync anchor
         */
    }

}
