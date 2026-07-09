#if canImport(SwiftUI)
import SwiftUI

/// A clean, system-styled default presentation for a launch note: a title and a vertical list of
/// highlighted changes, with a dismiss button. Apps with their own design system supply a custom view
/// instead via `launchNotes(_:content:)`.
public struct LaunchNotesView: View {
    private let note: LaunchNote
    private let accent: Color
    private let dismissTitle: String
    private let onDismiss: () -> Void

    public init(
        note: LaunchNote,
        accent: Color = .accentColor,
        dismissTitle: String = "Continue",
        onDismiss: @escaping () -> Void
    ) {
        self.note = note
        self.accent = accent
        self.dismissTitle = dismissTitle
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text(note.title)
                        .font(.largeTitle.bold())
                        .padding(.top, 32)

                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(note.highlights) { highlight in
                            HStack(alignment: .top, spacing: 16) {
                                if let symbolName = highlight.symbolName {
                                    Image(systemName: symbolName)
                                        .font(.title2)
                                        .foregroundStyle(accent)
                                        .frame(width: 34, alignment: .center)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(highlight.title)
                                        .font(.headline)
                                    if let detail = highlight.detail {
                                        Text(detail)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }

            Button(action: onDismiss) {
                Text(dismissTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(accent)
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
    }
}

public extension View {
    /// Presents the model's pending launch note as a sheet using the built-in `LaunchNotesView`.
    func launchNotes(_ model: LaunchNotesModel, accent: Color = .accentColor) -> some View {
        modifier(LaunchNotesModifier(model: model) { note, dismiss in
            LaunchNotesView(note: note, accent: accent, onDismiss: dismiss)
        })
    }

    /// Presents the model's pending launch note as a sheet using a custom view — for apps with their own
    /// design system. The closure receives the note and a `dismiss` action to call when done.
    func launchNotes<SheetContent: View>(
        _ model: LaunchNotesModel,
        @ViewBuilder content: @escaping (LaunchNote, @escaping () -> Void) -> SheetContent
    ) -> some View {
        modifier(LaunchNotesModifier(model: model, content: content))
    }
}

private struct LaunchNotesModifier<SheetContent: View>: ViewModifier {
    @ObservedObject var model: LaunchNotesModel
    let content: (LaunchNote, @escaping () -> Void) -> SheetContent

    func body(content base: Content) -> some View {
        base
            .onAppear { model.refresh() }
            .sheet(item: Binding(
                get: { model.pendingNote },
                set: { newValue in if newValue == nil { model.acknowledge() } }
            )) { note in
                self.content(note) { model.acknowledge() }
            }
    }
}
#endif
