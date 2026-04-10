import Foundation
import SwiftUI
import Combine

class SnippetStore: ObservableObject {
    @Published var snippets: [Snippet] = []

    private let key = "com.pastekey.snippets"

    init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Snippet].self, from: data)
        else {
            snippets = (0..<5).map { i in
                Snippet(name: "Snippet \(i + 1)")
            }
            return
        }
        snippets = decoded
    }

    func save() {
        if let data = try? JSONEncoder().encode(snippets) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func updateSnippet(_ snippet: Snippet) {
        if let idx = snippets.firstIndex(where: { $0.id == snippet.id }) {
            snippets[idx] = snippet
            save()
        }
    }

    @discardableResult
    func addSnippet() -> Snippet {
        let snippet = Snippet(name: "New Snippet")
        snippets.append(snippet)
        save()
        return snippet
    }

    func removeSnippet(id: UUID) {
        snippets.removeAll { $0.id == id }
        save()
    }

    func binding(for id: UUID) -> Binding<Snippet> {
        Binding(
            get: {
                self.snippets.first(where: { $0.id == id }) ?? Snippet()
            },
            set: { newValue in
                if let idx = self.snippets.firstIndex(where: { $0.id == id }) {
                    self.snippets[idx] = newValue
                }
            }
        )
    }
}
