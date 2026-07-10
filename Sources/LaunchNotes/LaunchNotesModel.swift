import Foundation

/// The observable controller an app drives from its root. It computes the pending launch note and records
/// the current version as seen when the note is dismissed — or when a brand-new user is caught up.
///
/// Wiring (see the README):
///   1. On onboarding completion, call `markCaughtUp()` so a brand-new user never sees the changelog.
///   2. Attach `.launchNotes(model)` at the post-onboarding root; it presents the pending note as a sheet.
@MainActor
public final class LaunchNotesModel: ObservableObject {
    /// The note to present now, or `nil`. The `.launchNotes` modifier binds a sheet to this.
    @Published public private(set) var pendingNote: LaunchNote?

    private let notes: [LaunchNote]
    private let currentVersion: String
    private let storage: LaunchNotesStorage

    public init(
        notes: [LaunchNote],
        currentVersion: String = LaunchNotesModel.bundleShortVersion(),
        storage: LaunchNotesStorage = UserDefaultsLaunchNotesStorage()
    ) {
        self.notes = notes
        self.currentVersion = currentVersion
        self.storage = storage
    }

    /// Recompute the pending note. The `.launchNotes` modifier calls this when the main UI appears; call it
    /// yourself if you present manually.
    public func refresh() {
        pendingNote = LaunchNotesEngine.pendingNote(
            current: currentVersion,
            lastSeen: storage.lastSeenVersion(),
            notes: notes
        )
    }

    /// The user saw and dismissed the notes → record this version so they aren't shown again.
    public func acknowledge() {
        recordSeen()
    }

    /// A brand-new user finished onboarding → mark them caught up to the current version so they never see
    /// the changelog. Call this once, on onboarding completion, BEFORE the main UI appears.
    public func markCaughtUp() {
        recordSeen()
    }

    private func recordSeen() {
        storage.setLastSeenVersion(currentVersion)
        pendingNote = nil
    }

    /// Forget the recorded "seen" version so the notes present again on the next `refresh()`/launch — for
    /// previews and debug menus. Does not present anything itself.
    public func resetSeenVersion() {
        storage.clearLastSeenVersion()
        pendingNote = nil
    }

    /// The app's marketing version (`CFBundleShortVersionString`), or "0" if unavailable. `nonisolated`
    /// so it's usable as the `init` default argument (default args evaluate in a nonisolated context).
    public nonisolated static func bundleShortVersion() -> String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "0"
    }
}
