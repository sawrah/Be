import Foundation

struct BreathingStats {
    static let sessionsKey = "completed_sessions"
    
    /// Records a completed breathing session.
    static func recordSession() {
        var sessions = getAllLoggedSessions()
        sessions.append(Date())
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    /// Retrieves all explicitly logged sessions.
    static func getAllLoggedSessions() -> [Date] {
        guard let data = UserDefaults.standard.data(forKey: sessionsKey),
              let decoded = try? JSONDecoder().decode([Date].self, from: data)
        else { return [] }
        return decoded
    }
    
    /// Returns the total number of flowers planted across all months.
    static func totalFlowersPlanted() -> Int {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        var count = 0
        for key in allKeys where key.hasPrefix("garden-") {
            if let data = UserDefaults.standard.data(forKey: key),
               let decoded = try? JSONDecoder().decode([Int: Date].self, from: data) {
                count += decoded.count
            }
        }
        return count
    }
    
    /// Returns total calm minutes (1 minute per session).
    /// Includes historical data inferred from garden plantings if session log is empty.
    static func totalCalmMinutes() -> Int {
        let loggedSessions = getAllLoggedSessions().count
        let flowers = totalFlowersPlanted()
        return max(loggedSessions, flowers)
    }
    
    /// Returns the current consecutive day streak.
    static func currentStreak() -> Int {
        // Collect all unique activity dates (sessions + plantings)
        var allDates: Set<Date> = Set(getAllLoggedSessions().map { Calendar.current.startOfDay(for: $0) })
        
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        for key in allKeys where key.hasPrefix("garden-") {
            if let data = UserDefaults.standard.data(forKey: key),
               let decoded = try? JSONDecoder().decode([Int: Date].self, from: data) {
                for date in decoded.values {
                    allDates.insert(Calendar.current.startOfDay(for: date))
                }
            }
        }
        
        let sortedDates = allDates.sorted(by: >)
        guard let latest = sortedDates.first else { return 0 }
        
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        // If the most recent activity was before yesterday, the streak is broken
        if latest < yesterday {
            return 0
        }
        
        var streak = 0
        var checkDate = latest
        
        for date in sortedDates {
            if Calendar.current.isDate(date, inSameDayAs: checkDate) {
                streak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        
        return streak
    }
}
