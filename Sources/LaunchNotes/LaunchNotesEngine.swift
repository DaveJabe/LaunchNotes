import Foundation

/// The pure decision behind "which launch note, if any, to present now". No I/O, no state — fully
/// deterministic from its inputs, so it is exhaustively unit-tested.
public enum LaunchNotesEngine {
    /// The launch note to present, or `nil`.
    ///
    /// - `lastSeen == nil` (the FIRST launch of a LaunchNotes-aware build): a returning user reaches the
    ///   main UI without re-onboarding, so present the newest note at or below `current`. A brand-new user
    ///   is caught up by `LaunchNotesModel.markCaughtUp()` on onboarding completion — which seeds
    ///   `lastSeen` BEFORE this is evaluated at the post-onboarding root — so they never hit this branch.
    /// - otherwise: present the newest note in `(lastSeen, current]`, or `nil` if there is none.
    ///
    /// Versions compare with `.numeric`, so "1.10" is newer than "1.9". Keep one string format everywhere
    /// (the app's `CFBundleShortVersionString` and each note's `version`).
    public static func pendingNote(current: String, lastSeen: String?, notes: [LaunchNote]) -> LaunchNote? {
        guard let lastSeen else {
            return newestNote(in: notes) { isNote($0, atOrBelow: current) }
        }
        return newestNote(in: notes) { isNote($0, atOrBelow: current) && isNote($0, strictlyAbove: lastSeen) }
    }

    private static func newestNote(in notes: [LaunchNote], where predicate: (LaunchNote) -> Bool) -> LaunchNote? {
        notes.filter(predicate).max { compare($0.version, $1.version) == .orderedAscending }
    }

    private static func isNote(_ note: LaunchNote, atOrBelow version: String) -> Bool {
        compare(note.version, version) != .orderedDescending
    }

    private static func isNote(_ note: LaunchNote, strictlyAbove version: String) -> Bool {
        compare(note.version, version) == .orderedDescending
    }

    static func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        lhs.compare(rhs, options: .numeric)
    }
}
