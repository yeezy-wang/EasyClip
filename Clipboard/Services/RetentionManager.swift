import CoreData
import Combine

final class RetentionManager {
    private let context: NSManagedObjectContext
    private var cleanupTimer: AnyCancellable?

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func start() {
        performCleanup()
        cleanupTimer = Timer.publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.performCleanup()
            }
    }

    func stop() {
        cleanupTimer?.cancel()
        cleanupTimer = nil
    }

    func performCleanup() {
        var retentionDays = UserDefaults.standard.integer(forKey: "retentionDays")
        if retentionDays == 0 {
            retentionDays = 1
        }

        guard let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -retentionDays,
            to: Date()
        ) else { return }

        let fetchRequest: NSFetchRequest<ClipboardItem> = ClipboardItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "isPinned == NO AND timestamp < %@",
            cutoffDate as NSDate
        )

        context.perform { [weak self] in
            guard let self = self else { return }
            do {
                let items = try self.context.fetch(fetchRequest)
                for item in items {
                    self.context.delete(item)
                }
                if !items.isEmpty {
                    try self.context.save()
                }
            } catch {
                print("Retention cleanup failed: \(error.localizedDescription)")
            }
        }
    }
}
