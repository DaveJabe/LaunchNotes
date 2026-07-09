import Foundation

/// One version's launch notes — a titled set of highlights shown once when a returning user updates to
/// that version. `version` is the app's marketing version (`CFBundleShortVersionString`, e.g. "2.0");
/// use the same string format for `version` and the app's bundle version so they compare cleanly.
public struct LaunchNote: Identifiable, Equatable, Codable, Sendable {
    public let version: String
    public let title: String
    public let highlights: [Highlight]

    /// Identity is the version, so a note maps 1:1 to a release.
    public var id: String { version }

    public init(version: String, title: String, highlights: [Highlight]) {
        self.version = version
        self.title = title
        self.highlights = highlights
    }
}

/// A single highlighted change: an optional SF Symbol, a headline, and an optional supporting line.
public struct Highlight: Identifiable, Equatable, Codable, Sendable {
    public let symbolName: String?
    public let title: String
    public let detail: String?

    public var id: String { title }

    public init(symbolName: String? = nil, title: String, detail: String? = nil) {
        self.symbolName = symbolName
        self.title = title
        self.detail = detail
    }
}
