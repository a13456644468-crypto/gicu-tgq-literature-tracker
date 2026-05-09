import SwiftUI

struct PapersView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedPaper: Paper?

    var body: some View {
        NavigationStack {
            List {
                filters
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)

                if appState.papers.isEmpty {
                    EmptyStateView(title: "暂无文献", systemImage: "doc.text.magnifyingglass")
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(appState.papers) { paper in
                        Button {
                            selectedPaper = paper
                        } label: {
                            PaperRow(paper: paper, journalName: journalName(for: paper))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("GICU-TGQ 文献追踪")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await appState.loadPapers() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .refreshable {
                await appState.loadPapers()
            }
            .sheet(item: $selectedPaper) { paper in
                PaperDetailView(paper: paper, journalName: journalName(for: paper))
            }
        }
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("分类", selection: $appState.selectedCategory) {
                ForEach(JournalCategory.allCases) { category in
                    Text(category.title).tag(category)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: appState.selectedCategory) {
                appState.selectedJournal = nil
                Task {
                    await appState.loadJournals()
                    await appState.loadPapers()
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button("全部期刊") {
                        appState.selectedJournal = nil
                        Task { await appState.loadPapers() }
                    }
                    .buttonStyle(FilterButtonStyle(isSelected: appState.selectedJournal == nil))

                    ForEach(appState.journals) { journal in
                        Button(journal.name) {
                            appState.selectedJournal = journal
                            Task { await appState.loadPapers() }
                        }
                        .buttonStyle(FilterButtonStyle(isSelected: appState.selectedJournal?.id == journal.id))
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
    }

    private func journalName(for paper: Paper) -> String {
        guard let id = paper.journalId else { return "未知期刊" }
        return appState.journals.first(where: { $0.id == id })?.name ?? "未知期刊"
    }
}

struct PaperRow: View {
    let paper: Paper
    let journalName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(journalName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.teal)
                Spacer()
                if paper.isNew {
                    Text("NEW")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.red, in: Capsule())
                }
            }

            Text(paper.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(3)

            if let authors = paper.authors, !authors.isEmpty {
                Text(authors)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack {
                Text(paper.pubDate?.gicuDayText ?? "日期未知")
                Spacer()
                Text("PMID \(paper.pmid)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct PaperDetailView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let paper: Paper
    let journalName: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(journalName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.teal)
                    Text(paper.title)
                        .font(.title3.bold())
                    Text(paper.authors ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Divider()
                    Text(paper.abstract?.isEmpty == false ? paper.abstract! : "暂无摘要")
                        .font(.body)
                        .textSelection(.enabled)
                    if let urlText = paper.pubmedURL, let url = URL(string: urlText) {
                        Link("打开 PubMed", destination: url)
                            .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
            .navigationTitle("文献详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("标记已读") {
                        Task {
                            await appState.markRead(paper)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

struct FilterButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(isSelected ? Color.teal : Color(.secondarySystemBackground), in: Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
