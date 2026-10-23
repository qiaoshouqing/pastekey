import SwiftUI

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case prompts, market, settings
    var id: String { rawValue }
    var title: String {
        switch self {
        case .prompts: return L.t("我的提示词", "My Prompts")
        case .market: return L.t("提示词市场", "Prompt Market")
        case .settings: return L.t("设置", "Settings")
        }
    }
    var icon: String {
        switch self {
        case .prompts: return "text.quote"
        case .market: return "sparkles"
        case .settings: return "gearshape"
        }
    }
}

@MainActor
final class Navigator: ObservableObject {
    @Published var section: AppSection = .prompts
    @Published var selectedPromptID: UUID?
}

struct MainView: View {
    @EnvironmentObject var nav: Navigator
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: Binding(get: { nav.section }, set: { if let s = $0 { nav.section = s } })) { s in
                Label(s.title, systemImage: s.icon).tag(s)
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 190)
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L.t("在任何 App 里按", "Press anywhere")).font(.caption).foregroundStyle(.secondary)
                    Text(settings.panelHotkey?.display ?? "—").font(.system(.title3, design: .rounded).weight(.semibold))
                    Text(L.t("搜索并粘贴提示词", "to search & paste a prompt")).font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(14)
            }
        } detail: {
            switch nav.section {
            case .prompts: PromptsView()
            case .market: MarketView()
            case .settings: SettingsView()
            }
        }
        .frame(minWidth: 880, minHeight: 560)
    }
}
