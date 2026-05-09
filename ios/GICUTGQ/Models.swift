import Foundation

enum JournalCategory: String, CaseIterable, Identifiable, Codable {
    case all
    case criticalCare = "critical_care"
    case lungTransplant = "lung_transplant"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "全部"
        case .criticalCare: "急危重症"
        case .lungTransplant: "肺移植"
        }
    }
}

enum Shift: String, CaseIterable, Identifiable, Codable {
    case day
    case night

    var id: String { rawValue }
    var title: String { self == .day ? "白班" : "夜班" }
}

struct Journal: Codable, Identifiable, Hashable {
    let id: Int
    let category: String
    let name: String
    let issn: String?
    let pubmedSearchTerm: String?
    let isActive: Bool
    let isBuiltin: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, category, name, issn
        case pubmedSearchTerm = "pubmed_search_term"
        case isActive = "is_active"
        case isBuiltin = "is_builtin"
        case createdAt = "created_at"
    }
}

struct Paper: Codable, Identifiable, Hashable {
    let id: Int
    let journalId: Int?
    let pmid: String
    let title: String
    let authors: String?
    let abstract: String?
    let doi: String?
    let pubDate: Date?
    let pubmedURL: String?
    let isNew: Bool
    let isRead: Bool
    let fetchedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, pmid, title, authors, abstract, doi
        case journalId = "journal_id"
        case pubDate = "pub_date"
        case pubmedURL = "pubmed_url"
        case isNew = "is_new"
        case isRead = "is_read"
        case fetchedAt = "fetched_at"
    }
}

struct PaperListResponse: Codable {
    let total: Int
    let items: [Paper]
}

struct ChecklistItem: Codable, Identifiable, Hashable {
    private var localID = UUID()
    var id: String { serverId.map { "server-\($0)" } ?? "local-\(localID.uuidString)" }
    var serverId: Int?
    var checklistDate: Date
    var shift: Shift
    var bedNumber: String
    var patientName: String
    var diagnosis: String
    var pathogen: String
    var antibiotics: String
    var anticoagulation: String
    var nutrition: String
    var plannedIO: String
    var actualIO: String
    var notes: String

    enum CodingKeys: String, CodingKey {
        case serverId = "id"
        case shift, diagnosis, pathogen, antibiotics, anticoagulation, nutrition, notes
        case checklistDate = "checklist_date"
        case bedNumber = "bed_number"
        case patientName = "patient_name"
        case plannedIO = "planned_io"
        case actualIO = "actual_io"
    }

    init(
        serverId: Int? = nil,
        checklistDate: Date = Date(),
        shift: Shift = .day,
        bedNumber: String = "",
        patientName: String = "",
        diagnosis: String = "",
        pathogen: String = "",
        antibiotics: String = "",
        anticoagulation: String = "",
        nutrition: String = "",
        plannedIO: String = "",
        actualIO: String = "",
        notes: String = ""
    ) {
        self.serverId = serverId
        self.checklistDate = checklistDate
        self.shift = shift
        self.bedNumber = bedNumber
        self.patientName = patientName
        self.diagnosis = diagnosis
        self.pathogen = pathogen
        self.antibiotics = antibiotics
        self.anticoagulation = anticoagulation
        self.nutrition = nutrition
        self.plannedIO = plannedIO
        self.actualIO = actualIO
        self.notes = notes
    }
}
