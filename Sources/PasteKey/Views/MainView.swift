import SwiftUI

struct MainView: View {
    @EnvironmentObject var store: SnippetStore
    @State private var selectedID: UUID?

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(spacing: 0) {
                List(selection: $selectedID) {
                    ForEach(store.snippets) { snippet in
                        SnippetRowView(snippet: snippet)
                            .tag(snippet.id)
                    }
                }
                .listStyle(.sidebar)

                Divider()

                HStack(spacing: 6) {
                    Button(action: addSnippet) {
                        Image(systemName: "plus")
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.borderless)
                    .help("Add Snippet")

                    Button(action: removeSnippet) {
                        Image(systemName: "minus")
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.borderless)
                    .disabled(selectedID == nil)
                    .help("Remove Snippet")

                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            }
            .frame(width: 220)
            .background(VisualEffectView(material: .sidebar))

            Divider()

            // Detail
            Group {
                if let id = selectedID,
                   store.snippets.contains(where: { $0.id == id }) {
                    SnippetDetailView(
                        snippet: store.binding(for: id),
                        onCommit: { store.save() },
                        onDelete: { removeSnippet() }
                    )
                } else {
                    emptyState
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 560, minHeight: 400)
        .onAppear {
            if selectedID == nil {
                selectedID = store.snippets.first?.id
            }
        }
        .onChange(of: store.snippets) { snippets in
            if let id = selectedID, !snippets.contains(where: { $0.id == id }) {
                selectedID = snippets.first?.id
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "keyboard")
                .font(.system(size: 44))
                .foregroundStyle(.quaternary)

            VStack(spacing: 6) {
                Text(store.snippets.isEmpty ? "No Snippets" : "Select a Snippet")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(store.snippets.isEmpty
                     ? "Click + to create your first snippet"
                     : "Choose a snippet from the left to edit")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
            }

            Divider().frame(width: 200).padding(.vertical, 4)

            howItWorksView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var howItWorksView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How it works")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                stepRow(icon: "plus.circle", text: "Create a snippet with the + button")
                stepRow(icon: "character.cursor.ibeam", text: "Enter the text you want to quick-paste")
                stepRow(icon: "keyboard", text: "Set a hotkey like \u{2318}\u{21E7}1")
                stepRow(icon: "sparkles", text: "Press the hotkey in any app to paste instantly")
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .frame(width: 300)
    }

    private func stepRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            Text(text)
                .font(.callout)
                .foregroundStyle(.primary.opacity(0.8))
        }
    }

    private func addSnippet() {
        let snippet = store.addSnippet()
        selectedID = snippet.id
    }

    private func removeSnippet() {
        guard let id = selectedID else { return }
        store.removeSnippet(id: id)
        selectedID = store.snippets.first?.id
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .followsWindowActiveState
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
    }
}
