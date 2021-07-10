//
//  CoreDataStackHandler.swift
//  VirtualTourist
//
//  Created by Khalil Kum on 7/4/21.
//

import Foundation
import CoreData

class CoreDataStackHandler {
    // MARK: Properties
    let persistenceContainer: NSPersistentContainer
    var backgroundContext: NSManagedObjectContext!
    
    var viewContext: NSManagedObjectContext {
        return persistenceContainer.viewContext
    }
    
    init(modelName: String) {
        persistenceContainer = NSPersistentContainer(name: modelName)
        backgroundContext = persistenceContainer.newBackgroundContext()
    }
    
    func configureContexts() {
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    func load(completionHandler: (() -> Void)? = nil) {
        persistenceContainer.loadPersistentStores { storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            
            self.autoSaveViewContext()
            self.configureContexts()
            completionHandler?()
        }
    }

    func autoSaveViewContext(interval: TimeInterval = 30) {
        guard interval > 0 else {
            print("Time interval should be greater than zero.")
            return
        }
        
        print("autosaving")
        
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext(interval: interval)
        }
    }
    
}
