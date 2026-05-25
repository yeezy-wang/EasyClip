import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ClipboardDataModel")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            if let desc = container.persistentStoreDescriptions.first {
                desc.shouldMigrateStoreAutomatically = true
                desc.shouldInferMappingModelAutomatically = true
            }
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                if !inMemory {
                    self.recreateStore()
                } else {
                    fatalError("Core Data store failed: \(error.localizedDescription)")
                }
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private func recreateStore() {
        guard let url = container.persistentStoreDescriptions.first?.url else { return }
        try? FileManager.default.removeItem(at: url)
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data store failed after recreate: \(error.localizedDescription)")
            }
        }
    }

    func save() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            print("Core Data save failed: \(error.localizedDescription)")
        }
    }

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }
}
