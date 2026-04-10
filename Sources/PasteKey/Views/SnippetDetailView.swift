import SwiftUI
import AppKit

struct SnippetDetailView: View {
    @Binding var snippet: Snippet
    var onCommit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !AccessibilityChecker.isTrusted {
                accessibilityBanner
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header: Name + Toggle
                    HStack(alignment: .center) {
                        TextField("Snippet name", text: $snippet.name)
                            .textFieldStyle(.plain)
                            .font(.title2.weight(.medium))
                            .onSubmit { onCommit() }

                        Spacer()

                        HStack(spacing: 6) {
                            Text(snippet.isEnabled ? "Enabled" : "Disabled")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Toggle("", isOn: $snippet.isEnabled)
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .onChange(of: snippet.isEnabled) { _ in onCommit() }
                        }
                    }

                    Divider()

                    // Hotkey
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Label("Hotkey", systemImage: "keyboard")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                            Text("Click the box below, then press a key combination (e.g. \u{2318}\u{21E7}1)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }

                        HStack(spacing: 8) {
                            HotkeyRecorderView(keyComboData: $snippet.hotkey, onRecord: onCommit)
                                .frame(width: 180, height: 28)

                            if snippet.hotkey != nil {
                                Button {
                                    snippet.hotkey = nil
                                    onCommit()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.borderless)
                                .help("Clear Hotkey")
                            }
                        }
                    }

                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Label("Content", systemImage: "doc.text")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                                Text("This text will be pasted when you press the hotkey")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }

                            Spacer()

                            Button {
                                if let str = NSPasteboard.general.string(forType: .string), !str.isEmpty {
                                    snippet.content = str
                                    onCommit()
                                }
                            } label: {
                                Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.secondary)
                            .help("Paste current clipboard content")
                        }

                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $snippet.content)
                                .font(.system(.body, design: .monospaced))
                                .scrollContentBackground(.hidden)
                                .padding(10)
                                .frame(minHeight: 160)
                                .onChange(of: snippet.content) { _ in onCommit() }

                            if snippet.content.isEmpty {
                                Text("Type the text that will be pasted when you press the hotkey...")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(.tertiary)
                                    .padding(10)
                                    .allowsHitTesting(false)
                            }
                        }
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color(nsColor: .separatorColor))
                        )
                    }

                    Spacer(minLength: 16)

                    // Delete
                    HStack {
                        Spacer()
                        Button(role: .destructive, action: onDelete) {
                            Label("Delete Snippet", systemImage: "trash")
                        }
                    }
                }
                .padding(24)
            }
        }
    }

    private var accessibilityBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("Accessibility permission required for hotkeys")
                .font(.callout)
            Spacer()
            Button("Grant Access") {
                AccessibilityChecker.checkAndPrompt()
            }
            .controlSize(.small)
        }
        .padding(12)
        .background(.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
}
