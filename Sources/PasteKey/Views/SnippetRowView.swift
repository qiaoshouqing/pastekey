import SwiftUI

struct SnippetRowView: View {
    let snippet: Snippet

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(snippet.isEnabled ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text(snippet.name.isEmpty ? "Untitled" : snippet.name)
                    .lineLimit(1)

                if !snippet.content.isEmpty {
                    Text(snippet.content)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if let hotkey = snippet.hotkey {
                    Text(hotkey.displayString)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }
        }
        .padding(.vertical, 2)
    }
}
