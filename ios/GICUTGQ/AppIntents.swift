import AppIntents
import Foundation

enum GICUTGQTabEnum: String, AppEnum {
    case papers
    case checklist
    case settings

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "GICU-TGQ 模块")
    static var caseDisplayRepresentations: [GICUTGQTabEnum: DisplayRepresentation] = [
        .papers: "文献追踪",
        .checklist: "ICU Checklist",
        .settings: "设置"
    ]

    var appTab: AppTab {
        switch self {
        case .papers: .papers
        case .checklist: .checklist
        case .settings: .settings
        }
    }
}

struct OpenGICUTGQIntent: AppIntent {
    static var title: LocalizedStringResource = "打开 GICU-TGQ 模块"
    static var description = IntentDescription("打开文献追踪、ICU Checklist 或设置页面。")
    static var openAppWhenRun = true

    @Parameter(title: "模块")
    var tab: GICUTGQTabEnum

    @MainActor
    func perform() async throws -> some IntentResult {
        AppIntentRouter.shared.open(tab.appTab)
        return .result()
    }
}

struct ShowNewPapersIntent: AppIntent {
    static var title: LocalizedStringResource = "查看 GICU-TGQ 新文献"
    static var description = IntentDescription("打开文献追踪页面并筛选未读新文献。")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppIntentRouter.shared.open(.papers, onlyNewPapers: true)
        return .result()
    }
}

struct OpenChecklistForTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "打开今日 ICU Checklist"
    static var description = IntentDescription("打开 ICU Checklist 页面，继续录入或导出当天表格。")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppIntentRouter.shared.open(.checklist)
        return .result()
    }
}

struct JournalEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "GICU-TGQ 期刊")
    static var defaultQuery = JournalEntityQuery()

    let id: String
    let name: String
    let category: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(categoryTitle)")
    }

    private var categoryTitle: String {
        category == "lung_transplant" ? "肺移植" : "急危重症"
    }
}

struct JournalEntityQuery: EntityStringQuery {
    func entities(for identifiers: [JournalEntity.ID]) async throws -> [JournalEntity] {
        let all = try await suggestedEntities()
        return all.filter { identifiers.contains($0.id) }
    }

    func entities(matching string: String) async throws -> [JournalEntity] {
        let all = try await suggestedEntities()
        guard !string.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(string) }
    }

    func suggestedEntities() async throws -> [JournalEntity] {
        let journals = try await APIClient.shared.journals()
        return journals.map {
            JournalEntity(id: String($0.id), name: $0.name, category: $0.category)
        }
    }
}

struct ShowPapersForJournalIntent: AppIntent {
    static var title: LocalizedStringResource = "查看指定期刊文献"
    static var description = IntentDescription("从快捷指令选择期刊，并打开 GICU-TGQ 文献追踪。")
    static var openAppWhenRun = true

    @Parameter(title: "期刊")
    var journal: JournalEntity

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        AppIntentRouter.shared.openPapers(journalID: Int(journal.id))
        return .result(dialog: "已打开 \(journal.name)")
    }
}

struct GICUTGQShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .teal

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShowNewPapersIntent(),
            phrases: [
                "查看 \(.applicationName) 新文献",
                "打开 \(.applicationName) 文献更新"
            ],
            shortTitle: "新文献",
            systemImageName: "doc.text.magnifyingglass"
        )
        AppShortcut(
            intent: OpenChecklistForTodayIntent(),
            phrases: [
                "打开 \(.applicationName) 今日 Checklist",
                "录入 \(.applicationName) ICU Checklist"
            ],
            shortTitle: "今日 Checklist",
            systemImageName: "checklist"
        )
        AppShortcut(
            intent: OpenGICUTGQIntent(),
            phrases: [
                "打开 \(.applicationName)"
            ],
            shortTitle: "打开模块",
            systemImageName: "square.grid.2x2"
        )
    }
}
