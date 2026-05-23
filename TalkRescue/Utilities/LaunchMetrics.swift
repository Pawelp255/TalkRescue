import Foundation
import os

/// Lightweight timing helpers for cold-start and rescue flow diagnostics.
enum LaunchMetrics {
    private static let logger = Logger(subsystem: "com.pawelp.talkrescue", category: "Metrics")
    private static let processStart = Date()

    static var coldStartTime: Date { processStart }

    static func log(_ label: String, since start: Date) {
        let ms = Int(Date().timeIntervalSince(start) * 1000)
        logger.info("\(label, privacy: .public) durationMs=\(ms, privacy: .public)")
    }

    static func logSinceLaunch(_ label: String) {
        log(label, since: processStart)
    }
}
