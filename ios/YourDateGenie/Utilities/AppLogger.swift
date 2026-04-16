import Foundation
import OSLog

/// Centralised logging that wraps the unified OSLog system.
/// Debug-level messages are stripped from release builds at compile time.
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.yourdategenie.app"
    private static let general = Logger(subsystem: subsystem, category: "general")
    private static let network = Logger(subsystem: subsystem, category: "network")
    private static let auth    = Logger(subsystem: subsystem, category: "auth")
    private static let storage = Logger(subsystem: subsystem, category: "storage")

    // MARK: - Debug (compile-time eliminated in Release builds)

    static func debug(
        _ message: String,
        category: Category = .general,
        file: String = #fileID,
        line: Int = #line
    ) {
        #if DEBUG
        logger(for: category).debug("[\(file):\(line)] \(message)")
        #endif
    }

    // MARK: - Info

    static func info(_ message: String, category: Category = .general) {
        logger(for: category).info("\(message)")
    }

    // MARK: - Error (always logged; no sensitive data should appear here)

    static func error(
        _ message: String,
        category: Category = .general,
        file: String = #fileID,
        line: Int = #line
    ) {
        logger(for: category).error("[\(file):\(line)] \(message)")
    }

    // MARK: -

    enum Category { case general, network, auth, storage }

    private static func logger(for category: Category) -> Logger {
        switch category {
        case .general: return general
        case .network: return network
        case .auth:    return auth
        case .storage: return storage
        }
    }
}
