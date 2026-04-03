import Foundation

struct GardenPersistence {
    static func storageKey(month: Int, year: Int) -> String {
        String(format: "garden-%04d-%02d", year, month)
    }

    static func save(tileId: Int, month: Int, year: Int) {
        let key = storageKey(month: month, year: year)
        var data = load(month: month, year: year)
        data[tileId] = Date()
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    static func load(month: Int, year: Int) -> [Int: Date] {
        let key = storageKey(month: month, year: year)
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Int: Date].self, from: data)
        else { return [:] }
        return decoded
    }

    static func plantedTileIds(month: Int, year: Int) -> Set<Int> {
        Set(load(month: month, year: year).keys)
    }
}
