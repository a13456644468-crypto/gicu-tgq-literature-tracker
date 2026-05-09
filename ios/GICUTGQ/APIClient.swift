import Foundation

enum APIError: Error, LocalizedError {
    case badURL
    case invalidResponse
    case server(Int)

    var errorDescription: String? {
        switch self {
        case .badURL: "服务地址无效"
        case .invalidResponse: "服务器响应无法解析"
        case .server(let code): "服务器错误：\(code)"
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    var baseURL = URL(string: UserDefaults.standard.string(forKey: "apiBaseURL") ?? "http://127.0.0.1:8000")!

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        decoder.dateDecodingStrategy = .custom(Self.decodeDate)
        encoder.dateEncodingStrategy = .custom(Self.encodeDate)
    }

    func saveBaseURL(_ text: String) throws {
        guard let url = URL(string: text), url.scheme != nil else { throw APIError.badURL }
        baseURL = url
        UserDefaults.standard.set(text, forKey: "apiBaseURL")
    }

    func journals(category: JournalCategory? = nil) async throws -> [Journal] {
        var query: [URLQueryItem] = []
        if let category, category != .all {
            query.append(URLQueryItem(name: "category", value: category.rawValue))
        }
        return try await request("/journals", query: query)
    }

    func papers(journalId: Int? = nil, onlyNew: Bool = false, limit: Int = 30, offset: Int = 0) async throws -> PaperListResponse {
        var query = [
            URLQueryItem(name: "only_new", value: String(onlyNew)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        if let journalId {
            query.append(URLQueryItem(name: "journal_id", value: String(journalId)))
        }
        return try await request("/papers", query: query)
    }

    func paper(id: Int) async throws -> Paper {
        try await request("/papers/\(id)")
    }

    func markPaperRead(id: Int) async throws -> Paper {
        try await request("/papers/\(id)/read", method: "POST")
    }

    func checklists(date: Date, shift: Shift) async throws -> [ChecklistItem] {
        try await request(
            "/checklists",
            query: [
                URLQueryItem(name: "checklist_date", value: Self.dayFormatter.string(from: date)),
                URLQueryItem(name: "shift", value: shift.rawValue)
            ]
        )
    }

    func createChecklistBatch(_ items: [ChecklistItem]) async throws -> [ChecklistItem] {
        try await request("/checklists/batch", method: "POST", body: items)
    }

    private func request<T: Decodable, B: Encodable>(_ path: String, query: [URLQueryItem] = [], method: String = "GET", body: B?) async throws -> T {
        var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false)
        components?.queryItems = query.isEmpty ? nil : query
        guard let url = components?.url else { throw APIError.badURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = try encoder.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard 200..<300 ~= http.statusCode else { throw APIError.server(http.statusCode) }
        return try decoder.decode(T.self, from: data)
    }

    private func request<T: Decodable>(_ path: String, query: [URLQueryItem] = [], method: String = "GET") async throws -> T {
        try await request(path, query: query, method: method, body: Optional<EmptyBody>.none)
    }

    private struct EmptyBody: Encodable {}

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static func decodeDate(decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        if let date = isoFormatter.date(from: value) { return date }
        if let date = ISO8601DateFormatter().date(from: value) { return date }
        if let date = serverDateTimeFormatter.date(from: value) { return date }
        if let date = dayFormatter.date(from: value) { return date }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(value)")
    }

    private static let serverDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    private static func encodeDate(date: Date, encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(dayFormatter.string(from: date))
    }
}
