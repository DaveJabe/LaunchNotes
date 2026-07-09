import Foundation

/// Persists the last app version whose launch notes the user has seen (or been caught up to). Injectable
/// so the engine and model can be unit-tested against an in-memory double.
public protocol LaunchNotesStorage {
    func lastSeenVersion() -> String?
    func setLastSeenVersion(_ version: String)
}

/// The default `UserDefaults`-backed storage. Uses a single string key; override it to isolate the value
/// (e.g. a shared App Group) or to run parallel instances in tests.
public struct UserDefaultsLaunchNotesStorage: LaunchNotesStorage {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "LaunchNotes.lastSeenVersion") {
        self.defaults = defaults
        self.key = key
    }

    public func lastSeenVersion() -> String? { defaults.string(forKey: key) }
    public func setLastSeenVersion(_ version: String) { defaults.set(version, forKey: key) }
}
