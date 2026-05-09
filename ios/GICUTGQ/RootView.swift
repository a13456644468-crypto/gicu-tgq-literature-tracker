import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: AppIntentRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            PapersView()
                .tabItem { Label(AppTab.papers.title, systemImage: AppTab.papers.symbol) }
                .tag(AppTab.papers)

            ChecklistView()
                .tabItem { Label(AppTab.checklist.title, systemImage: AppTab.checklist.symbol) }
                .tag(AppTab.checklist)

            SettingsView()
                .tabItem { Label(AppTab.settings.title, systemImage: AppTab.settings.symbol) }
                .tag(AppTab.settings)
        }
        .tint(.teal)
        .alert("提示", isPresented: Binding(get: { appState.message != nil }, set: { _ in appState.message = nil })) {
            Button("好", role: .cancel) {}
        } message: {
            Text(appState.message ?? "")
        }
        .onChange(of: router.pendingOnlyNewPapers) { _, onlyNew in
            guard onlyNew else { return }
            Task {
                await appState.loadPapers(onlyNew: true)
                router.pendingOnlyNewPapers = false
            }
        }
        .onChange(of: router.pendingJournalID) { _, journalID in
            guard let journalID else { return }
            Task {
                if appState.journals.isEmpty {
                    await appState.loadJournals()
                }
                appState.selectedJournal = appState.journals.first(where: { $0.id == journalID })
                await appState.loadPapers()
                router.pendingJournalID = nil
            }
        }
    }
}
