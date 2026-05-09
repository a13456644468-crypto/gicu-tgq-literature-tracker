import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var journals: [Journal] = []
    @Published var papers: [Paper] = []
    @Published var checklistItems: [ChecklistItem] = []
    @Published var selectedCategory: JournalCategory = .all
    @Published var selectedJournal: Journal?
    @Published var selectedDate = Date()
    @Published var selectedShift: Shift = .day
    @Published var isLoading = false
    @Published var message: String?

    private let api = APIClient.shared

    func bootstrap() async {
        await loadJournals()
        await loadPapers()
        await loadChecklist()
    }

    func loadJournals() async {
        do {
            journals = try await api.journals(category: selectedCategory)
        } catch {
            message = error.localizedDescription
        }
    }

    func loadPapers(onlyNew: Bool = false) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await api.papers(journalId: selectedJournal?.id, onlyNew: onlyNew)
            papers = response.items
        } catch {
            message = error.localizedDescription
        }
    }

    func markRead(_ paper: Paper) async {
        do {
            _ = try await api.markPaperRead(id: paper.id)
            await loadPapers()
        } catch {
            message = error.localizedDescription
        }
    }

    func loadChecklist() async {
        do {
            checklistItems = try await api.checklists(date: selectedDate, shift: selectedShift)
        } catch {
            checklistItems = []
            message = error.localizedDescription
        }
    }

    func addEmptyChecklistRow() {
        checklistItems.append(ChecklistItem(checklistDate: selectedDate, shift: selectedShift))
    }

    func saveChecklist() async {
        let validItems = checklistItems.filter {
            !$0.bedNumber.trimmingCharacters(in: .whitespaces).isEmpty &&
            !$0.patientName.trimmingCharacters(in: .whitespaces).isEmpty &&
            !$0.diagnosis.trimmingCharacters(in: .whitespaces).isEmpty
        }
        guard !validItems.isEmpty else {
            message = "请至少填写床号、姓名和诊断"
            return
        }
        do {
            checklistItems = try await api.createChecklistBatch(validItems)
            message = "Checklist 已保存"
        } catch {
            message = error.localizedDescription
        }
    }
}

@MainActor
final class AppIntentRouter: ObservableObject {
    static let shared = AppIntentRouter()

    @Published var selectedTab: AppTab = .papers
    @Published var pendingOnlyNewPapers = false
    @Published var pendingJournalID: Int?

    private init() {}

    func open(_ tab: AppTab, onlyNewPapers: Bool = false) {
        selectedTab = tab
        pendingOnlyNewPapers = onlyNewPapers
    }

    func openPapers(journalID: Int?) {
        selectedTab = .papers
        pendingJournalID = journalID
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case papers
    case checklist
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .papers: "文献"
        case .checklist: "Checklist"
        case .settings: "设置"
        }
    }

    var symbol: String {
        switch self {
        case .papers: "doc.text.magnifyingglass"
        case .checklist: "checklist"
        case .settings: "gearshape"
        }
    }
}
