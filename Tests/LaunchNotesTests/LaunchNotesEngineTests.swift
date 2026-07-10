import Testing
@testable import LaunchNotes

@Suite("LaunchNotesEngine")
struct LaunchNotesEngineTests {
    private let v2 = LaunchNote(version: "2.0", title: "Two", highlights: [Highlight(title: "New home")])
    private let v3 = LaunchNote(version: "3.0", title: "Three", highlights: [])

    @Test("first LaunchNotes build, returning user (no lastSeen) → newest note at/below current")
    func firstBuildReturningUser() {
        #expect(LaunchNotesEngine.pendingNote(current: "2.0", lastSeen: nil, notes: [v2]) == v2)
    }

    @Test("caught-up user (lastSeen == current) → nothing")
    func caughtUpShowsNothing() {
        #expect(LaunchNotesEngine.pendingNote(current: "2.0", lastSeen: "2.0", notes: [v2]) == nil)
    }

    @Test("in-place update (lastSeen < current) → the new version's note")
    func updateShowsNewNote() {
        #expect(LaunchNotesEngine.pendingNote(current: "3.0", lastSeen: "2.0", notes: [v2, v3]) == v3)
    }

    @Test("skipping versions → only the newest applicable note")
    func skippedVersionsShowNewest() {
        #expect(LaunchNotesEngine.pendingNote(current: "3.0", lastSeen: "1.0", notes: [v2, v3]) == v3)
    }

    @Test("a future note above current is not shown")
    func futureNoteHidden() {
        #expect(LaunchNotesEngine.pendingNote(current: "2.0", lastSeen: "1.0", notes: [v2, v3]) == v2)
    }

    @Test("an already-seen note is not re-shown even when current is higher but has no note")
    func alreadySeenNotReshown() {
        #expect(LaunchNotesEngine.pendingNote(current: "2.1", lastSeen: "2.0", notes: [v2]) == nil)
    }

    @Test("numeric version compare: 1.10 is newer than 1.9")
    func numericCompare() {
        let v1_9 = LaunchNote(version: "1.9", title: "", highlights: [])
        let v1_10 = LaunchNote(version: "1.10", title: "", highlights: [])
        #expect(LaunchNotesEngine.pendingNote(current: "1.10", lastSeen: "1.9", notes: [v1_9, v1_10]) == v1_10)
        #expect(LaunchNotesEngine.pendingNote(current: "1.9", lastSeen: "1.10", notes: [v1_9, v1_10]) == nil)
    }

    @Test("no notes at all → nothing")
    func noNotes() {
        #expect(LaunchNotesEngine.pendingNote(current: "2.0", lastSeen: nil, notes: []) == nil)
    }
}

@MainActor
@Suite("LaunchNotesModel")
struct LaunchNotesModelTests {
    /// In-memory storage double so the model's persistence side effects are observable and isolated.
    final class MemoryStorage: LaunchNotesStorage {
        var version: String?
        func lastSeenVersion() -> String? { version }
        func setLastSeenVersion(_ version: String) { self.version = version }
        func clearLastSeenVersion() { version = nil }
    }

    private let v2 = LaunchNote(version: "2.0", title: "Two", highlights: [])

    @Test("refresh surfaces the pending note for a returning user")
    func refreshSurfacesReturningUser() {
        let storage = MemoryStorage()
        let model = LaunchNotesModel(notes: [v2], currentVersion: "2.0", storage: storage)
        model.refresh()
        #expect(model.pendingNote == v2)
    }

    @Test("markCaughtUp seeds the current version and suppresses the note (brand-new user)")
    func markCaughtUpSuppresses() {
        let storage = MemoryStorage()
        let model = LaunchNotesModel(notes: [v2], currentVersion: "2.0", storage: storage)
        model.markCaughtUp()
        #expect(storage.version == "2.0")
        model.refresh()
        #expect(model.pendingNote == nil)
    }

    @Test("acknowledge seeds the current version and clears the note")
    func acknowledgeSeedsAndClears() {
        let storage = MemoryStorage()
        let model = LaunchNotesModel(notes: [v2], currentVersion: "2.0", storage: storage)
        model.refresh()
        #expect(model.pendingNote == v2)
        model.acknowledge()
        #expect(storage.version == "2.0")
        #expect(model.pendingNote == nil)
    }

    @Test("resetSeenVersion forgets the seen version so refresh presents again (debug/preview)")
    func resetSeenVersionRepresents() {
        let storage = MemoryStorage()
        let model = LaunchNotesModel(notes: [v2], currentVersion: "2.0", storage: storage)
        model.markCaughtUp()
        #expect(storage.version == "2.0")
        model.resetSeenVersion()
        #expect(storage.version == nil)
        model.refresh()
        #expect(model.pendingNote == v2)
    }
}
