import Foundation

struct HistoryStore {
    private let key = "muzip.history"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func load() -> [CompressionRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let records = try? decoder.decode([CompressionRecord].self, from: data) else {
            return []
        }
        return records
    }

    @discardableResult
    func save(record: CompressionRecord) -> [CompressionRecord] {
        var records = load()
        records.insert(record, at: 0)
        records = Array(records.prefix(10))

        if let data = try? encoder.encode(records) {
            UserDefaults.standard.set(data, forKey: key)
        }

        return records
    }
}
