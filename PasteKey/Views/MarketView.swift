import SwiftUI

struct MarketView: View {
    @EnvironmentObject var market: MarketStore
    @EnvironmentObject var store: PromptStore
    @EnvironmentObject var nav: Navigator
    @State private var category: String?
    @State private var query = ""
    @State private var preview: MarketPrompt?

    private let columns = [GridItem(.adaptive(minimum: 250, maximum: 360), spacing: 14)]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                TextField(L.t("搜索提示词市场", "Search the market", ja: "マーケットを検索"), text: $query).textFieldStyle(.roundedBorder).frame(maxWidth: 320)
                Spacer()
                if let err = market.lastError { Text(err).font(.caption).foregroundStyle(.secondary) }
                Button { Task { await market.refresh() } } label: {
                    if market.isRefreshing { ProgressView().controlSize(.small) } else { Label(L.t("更新", "Refresh", ja: "更新"), systemImage: "arrow.clockwise") }
                }
            }
            .padding(.horizontal, 18).padding(.top, 14)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Chip(title: L.t("全部", "All", ja: "すべて"), icon: "square.grid.2x2", selected: category == nil) { category = nil }
                    ForEach(market.catalog.categories) { c in
                        Chip(title: c.name.value, icon: c.icon, selected: category == c.id) { category = c.id }
                    }
                }.padding(.horizontal, 18).padding(.vertical, 12)
            }
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(market.prompts(in: category, query: query)) { p in
                        MarketCard(prompt: p, category: market.categoryName(p.category), added: store.contains(marketID: p.id),
                                   onAdd: { add(p) }, onPreview: { preview = p })
                    }
                }
                .padding(.horizontal, 18).padding(.bottom, 18)
            }
        }
        .navigationTitle(L.t("提示词市场", "Prompt Market", ja: "プロンプトマーケット"))
        .sheet(item: $preview) { p in
            MarketPreview(prompt: p, category: market.categoryName(p.category), added: store.contains(marketID: p.id), onAdd: { add(p); preview = nil })
        }
    }

    private func add(_ p: MarketPrompt) {
        store.add(from: p, categoryName: market.categoryName(p.category))
    }
}

private struct Chip: View {
    let title: String; let icon: String; let selected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon).font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(selected ? Color.accentColor : Color.primary.opacity(0.06))
                .foregroundStyle(selected ? .white : .primary)
                .clipShape(Capsule())
        }.buttonStyle(.plain)
    }
}

private struct MarketCard: View {
    let prompt: MarketPrompt; let category: String; let added: Bool
    let onAdd: () -> Void; let onPreview: () -> Void
    @State private var hover = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                Spacer()
                if prompt.featured == true { Text(L.t("精选", "Featured", ja: "おすすめ")).font(.caption2.weight(.bold)).foregroundStyle(.orange) }
            }
            Text(prompt.title.value).font(.system(size: 15, weight: .semibold)).lineLimit(2)
            Text(prompt.summary.value).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(3)
            Spacer(minLength: 4)
            HStack {
                ForEach(prompt.tags.value.prefix(3), id: \.self) { t in
                    Text(t).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2).background(Color.primary.opacity(0.06)).clipShape(Capsule())
                }
                Spacer()
                Button(added ? L.t("已添加", "Added", ja: "追加済み") : L.t("添加", "Add", ja: "追加"), action: onAdd).disabled(added).controlSize(.small)
            }
        }
        .padding(14)
        .frame(minHeight: 132, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(hover ? 0.07 : 0.04)))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.06)))
        .onHover { hover = $0 }
        .onTapGesture(perform: onPreview)
    }
}

private struct MarketPreview: View {
    let prompt: MarketPrompt; let category: String; let added: Bool; let onAdd: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(category).font(.caption).foregroundStyle(.secondary)
            Text(prompt.title.value).font(.title2.weight(.semibold))
            Text(prompt.summary.value).foregroundStyle(.secondary)
            ScrollView {
                Text(prompt.body.value).font(.system(size: 13)).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading).padding(12)
            }
            .background(Color.primary.opacity(0.04)).clipShape(RoundedRectangle(cornerRadius: 8))
            HStack {
                Button(L.t("关闭", "Close", ja: "閉じる")) { dismiss() }
                Spacer()
                Button(copied ? L.t("已复制", "Copied", ja: "コピーしました") : L.t("复制", "Copy", ja: "コピー")) { PasteService.copy(prompt.body.value); copied = true }
                Button(added ? L.t("已添加", "Added", ja: "追加済み") : L.t("添加到我的提示词", "Add to My Prompts", ja: "マイプロンプトに追加"), action: onAdd).disabled(added).buttonStyle(.borderedProminent)
            }
        }
        .padding(22).frame(width: 620, height: 520)
    }
}
