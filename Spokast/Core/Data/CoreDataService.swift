//
//  CoreDataService.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 25/12/25.
//

import Foundation
import CoreData

final class CoreDataService {
    
    static let shared = CoreDataService()
    private let modelName = "Spokast"
    
    private init() {}
    
    // MARK: - Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("❌ Core Data Store failed to load: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    // MARK: - Context Accessors
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }
    
    // MARK: - Saving
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("❌ Error saving main context: \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
